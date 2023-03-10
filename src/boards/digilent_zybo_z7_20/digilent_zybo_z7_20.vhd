--------------------------------------------------------------------------------
-- digilent_zybo_z7_20.vhd                                                    --
-- Top level entity for Digilent Nexys Video board.                           --
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

entity digilent_zybo_z7_20 is
  port (

    -- clock 125 MHz
    sysclk              : in    std_logic;

    -- LEDs, buttons and switches
    sw                  : in    std_logic_vector(3 downto 0);
    btn                 : in    std_logic_vector(3 downto 0);
    led                 : out   std_logic_vector(3 downto 0);
    led5_r              : out   std_logic;
    led5_g              : out   std_logic;
    led5_b              : out   std_logic;
    led6_r              : out   std_logic;
    led6_g              : out   std_logic;
    led6_b              : out   std_logic;

    -- HDMI RX
    hdmi_rx_hpd         : out   std_logic;
    hdmi_rx_scl         : inout std_logic;
    hdmi_rx_sda         : inout std_logic;
    hdmi_rx_clk_n       : in    std_logic;
    hdmi_rx_clk_p       : in    std_logic;
    hdmi_rx_n           : in    std_logic_vector(0 to 2);
    hdmi_rx_p           : in    std_logic_vector(0 to 2);
    hdmi_rx_cec         : in    std_logic;

    -- HDMI TX
    hdmi_tx_hpd         : in    std_logic;
    hdmi_tx_scl         : inout std_logic;
    hdmi_tx_sda         : inout std_logic;
    hdmi_tx_clk_n       : out   std_logic;
    hdmi_tx_clk_p       : out   std_logic;
    hdmi_tx_n           : out   std_logic_vector(0 to 2);
    hdmi_tx_p           : out   std_logic_vector(0 to 2);
    hdmi_tx_cec         : out   std_logic;

    -- PMODs
    ja                  : inout std_logic_vector(7 downto 0);
    jb                  : inout std_logic_vector(7 downto 0);
    jc                  : inout std_logic_vector(7 downto 0);
    jd                  : inout std_logic_vector(7 downto 0);
    je                  : inout std_logic_vector(7 downto 0);

    -- Audio codex
    -- SSM2603CPZ
    -- I2C address 0011010
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

    -- Not connected
    otg_oc              : in    std_logic;

    -- Not present in schematic
    dphy_clk_lp_n       : in    std_logic;
    dphy_clk_lp_p       : in    std_logic;
    dphy_data_lp_n      : in    std_logic_vector(1 downto 0);
    dphy_data_lp_p      : in    std_logic_vector(1 downto 0);
    dphy_hs_clock_clk_n : in    std_logic;
    dphy_hs_clock_clk_p : in    std_logic;
    dphy_data_hs_n      : in    std_logic_vector(1 downto 0);
    dphy_data_hs_p      : in    std_logic_vector(1 downto 0);

    netic19_t9          : in    std_logic;
    netic19_u10         : in    std_logic;
    netic19_u5          : in    std_logic;
    netic19_u8          : in    std_logic;
    netic19_u9          : in    std_logic;
    netic19_v10         : in    std_logic;
    netic19_v11         : in    std_logic;
    netic19_v5          : in    std_logic;
    netic19_w10         : in    std_logic;
    netic19_w11         : in    std_logic;
    netic19_w9          : in    std_logic;
    netic19_y9          : in    std_logic
  );
end entity digilent_zybo_z7_20;

architecture synth of digilent_zybo_z7_20 is

begin

  led           <= "0000";
  led5_r        <= '0';
  led5_g        <= '0';
  led5_b        <= '0';
  led6_r        <= '0';
  led6_g        <= '0';
  led6_b        <= '0';

  hdmi_rx_hpd   <= '0';
  hdmi_rx_scl   <= 'Z';
  hdmi_rx_sda   <= 'Z';

  hdmi_tx_scl   <= 'Z';
  hdmi_tx_sda   <= 'Z';
  hdmi_tx_clk_n <= '1';
  hdmi_tx_clk_p <= '0';
  hdmi_tx_n     <= "111";
  hdmi_tx_p     <= "000";
  hdmi_tx_cec   <= '0';

  ja            <= (others => 'Z');
  jb            <= (others => 'Z');
  jc            <= (others => 'Z');
  jd            <= (others => 'Z');
  je            <= (others => 'Z');

  ac_bclk       <= 'Z';
  ac_muten      <= '0';
  ac_pbdat      <= '0';
  ac_pblrc      <= 'Z';
  ac_reclrc     <= 'Z';
  ac_scl        <= 'Z';
  ac_sda        <= 'Z';

  eth_rst_b     <= '1';

  cam_sda       <= 'Z';

  crypto_sda    <= 'Z';

end architecture synth;

