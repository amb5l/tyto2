--------------------------------------------------------------------------------
-- tb_hram_test.vhd                                                           --
-- Testbench for hram_test                                                    --
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

use work.tyto_types_pkg.all;
use work.hram_test_pkg.all;
use work.model_hram_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity tb_hram_test is
  generic (
    OUTPUT_DELAY : string;
    ROWS_LOG2    : integer;
    COLS_LOG2    : integer
  );
end entity tb_hram_test;

architecture sim of tb_hram_test is

  constant SIM_MEM_SIZE : integer := 2**23; -- 8 MBytes

  alias reg_addr_t is hram_test_reg_addr_t;
  alias reg_data_t is hram_test_reg_data_t;

  signal clk_100m : std_ulogic;
  signal x_rst    : std_ulogic;
  signal x_clk    : std_ulogic;
  signal s_rst    : std_ulogic;
  signal s_clk    : std_ulogic;
  signal s_en     : std_ulogic;
  signal s_we     : std_ulogic_vector(3 downto 0);
  signal s_addr   : std_ulogic_vector(7 downto 2);
  signal s_din    : std_ulogic_vector(31 downto 0);
  signal s_dout   : std_ulogic_vector(31 downto 0);
  signal h_rst_n  : std_logic;
  signal h_cs_n   : std_logic;
  signal h_clk    : std_logic;
  signal h_rwds   : std_logic;
  signal h_dq     : std_logic_vector(7 downto 0);

  constant ADDR_IDREG0  : std_ulogic_vector(31 downto 0) := (others => '0');
  constant ADDR_CFGREG0 : std_ulogic_vector(31 downto 0) := (12 => '1', others => '0');

  constant DATA_IDREG0  : std_ulogic_vector(15 downto 0) := IS66WVH8M8DBLL_100B1LI.idreg0;
  constant DATA_CFGREG0 : std_ulogic_vector(15 downto 0) := "1000111111110111"; -- latency 4

  function hram_params(i : hram_params_t) return hram_params_t is
    variable r : hram_params_t;
  begin
    r := i;
    r.abw  := COLS_LOG2; -- write address boundary = row
    r.abr  := -1;        -- read address boundary = none
    r.tVCS := 10.0;      -- override tVCS to shorten simulation time
    return r;
  end function hram_params;

begin

  --------------------------------------------------------------------------------

  clk_100m <= '1' when clk_100m = 'U' else not clk_100m after 5 ns; -- 100 MHz
  x_clk <= clk_100m;
  s_clk <= clk_100m;

  --------------------------------------------------------------------------------

  P_MAIN: process

    procedure reg_poke(
      addr : in    reg_addr_t;
      data : in    reg_data_t
    ) is
    begin
      s_en   <= '1';
      s_we   <= "1111";
      s_addr <= addr(7 downto 2);
      s_din  <= data;
      wait until rising_edge(s_clk);
      s_en   <= '0';
      s_we   <= "XXXX";
      s_addr <= (others => 'X');
      s_din  <= (others => 'X');
    end procedure reg_poke;

    procedure reg_peek(
      addr : in    reg_addr_t;
      data : out   reg_data_t
    ) is
    begin
      s_en   <= '1';
      s_we   <= "0000";
      s_addr <= addr(7 downto 2);
      wait for 5 ns;
      data   := s_dout;
      wait until rising_edge(s_clk);
      s_en   <= '0';
      s_we   <= "XXXX";
      s_addr <= (others => 'X');
    end procedure reg_peek;

    variable clksel : std_ulogic_vector(2 downto 0);
    variable tLAT   : std_ulogic_vector(2 downto 0);
    variable tRWR   : std_ulogic_vector(2 downto 0);
    variable tRAC   : std_ulogic_vector(1 downto 0);
    variable fix_w2 : std_ulogic;
    variable abw    : std_ulogic_vector(3 downto 0);
    variable rd     : std_ulogic_vector(31 downto 0);

    procedure run(
      w      : in    std_ulogic := '0';
      r      : in    std_ulogic := '0';
      reg    : in    std_ulogic := '0';
      addr   : in    reg_data_t := (others => '0');
      size   : in    reg_data_t;
      data   : in    reg_data_t := (others => '0');
      incr   : in    reg_data_t := (others => 'X');
      arnd   : in    std_ulogic := '0';
      drnd   : in    std_ulogic := '0';
      dinv   : in    std_ulogic := '0';
      d32    : in    std_ulogic := '0';
      cb_m   : in    std_ulogic := '0';
      cb_i   : in    std_ulogic := '0';
      cb_pol : in    std_ulogic := '0';
      brnd   : in    std_ulogic := '0';
      bmag   : in    std_ulogic_vector(3 downto 0) := "0000";
      xadd   : in    std_ulogic_vector(31 downto 0) := (others => 'U');
      xdat   : in    std_ulogic_vector(15 downto 0) := (others => 'U')
    ) is
      variable eadd : std_ulogic_vector(31 downto 0);
      variable edat : std_ulogic_vector(31 downto 0);
      variable edr  : sulv_vector(0 to 3)(31 downto 0);
      variable x    : std_ulogic_vector(31 downto 1);
    begin
      x := '0' & clksel & abw & fix_w2 &
        tRAC(0) & tRWR & tLAT &
        bmag & brnd & cb_pol & cb_i & cb_m &
        d32 & dinv & drnd & arnd & reg & r & w;
      reg_poke(RA_BASE,addr);
      reg_poke(RA_DATA,data);
      reg_poke(RA_INCR,incr);
      reg_poke(RA_SIZE,size);
      reg_poke(RA_CTRL,x & '1'); -- run
      loop -- wait for busy
        reg_peek(RA_STAT,rd);
        if rd(0) = '1' then exit; end if;
      end loop;
      loop -- wait for done
        reg_peek(RA_STAT,rd);
        if rd(8) = '1' then exit; end if;
      end loop;
      reg_poke(RA_CTRL,x & '0'); -- stop
      loop -- wait for not busy
        reg_peek(RA_STAT,rd);
        if rd(0) = '0' then exit; end if;
      end loop;
      if rd(16) = '1' then
        reg_peek(RA_EADD,eadd);
        reg_peek(RA_EDAT,edat);
        if eadd /= xadd or edat(15 downto 0) /= xdat then
          reg_peek(RA_EDR0,edr(0));
          reg_peek(RA_EDR1,edr(1));
          reg_peek(RA_EDR2,edr(2));
          reg_peek(RA_EDR3,edr(3));
          report "read error:" &
            " address " & to_hstring(eadd) &
            " read " & to_hstring(edat(15 downto 0)) &
            " expected " & to_hstring(edat(31 downto 16)) &
            " EDR0 " & to_hstring(edr(0)) &
            " EDR1 " & to_hstring(edr(1)) &
            " EDR2 " & to_hstring(edr(2)) &
            " EDR3 " & to_hstring(edr(3)) &
            " (ref = " & to_string(rd(17)) &")"
            severity failure;
        end if;
      end if;
    end procedure run;

  begin

    --------------------------------------------------------------------------------

    assert ROWS_LOG2 = 13 and COLS_LOG2 = 9
      report "ROWS_LOG2 and COLS_LOG2 must be 13 and 9 respectively"
      severity failure;

    --------------------------------------------------------------------------------
    -- initialise

    x_rst  <= '1';
    s_rst  <= '1';
    s_en   <= '0';
    s_we   <= "XXXX";
    s_addr <= (others => 'X');
    s_din  <= (others => 'X');
    wait for 100 ns;
    x_rst <= '0';
    s_rst <= '0';
    wait until rising_edge(s_clk);
    wait until rising_edge(s_clk);

    clksel := "000";
    tLAT   := "100";
    tRWR   := "100";
    tRAC   := "11";
    fix_w2 := '1';
    abw    := "1001";

    reg_poke(RA_CTRL, "0" & clksel & abw & fix_w2 & tRAC(0) & tRWR & tLAT & x"0000"); -- set up

    -- wait for MMCM lock
    loop
      reg_peek(RA_STAT,rd);
      if rd(24) = '0' then
        exit;
      end if;
    end loop;
    report "LOCKED";

    --------------------------------------------------------------------------------

    -- set up latency (configuration register 0)
    run(
      w => '1', reg => '1',
      addr => ADDR_CFGREG0, size => x"0000_0002",
      data => x"0000" & DATA_CFGREG0
    );

    -- check ID register 0
    run(
      r => '1', reg => '1',
      addr => ADDR_IDREG0, size => x"0000_0002",
      data => x"0000" & DATA_IDREG0
    );
    report "ID register 0 OK";

    --------------------------------------------------------------------------------
    -- single cycle fill, multiple burst types for test

    report "fill - 4kB, sequential addressing, sequential data, burst length 1";
    run(
      w => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"0"
    );

    report "test - 4kB, sequential addressing, sequential data, burst length 1";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"0"
    );

    report "test - 4kB, sequential addressing, sequential data, burst length 8";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"3"
    );

    report "test - 4kB, sequential addressing, sequential data, burst length 256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"8"
    );

    report "test - 4kB, sequential addressing, sequential data, random burst length 1..256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"8", brnd => '1'
    );

    --------------------------------------------------------------------------------
    -- short burst fill

    report "fill - 4kB, sequential addressing, inverted sequential data, burst length 8";
    run(
      w => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002", dinv => '1',
      bmag => x"3"
    );

    report "test - 4kB, sequential addressing, inverted sequential data, random burst length 1..256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002", dinv => '1',
      bmag => x"8", brnd => '1'
    );

    --------------------------------------------------------------------------------
    -- long burst fill

    report "fill - 4kB, sequential addressing, sequential data, burst length 256";
    run(
      w => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"8"
    );

    report "test - 4kB, sequential addressing, sequential data, random burst length 1..256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"8", brnd => '1'
    );

    --------------------------------------------------------------------------------
    -- random burst fill

    report "fill - 4kB, sequential addressing, inverted sequential data, random burst length 1..256";
    run(
      w => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002", dinv => '1',
      bmag => x"8", brnd => '1'
    );

    report "test - 4kB, sequential addressing, inverted sequential data, burst length 256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002", dinv => '1',
      bmag => x"8"
    );

    --------------------------------------------------------------------------------
    -- checkerboard inversion

    report "fill - 4kB, sequential addressing, checkerboard inverted sequential data, burst length 256";
    run(
      w => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      cb_i => '1', bmag => x"8"
    );

    report "test - 4kB, sequential addressing, checkerboard inverted sequential data, burst length 256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      cb_i => '1', bmag => x"8"
    );

    --------------------------------------------------------------------------------
    -- checkboard masking

    report "fill - 4kB, sequential addressing, sequential data, burst length 256";
    run(
      w => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"8"
    );

    report "fill - 4kB, sequential addressing, checkerboard masked inverted sequential data, burst length 256";
    run(
      w => '1',
      addr => x"0000_0000", size => x"0000_1000", dinv => '1',
      data => x"0001_0000", incr => x"0002_0002",
      cb_m => '1',
      bmag => x"8"
    );

    report "test - 4kB, sequential addressing, checkerboard inverted sequential data, burst length 256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      cb_i => '1', bmag => x"8"
    );

    report "fill - 4kB, sequential addressing, checkerboard inverted masked inverted sequential data, burst length 256";
    run(
      w => '1',
      addr => x"0000_0000", size => x"0000_1000", dinv => '1',
      data => x"0001_0000", incr => x"0002_0002",
      cb_m => '1', cb_pol => '1',
      bmag => x"8"
    );

    report "test - 4kB, sequential addressing, inverted sequential data, burst length 256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002", dinv => '1',
      bmag => x"8"
    );

    --------------------------------------------------------------------------------
    -- sequential interleaved write/read

    report "concurrent fill and test - 4kB, sequential addressing, sequential data, read burst length 8";
    run(
      w => '1', r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"3"
    );

    report "test - 4kB, sequential addressing, sequential data, burst length 256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_1000",
      data => x"0001_0000", incr => x"0002_0002",
      bmag => x"8"
    );

    --------------------------------------------------------------------------------
    -- random address interleaved write/read

    report "concurrent fill and test - 8MB, random addressing, 32 bit data = inverted address, 8 beat burst";
    run(
      w => '1', r => '1',
      addr => x"0000_0000", size => x"0000_0000", arnd => '1',
      data => x"0000_0000", incr => x"0000_0004", dinv => '1', d32 => '1',
      bmag => x"3"
    );

    report "test - 8MB, sequential addressing, sequential data = inverted address, burst length 256";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_0000",
      data => x"0000_0000", incr => x"0000_0004", dinv => '1',
      bmag => x"8"
    );

    report "test - 8MB, random addressing, 32 bit data = inverted address, 8 beat burst";
    run(
      r => '1',
      addr => x"0000_0000", size => x"0000_0000", arnd => '1',
      data => x"0000_0000", incr => x"0000_0004", dinv => '1', d32 => '1',
      bmag => x"3"
    );

--    --------------------------------------------------------------------------------
--    -- short tests
--
--    report "fill and check (interleaved read/write), incrementing data, readback burst length 2";
--    run(
--      w      => '1',
--      r      => '1',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- data start value
--      incr   => x"0000_0004", -- data increment
--      size   => x"0000_0100", -- 128 words / 256 bytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '0',          -- incrementing data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '0',          -- must be 0 (readback)
--      bmag   => x"1"          -- BURST LENGTH 2^1 = 2
--    );
--
--    report "follow on read";
--    run(
--      w      => '0',
--      r      => '1',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- data start value
--      incr   => x"0000_0004", -- data increment
--      size   => x"0000_0100", -- 128 words / 256 bytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '0',          -- incrementing data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '0',          -- must be 0 (readback)
--      bmag   => x"3"          -- burst length 8
--    );
--
--    report "fill and check (interleaved read/write), inverted incrementing data, readback burst length 8";
--    run(
--      w      => '1',
--      r      => '1',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- data start value
--      incr   => x"0000_0004", -- data increment
--      size   => x"0000_0100", -- 128 words / 256 bytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '0',          -- incrementing data
--      dinv   => '1',          -- data inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '0',          -- must be 0 (readback)
--      bmag   => x"3"          -- BURST LENGTH 8
--    );
--
--    report "follow on read";
--    run(
--      w      => '1',
--      r      => '1',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- data start value
--      incr   => x"0000_0004", -- data increment
--      size   => x"0000_0100", -- 128 words / 256 bytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '0',          -- incrementing data
--      dinv   => '1',          -- data inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '0',          -- must be 0 (readback)
--      bmag   => x"0"          -- burst length 1
--    );
--
--
--    --------------------------------------------------------------------------------
--
--    report "short fill then check";
--
--    -- fill
--    run(
--      w      => '1',
--      r      => '0',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- n/a
--      incr   => x"0000_0000", -- n/a
--      size   => x"0000_0100", -- 128 words / 256 bytes
--      arnd   => '1',          -- scattered addressing
--      drnd   => '1',          -- random data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '0',          -- n/a (scattered addressing)
--      bmag   => x"0"          -- n/a (scattered addressing)
--    );
--
--    -- check
--    run(
--      w      => '0',
--      r      => '1',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- n/a
--      incr   => x"0000_0000", -- n/a
--      size   => x"0000_0100", -- 256 bytes
--      arnd   => '1',          -- scattered addressing
--      drnd   => '1',          -- random data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '0',          -- n/a (scattered addressing)
--      bmag   => x"0"          -- n/a (scattered addressing)
--    );
--
--    --------------------------------------------------------------------------------
--
--    report "short sequential checkerboard fill then check";
--
--    -- fill
--    run(
--      w      => '1',
--      r      => '0',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0403_0201", -- initial data
--      incr   => x"0404_0404", -- data increment
--      size   => x"0000_0100", -- 256 Bytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '0',          -- sequential data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '0',          -- fixed burst length
--      bmag   => x"3"          -- burst length 8
--    );
--
--    -- masked checkerboard inverse fill
--    run(
--      w      => '1',
--      r      => '0',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0403_0201", -- initial data
--      incr   => x"0404_0404", -- data increment
--      size   => x"0000_0100", -- 256 Bytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '0',          -- sequential data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '1',          -- checkerboard masking
--      cb_i   => '1',          -- checkerboard inversion
--      cb_pol => '0',          -- normal checkerboard polarity
--      brnd   => '0',          -- fixed burst length
--      bmag   => x"3"          -- burst length 8
--    );
--
--    -- check
--    run(
--      w      => '0',
--      r      => '1',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0403_0201", -- initial data
--      incr   => x"0404_0404", -- data increment
--      size   => x"0000_0100", -- 256 Bytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '0',          -- sequential data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '1',          -- checkerboard masking
--      cb_i   => '1',          -- checkerboard inversion
--      cb_pol => '0',          -- normal checkerboard polarity
--      brnd   => '0',          -- fixed burst length
--      bmag   => x"3"          -- burst length 8
--    );
--
--    --------------------------------------------------------------------------------
--
--    report "64kB sequential address random data checkerboard fill then check";
--
--    -- fill
--    run(
--      w      => '1',
--      r      => '0',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- n/a
--      incr   => x"0000_0000", -- n/a
--      size   => x"0001_0000", -- 64kBytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '1',          -- random data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '1',          -- random burst length
--      bmag   => x"5"          -- burst length 1..64
--    );
--
--    -- masked checkerboard inverse fill
--    run(
--      w      => '1',
--      r      => '0',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- n/a
--      incr   => x"0000_0000", -- n/a
--      size   => x"0001_0000", -- 64kBytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '1',          -- random data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '1',          -- checkerboard masking
--      cb_i   => '1',          -- checkerboard inversion
--      cb_pol => '0',          -- normal checkerboard polarity
--      brnd   => '1',          -- random burst length
--      bmag   => x"5"          -- burst length 1..64
--    );
--
--    -- -- create error deliberately
--    -- run(
--    --   w      => '1',
--    --   r      => '0',
--    --   reg    => '0',
--    --   addr   => x"0000_FFFE", -- address = FFFE
--    --   data   => x"0000_ABCD", -- data = ABCD
--    --   incr   => x"0000_0000", -- n/a
--    --   size   => x"0000_0002", -- single word (2 bytes)
--    --   arnd   => '0',          -- n/a
--    --   drnd   => '0',          -- regular data
--    --   dinv   => '0',          -- data not inverted
--    --   d32    => '0',          -- 16-bit mode
--    --   cb_m   => '0',          -- no masking
--    --   cb_i   => '0',          -- no inversion
--    --   cb_pol => '0',          -- n/a
--    --   brnd   => '0',          -- n/a
--    --   bmag   => x"0"          -- n/a
--    -- );
--
--    -- check
--    run(
--      w      => '0',
--      r      => '1',
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- n/a
--      incr   => x"0000_0000", -- n/a
--      size   => x"0001_0000", -- 64kBytes
--      arnd   => '0',          -- sequential addressing
--      drnd   => '1',          -- random data
--      dinv   => '0',          -- data not inverted
--      d32    => '0',          -- 16-bit mode
--      cb_m   => '1',          -- checkerboard masking
--      cb_i   => '1',          -- checkerboard inversion
--      cb_pol => '0',          -- normal checkerboard polarity
--      brnd   => '1',          -- random burst length
--      bmag   => x"5"          -- burst length 1..64
--    );
--
--    --------------------------------------------------------------------------------
--
--    report "random 32 bit address-at-address fill and test, then 2nd read";
--
--    -- fill
--    run(
--      w      => '1',          -- write } interleaved
--      r      => '1',          -- read  }
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- n/a
--      incr   => x"0000_0000", -- n/a
--      size   => x"0000_0100", -- 128 words / 256 bytes
--      arnd   => '1',          -- random addressing
--      drnd   => '0',          -- sequential data
--      dinv   => '0',          -- data not inverted
--      d32    => '1',          -- 32-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '0',          -- n/a (scattered addressing)
--      bmag   => x"3"          -- 8 cycle reads for diagnostics
--    );
--
--    -- check
--    run(
--      w      => '0',
--      r      => '1',          -- read
--      reg    => '0',
--      addr   => x"0000_0000", -- start address = 0
--      data   => x"0000_0000", -- n/a
--      incr   => x"0000_0000", -- n/a
--      size   => x"0000_0100", -- 256 bytes
--      arnd   => '1',          -- random addressing
--      drnd   => '0',          -- sequential data
--      dinv   => '0',          -- data not inverted
--      d32    => '1',          -- 32-bit mode
--      cb_m   => '0',          -- no masking
--      cb_i   => '0',          -- no inversion
--      cb_pol => '0',          -- n/a
--      brnd   => '0',          -- n/a (scattered addressing)
--      bmag   => x"3"          -- 8 cycle reads for diagnostics
--    );
--
--    --------------------------------------------------------------------------------

    report "DONE";
    std.env.finish;

    --------------------------------------------------------------------------------

  end process P_MAIN;

  --------------------------------------------------------------------------------

  DUT: component hram_test
    generic map (
      ROWS_LOG2 => ROWS_LOG2,
      COLS_LOG2 => COLS_LOG2
    )
    port map (
      x_rst   => x_rst,
      x_clk   => x_clk,
      s_rst   => s_rst,
      s_clk   => s_clk,
      s_en    => s_en,
      s_we    => s_we,
      s_addr  => s_addr,
      s_din   => s_din,
      s_dout  => s_dout,
      h_rst_n => h_rst_n,
      h_cs_n  => h_cs_n,
      h_clk   => h_clk,
      h_rwds  => h_rwds,
      h_dq    => h_dq
    );

  h_rwds <= 'L';

  --------------------------------------------------------------------------------

  MEM: component model_hram
    generic map (
      SIM_MEM_SIZE => SIM_MEM_SIZE,
      OUTPUT_DELAY => OUTPUT_DELAY,
      PARAMS       => hram_params(IS66WVH8M8DBLL_100B1LI)
    )
    port map (
      rst_n => h_rst_n,
      cs_n  => h_cs_n,
      clk   => h_clk,
      rwds  => h_rwds,
      dq    => h_dq
    );

  --------------------------------------------------------------------------------

end architecture sim;
