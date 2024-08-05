--------------------------------------------------------------------------------
-- hram_test.vhd                                                              --
-- HyperRAM tester.                                                           --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package hram_test_pkg is

  subtype hram_test_reg_addr_t is std_ulogic_vector(7 downto 0);
  subtype hram_test_reg_data_t is std_ulogic_vector(31 downto 0);

  constant RA_CTRL : std_ulogic_vector(7 downto 0) := x"00";
  constant RA_STAT : std_ulogic_vector(7 downto 0) := x"04";
  constant RA_BASE : std_ulogic_vector(7 downto 0) := x"08";
  constant RA_SIZE : std_ulogic_vector(7 downto 0) := x"0C";
  constant RA_DATA : std_ulogic_vector(7 downto 0) := x"10";
  constant RA_INCR : std_ulogic_vector(7 downto 0) := x"14";
  constant RA_EADD : std_ulogic_vector(7 downto 0) := x"18";
  constant RA_EDAT : std_ulogic_vector(7 downto 0) := x"1C";

  component hram_test is
    generic (
      ROWS_LOG2 : integer; -- e.g. 13 for 8k rows
      COLS_LOG2 : integer  -- e.g. 9 for 512 columns
    );
    port (
      x_rst     : in    std_ulogic;
      x_clk     : in    std_ulogic;
      s_rst     : in    std_ulogic;
      s_clk     : in    std_ulogic;
      s_en      : in    std_ulogic;
      s_we      : in    std_ulogic_vector(3 downto 0);
      s_addr    : in    std_ulogic_vector(7 downto 2);
      s_din     : in    std_ulogic_vector(31 downto 0);
      s_dout    : out   std_ulogic_vector(31 downto 0);
      h_rst_n   : out   std_logic;
      h_cs_n    : out   std_logic;
      h_clk     : out   std_logic;
      h_rwds    : inout std_logic;
      h_dq      : inout std_logic_vector(7 downto 0)
    );
  end component hram_test;

end package hram_test_pkg;

--------------------------------------------------------------------------------
-- entity/architecture

use work.tyto_types_pkg.all;
use work.tyto_utils_pkg.all;
use work.csr_pkg.all;
use work.sync_reg_u_pkg.all;
use work.overclock_pkg.all;
use work.hram_ctrl_pkg.all;
use work.hram_swizzle_pkg.all;
use work.hram_test_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity hram_test is
  generic (
    ROWS_LOG2 : integer; -- e.g. 13 for 8k rows
    COLS_LOG2 : integer  -- e.g. 9 for 512 columns
  );
  port (

    -- external (reference) clock for MMCM
    x_rst     : in    std_ulogic;
    x_clk     : in    std_ulogic;

    -- system bus (for register access)
    s_rst     : in    std_ulogic;
    s_clk     : in    std_ulogic;
    s_en      : in    std_ulogic;
    s_we      : in    std_ulogic_vector(3 downto 0);
    s_addr    : in    std_ulogic_vector(7 downto 2);
    s_din     : in    std_ulogic_vector(31 downto 0);
    s_dout    : out   std_ulogic_vector(31 downto 0);

    -- HyperRAM interface
    h_rst_n   : out   std_logic;                      -- reset
    h_cs_n    : out   std_logic;                      -- chip select
    h_clk     : out   std_logic;                      -- clock
    h_rwds    : inout std_logic;                      -- read/write data strobe
    h_dq      : inout std_logic_vector(7 downto 0)    -- command/address/data bus

  );
end entity hram_test;

architecture rtl of hram_test is

  --------------------------------------------------------------------------------

  constant BM        : integer := 4; -- burst magitude - width of BMAG field
  constant ADDR_MSB  : integer := ROWS_LOG2+COLS_LOG2;
  constant LEN_MSB   : integer := (2**BM)-1;

  constant ROW_SWIZZLE_TABLE : sulv_vector(0 to (2**ROWS_LOG2)-1)(ROWS_LOG2-1 downto 0) := swizzle_table(ROWS_LOG2);
  constant COL_SWIZZLE_TABLE : sulv_vector(0 to (2**COLS_LOG2)-1)(COLS_LOG2-1 downto 0) := swizzle_table(COLS_LOG2);

  --------------------------------------------------------------------------------
  -- registers

  alias reg_addr_t is hram_test_reg_addr_t;
  alias reg_data_t is hram_test_reg_data_t;
  type regs_data_t is array(natural range <>) of reg_data_t;

  constant CSR_DEFS : csr_defs_t(open)(
    addr(reg_addr_t'range),
    init(reg_data_t'range),
    bits(reg_data_t'range)
  ) := (
      ( RA_CTRL, x"FFFFFFFF", (BM+11 downto 0 => RW, others => RO)    ),
      ( RA_STAT, x"FFFFFFFF", (others => RO)                          ),
      ( RA_BASE, x"FFFFFFFF", (ADDR_MSB downto 1 => RW, others => RO) ),
      ( RA_SIZE, x"FFFFFFFF", (ADDR_MSB downto 1 => RW, others => RO) ),
      ( RA_DATA, x"FFFFFFFF", (others => RW)                          ),
      ( RA_INCR, x"FFFFFFFF", (others => RW)                          ),
      ( RA_EADD, x"FFFFFFFF", (others => RO)                          ),
      ( RA_EDAT, x"FFFFFFFF", (others => RO)                          )
  );

  signal s_csr_w : regs_data_t(CSR_DEFS'range);
  signal s_csr_p : regs_data_t(CSR_DEFS'range);
  signal s_csr_r : regs_data_t(CSR_DEFS'range) := (others => (others => '0'));

  alias s_csr_ctrl : std_ulogic_vector(31 downto 0) is s_csr_w(csr_addr_to_idx(RA_CTRL,CSR_DEFS));
  alias s_csr_stat : reg_data_t is s_csr_r(csr_addr_to_idx(RA_STAT,CSR_DEFS));
  alias s_csr_base : reg_data_t is s_csr_w(csr_addr_to_idx(RA_BASE,CSR_DEFS));
  alias s_csr_size : reg_data_t is s_csr_w(csr_addr_to_idx(RA_SIZE,CSR_DEFS));
  alias s_csr_data : reg_data_t is s_csr_w(csr_addr_to_idx(RA_DATA,CSR_DEFS));
  alias s_csr_incr : reg_data_t is s_csr_w(csr_addr_to_idx(RA_INCR,CSR_DEFS));
  alias s_csr_eadd : reg_data_t is s_csr_r(csr_addr_to_idx(RA_EADD,CSR_DEFS));
  alias s_csr_edat : reg_data_t is s_csr_r(csr_addr_to_idx(RA_EDAT,CSR_DEFS));

  alias s_csr_ctrl_clksel : std_ulogic_vector(1 downto 0)    is s_csr_ctrl(1 downto 0);
  alias s_csr_ctrl_run    : std_ulogic                       is s_csr_ctrl(2);
  alias s_csr_ctrl_r_w    : std_ulogic                       is s_csr_ctrl(3);
  alias s_csr_ctrl_reg    : std_ulogic                       is s_csr_ctrl(4);
  alias s_csr_ctrl_amode  : std_ulogic                       is s_csr_ctrl(5);               -- 0 = sequential, 1 = scattered
  alias s_csr_ctrl_wmode  : std_ulogic_vector(1 downto 0)    is s_csr_ctrl(7 downto 6);
  alias s_csr_ctrl_dmode  : std_ulogic_vector(2 downto 0)    is s_csr_ctrl(10 downto 8);
  alias s_csr_ctrl_bmode  : std_ulogic                       is s_csr_ctrl(11);              -- burst mode: 0 = fixed, 1 = PRNG
  alias s_csr_ctrl_bmag   : std_ulogic_vector(BM-1 downto 0) is s_csr_ctrl(BM+11 downto 12); -- burst magnitude

  alias s_csr_ctrl_wmode_cbm  : std_ulogic is s_csr_ctrl_wmode(0); -- checkerboard masking
  alias s_csr_ctrl_wmode_pol  : std_ulogic is s_csr_ctrl_wmode(1); -- checkerboard initial polarity
  alias s_csr_ctrl_dmode_rand : std_ulogic is s_csr_ctrl_dmode(0); -- regular or PRNG data
  alias s_csr_ctrl_dmode_cbi  : std_ulogic is s_csr_ctrl_dmode(1); -- checkerboard inversion
  alias s_csr_ctrl_dmode_pol  : std_ulogic is s_csr_ctrl_dmode(2); -- checkerboard initial polarity

  alias s_csr_stat_bsy : std_ulogic is s_csr_stat( 0); -- running
  alias s_csr_stat_fin : std_ulogic is s_csr_stat( 8); -- finished
  alias s_csr_stat_err : std_ulogic is s_csr_stat(16); -- error occurred
  alias s_csr_ctrl_lol : std_ulogic is s_csr_stat(24); -- loss of lock

  --------------------------------------------------------------------------------
  -- internal clock domain

  signal i_rst      : std_ulogic;
  signal i_clk      : std_ulogic;
  signal i_clk_dly  : std_ulogic;
  signal i_a_ready  : std_ulogic;
  signal i_a_valid  : std_ulogic;
  signal i_a_r_w    : std_ulogic;
  signal i_a_reg    : std_ulogic;
  signal i_a_wrap   : std_ulogic;
  signal i_a_len    : std_ulogic_vector(LEN_MSB downto 0);
  signal i_a_addr   : std_ulogic_vector(ADDR_MSB downto 1);
  signal i_w_ready  : std_ulogic;
  signal i_w_valid  : std_ulogic;
  signal i_w_last   : std_ulogic;
  signal i_w_be     : std_ulogic_vector(1 downto 0);
  signal i_w_data   : std_ulogic_vector(15 downto 0);
  signal i_r_ready  : std_ulogic;
  signal i_r_valid  : std_ulogic;
  signal i_r_last   : std_ulogic;
  signal i_r_data   : std_ulogic_vector(15 downto 0);

  signal i_run      : std_ulogic;
  signal i_bsy      : std_ulogic;
  signal i_fin      : std_ulogic;
  signal i_err      : std_ulogic;

  signal i_r_w      : std_ulogic;
  signal i_reg      : std_ulogic;
  signal i_count    : std_ulogic_vector(i_a_addr'range);
  signal i_lm       : std_ulogic_vector(i_a_len'range);  -- len mask
  signal i_len      : std_ulogic_vector(i_a_len'range);
  signal i_addr     : std_ulogic_vector(i_a_addr'range);
  signal i_col_swz  : std_ulogic_vector(COLS_LOG2-1 downto 0);
  signal i_row_swz  : std_ulogic_vector(ROWS_LOG2-1 downto 0);
  signal i_addr_swz : std_ulogic_vector(i_a_addr'range); -- address, swizzled
  signal i_word     : std_ulogic;
  signal i_data     : std_ulogic_vector(31 downto 0);
  signal i_eadd     : std_ulogic_vector(i_a_addr'range);
  signal i_edat     : std_ulogic_vector(31 downto 0);

  signal incr_data  : std_ulogic_vector(31 downto 0);

  alias i_col : std_ulogic_vector(COLS_LOG2-1 downto 0) is i_addr(COLS_LOG2 downto 1);
  alias i_row : std_ulogic_vector(ROWS_LOG2-1 downto 0) is i_addr(ROWS_LOG2+COLS_LOG2 downto COLS_LOG2+1);

  type state_a_t is (A_IDLE,A_PRNG,A_PREP1,A_PREP2,A_PREP3,A_ADDR,A_DONE);
  signal state_a : state_a_t;

  type state_d_t is (D_IDLE,D_PREP,W_DATA,W_DONE,R_DATA);
  signal state_d : state_d_t;

  --------------------------------------------------------------------------------
  -- PRNG related

  signal prng_init  : std_ulogic;
  signal prng_seed  : std_ulogic_vector(127 downto 0);
  signal prng_ready : std_ulogic;
  signal prng_valid : std_ulogic;
  signal prng_data  : std_ulogic_vector(31 downto 0);

  component rng_xoshiro128plusplus is
    generic (
      INIT_SEED : std_logic_vector(127 downto 0);
      PIPELINE  : boolean := true
    );
    port (
      clk       : in    std_logic;
      rst       : in    std_logic;
      reseed    : in    std_logic;
      newseed   : in    std_logic_vector(127 downto 0);
      out_ready : in    std_logic;
      out_valid : out   std_logic;
      out_data  : out   std_logic_vector(31 downto 0)
    );
  end component;

  --------------------------------------------------------------------------------

begin

  --------------------------------------------------------------------------------

  U_CSR: component csr
    generic map (
      reg_addr_t => reg_addr_t,
      reg_data_t => reg_data_t,
      csr_defs_t => csr_defs_t,
      CSR_DEFS   => CSR_DEFS,
      ADDR_MASK  => "00011100" -- 8 registers max
    )
    port map (
      rst  => s_rst,
      clk  => s_clk,
      en   => s_en,
      we   => s_we,
      addr => s_addr,
      din  => s_din,
      dout => s_dout,
      w    => s_csr_w,
      p    => s_csr_p,
      r    => s_csr_r
    );

  s_csr_eadd <= (ADDR_MSB downto 1 => i_eadd, others => '0');
  s_csr_edat <= i_edat;

  --------------------------------------------------------------------------------

  U_SYNC_S: component sync_reg_u
    generic map (
      STAGES => 3
    )
    port map (
      rst   => s_rst,
      clk   => s_clk,
      i(0)  => i_bsy,
      i(1)  => i_fin,
      i(2)  => i_err,
      i(3)  => i_rst,
      o(0)  => s_csr_stat_bsy,
      o(1)  => s_csr_stat_fin,
      o(2)  => s_csr_stat_err,
      o(3)  => s_csr_ctrl_lol
    );

  U_SYNC_I: component sync_reg_u
    generic map (
      STAGES => 3
    )
    port map (
      rst   => i_rst,
      clk   => i_clk,
      i(0)  => s_csr_ctrl_run,
      o(0)  => i_run
    );

  --------------------------------------------------------------------------------

  U_MMCM: component overclock
    port map (
      rsti      => x_rst,
      clki      => x_clk,
      sel       => s_csr_ctrl_clksel,
      s_rst     => i_rst,
      s_clk     => i_clk,
      s_clk_dly => i_clk_dly
    );

  --------------------------------------------------------------------------------

  P_COMB: process(all)
  begin

    i_a_wrap  <= '0'; -- TODO excercise wrapping

    i_addr_swz <= i_row_swz & i_col_swz;

    prng_ready <= '1' when (state_a = A_PREP1) or (
      (s_csr_ctrl_dmode_rand = '1') and (
        (state_d = D_PREP) or
        (i_w_valid = '1' and i_w_ready = '1') or
        (i_r_valid = '1' and i_r_ready = '1')
      )
    ) else '0';

  end process P_COMB;


  P_MAIN: process(i_rst,i_clk)

    procedure i_data_update is
      variable s : std_ulogic_vector(1 downto 0);
    begin
      if s_csr_ctrl_dmode_rand then -- random
        i_data <= prng_data(31 downto 16) when i_word else prng_data(15 downto 0);
      else -- regular (handle checkerboard inversion)
        if s_csr_ctrl_dmode_cbi then
          s := s_csr_ctrl_dmode_pol & i_word;
          case s is
            when "00"   => i_data <=     incr_data(15 downto  8) & not incr_data( 7 downto  0);
            when "01"   => i_data <= not incr_data(31 downto 24) &     incr_data(23 downto 16);
            when "10"   => i_data <= not incr_data(15 downto  8) &     incr_data( 7 downto  0);
            when "11"   => i_data <=     incr_data(31 downto 24) & not incr_data(23 downto 16);
            when others => i_data <= (others => 'X');
          end case;
        else
          i_data <= incr_data;
        end if;
      end if;
    end procedure i_data_update;

  begin
    if i_rst = '1' then

      i_a_valid  <= '0';
      i_a_r_w    <= 'X';
      i_a_reg    <= 'X';
      i_a_wrap   <= 'X';
      i_a_len    <= (others => 'X');
      i_a_addr   <= (others => 'X');
      i_w_valid  <= '0';
      i_w_be     <= (others => 'X');
      i_w_data   <= (others => 'X');
      i_r_valid  <= '0';
      i_bsy      <= '0';
      i_fin      <= '0';
      i_err      <= '0';
      i_lm       <= (others => 'X');
      i_addr     <= (others => 'X');
      state_a    <= A_IDLE;
      state_d    <= D_IDLE;

    elsif rising_edge(i_clk) then

      --------------------------------------------------------------------------------
      -- address swizzling (synchronous ROM)

      i_row_swz <= ROW_SWIZZLE_TABLE(to_integer(unsigned(i_row)));
      i_col_swz <= COL_SWIZZLE_TABLE(to_integer(unsigned(i_col)));

      --------------------------------------------------------------------------------
      -- address state machine

      -- default states
      prng_init  <= '0';
      prng_ready <= '0';

      -- address channel state machine
      case state_a is

        when A_IDLE =>
          if i_run then
            i_bsy    <= '1';
            i_count   <= s_csr_size(ADDR_MSB downto 1);
            i_lm      <= (to_integer(unsigned(s_csr_ctrl_bmag)) downto 0 => '1', others => '0');
            i_addr    <= s_csr_base(ADDR_MSB downto 1);
            prng_init <= '1';
            state_a   <= A_PRNG;
          end if;

        -- wait until PRNG ready
        when A_PRNG =>
          if prng_valid then
            prng_ready <= '1';
            state_a    <= A_PREP1;
          end if;

        when A_PREP1 =>
          i_r_w <= s_csr_ctrl_r_w;
          i_reg <= s_csr_ctrl_reg;
          if s_csr_ctrl_amode = '0' then -- sequential addressing
            if s_csr_ctrl_bmode = '0' then -- fixed burst length
              i_len <= (others => '0');
              i_len(to_integer(unsigned(s_csr_ctrl_bmag))) <= '1';
            else -- PRNG burst length
              i_len <= i_lm and prng_data;
            end if;
          else -- scattered addressing => burst length is always 1
            i_len  <= (0 => '1', others => '0');
          end if;
          state_a <= A_PREP2;

        when A_PREP2 =>
          if unsigned(i_len) > unsigned(i_count) then
            i_len <= i_count;
          end if;
          state_a <= A_PREP3;

        when A_PREP3 =>
          i_a_valid  <= '1';
          i_a_r_w    <= i_r_w;
          i_a_reg    <= i_reg;
          i_a_len    <= i_len;
          if s_csr_ctrl_amode = '0' then -- sequential addressing
            i_a_addr <= i_addr;
          else -- scattered addressing => burst length is always 1
            i_a_addr <= i_addr_swz;
          end if;
          i_count <= std_ulogic_vector(unsigned(i_count) - unsigned(i_len));
          if s_csr_ctrl_amode = '0' then -- sequential addressing
            i_addr <= std_ulogic_vector(unsigned(i_addr) + unsigned(i_len));
          else -- scattered addressing - increment row before col
            i_row <= incr(i_row);
            i_col <= incr(i_col) when unsigned(not i_row) = 0 else i_col;
          end if;
          state_a <= A_ADDR;

        when A_ADDR => -- present address until it is accepted
          if i_a_ready = '1' then
            i_a_valid  <= '0';
            i_a_r_w    <= 'X';
            i_a_reg    <= 'X';
            i_a_wrap   <= 'X';
            i_a_len    <= (others => 'X');
            i_a_addr   <= (others => 'X');
            if unsigned(i_count) = 0 then
              i_fin   <= '1';
              state_a <= A_DONE;
            else
              state_a <= A_PREP1;
            end if;
          end if;

        when A_DONE =>
          if i_run = '0' and state_d = D_IDLE then
            i_bsy   <= '0';
            state_a <= A_IDLE;
          end if;

        when others => null;
      end case;

      --------------------------------------------------------------------------------
      -- data state machine

      case state_d is

        when D_IDLE =>
          if i_a_valid and i_a_ready then
            i_err     <= '0';
            i_eadd    <= i_a_addr;
            i_edat    <= (others => 'X');
            i_word    <= '0';
            incr_data <= s_csr_data;
          end if;

        when D_PREP =>
          i_data_update;
          if not s_csr_ctrl_dmode_rand then
            incr_data <= std_ulogic_vector(unsigned(incr_data)+unsigned(s_csr_incr));
          end if;
          if i_r_w then
            state_d <= R_DATA;
          else
            state_d <= W_DATA;
          end if;

        when W_DATA =>
          if (not i_w_valid) or (i_w_valid and i_w_ready) then
            i_w_valid <= '1';
            i_data_update;
            if not s_csr_ctrl_dmode_rand then
              incr_data <= std_ulogic_vector(unsigned(incr_data)+unsigned(s_csr_incr));
            end if;
            i_word <= not i_word;
            if i_w_valid and i_w_ready and i_w_last then
              i_w_valid <= '0';
              i_w_data  <= (others => 'X');
              state_d <= D_IDLE;
            end if;
          end if;

        when R_DATA =>
          i_r_ready <= '1';
          if i_r_valid and i_r_ready then
            if i_r_data /= i_data and i_err = '0' then
              i_err  <= '1';
              --i_eadd <=
              i_edat(15 downto  0) <= i_r_data;
              i_edat(31 downto 16) <= i_data;
            end if;
            i_data_update;
            i_eadd <= incr(i_eadd);
          end if;

      end case;

      --------------------------------------------------------------------------------

    end if;
  end process P_MAIN;

  U_CTRL: component hram_ctrl
    generic map (
      PARAMS => HRAM_CTRL_PARAMS_100_100
    )
    port map (
      s_rst     => i_rst,
      s_clk     => i_clk,
      s_clk_dly => i_clk_dly,
      s_a_ready => i_a_ready,
      s_a_valid => i_a_valid,
      s_a_r_w   => i_a_r_w,
      s_a_reg   => i_a_reg,
      s_a_wrap  => i_a_wrap,
      s_a_len   => i_a_len,
      s_a_addr  => i_a_addr,
      s_w_ready => i_w_ready,
      s_w_valid => i_w_valid,
      s_w_last  => i_w_last,
      s_w_be    => i_w_be,
      s_w_data  => i_w_data,
      s_r_ready => i_r_ready,
      s_r_valid => i_r_valid,
      s_r_last  => i_r_last,
      s_r_data  => i_r_data,
      h_rst_n   => h_rst_n,
      h_cs_n    => h_cs_n,
      h_clk     => h_clk,
      h_rwds    => h_rwds,
      h_dq      => h_dq
    );

  --------------------------------------------------------------------------------

  prng_seed <= s_csr_data & not s_csr_data & mirror(s_csr_data) & not mirror(s_csr_data);

  U_PRNG: component rng_xoshiro128plusplus
    generic map (
      INIT_SEED => (others => '0')
    )
    port map (
      clk       => i_clk,
      rst       => i_rst,
      reseed    => prng_init,
      newseed   => prng_seed,
      out_ready => prng_ready,
      out_valid => prng_valid,
      out_data  => prng_data
    );

  --------------------------------------------------------------------------------

end architecture rtl;
