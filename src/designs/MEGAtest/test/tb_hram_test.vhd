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

library ieee;
  use ieee.std_logic_1164.all;

entity tb_hram_test is
end entity tb_hram_test;

architecture sim of tb_hram_test is

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

  signal rd      : std_ulogic_vector(31 downto 0);

  constant ADDR_IDREG0  : std_ulogic_vector(31 downto 0) := (16 downto 1 => x"0000", others => '0');
  constant ADDR_CFGREG0 : std_ulogic_vector(31 downto 0) := (16 downto 1 => x"1000", others => '0');

  constant DATA_IDREG0  : std_ulogic_vector(15 downto 0) := "0000110010000011";
  constant DATA_CFGREG0 : std_ulogic_vector(15 downto 0) := "1000111111110111";

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
      addr : in    reg_addr_t
    ) is
    begin
      s_en   <= '1';
      s_we   <= "0000";
      s_addr <= addr(7 downto 2);
      wait until rising_edge(s_clk);
      rd     <= s_dout;
      s_en   <= '0';
      s_we   <= "XXXX";
      s_addr <= (others => 'X');
    end procedure reg_peek;

  begin

    x_rst  <= '1';
    s_rst  <= '1';
    s_en   <= '0';
    s_we   <= "XXXX";
    s_addr <= (others => 'X');
    s_din  <= (others => 'X');
    wait for 100 ns;
    x_rst <= '0';
    s_rst <= '0';

    reg_poke(RA_CTRL,x"0000_0003"); -- select 120 MHz clock
    loop
      reg_peek(RA_STAT);
      if rd(24) = '0' then
        exit;
      end if;
    end loop;
    report "LOCKED";

    -- set up latency
    reg_poke(RA_BASE,ADDR_CFGREG0);
    reg_poke(RA_DATA,x"0000" & DATA_CFGREG0);
    reg_poke(RA_INCR,x"0000_0000");
    reg_poke(RA_SIZE,x"0000_0002");
    reg_poke(RA_CTRL,x"0000_0017"); -- single register write

    wait;

  end process P_MAIN;

  --------------------------------------------------------------------------------

  DUT: component hram_test
    generic map (
      ROWS_LOG2 => 13,
      COLS_LOG2 => 9
    )
    port map (
      x_rst     => x_rst,
      x_clk     => x_clk,
      s_rst     => s_rst,
      s_clk     => s_clk,
      s_en      => s_en,
      s_we      => s_we,
      s_addr    => s_addr,
      s_din     => s_din,
      s_dout    => s_dout,
      h_rst_n   => h_rst_n,
      h_cs_n    => h_cs_n,
      h_clk     => h_clk,
      h_rwds    => h_rwds,
      h_dq      => h_dq
    );

  h_rwds <= 'L';

  --------------------------------------------------------------------------------

end architecture sim;
