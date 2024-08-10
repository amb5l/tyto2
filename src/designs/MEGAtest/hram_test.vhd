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

  constant BMW       : integer := 4; -- burst magitude (BMAG) field width
  constant ADDR_MSB  : integer := ROWS_LOG2+COLS_LOG2;
  constant LEN_MSB   : integer := (2**BMW)-1;

  --------------------------------------------------------------------------------
  -- registers

  constant RA_HI : integer := 4;
  constant RA_LO : integer := 2;

  alias reg_data_t is hram_test_reg_data_t;
  subtype regs_data_t is sulv_vector(open)(31 downto 0);

  function csr_bits_addr return csr_bits_t is
    variable r : csr_bits_t(reg_data_t'range) := (others => RO);
  begin
    r(ADDR_MSB downto 1) := (others => RW);
    return r;
  end function csr_bits_addr;

  constant CSR_DEFS : csr_defs_t(open)(
    addr(RA_HI downto RA_LO),
    init(reg_data_t'range),
    bits(reg_data_t'range)
  ) := (
      ( RA_CTRL(RA_HI downto RA_LO), x"00000000", (BMW+11 downto 0 => RW, others => RO)   ),
      ( RA_STAT(RA_HI downto RA_LO), x"00000000", (others => RO)                          ),
      ( RA_BASE(RA_HI downto RA_LO), x"00000000", csr_bits_addr                           ),
      ( RA_SIZE(RA_HI downto RA_LO), x"FFFFFFFF", csr_bits_addr                           ),
      ( RA_DATA(RA_HI downto RA_LO), x"00000000", (others => RW)                          ),
      ( RA_INCR(RA_HI downto RA_LO), x"00000000", (others => RW)                          ),
      ( RA_EADD(RA_HI downto RA_LO), x"00000000", (others => RO)                          ),
      ( RA_EDAT(RA_HI downto RA_LO), x"00000000", (others => RO)                          )
  );

  signal s_csr_w : regs_data_t(CSR_DEFS'range);
  signal s_csr_p : regs_data_t(CSR_DEFS'range);
  signal s_csr_r : regs_data_t(CSR_DEFS'range) := (others => (others => '0'));

  alias s_csr_ctrl : reg_data_t is s_csr_w(csr_addr_to_idx(RA_CTRL(RA_HI downto RA_LO),CSR_DEFS));
  alias s_csr_stat : reg_data_t is s_csr_r(csr_addr_to_idx(RA_STAT(RA_HI downto RA_LO),CSR_DEFS));
  alias s_csr_base : reg_data_t is s_csr_w(csr_addr_to_idx(RA_BASE(RA_HI downto RA_LO),CSR_DEFS));
  alias s_csr_size : reg_data_t is s_csr_w(csr_addr_to_idx(RA_SIZE(RA_HI downto RA_LO),CSR_DEFS));
  alias s_csr_data : reg_data_t is s_csr_w(csr_addr_to_idx(RA_DATA(RA_HI downto RA_LO),CSR_DEFS));
  alias s_csr_incr : reg_data_t is s_csr_w(csr_addr_to_idx(RA_INCR(RA_HI downto RA_LO),CSR_DEFS));
  alias s_csr_eadd : reg_data_t is s_csr_r(csr_addr_to_idx(RA_EADD(RA_HI downto RA_LO),CSR_DEFS));
  alias s_csr_edat : reg_data_t is s_csr_r(csr_addr_to_idx(RA_EDAT(RA_HI downto RA_LO),CSR_DEFS));

  alias s_csr_ctrl_clksel : std_ulogic_vector(1 downto 0)     is s_csr_ctrl(1 downto 0);
  alias s_csr_ctrl_run    : std_ulogic                        is s_csr_ctrl(2);
  alias s_csr_ctrl_r_w    : std_ulogic                        is s_csr_ctrl(3);
  alias s_csr_ctrl_reg    : std_ulogic                        is s_csr_ctrl(4);
  alias s_csr_ctrl_amode  : std_ulogic                        is s_csr_ctrl(5);                -- 0 = sequential, 1 = randomised
  alias s_csr_ctrl_wmode  : std_ulogic_vector(1 downto 0)     is s_csr_ctrl(7 downto 6);
  alias s_csr_ctrl_dmode  : std_ulogic_vector(2 downto 0)     is s_csr_ctrl(10 downto 8);
  alias s_csr_ctrl_bmode  : std_ulogic                        is s_csr_ctrl(11);               -- burst mode: 0 = fixed, 1 = PRNG
  alias s_csr_ctrl_bmag   : std_ulogic_vector(BMW-1 downto 0) is s_csr_ctrl(BMW+11 downto 12); -- burst magnitude

  alias s_csr_ctrl_wmode_cbm  : std_ulogic is s_csr_ctrl_wmode(0); -- checkerboard masking
  alias s_csr_ctrl_wmode_pol  : std_ulogic is s_csr_ctrl_wmode(1); -- checkerboard initial polarity
  alias s_csr_ctrl_dmode_rand : std_ulogic is s_csr_ctrl_dmode(0); -- regular or PRNG data
  alias s_csr_ctrl_dmode_cbi  : std_ulogic is s_csr_ctrl_dmode(1); -- checkerboard inversion
  alias s_csr_ctrl_dmode_pol  : std_ulogic is s_csr_ctrl_dmode(2); -- checkerboard initial polarity

  alias s_csr_stat_bsy : std_ulogic is s_csr_stat( 0); -- running
  alias s_csr_stat_fin : std_ulogic is s_csr_stat( 8); -- finished
  alias s_csr_stat_err : std_ulogic is s_csr_stat(16); -- error occurred
  alias s_csr_ctrl_lol : std_ulogic is s_csr_stat(24); -- loss of lock

  -- register fields synchronised to internal clock domain

  signal i_csr_ctrl_run      : std_ulogic;

  --------------------------------------------------------------------------------
  -- internal clock domain

  -- reset and clocks
  signal i_rst      : std_ulogic;
  signal i_clk      : std_ulogic;
  signal i_clk_dly  : std_ulogic;

  -- controller system interface
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

  -- test controller status
  signal t_bsy      : std_ulogic;
  signal t_fin      : std_ulogic;
  signal t_err      : std_ulogic;

  -- address state machine
  type state_a_t is (A_IDLE,A_PRNG,A_PREP1,A_PREP2,A_PREP3,A_VALID,A_DONE);
  signal state_a    : state_a_t;
  signal a_count    : std_ulogic_vector(i_a_addr'range); -- count remaining words
  signal a_lm       : std_ulogic_vector(i_a_len'range);  -- len mask
  signal a_len      : std_ulogic_vector(i_a_len'range);
  signal a_addr     : std_ulogic_vector(i_a_addr'range);
  signal a_row_rnd  : std_ulogic_vector(ROWS_LOG2-1 downto 0);
  signal a_addr_rnd : std_ulogic_vector(i_a_addr'range); -- address, swizzled
  alias a_col : std_ulogic_vector(COLS_LOG2-1 downto 0) is a_addr(COLS_LOG2 downto 1);
  alias a_row : std_ulogic_vector(ROWS_LOG2-1 downto 0) is a_addr(ROWS_LOG2+COLS_LOG2 downto COLS_LOG2+1);

  -- data state machine
  type state_d_t is (D_IDLE,D_PRNG,D_PREP,D_WAIT,D_WR,D_RD,D_DONE);
  signal state_d : state_d_t;
  signal d_word     : std_ulogic;
  signal d_data     : std_ulogic_vector(31 downto 0);
  signal d_eadd     : std_ulogic_vector(i_a_addr'range);
  signal d_edat     : std_ulogic_vector(31 downto 0);
  signal incr_data  : std_ulogic_vector(31 downto 0);

  --------------------------------------------------------------------------------
  -- synthesisable PRNG

  signal prng_a_init  : std_ulogic;
  signal prng_a_seed  : std_ulogic_vector(127 downto 0);
  signal prng_a_ready : std_ulogic;
  signal prng_a_valid : std_ulogic;
  signal prng_a_data  : std_ulogic_vector(31 downto 0);

  signal prng_d_init  : std_ulogic;
  signal prng_d_seed  : std_ulogic_vector(127 downto 0);
  signal prng_d_ready : std_ulogic;
  signal prng_d_valid : std_ulogic;
  signal prng_d_data  : std_ulogic_vector(31 downto 0);

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
  -- row address randomisation:
  -- TODO fix this to guarantee 1:1 mapping

  impure function random_1to1(n : integer) return sulv_vector is
    variable r    : sulv_vector(0 to (2**n)-1)(n-1 downto 0);
    variable v    : std_ulogic_vector(n-1 downto 0);
    variable prng : prng_t;
    function find(v : std_ulogic_vector; t : sulv_vector) return boolean is
    begin
      for i in t'range loop
        if t(i) = v then
          return true;
        end if;
      end loop;
      return false;
    end function find;
  begin
    prng.rand_seed(123,456);
    r := (others => (others => 'X'));
    outer: for i in r'range loop
      inner: loop
        v := prng.rand_slv(0,(2**n)-1,n);
        if not find(v,r) then
          r(i) := v;
      --    report "random_table: i =" & integer'image(i) & "r(i) =" & to_hstring(r(i));
          exit inner;
        end if;
      end loop inner;
    end loop outer;
    return r;
  end function random_1to1;

  constant ROW_RANDOM_TABLE : sulv_vector(0 to (2**ROWS_LOG2)-1)(ROWS_LOG2-1 downto 0) := random_1to1(ROWS_LOG2);

  --------------------------------------------------------------------------------

begin

  --------------------------------------------------------------------------------

  U_CSR: component csr
    generic map (
      CSR_DEFS  => CSR_DEFS
    )
    port map (
      rst  => s_rst,
      clk  => s_clk,
      en   => s_en,
      we   => s_we,
      addr => s_addr(RA_HI downto RA_LO),
      din  => s_din,
      dout => s_dout,
      w    => s_csr_w,
      p    => s_csr_p,
      r    => s_csr_r
    );

  P_CSR: process(all)
  begin
    s_csr_eadd <= (others => '0');
    s_csr_eadd(ADDR_MSB downto 1) <= d_eadd;
    s_csr_edat <= d_edat;
  end process P_CSR;

  --------------------------------------------------------------------------------

  U_SYNC_S: component sync_reg_u -- v4p ignore w-301 (missing port associations)
    generic map (
      STAGES => 3
    )
    port map (
      clk   => s_clk,
      i(0)  => t_bsy,
      i(1)  => t_fin,
      i(2)  => t_err,
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
      o(0)  => i_csr_ctrl_run
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

  i_a_wrap  <= '0'; -- TODO exercise wrapping?

  P_LM: process(s_csr_ctrl_bmag)
  begin
    a_lm <= (others => '0');
    a_lm(to_integer(unsigned(s_csr_ctrl_bmag)) downto 0) <= (others => '1');
  end process P_LM;

  a_addr_rnd <= a_row_rnd & a_col;

  prng_a_ready <= bool2sl(state_a = A_PREP1) and s_csr_ctrl_bmode and not s_csr_ctrl_amode;

  prng_d_ready <=
    bool2sl(state_d = D_PREP) or
    (bool2sl(state_d = D_WR) and d_word and ((i_w_valid and i_w_ready and not i_w_last) or not i_w_valid)) or
    (bool2sl(state_d = D_RD) and d_word and i_r_valid and i_r_ready);

  P_MAIN: process(i_rst,i_clk)

    procedure i_data_update is
    begin
      if s_csr_ctrl_dmode_rand then -- random
        d_data <= prng_d_data;
      else -- regular
        d_data <= incr_data;
        incr_data <= std_ulogic_vector(unsigned(incr_data)+unsigned(s_csr_incr));
      end if;
    end procedure i_data_update;

    variable x : std_ulogic_vector(31 downto 0);
    variable d : std_ulogic_vector(31 downto 0);

  begin
    if i_rst = '1' then

      i_a_valid    <= '0';
      i_a_r_w      <= 'X';
      i_a_reg      <= 'X';
      i_a_len      <= (others => 'X');
      i_a_addr     <= (others => 'X');
      i_w_valid    <= '0';
      i_w_be       <= (others => 'X');
      i_w_data     <= (others => 'X');
      i_r_ready    <= '0';
      t_bsy        <= '0';
      t_fin        <= '0';
      t_err        <= '0';
      a_addr       <= (others => 'X');
      state_a      <= A_IDLE;
      state_d      <= D_IDLE;
      prng_a_init  <= '0';
      prng_d_init  <= '0';

    elsif rising_edge(i_clk) then

      -- synchronous ROM
      a_row_rnd <= ROW_RANDOM_TABLE(to_integer(unsigned(a_row)));

      --------------------------------------------------------------------------------
      -- address state machine

      -- default states
      prng_a_init  <= '0';
      prng_d_init  <= '0';

      -- address channel state machine
      case state_a is

        when A_IDLE =>
          if i_csr_ctrl_run then
            t_bsy       <= '1';
            a_count     <= s_csr_size(ADDR_MSB downto 1);
            a_addr      <= s_csr_base(ADDR_MSB downto 1);
            d_word      <= '0';
            incr_data   <= s_csr_data;
            prng_a_init <= '1';
            state_a     <= A_PRNG;
          end if;

        when A_PRNG => -- wait until PRNG ready
          if prng_a_valid and not prng_a_init then
            state_a <= A_PREP1;
          end if;

        when A_PREP1 =>
          if s_csr_ctrl_amode = '0' then -- sequential addressing
            if s_csr_ctrl_bmode = '0' then -- fixed burst length
              a_len <= (others => '0');
              a_len(to_integer(unsigned(s_csr_ctrl_bmag))) <= '1';
            else -- PRNG burst length
              a_len <= incr(a_lm and prng_a_data(a_lm'range));
            end if;
          else -- randomised addressing => burst length is always 1
            a_len  <= (0 => '1', others => '0');
          end if;
          state_a <= A_PREP2;

        when A_PREP2 =>
          if unsigned(a_len) > unsigned(a_count) then
            a_len <= a_count(a_count'right+a_len'length-1 downto a_count'right);
          end if;
          state_a <= A_PREP3;

        when A_PREP3 =>
          i_a_valid  <= '1';
          i_a_r_w    <= s_csr_ctrl_r_w;
          i_a_reg    <= s_csr_ctrl_reg;
          i_a_len    <= a_len;
          if s_csr_ctrl_amode = '0' then -- sequential addressing
            i_a_addr <= a_addr;
          else -- randomised addressing => burst length is always 1
            i_a_addr <= a_addr_rnd;
          end if;
          a_count <= std_ulogic_vector(unsigned(a_count) - unsigned(a_len));
          if s_csr_ctrl_amode = '0' then -- sequential addressing
            a_addr <= std_ulogic_vector(unsigned(a_addr) + unsigned(a_len));
          else -- randomised addressing - increment row before col
            a_row <= incr(a_row);
            a_col <= incr(a_col) when unsigned(not a_row) = 0 else a_col;
          end if;
          state_a <= A_VALID;

        when A_VALID => -- present address until it is accepted
          if i_a_ready = '1' then
            i_a_valid  <= '0';
            i_a_r_w    <= 'X';
            i_a_reg    <= 'X';
            i_a_len    <= (others => 'X');
            i_a_addr   <= (others => 'X');
            if unsigned(a_count) = 0 then
              state_a <= A_DONE;
            else
              state_a <= A_PREP1;
            end if;
          end if;

        when A_DONE => -- test sequence is complete
          if state_d = D_DONE then
            t_fin <= '1';
            if i_csr_ctrl_run = '0' then
              t_bsy   <= '0';
              t_fin   <= '0';
              state_a <= A_IDLE;
            end if;
          end if;

        when others => null;
      end case;

      --------------------------------------------------------------------------------
      -- data state machine

      case state_d is

        when D_IDLE =>
          if i_csr_ctrl_run then
            prng_d_init <= '1';
            state_d     <= D_PRNG;
          end if;

        when D_PRNG => -- wait until PRNG ready
          if prng_d_valid and not prng_d_init then
            state_d <= D_PREP;
          end if;

        when D_PREP =>
          i_data_update;
          t_err     <= '0';
          d_edat    <= (others => 'X');
          state_d   <= D_WAIT;

        when D_WAIT =>
          if i_a_valid and i_a_ready then
            if t_err = '0' then
              d_eadd  <= i_a_addr;
            end if;
            if s_csr_ctrl_r_w then
              state_d <= D_RD;
            else
              state_d <= D_WR;
            end if;
          end if;

        when D_WR =>
          if s_csr_ctrl_dmode_cbi then
            x := x"00FF_FF00" when s_csr_ctrl_dmode_pol = '1' else x"FF00_00FF";
          else
            x := x"0000_0000";
          end if;
          d := d_data xor x;
          if not i_w_valid then
            i_w_valid <= '1';
            i_w_be    <= "11"; -- TODO fix this to support masking
            if d_word then
              i_w_be <= not s_csr_ctrl_wmode_pol & s_csr_ctrl_wmode_pol
                when s_csr_ctrl_wmode_cbm = '1' else "11";
              i_w_data <= d(31 downto 16);
              i_data_update;
            else
              i_w_be <= s_csr_ctrl_wmode_pol & not s_csr_ctrl_wmode_pol
                when s_csr_ctrl_wmode_cbm = '1' else "11";
              i_w_data <= d(15 downto 0);
            end if;
            d_word <= not d_word;
          elsif i_w_valid and i_w_ready then
            if i_w_last then
              i_w_valid <= '0';
              i_w_be    <= (others => 'X');
              i_w_data  <= (others => 'X');
              state_d   <= D_DONE when state_a = A_DONE else D_WAIT;
            else
              if d_word then
                i_w_be <= not s_csr_ctrl_wmode_pol & s_csr_ctrl_wmode_pol
                  when s_csr_ctrl_wmode_cbm = '1' else "11";
                i_w_data <= d(31 downto 16);
                i_data_update;
              else
                i_w_be <= s_csr_ctrl_wmode_pol & not s_csr_ctrl_wmode_pol
                  when s_csr_ctrl_wmode_cbm = '1' else "11";
                i_w_data <= d(15 downto 0);
              end if;
              d_word <= not d_word;
            end if;
          end if;

        when D_RD =>
          if s_csr_ctrl_dmode_cbi then
            x := x"00FF_FF00" when s_csr_ctrl_dmode_pol = '1' else x"FF00_00FF";
          else
            x := x"0000_0000";
          end if;
          d := d_data xor x;
          if i_r_valid and i_r_ready then
            if t_err = '0' then
              if (d_word = '0' and i_r_data /= d(15 downto  0))
              or (d_word = '1' and i_r_data /= d(31 downto 16))
              then
                t_err  <= '1';
                d_edat(15 downto  0) <= i_r_data;
                d_edat(31 downto 16) <= d(31 downto 16) when d_word = '1' else d(15 downto 0);
              else
                d_eadd <= incr(d_eadd);
              end if;
            end if;
            if d_word then
              i_data_update;
            end if;
            d_word <= not d_word;
          end if;
          if i_r_valid and i_r_ready and i_r_last then
            i_r_ready <= '0';
            state_d   <= D_DONE when state_a = A_DONE else D_WAIT;
          elsif not i_r_ready then
            i_r_ready <= '1';
          end if;

        when D_DONE =>
          if i_csr_ctrl_run = '0' then
            state_d <= D_IDLE;
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

  prng_a_seed <=
    x"DEADBEEFBAADF00D0D15EA5EA5A5A5A5" xor
    s_csr_data & s_csr_data & s_csr_data & s_csr_data;

  U_PRNG_A: component rng_xoshiro128plusplus
    generic map (
      INIT_SEED => (others => '0')
    )
    port map (
      clk       => i_clk,
      rst       => i_rst,
      reseed    => prng_a_init,
      newseed   => prng_a_seed,
      out_ready => prng_a_ready,
      out_valid => prng_a_valid,
      out_data  => prng_a_data
    );

  -- TODO: consider using s_csr_incr for prng_d_seed
  prng_d_seed <= mirror(prng_a_seed);

  U_PRNG_D: component rng_xoshiro128plusplus
    generic map (
      INIT_SEED => (others => '0')
    )
    port map (
      clk       => i_clk,
      rst       => i_rst,
      reseed    => prng_d_init,
      newseed   => prng_d_seed,
      out_ready => prng_d_ready,
      out_valid => prng_d_valid,
      out_data  => prng_d_data
    );

  --------------------------------------------------------------------------------

end architecture rtl;
