-- --------------------------------------------------------------------------------
-- tb_np6532_poc_256k_terasic_de10nano.vhd                                    --
-- Simulation testbench for np6532_poc_256k_terasic_de10nano.vhd.             --
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

entity tb_np6532_poc_256k_terasic_de10nano is
  generic (
    success_addr : integer
  );
end entity tb_np6532_poc_256k_terasic_de10nano;

architecture sim of tb_np6532_poc_256k_terasic_de10nano is

  signal clk    : std_logic;
  signal key    : std_logic_vector(1 downto 0);
  signal led    : std_logic_vector(7 downto 0);
  signal gpio_1 : std_logic_vector(0 to 35);

begin

  clk <=
         '1' after 10 ns when clk = '0' else
         '0' after 10 ns when clk = '1' else
         '0';

  TEST: process is
  begin
    key(0) <= '0';
    wait for 20 ns;
    key(0) <= '1';
    wait;
  end process TEST;

  gpio_1(7 downto 0) <= '1';

  DUT: entity work.np6532_poc_256k_terasic_de10nano
    generic map (
      success_addr    => success_addr
    )
    port map (
      fpga_clk1_50    => clk,
      fpga_clk2_50    => clk,
      fpga_clk3_50    => clk,
      sw              => open,
      key             => key,
      led             => led,
      hdmi_tx_clk     => open,
      hdmi_tx_d       => open,
      hdmi_tx_vs      => open,
      hdmi_tx_hs      => open,
      hdmi_tx_de      => open,
      hdmi_tx_int     => '1',
      hdmi_sclk       => open,
      hdmi_mclk       => open,
      hdmi_lrclk      => open,
      hdmi_i2s        => open,
      hdmi_i2c_scl    => open,
      hdmi_i2c_sda    => open,
      adc_convst      => open,
      adc_sck         => open,
      adc_sdi         => open,
      adc_sdo         => '0',
      arduino_reset_n => open,
      arduino_io      => open,
      gpio_0          => open,
      gpio_1          => gpio_1
    );

end architecture sim;
