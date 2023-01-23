--------------------------------------------------------------------------------
-- tb_hdmi_rx_selectio_clk.vhd                                                --
-- Simulation testbench for hdmi_rx_selectio_clk.vhd.                         --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
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

library std;
  use std.env.finish;

library work;
  use work.hdmi_rx_selectio_clk_pkg.all;

entity tb_hdmi_rx_selectio_clk is
end entity tb_hdmi_rx_selectio_clk;

architecture sim of tb_hdmi_rx_selectio_clk is

  signal rst     : std_logic;
  signal clk     : std_logic;
  signal pclki   : std_logic;
  signal prsto   : std_logic;
  signal pclko   : std_logic;
  signal sclko_p : std_logic;
  signal sclko_n : std_logic;
  signal lock    : std_logic;
  signal band    : std_logic_vector(1 downto 0);

  signal tpclk   : time := 1000 ns;

begin

  -- 100 MHz
  clk <=
    '1' after 5 ns when clk = '0' else
    '0' after 5 ns when clk = '1' else
    '0';

  rst <= '1', '0' after 10 ns;

  pclki <=
    '1' after tpclk/2 when pclki = '0' else
    '0' after tpclk/2 when pclki = '1' else
    '0';

  process

    procedure try (
        period       : in    real;
        signal tpclk : inout time;
        signal pclko : in    std_logic;
        signal lock  : in    std_logic
    ) is
      variable t : time;
    begin
      tpclk <= 1000000000 ps / integer(1000.0*period);
      if lock = '1' then
        wait until lock = '0';
      end if;
      wait until lock = '1';
      wait for 1 us;
      wait until rising_edge(pclko);
      t := now;
      wait until rising_edge(pclko);
      t := now-t;
      -- detect > 2 ps error
      if abs((t / 1 ps)-(tpclk / 1 ps)) > 2 then
        report "clock period error: expected " & time'image(tpclk) & " measured " & time'image(t) severity FAILURE;
      end if;
    end procedure try;

  begin

    wait until rst = '0';
    if lock /= '0' then
        report "lock should start out negated" severity FAILURE;
    end if;

    report "trying 25.175 MHz";
    try(25.175,tpclk,pclko,lock);
    report "trying 27.0 MHz";
    try(27.0,tpclk,pclko,lock);
    report "trying 74.25 MHz";
    try(74.25,tpclk,pclko,lock);
    report "trying 148.5 MHz";
    try(148.5,tpclk,pclko,lock);
    report "SUCCESS!";
    finish;

  end process;

  DUT: component hdmi_rx_selectio_clk
    generic map (
      fclk    => 100.0
    )
    port map (
      rst     => rst,
      clk     => clk,
      pclki   => pclki,
      prsto   => prsto,
      pclko   => pclko,
      sclko_p => sclko_p,
      sclko_n => sclko_n,
      lock    => lock,
      band    => band
    );

end architecture sim;
