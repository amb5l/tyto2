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
  constant RA_ERRL : std_ulogic_vector(7 downto 0) := x"18";
  constant RA_ERRH : std_ulogic_vector(7 downto 0) := x"1C";

  component hram_test is
    generic (
      ROWS_LOG2 : integer; -- e.g. 13 for 8k rows
      COLS_LOG2 : integer  -- e.g. 9 for 512 columns
    );
    port (
      x_rst   : in    std_ulogic;
      x_clk   : in    std_ulogic;
      s_rst   : in    std_ulogic;
      s_clk   : in    std_ulogic;
      s_en    : in    std_ulogic;
      s_r_w   : in    std_ulogic;
      s_bwe   : in    std_ulogic_vector(3 downto 0);
      s_addr  : in    std_ulogic_vector(7 downto 2);
      s_din   : in    std_ulogic_vector(31 downto 0);
      s_dout  : out   std_ulogic_vector(31 downto 0);
      h_rst_n : out   std_logic;
      h_cs_n  : out   std_logic;
      h_clk   : out   std_logic;
      h_rwds  : inout std_logic;
      h_dq    : inout std_logic_vector(7 downto 0)
    );
  end component hram_test;

end package hram_test_pkg;

--------------------------------------------------------------------------------
-- entity/architecture

use work.tyto_types_pkg.all;
use work.tyto_utils_pkg.all;
use work.csr_pkg.all;
use work.sync_pkg.all;
use work.overclock_pkg.all;
use work.hram_ctrl_pkg.all;
use work.random_1to1_pkg.all;
use work.hram_test_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

entity hram_test is
  generic (
    ROWS_LOG2 : integer; -- e.g. 13 for 8k rows
    COLS_LOG2 : integer  -- e.g. 9 for 512 columns
  );
  port (

    -- external (reference) clock for MMCM
    x_rst   : in    std_ulogic;
    x_clk   : in    std_ulogic;

    -- system bus (for register access)
    s_rst   : in    std_ulogic;
    s_clk   : in    std_ulogic;
    s_en    : in    std_ulogic;
    s_r_w   : in    std_ulogic;
    s_bwe   : in    std_ulogic_vector(3 downto 0);
    s_addr  : in    std_ulogic_vector(7 downto 2);
    s_din   : in    std_ulogic_vector(31 downto 0);
    s_dout  : out   std_ulogic_vector(31 downto 0);

    -- HyperRAM interface
    h_rst_n : out   std_logic;                      -- reset
    h_cs_n  : out   std_logic;                      -- chip select
    h_clk   : out   std_logic;                      -- clock
    h_rwds  : inout std_logic;                      -- read/write data strobe
    h_dq    : inout std_logic_vector(7 downto 0)    -- command/address/data bus

  );
end entity hram_test;

architecture rtl of hram_test is

  --------------------------------------------------------------------------------

  constant BMW      : integer := 4; -- burst magitude (BMAG) field width
  constant ADDR_MSB : integer := ROWS_LOG2+COLS_LOG2;
  constant LEN_MSB  : integer := (2**BMW)-1;

  --------------------------------------------------------------------------------
  -- registers

  constant RA_HI : integer := 4; -- register address MSB (enough for 8 registers)
  constant RA_LO : integer := 2; -- register address LSB

  function ra(addr : std_ulogic_vector) return std_ulogic_vector is
  begin
    return addr(RA_HI downto RA_LO);
  end function ra;

  alias reg_data_t is hram_test_reg_data_t;
  subtype regs_data_t is sulv_vector(open)(31 downto 0);

  constant csr_ctrl_bits : csr_bits_t(31 downto 0) := (
    31 downto 16 => RW,
    BMW+11 downto 0 => RW,
    others => RO
  );
  function csr_addr_bits return csr_bits_t is
    variable r : csr_bits_t(reg_data_t'range) := (others => RO);
  begin
    r(ADDR_MSB downto 1) := (others => RW);
    return r;
  end function csr_addr_bits;

  constant CSR_DEFS : csr_defs_t(open)(
    addr(RA_HI downto RA_LO),
    init(reg_data_t'range),
    bits(reg_data_t'range)
  ) := (
      ( ra(RA_CTRL), x"00000000", csr_ctrl_bits  ),
      ( ra(RA_STAT), x"00000000", (others => RO) ),
      ( ra(RA_BASE), x"00000000", csr_addr_bits  ),
      ( ra(RA_SIZE), x"00000000", csr_addr_bits  ),
      ( ra(RA_DATA), x"00000000", (others => RW) ),
      ( ra(RA_INCR), x"00000000", (others => RW) ),
      ( ra(RA_ERRL), x"00000000", (others => RO) ),
      ( ra(RA_ERRH), x"00000000", (others => RO) )
  );

  signal s_csr_w : regs_data_t(CSR_DEFS'range);
  signal s_csr_p : regs_data_t(CSR_DEFS'range); -- v4p ignore w-303 (unused signal)
  signal s_csr_r : regs_data_t(CSR_DEFS'range) := (others => (others => '0'));

  alias s_csr_ctrl : reg_data_t is s_csr_w(csr_addr_to_idx(ra(RA_CTRL),CSR_DEFS));
  alias s_csr_stat : reg_data_t is s_csr_r(csr_addr_to_idx(ra(RA_STAT),CSR_DEFS));
  alias s_csr_base : reg_data_t is s_csr_w(csr_addr_to_idx(ra(RA_BASE),CSR_DEFS));
  alias s_csr_size : reg_data_t is s_csr_w(csr_addr_to_idx(ra(RA_SIZE),CSR_DEFS));
  alias s_csr_data : reg_data_t is s_csr_w(csr_addr_to_idx(ra(RA_DATA),CSR_DEFS));
  alias s_csr_incr : reg_data_t is s_csr_w(csr_addr_to_idx(ra(RA_INCR),CSR_DEFS));
  alias s_csr_errl : reg_data_t is s_csr_r(csr_addr_to_idx(ra(RA_ERRL),CSR_DEFS));
  alias s_csr_errh : reg_data_t is s_csr_r(csr_addr_to_idx(ra(RA_ERRH),CSR_DEFS));

  alias s_csr_ctrl_run    : std_ulogic                        is s_csr_ctrl(0);
  alias s_csr_ctrl_w      : std_ulogic                        is s_csr_ctrl(1);
  alias s_csr_ctrl_r      : std_ulogic                        is s_csr_ctrl(2);
  alias s_csr_ctrl_reg    : std_ulogic                        is s_csr_ctrl(3);
  alias s_csr_ctrl_arnd   : std_ulogic                        is s_csr_ctrl(4);                -- 0 = sequential, 1 = randomised
  alias s_csr_ctrl_drnd   : std_ulogic                        is s_csr_ctrl(5);
  alias s_csr_ctrl_dinv   : std_ulogic                        is s_csr_ctrl(6);
  alias s_csr_ctrl_d32    : std_ulogic                        is s_csr_ctrl(7);                -- 0/1 = 16/32 bit single cycle size
  alias s_csr_ctrl_cb     : std_ulogic_vector(2 downto 0)     is s_csr_ctrl(10 downto 8);
  alias s_csr_ctrl_brnd   : std_ulogic                        is s_csr_ctrl(11);               -- burst mode: 0 = fixed, 1 = PRNG
  alias s_csr_ctrl_bmag   : std_ulogic_vector(BMW-1 downto 0) is s_csr_ctrl(BMW+11 downto 12); -- burst magnitude
  alias s_csr_ctrl_tlat   : std_ulogic_vector(2 downto 0)     is s_csr_ctrl(18 downto 16);     -- tLAT (latency) in clock cycles
  alias s_csr_ctrl_trwr   : std_ulogic_vector(2 downto 0)     is s_csr_ctrl(21 downto 19);     -- tRWR (read write recovery) in clock cycles
  alias s_csr_ctrl_trac0  : std_ulogic                        is s_csr_ctrl(22);               -- tRAC (read access) in clock cycles (LSB)
  alias s_csr_ctrl_fix_w2 : std_ulogic                        is s_csr_ctrl(23);               -- fix ISSI single write bug (add dummy write to single writes)
  alias s_csr_ctrl_abw    : std_ulogic_vector(3 downto 0)     is s_csr_ctrl(27 downto 24);     -- address boundary for writes
  alias s_csr_ctrl_clksel : std_ulogic_vector(2 downto 0)     is s_csr_ctrl(30 downto 28);
  alias s_csr_ctrl_rst    : std_ulogic                        is s_csr_ctrl(31);

  alias s_csr_ctrl_cb_m   : std_ulogic is s_csr_ctrl_cb(0); -- checkerboard masking
  alias s_csr_ctrl_cb_i   : std_ulogic is s_csr_ctrl_cb(1); -- checkerboard inversion
  alias s_csr_ctrl_cb_pol : std_ulogic is s_csr_ctrl_cb(2); -- checkerboard polarity

  alias s_csr_stat_bsy : std_ulogic is s_csr_stat( 0); -- running
  alias s_csr_stat_fin : std_ulogic is s_csr_stat( 8); -- finished
  alias s_csr_stat_ef  : std_ulogic is s_csr_stat(16); -- underflow
  alias s_csr_stat_uf  : std_ulogic is s_csr_stat(17); -- underflow
  alias s_csr_stat_of  : std_ulogic is s_csr_stat(18); -- overflow
  alias s_csr_ctrl_lol : std_ulogic is s_csr_stat(24); -- loss of lock

  -- register fields synchronised to internal clock domain

  signal i_csr_ctrl_run : std_ulogic;

  --------------------------------------------------------------------------------
  -- internal clock domain

  -- reset and clocks
  signal i_rst       : std_ulogic;
  signal i_clk       : std_ulogic;
  signal i_clk_dly   : std_ulogic;

  -- controller system interface
  signal i_cfg       : hram_ctrl_cfg_t;
  signal i_a_ready   : std_ulogic;
  signal i_a_valid   : std_ulogic;
  signal i_a_rb      : std_ulogic; -- readback
  signal i_a_r_w     : std_ulogic;
  signal i_a_reg     : std_ulogic;
  signal i_a_wrap    : std_ulogic;
  signal i_a_len     : std_ulogic_vector(LEN_MSB downto 0);
  signal i_a_addr    : std_ulogic_vector(ADDR_MSB downto 1);
  signal i_w_ready   : std_ulogic;
  signal i_w_valid   : std_ulogic;
  signal i_w_last    : std_ulogic;
  signal i_w_be      : std_ulogic_vector(1 downto 0);
  signal i_w_data    : std_ulogic_vector(15 downto 0);
  signal i_r_ready   : std_ulogic;
  signal i_r_valid   : std_ulogic;
  signal i_r_ref     : std_ulogic;
  signal i_r_last    : std_ulogic;
  signal i_r_data    : std_ulogic_vector(15 downto 0);

  -- test controller status
  signal t_bsy       : std_ulogic;
  signal t_fin       : std_ulogic;

  -- address state machine
  type state_a_t is (A_IDLE,A_PRNG,A_PREP1,A_PREP2,A_PREP3,A_VALID,A_RB_WAIT,A_RB_PREP,A_RB_VALID,A_DONE);
  signal state_a     : state_a_t;
  signal a_count     : std_ulogic_vector(i_a_addr'range); -- count remaining words
  signal a_lm        : std_ulogic_vector(i_a_len'range);  -- len mask
  signal a_len       : std_ulogic_vector(i_a_len'range);
  signal a_addr32    : std_ulogic_vector(31 downto 0);
  signal a_incr      : std_ulogic_vector(i_a_len'range);
  signal a_row_rnd   : std_ulogic_vector(ROWS_LOG2-1 downto 0);
  signal a_addr_rnd  : std_ulogic_vector(i_a_addr'range); -- address, swizzled
  alias a_addr : std_ulogic_vector(i_a_addr'range) is a_addr32(i_a_addr'range);
  alias a_col  : std_ulogic_vector(COLS_LOG2-1 downto 0) is a_addr(COLS_LOG2 downto 1);
  alias a_row  : std_ulogic_vector(ROWS_LOG2-1 downto 0) is a_addr(ROWS_LOG2+COLS_LOG2 downto COLS_LOG2+1);

  -- data state machine
  type state_d_t is (D_IDLE,D_WAIT,D_WR,D_RD,D_RB,D_DONE);
  signal state_d     : state_d_t;                         -- data machine state
  signal d_seq       : std_ulogic_vector(31 downto 0);    -- sequential data value
  signal d_word      : std_ulogic;                        -- word select (within dword)
  signal d_adv       : std_ulogic;                        -- advance 32 bit data pattern
  signal d_addr      : std_ulogic_vector(i_a_addr'range); -- address of current data access

  -- interleaved read/write (readback)
  type rb_addr_t is array(natural range <>) of std_ulogic_vector(i_a_addr'range);
  type rb_data_t is array(natural range <>) of std_ulogic_vector(31 downto 0);
  signal rb_valid    : std_ulogic_vector(1 to 2);
  signal rb_addr     : rb_addr_t(rb_valid'range);
  signal rb_data     : rb_data_t(rb_valid'range);

  -- read check
  signal rc_en       : std_ulogic;                      -- enable
  signal rc_addr     : std_ulogic_vector(d_addr'range);
  signal rc_rdat     : std_ulogic_vector(15 downto 0);
  signal rc_xdat     : std_ulogic_vector(15 downto 0);
  signal rc_ref      : std_ulogic;

  -- error FIFO
  signal efifo_rst   : std_ulogic;                      -- reset
  signal efifo_we    : std_ulogic;                      -- write enable
  signal efifo_wd    : std_ulogic_vector(63 downto 0);  -- write data
  signal efifo_re    : std_ulogic;                      -- read enable
  signal efifo_rd    : std_ulogic_vector(63 downto 0);  -- read data
  signal efifo_ef    : std_ulogic;                      -- empty flag
  signal efifo_af    : std_ulogic;                      -- almost full flag
  signal efifo_uf    : std_ulogic;                      -- underflow flag
  signal efifo_of    : std_ulogic;                      -- overflow flag

  --------------------------------------------------------------------------------
  -- synthesisable PRNG

  signal prng_init    : std_ulogic;
  signal prng_a_seed  : std_ulogic_vector(127 downto 0);
  signal prng_a_ready : std_ulogic;
  signal prng_a_valid : std_ulogic;
  signal prng_a_data  : std_ulogic_vector(31 downto 0);
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

  impure function random_1to1_v(n : integer) return sulv_vector is
    constant t : integer_vector := random_1to1;
    variable r : sulv_vector(0 to (2**n)-1)(n-1 downto 0);
  begin
    for i in r'range loop
      r(i) := std_ulogic_vector(to_unsigned(t(i),n));
    end loop;
    return r;
  end function random_1to1_v;

  constant ROW_RND : sulv_vector(0 to (2**ROWS_LOG2)-1)(ROWS_LOG2-1 downto 0) := random_1to1_v(ROWS_LOG2);

  --------------------------------------------------------------------------------
  -- attributes

  -- attribute mark_debug : string;

begin

  --------------------------------------------------------------------------------

  U_CSR: component csr
    generic map (
      CSR_DEFS => CSR_DEFS
    )
    port map (
      rst  => s_rst,
      clk  => s_clk,
      en   => s_en,
      bwe  => s_bwe,
      addr => s_addr(RA_HI downto RA_LO),
      din  => s_din,
      dout => s_dout,
      w    => s_csr_w,
      p    => s_csr_p,
      r    => s_csr_r
    );

  P_CSR: process(all)
  begin
    s_csr_errl <= efifo_rd(31 downto 0);
    s_csr_errh <= efifo_rd(63 downto 32);
  end process P_CSR;

  --------------------------------------------------------------------------------

  U_SYNC_S: component sync -- v4p ignore w-301 (missing port associations)
    generic map (
      WIDTH => 6
    )
    port map (
      clk  => s_clk,
      i(0) => t_bsy,
      i(1) => t_fin,
      i(2) => efifo_ef,
      i(3) => efifo_uf,
      i(4) => efifo_of,
      i(5) => i_rst,
      o(0) => s_csr_stat_bsy,
      o(1) => s_csr_stat_fin,
      o(2) => s_csr_stat_ef,
      o(3) => s_csr_stat_uf,
      o(4) => s_csr_stat_of,
      o(5) => s_csr_ctrl_lol
    );

  U_SYNC_I: component sync
    port map (
      rst  => i_rst,
      clk  => i_clk,
      i(0) => s_csr_ctrl_run,
      o(0) => i_csr_ctrl_run
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

  i_a_wrap <= '0'; -- TODO exercise wrapping?

  P_LM: process(s_csr_ctrl_bmag)
  begin
    a_lm <= (others => '0');
    a_lm(to_integer(unsigned(s_csr_ctrl_bmag))-1 downto 0) <= (others => '1');
  end process P_LM;

  a_addr32(31 downto ADDR_MSB+1) <= (others => '0');
  a_addr32(0) <= '0';

  a_addr_rnd <= a_row_rnd & a_col;

  d_adv <=
    (bool2sl(state_d = D_WR) and d_word and ((i_w_valid and i_w_ready and not i_w_last) or not i_w_valid)) or
    (bool2sl(state_d = D_RD) and d_word and i_r_valid and i_r_ready);

  prng_a_ready <= bool2sl(state_a = A_PREP1) and s_csr_ctrl_brnd and not s_csr_ctrl_arnd;
  prng_d_ready <= d_adv and s_csr_ctrl_drnd;

  P_MAIN: process(i_rst,i_clk)

    variable x : std_ulogic_vector(31 downto 0);
    variable d : std_ulogic_vector(31 downto 0);

  begin
    if i_rst then

      i_a_valid   <= '0';
      i_a_rb      <= '0';
      i_a_r_w     <= 'X';
      i_a_reg     <= 'X';
      i_a_len     <= (others => 'X');
      i_a_addr    <= (others => 'X');
      i_w_valid   <= '0';
      i_w_be      <= (others => 'X');
      i_w_data    <= (others => 'X');
      i_r_ready   <= '0';
      t_bsy       <= '0';
      t_fin       <= '0';
      a_count     <= (others => 'X');
      a_len       <= (others => 'X');
      a_addr      <= (others => 'X');
      state_a     <= A_IDLE;
      d_seq       <= (others => 'X');
      d_word      <= 'X';
      d_addr      <= (others => 'X');
      state_d     <= D_IDLE;
      rb_valid    <= (others => '0');
      rb_addr     <= (others => (others => 'X'));
      rb_data     <= (others => (others => 'X'));
      rc_en       <= '0';
      rc_addr     <= (others => 'X');
      rc_rdat     <= (others => 'X');
      rc_xdat     <= (others => 'X');
      rc_ref      <= '0';
      efifo_we    <= '0';
      efifo_wd    <= (others => 'X');
      prng_init   <= '0';

    elsif rising_edge(i_clk) then

      --------------------------------------------------------------------------------
      -- synchronous ROM

      a_row_rnd <= ROW_RND(to_integer(unsigned(a_row)));

      --------------------------------------------------------------------------------
      -- address state machine

      prng_init <= '0';

      x( 7 downto  0) := (others => not s_csr_ctrl_cb_pol);
      x(15 downto  8) := (others =>     s_csr_ctrl_cb_pol);
      x(23 downto 16) := (others =>     s_csr_ctrl_cb_pol);
      x(31 downto 24) := (others => not s_csr_ctrl_cb_pol);

      case state_a is

        when A_IDLE =>
          if i_csr_ctrl_run then
            t_bsy     <= '1';
            a_count   <= s_csr_size(ADDR_MSB downto 2) & (s_csr_size(1) and not s_csr_ctrl_d32);
            a_addr    <= s_csr_base(ADDR_MSB downto 2) & (s_csr_base(1) and not s_csr_ctrl_d32);
            prng_init <= '1';
            state_a   <= A_PRNG;
          end if;

        when A_PRNG => -- wait until PRNG ready
          state_a <= A_PREP1 when prng_a_valid and prng_d_valid and not prng_init;

        when A_PREP1 => -- set burst length
          a_len  <= (0 => not s_csr_ctrl_d32, 1 => s_csr_ctrl_d32, others => '0'); -- default: single 16 or 32 bit accesses
          a_incr <= (0 => not s_csr_ctrl_d32, 1 => s_csr_ctrl_d32, others => '0');
          state_a <= A_PREP3; -- default: skip burst length clipping
          if s_csr_ctrl_w and s_csr_ctrl_r then -- interleaved write/read
            null; -- single 16 or 32 bit write
          elsif s_csr_ctrl_arnd then -- random addressing
            if s_csr_ctrl_w then -- random address writes are single 16 or 32 bit accesses
              null;
            else -- random address read bursts can be longer (for diagnostics) but must be fixed length
              a_len <= (others => '0');
              a_len(to_integer(unsigned(s_csr_ctrl_bmag))) <= '1';
            end if;
          else -- sequential addressing
            a_len  <= (others => '0');
            a_incr <= (others => '0');
            if s_csr_ctrl_brnd then -- random burst length
              a_len  <= incr(a_lm and prng_a_data(a_lm'range));
              a_incr <= incr(a_lm and prng_a_data(a_lm'range));
            else -- fixed burst length
              a_len  (to_integer(unsigned(s_csr_ctrl_bmag))) <= '1';
              a_incr (to_integer(unsigned(s_csr_ctrl_bmag))) <= '1';
            end if;
            state_a <= A_PREP2; -- clip burst length
          end if;

        when A_PREP2 => -- clip burst length
          if (unsigned(a_count) /= 0) -- zero count means maximum test size
          and (unsigned(a_count(a_count'left downto a_count'right+a_len'length)) = 0) -- count MSBs are zero
          and (unsigned(a_len) > unsigned(a_count(a_count'right+a_len'length-1 downto a_count'right))) -- len > count LSBs
          then -- clip burst length to prevent it going beyond end of test memory
            a_len  <= a_count(a_count'right+a_len'length-1 downto a_count'right);
            a_incr <= a_count(a_count'right+a_len'length-1 downto a_count'right);
          end if;
          state_a <= A_PREP3;

        when A_PREP3 => -- present address to controller
          i_a_valid   <= '1';
          i_a_r_w     <= not s_csr_ctrl_w;
          i_a_reg     <= s_csr_ctrl_reg;
          i_a_addr    <= a_addr_rnd when s_csr_ctrl_arnd else a_addr;
          i_a_len     <= a_len;
          a_count     <= sub(a_count,a_incr);
          rb_valid(1) <= s_csr_ctrl_w and s_csr_ctrl_r;
          rb_addr(1)  <= a_addr_rnd when s_csr_ctrl_arnd else a_addr;
          if s_csr_ctrl_arnd then
            a_row <= incr(a_row);
            a_col <= add(a_col,ternary(??s_csr_ctrl_d32,2,1)) when unsigned(not a_row) = 0;
          else
            a_addr <= add(a_addr,a_incr);
          end if;
          state_a     <= A_VALID;

        when A_VALID => -- present address until it is accepted
          if i_a_ready then
            i_a_valid <= '0';
            i_a_r_w   <= 'X';
            i_a_reg   <= 'X';
            i_a_len   <= (others => 'X');
            i_a_addr  <= (others => 'X');
            if i_a_r_w = '0' and s_csr_ctrl_r = '1' then -- test with readback
              state_a <= A_RB_WAIT;
            else
              state_a <= A_DONE when unsigned(a_count) = 0 else A_PREP1;
            end if;
          end if;

        when A_RB_WAIT => -- wait for write data phase to complete before readback
          if state_d = D_WR then
            a_len <= (others => '0');
            if s_csr_ctrl_d32 = '1' and unsigned(s_csr_ctrl_bmag) = 0 then -- 32 bit => minimum burst length = 2
              a_len(1) <= '1';
            else
              a_len(to_integer(unsigned(s_csr_ctrl_bmag))) <= '1';
            end if;
            state_a <= A_RB_PREP when state_d = D_WR;
          end if;

        when A_RB_PREP => -- present readback address, advance readback address pipeline
          if rb_valid(rb_valid'high) then
            i_a_valid <= '1';
            i_a_rb    <= '1';
            i_a_r_w   <= '1';
            i_a_reg   <= s_csr_ctrl_reg; -- unlikely to be 1
            i_a_len   <= a_len; -- variable burst length for diagnostic purposes
            i_a_addr  <= rb_addr(rb_addr'high);
            state_a   <= A_RB_VALID;
          else
            rb_data(2 to rb_data'high) <= rb_data(1 to rb_data'high-1);
            rb_data(1) <= (others => 'X');
            state_a <= A_PREP1 when unsigned(a_count) /= 0;
          end if;
          rb_valid <= '0' & rb_valid(1 to rb_valid'high-1);
          rb_addr(2 to rb_addr'high) <= rb_addr(1 to rb_addr'high-1);
          rb_addr(1) <= (others => 'X');

        when A_RB_VALID => -- present readback address until it is accepted
          if i_a_ready then
            i_a_valid <= '0';
            i_a_rb    <= '0';
            i_a_r_w   <= 'X';
            i_a_reg   <= 'X';
            i_a_len   <= (others => 'X');
            i_a_addr  <= (others => 'X');
            state_a <=
              A_PREP1   when unsigned(a_count)  /= 0 else
              A_RB_PREP when unsigned(rb_valid) /= 0 else
              A_DONE;
          end if;

        when A_DONE => -- test sequence is complete
          if state_d = D_DONE then
            t_fin <= '1';
            if not i_csr_ctrl_run then
              t_bsy   <= '0';
              t_fin   <= '0';
              a_count <= (others => 'X');
              a_len   <= (others => 'X');
              a_addr  <= (others => 'X');
              state_a <= A_IDLE;
            end if;
          end if;

      end case;

      --------------------------------------------------------------------------------
      -- data state machine

      rc_en   <= '0';
      rc_ref  <= '0';

      case state_d is

        when D_IDLE =>
          if i_csr_ctrl_run then
            d_seq   <= s_csr_data;
            d_word  <= '0';
            state_d <= D_WAIT;
          end if;

        when D_WAIT =>
          if i_a_valid and i_a_ready then
            d_addr  <= i_a_addr;
            state_d <= D_RB when i_a_rb else D_RD when i_a_r_w else D_WR;
          end if;

        when D_WR =>
          if (i_w_valid and i_w_ready) or not i_w_valid then -- first or subsequent write
            if i_w_last then
              i_w_valid <= '0';
              i_w_be    <= (others => 'X');
              i_w_data  <= (others => 'X');
              state_d   <= D_DONE when state_a = A_DONE else D_WAIT;
            else
              d := (others => '0');
              if s_csr_ctrl_arnd and not s_csr_ctrl_drnd and s_csr_ctrl_dinv then -- random address + sequential data, inverted
                d := (others => '1'); d(d_addr'range) := not d_addr;
              elsif s_csr_ctrl_arnd and not s_csr_ctrl_drnd then                  -- random address + sequential data
                d := (others => '0'); d(d_addr'range) := d_addr;
              elsif s_csr_ctrl_drnd and s_csr_ctrl_dinv then                      -- random data, inverted
                d := not prng_d_data;
              elsif s_csr_ctrl_drnd then                                          -- random data
                d := prng_d_data;
              elsif s_csr_ctrl_dinv then                                          -- sequential data, inverted
                d := not d_seq;
              else                                                                -- sequential data
                d := d_seq;
              end if;
              d := d xor x when s_csr_ctrl_cb_i;
              i_w_valid <= '1';
              i_w_be    <= "11";
              i_w_data  <= d(31 downto 16) when d_word else d(15 downto 0);
              if s_csr_ctrl_cb_m then
                i_w_be(0)             <= s_csr_ctrl_cb_pol xor not d_word;
                i_w_be(1)             <= s_csr_ctrl_cb_pol xor     d_word;
                i_w_data( 7 downto 0) <= (others => 'X') when s_csr_ctrl_cb_pol xor     d_word; -- drive masked byte to 'X'
                i_w_data(15 downto 8) <= (others => 'X') when s_csr_ctrl_cb_pol xor not d_word; -- drive masked byte to 'X'
              end if;
              if s_csr_ctrl_w and s_csr_ctrl_r and not i_w_valid then -- test with readback
                rb_data(1)(15 downto  0) <= d(31 downto 16) when d_word else d(15 downto  0);
                rb_data(1)(31 downto 16) <= d(31 downto 16) when s_csr_ctrl_d32 else (others => 'X');
              end if;
              d_word <= not d_word;
            end if;
          end if;

        when D_RD =>
          if i_r_valid and i_r_ready then
            d := (others => '0');
            if s_csr_ctrl_arnd and not s_csr_ctrl_drnd and s_csr_ctrl_dinv then -- random address + sequential data, inverted
              d := (others => '1'); d(d_addr'range) := not d_addr;
            elsif s_csr_ctrl_arnd and not s_csr_ctrl_drnd then                  -- random address + sequential data
              d := (others => '0'); d(d_addr'range) := d_addr;
            elsif s_csr_ctrl_drnd and s_csr_ctrl_dinv then                      -- random data, inverted
              d := not prng_d_data;
            elsif s_csr_ctrl_drnd then                                          -- random data
              d := prng_d_data;
            elsif s_csr_ctrl_dinv then                                          -- sequential data, inverted
              d := not d_seq;
            else                                                                -- sequential data
              d := d_seq;
            end if;
            d := d xor x when s_csr_ctrl_cb_i;
            rc_en   <= '1';
            rc_addr <= d_addr;
            rc_rdat <= i_r_data;
            rc_xdat <= d(31 downto 16) when d_word else d(15 downto 0);
            rc_ref  <= i_r_ref;
            d_word <= not d_word;
            d_addr <= incr(d_addr);
            if i_r_last then
              i_r_ready <= '0';
              if state_a = A_DONE then
                state_d <= D_DONE;
              elsif i_a_valid and i_a_ready then
                d_addr  <= i_a_addr;
                state_d <= D_RB when i_a_rb else D_RD when i_a_r_w else D_WR;
              else
                state_d <= D_WAIT;
              end if;
            end if;
          end if;
          if not i_r_ready then
            i_r_ready <= '1';
          end if;

        when D_RB =>
          if i_r_valid and i_r_ready then
            rc_en   <= '1';
            rc_addr <= d_addr;
            rc_rdat <= i_r_data;
            rc_xdat <= rb_data(rb_data'high)(31 downto 16) when rc_en else rb_data(rb_data'high)(15 downto 0);
            rc_ref  <= i_r_ref;
            if i_r_last then
              rb_data(2 to rb_data'high) <= rb_data(1 to rb_data'high-1);
              rb_data(1) <= (others => 'X');
              i_r_ready <= '0';
              if state_a = A_DONE then
                state_d <= D_DONE;
              elsif i_a_valid and i_a_ready then
                d_addr  <= i_a_addr;
                state_d <= D_RB when i_a_rb else D_RD when i_a_r_w else D_WR;
              else
                state_d <= D_WAIT;
              end if;
            end if;
          end if;
          if not i_r_ready then
            i_r_ready <= '1';
          end if;

        when D_DONE =>
          d_seq   <= (others => 'X');
          d_word  <= 'X';
          state_d <= D_IDLE when not i_csr_ctrl_run;

      end case;

      d_seq <= add(d_seq, s_csr_incr) when d_adv and not s_csr_ctrl_drnd;

      --------------------------------------------------------------------------------
      -- read data error checking - 1 cycle delay to improve timing

      efifo_we <= '0';
      efifo_wd <= (others => 'X');
      if efifo_af = '0' and rc_en = '1' and (rc_rdat /= rc_xdat) then
        efifo_we               <= '1';
        efifo_wd               <= (others => '0');
        efifo_wd(d_addr'range) <= rc_addr;          -- address of data access
        efifo_wd(31)           <= rc_ref;          -- refresh collision
        efifo_wd(47 downto 32) <= rc_rdat;         -- data read
        efifo_wd(63 downto 48) <= rc_xdat;         -- data expected
      end if;

      --------------------------------------------------------------------------------

    end if;
  end process P_MAIN;

  --------------------------------------------------------------------------------
  -- error FIFO
  -- bits:
  --  16  expected
  --  16  actual
  --  x   address (LSB 1 = invalid, 0 = valid)

  efifo_rst <= s_rst or i_rst or s_csr_ctrl_rst;

  efifo_re <= s_en and s_r_w and bool2sl(ra(s_addr) = ra(RA_ERRH));

  U_EFIFO : component fifo36e1
    generic map (
      almost_empty_offset     => x"0010",
      almost_full_offset      => x"01F0",
      data_width              => 72,
      do_reg                  => 1,
      en_ecc_read             => false,
      en_ecc_write            => false,
      en_syn                  => false,
      fifo_mode               => "FIFO36_72",
      first_word_fall_through => true,
      init                    => x"000000000000000000",
      sim_device              => "7SERIES",
      srval                   => x"000000000000000000"
    )
    port map (
      wrclk         => i_clk,
      wren          => efifo_we,
      di            => efifo_wd,
      dip           => (others => '0'),
      rdclk         => s_clk,
      rden          => efifo_re,
      regce         => '1',
      rst           => efifo_rst,
      rstreg        => efifo_rst,
      do            => efifo_rd,
      dop           => open,
      almostempty   => open,
      almostfull    => efifo_af,
      empty         => efifo_ef,
      full          => open,
      rdcount       => open,
      rderr         => efifo_uf,
      wrcount       => open,
      wrerr         => efifo_of,
      injectdbiterr => '0',
      injectsbiterr => '0',
      dbiterr       => open,
      eccparity     => open,
      sbiterr       => open
    );

  --------------------------------------------------------------------------------

  i_cfg.tLAT   <= s_csr_ctrl_tlat;
  i_cfg.tRWR   <= s_csr_ctrl_trwr;
  i_cfg.tRAC   <= '1' & s_csr_ctrl_trac0;
  i_cfg.abw    <= s_csr_ctrl_abw;
  i_cfg.fix_w2 <= s_csr_ctrl_fix_w2;

  U_CTRL: component hram_ctrl
    generic map (
      PARAMS => HRAM_CTRL_PARAMS_100_100
    )
    port map (
      s_rst     => i_rst,
      s_clk     => i_clk,
      s_clk_dly => i_clk_dly,
      s_cfg     => i_cfg,
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
      s_r_ref   => i_r_ref,
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
      reseed    => prng_init,
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
      reseed    => prng_init,
      newseed   => prng_d_seed,
      out_ready => prng_d_ready,
      out_valid => prng_d_valid,
      out_data  => prng_d_data
    );

  --------------------------------------------------------------------------------

end architecture rtl;
