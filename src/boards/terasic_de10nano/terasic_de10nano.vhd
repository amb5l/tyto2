--------------------------------------------------------------------------------
-- terasic_de10nano.vhd                                                       --
-- Top level entity for Terasic DE10-Nano board.                              --
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

entity terasic_de10nano is
  port (

    fpga_clk1_50    : in    std_logic;
    fpga_clk2_50    : in    std_logic;
    fpga_clk3_50    : in    std_logic;

    sw              : in    std_logic_vector(3 downto 0);
    key             : in    std_logic_vector(1 downto 0);
    led             : out   std_logic_vector(7 downto 0);

    hdmi_tx_clk     : out   std_logic;
    hdmi_tx_d       : out   std_logic_vector(23 downto 0);
    hdmi_tx_vs      : out   std_logic;
    hdmi_tx_hs      : out   std_logic;
    hdmi_tx_de      : out   std_logic;
    hdmi_tx_int     : in    std_logic;

    hdmi_sclk       : inout std_logic;
    hdmi_mclk       : inout std_logic;
    hdmi_lrclk      : inout std_logic;
    hdmi_i2s        : inout std_logic;

    hdmi_i2c_scl    : inout std_logic;
    hdmi_i2c_sda    : inout std_logic;

    adc_convst      : out   std_logic;
    adc_sck         : out   std_logic;
    adc_sdi         : out   std_logic;
    adc_sdo         : in    std_logic;

    arduino_reset_n : inout std_logic;
    arduino_io      : inout std_logic_vector(15 downto 0);
    gpio_0          : inout std_logic_vector(35 downto 0);
    gpio_1          : inout std_logic_vector(35 downto 0)

  );
end entity terasic_de10nano;

architecture synth of terasic_de10nano is

begin

  -- unused outputs
  led         <= (others => '0');
  hdmi_tx_clk <= '0';
  hdmi_tx_d   <= (others => '0');
  hdmi_tx_vs  <= '0';
  hdmi_tx_hs  <= '0';
  hdmi_tx_de  <= '0';
  adc_convst  <= '0';
  adc_sck     <= '0';
  adc_sdi     <= '0';

end architecture synth;
