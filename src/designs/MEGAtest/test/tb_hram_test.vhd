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

use work.hram_test_pkg.all;
use work.model_hram_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity tb_hram_test is
  generic (
    OUTPUT_DELAY : string
  );
end entity tb_hram_test;

architecture sim of tb_hram_test is
  constant SIM_MEM_SIZE : integer := 2**16;

  alias reg_addr_t is hram_test_reg_addr_t;
  alias reg_data_t is hram_test_reg_data_t;

  signal clk_100m : std_ulogic;
  signal x_rst   : std_ulogic;
  signal x_clk   : std_ulogic;
  signal s_rst   : std_ulogic;
  signal s_clk   : std_ulogic;
  signal s_en    : std_ulogic;
  signal s_we    : std_ulogic_vector(3 downto 0);
  signal s_addr  : std_ulogic_vector(7 downto 2);
  signal s_din   : std_ulogic_vector(31 downto 0);
  signal s_dout  : std_ulogic_vector(31 downto 0);
  signal h_rst_n : std_logic;
  signal h_cs_n  : std_logic;
  signal h_clk   : std_logic;
  signal h_rwds  : std_logic;
  signal h_dq    : std_logic_vector(7 downto 0);

  constant ADDR_IDREG0  : std_ulogic_vector(31 downto 0) := (others => '0');
  constant ADDR_CFGREG0 : std_ulogic_vector(31 downto 0) := (12 => '1', others => '0');

  constant DATA_IDREG0  : std_ulogic_vector(15 downto 0) := IS66WVH8M8DBLL_100B1LI.idreg0;
  constant DATA_CFGREG0 : std_ulogic_vector(15 downto 0) := "1000111111110111"; -- latency 4

  function hram_params(i : hram_params_t) return hram_params_t is
    variable r : hram_params_t;
  begin
    r := i;
    r.tVCS := 10.0; -- override tVCS to shorten simulation time
    return r;
  end function hram_params;

begin

  clk_100m <= '0' when clk_100m = 'U' else not clk_100m after 5 ns; -- 100 MHz
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

    variable clksel : std_ulogic_vector(1 downto 0);
    variable rd   : std_ulogic_vector(31 downto 0);

    procedure run(
      r_w   : in    std_ulogic;
      reg   : in    std_ulogic;
      addr  : in    reg_data_t;
      data  : in    reg_data_t;
      size  : in    reg_data_t := x"0000_0002";
      incr  : in    reg_data_t := x"0000_0000";
      amode : in    std_ulogic := '0';
      wmode : in    std_ulogic_vector(1 downto 0) := "00";
      dmode : in    std_ulogic_vector(2 downto 0) := "000";
      bmode : in    std_ulogic := '0';
      bmag  : in    std_ulogic_vector(3 downto 0) := "0000"
    ) is
      variable eadd : std_ulogic_vector(31 downto 0);
      variable edat : std_ulogic_vector(31 downto 0);
    begin
      reg_poke(RA_BASE,addr);
      reg_poke(RA_DATA,data);
      reg_poke(RA_INCR,incr);
      reg_poke(RA_SIZE,size);
      -- run
      reg_poke(RA_CTRL,x"0000" & bmag & bmode & dmode & wmode & amode & reg & r_w & '1' & clksel);
      loop -- wait for busy
        reg_peek(RA_STAT,rd);
        if rd(0) = '1' then exit; end if;
      end loop;
      loop -- wait for done
        reg_peek(RA_STAT,rd);
        if rd(8) = '1' then exit; end if;
      end loop;
      reg_poke(RA_CTRL,x"0000_000" & "00" & clksel);
      loop -- wait for not busy
        reg_peek(RA_STAT,rd);
        if rd(0) = '0' then exit; end if;
      end loop;
      if rd(16) = '1' then
        reg_peek(RA_EADD,eadd);
        reg_peek(RA_EDAT,edat);
        report "read error:" &
          " address " & to_hstring(eadd) &
          " read " & to_hstring(edat(15 downto 0)) &
          " expected " & to_hstring(edat(31 downto 16))
          severity failure;
      end if;
    end procedure run;

  begin

    --------------------------------------------------------------------------------

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

    clksel := "00";
    reg_poke(RA_CTRL,x"0000_000" & "00" & clksel); -- select 100 MHz clock

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
    run('0', '1', ADDR_CFGREG0, x"0000" & DATA_CFGREG0);

    -- check ID register 0
    run('1', '1', ADDR_IDREG0, x"0000" & DATA_IDREG0);
    report "ID register 0 OK";

    --------------------------------------------------------------------------------

    -- fill
    run(
      r_w   => '0',
      reg   => '0',
      addr  => x"0000_0000",
      data  => x"0000_0000",
      incr  => x"0000_0000",
      size  => x"0001_0000", -- 64kBytes
      amode => '0',          -- sequential addressing
      wmode => "00",         -- no masking
      dmode => "001",        -- random data
      bmode => '1',          -- random burst:
      bmag  => x"5"          --  1-64 words
    );

    -- masked checkerboard inverse fill
    run(
      r_w   => '0',
      reg   => '0',
      addr  => x"0000_0000",
      data  => x"0000_0000",
      incr  => x"0000_0000",
      size  => x"0001_0000", -- 64kBytes
      amode => '0',          -- sequential addressing
      wmode => "01",         -- checkerboard masking
      dmode => "011",        -- random data, checkerboard inversion
      bmode => '1',          -- random burst:
      bmag  => x"5"          --  1-64 words
    );

    -- create error deliberately
    run(
      r_w   => '0',
      reg   => '0',
      addr  => x"0000_FFFE",
      data  => x"0000_ABCD",
      incr  => x"0000_0000",
      size  => x"0000_0002",
      amode => '0',
      wmode => "00",
      dmode => "000",
      bmode => '0',
      bmag  => x"0"
    );

    -- check
    run(
      r_w   => '1',
      reg   => '0',
      addr  => x"0000_0000",
      data  => x"0000_0000",
      incr  => x"0000_0000",
      size  => x"0001_0000", -- 64kBytes
      amode => '0',          -- sequential addressing
      wmode => "00",         -- masking n/a for read
      dmode => "011",        -- random data, checkerboard inversion
      bmode => '1',          -- random burst:
      bmag  => x"5"          --  1-64 words
    );

    --------------------------------------------------------------------------------

    report "DONE";
    std.env.finish;

    --------------------------------------------------------------------------------

  end process P_MAIN;

  --------------------------------------------------------------------------------

  DUT: component hram_test
    generic map (
      ROWS_LOG2 => 13,
      COLS_LOG2 => 9
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
