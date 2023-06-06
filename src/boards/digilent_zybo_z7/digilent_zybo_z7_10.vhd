--------------------------------------------------------------------------------
-- digilent_zybo_z7_10.vhd                                                    --
-- Top level entity for Digilent Zybo Z7-10 board.                            --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Michael Jørgensen <michael.finn.jorgensen@gmail.com>    --
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

entity digilent_zybo_z7_10 is
  port (

    -- clock
    clki_125m           : in    std_logic;

    -- LEDs, buttons and switches
    sw                  : in    std_logic_vector(3 downto 0);
    btn                 : in    std_logic_vector(3 downto 0);
    led                 : out   std_logic_vector(3 downto 0);
    led_r               : out   std_logic_vector(6 downto 6);
    led_g               : out   std_logic_vector(6 downto 6);
    led_b               : out   std_logic_vector(6 downto 6);

    -- HDMI RX
    hdmi_rx_hpd         : out   std_logic;
    hdmi_rx_scl         : inout std_logic;
    hdmi_rx_sda         : inout std_logic;
    hdmi_rx_clk_p       : in    std_logic;
    hdmi_rx_clk_n       : in    std_logic;
    hdmi_rx_d_p         : in    std_logic_vector(0 to 2);
    hdmi_rx_d_n         : in    std_logic_vector(0 to 2);
--  hdmi_rx_cec         : in    std_logic; -- available on Zybo Z7-20 only

    -- HDMI TX
    hdmi_tx_hpd         : in    std_logic;
    hdmi_tx_scl         : inout std_logic;
    hdmi_tx_sda         : inout std_logic;
    hdmi_tx_clk_p       : out   std_logic;
    hdmi_tx_clk_n       : out   std_logic;
    hdmi_tx_d_p         : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n         : out   std_logic_vector(0 to 2);
    hdmi_tx_cec         : out   std_logic;

    -- PMODs
    ja                  : inout std_logic_vector(7 downto 0);
--  jb                  : inout std_logic_vector(7 downto 0); -- available on Zybo Z7-20 only
    jc                  : inout std_logic_vector(7 downto 0);
    jd                  : inout std_logic_vector(7 downto 0);
    je                  : inout std_logic_vector(7 downto 0);

    -- Audio codec (SSM2603CPZ, I2C address 0011010)
    ac_bclk             : inout std_logic;
    ac_mclk             : in    std_logic;
    ac_muten            : out   std_logic;
    ac_pbdat            : out   std_logic;
    ac_pblrc            : inout std_logic;
    ac_recdat           : in    std_logic;
    ac_reclrc           : inout std_logic;
    ac_scl              : out   std_logic;
    ac_sda              : inout std_logic;

    -- RTL8211E-VL
    eth_int_pu_b        : in    std_logic; -- pin 20, INTB
    eth_rst_b           : out   std_logic; -- pin 29, PHYRSTB

    -- Jumper J14
    fan_fb_pu           : in    std_logic;

    -- Jumper J2
    cam_clk             : in    std_logic;
    cam_gpio            : in    std_logic;
    cam_scl             : in    std_logic;
    cam_sda             : inout std_logic;

    -- ATSHA204A-SSHCZ-T
    crypto_sda          : inout std_logic;

    -- USB OTG
    otg_oc              : in    std_logic;

    -- MIPI
    dphy_clk_lp_p       : in    std_logic;
    dphy_clk_lp_n       : in    std_logic;
    dphy_data_lp_p      : in    std_logic_vector(1 downto 0);
    dphy_data_lp_n      : in    std_logic_vector(1 downto 0);
    dphy_hs_clock_clk_p : in    std_logic;
    dphy_hs_clock_clk_n : in    std_logic;
    dphy_data_hs_p      : in    std_logic_vector(1 downto 0);
    dphy_data_hs_n      : in    std_logic_vector(1 downto 0)

  );
end entity digilent_zybo_z7_10;

architecture synth of digilent_zybo_z7_10 is

begin

  -- safe states
  led           <= "0000";
  led_r(6)      <= '0';
  led_g(6)      <= '0';
  led_b(6)      <= '0';
  hdmi_tx_cec   <= '0';
  ac_muten      <= '0';
  ac_pbdat      <= '0';
  eth_rst_b     <= '1'; -- beware: reset will stop clki_125m

end architecture synth;

