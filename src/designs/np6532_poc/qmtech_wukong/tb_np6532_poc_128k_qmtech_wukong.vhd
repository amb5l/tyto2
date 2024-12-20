--------------------------------------------------------------------------------
-- tb_np6532_poc_128k_qmtech_wukong.vhd                                       --
-- Simulation testbench for np6532_poc_128k_qmtech_wukong.vhd.                --
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

entity tb_np6532_poc_128k_qmtech_wukong is
  generic (
    success_addr : integer
  );
end entity tb_np6532_poc_128k_qmtech_wukong;

architecture sim of tb_np6532_poc_128k_qmtech_wukong is

  signal clki_50m : std_logic;
  signal key_n    : std_logic_vector(1 downto 0);
  signal led_n    : std_logic_vector(1 downto 0);

begin

  clki_50m <=
              '1' after 10 ns when clki_100m = '0' else
              '0' after 10 ns when clki_100m = '1' else
              '0';

  TEST: process is
  begin
    key_n(0) <= '0';
    wait for 20 ns;
    key_n(0) <= '1';
    wait;
  end process TEST;

  DUT: entity work.np6532_poc_128k_qmtech_wukong
    generic map (
      success_addr => success_addr
    )
    port map (
      clki_50m     => clki_50m,
      led_n        => led_n,
      key_n        => key_n,
      ser_tx       => open,
      ser_rx       => '1',
      hdmi_scl     => open,
      hdmi_sda     => open,
      eth_rst_n    => open,
      ddr3_rst_n   => open,
      j10          => (others => '0'),
      j11          => (others => '0'),
      jp2          => open
    );

end architecture sim;
