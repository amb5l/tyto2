--------------------------------------------------------------------------------
-- tb_hdmi_rx_selectio_clk.vhd                                                --
-- Simulation testbench for hdmi_rx_selectio_clk.vhd.                         --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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
  use ieee.numeric_std.all;

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
  signal sclko   : std_logic;
  signal status  : hdmi_rx_selectio_clk_status_t;

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
    if status.lock /= '0' then
        report "lock should start out negated" severity FAILURE;
    end if;

    report "trying 25.175 MHz";
    try(25.175,tpclk,pclko,status.lock);
    if status.band /= "00" then
      report "band incorrect - expect 0, got " & integer'image(to_integer(unsigned(status.band))) severity failure;
    end if;

    report "trying 27.0 MHz";
    try(27.0,tpclk,pclko,status.lock);
    if status.band /= "00" then
      report "band incorrect - expect 0, got " & integer'image(to_integer(unsigned(status.band))) severity failure;
    end if;

    report "trying 74.25 MHz";
    try(74.25,tpclk,pclko,status.lock);
    if status.band /= "10" then
      report "band incorrect - expect 2, got " & integer'image(to_integer(unsigned(status.band))) severity failure;
    end if;

    report "trying 148.5 MHz";
    try(148.5,tpclk,pclko,status.lock);
    if status.band /= "11" then
      report "band incorrect - expect 3, got " & integer'image(to_integer(unsigned(status.band))) severity failure;
    end if;

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
      sclko   => sclko,
      status  => status
    );

end architecture sim;
