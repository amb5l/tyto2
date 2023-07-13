--------------------------------------------------------------------------------
-- tmds_cap_digilent_zybo_z7_10.vhd                                           --
-- Board specific variant of the tmds_cap design.                             --
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

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.tyto_types_pkg.all;
  use work.axi4_pkg.all;
  use work.axi4s_pkg.all;
  use work.mmcm_pkg.all;
  use work.tmds_cap_z7ps_pkg.all;
  use work.tmds_cap_io_pkg.all;

entity tmds_cap_digilent_zybo_z7_10 is
  port (

    -- clock
    clki_125m           : in    std_logic;

    -- LEDs, buttons and switches
--  sw                  : in    std_logic_vector(3 downto 0);
    btn                 : in    std_logic_vector(3 downto 0);
    led                 : out   std_logic_vector(3 downto 0);
    led_r               : out   std_logic_vector(6 downto 6);
    led_g               : out   std_logic_vector(6 downto 6);
    led_b               : out   std_logic_vector(6 downto 6);

    -- HDMI RX
--  hdmi_rx_hpd         : out   std_logic;
--  hdmi_rx_scl         : inout std_logic;
--  hdmi_rx_sda         : inout std_logic;
    hdmi_rx_clk_p       : in    std_logic;
    hdmi_rx_clk_n       : in    std_logic;
    hdmi_rx_d_p         : in    std_logic_vector(0 to 2);
    hdmi_rx_d_n         : in    std_logic_vector(0 to 2);
--  hdmi_rx_cec         : in    std_logic;

    -- HDMI TX
--  hdmi_tx_hpd         : in    std_logic;
--  hdmi_tx_scl         : inout std_logic;
--  hdmi_tx_sda         : inout std_logic;
    hdmi_tx_clk_p       : out   std_logic;
    hdmi_tx_clk_n       : out   std_logic;
    hdmi_tx_d_p         : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n         : out   std_logic_vector(0 to 2);
    hdmi_tx_cec         : out   std_logic;

    -- PMODs
--  ja                  : inout std_logic_vector(7 downto 0);
--  jb                  : inout std_logic_vector(7 downto 0);
--  jc                  : inout std_logic_vector(7 downto 0);
--  jd                  : inout std_logic_vector(7 downto 0);
--  je                  : inout std_logic_vector(7 downto 0);

    -- Audio codec (SSM2603CPZ, I2C address 0011010)
--  ac_bclk             : inout std_logic;
--  ac_mclk             : in    std_logic;
    ac_muten            : out   std_logic;
    ac_pbdat            : out   std_logic;
--  ac_pblrc            : inout std_logic;
--  ac_recdat           : in    std_logic;
--  ac_reclrc           : inout std_logic;
--  ac_scl              : out   std_logic;
--  ac_sda              : inout std_logic;

    -- RTL8211E-VL
--  eth_int_pu_b        : in    std_logic; -- pin 20, INTB
    eth_rst_b           : out   std_logic  -- pin 29, PHYRSTB

    -- Jumper J14
--  fan_fb_pu           : in    std_logic;

    -- Jumper J2
--  cam_clk             : in    std_logic;
--  cam_gpio            : in    std_logic;
--  cam_scl             : in    std_logic;
--  cam_sda             : inout std_logic;

    -- ATSHA204A-SSHCZ-T
--  crypto_sda          : inout std_logic;

    -- USB OTG
--  otg_oc              : in    std_logic;

    -- MIPI
--  dphy_clk_lp_p       : in    std_logic;
--  dphy_clk_lp_n       : in    std_logic;
--  dphy_data_lp_p      : in    std_logic_vector(1 downto 0);
--  dphy_data_lp_n      : in    std_logic_vector(1 downto 0);
--  dphy_hs_clock_clk_p : in    std_logic;
--  dphy_hs_clock_clk_n : in    std_logic;
--  dphy_data_hs_p      : in    std_logic_vector(1 downto 0);
--  dphy_data_hs_n      : in    std_logic_vector(1 downto 0)

  );
end entity tmds_cap_digilent_zybo_z7_10;

architecture synth of tmds_cap_digilent_zybo_z7_10 is

  signal rst        : std_logic;
  signal clk_200m   : std_logic;

  signal axi_clk    : std_logic;
  signal axi_rst_n  : std_logic;
  signal axi4_mosi  : axi4_a32d32_h_mosi_t;
  signal axi4_miso  : axi4_a32d32_h_miso_t;
  signal axi4s_mosi : axi4s_64_mosi_t;
  signal axi4s_miso : axi4s_64_miso_t;

begin

  -- board specific clocking
  U_MMCM : component mmcm
    generic map (
      mul         => 8.0,
      div         => 1,
      num_outputs => 1,
      odiv0       => 5.0
    )
    port map (
      rsti    => btn(0),
      clki    => clki_125m,
      rsto    => rst,
      clko(0) => clk_200m
    );

  -- controller
  U_CTRL: component tmds_cap_z7ps
    port map (
      axi_clk     => axi_clk,
      axi_rst_n   => axi_rst_n,
      maxi4_mosi  => axi4_mosi,
      maxi4_miso  => axi4_miso,
      saxi4s_mosi => axi4s_mosi,
      saxi4s_miso => axi4s_miso
    );

  -- I/O
  U_IO: component tmds_cap_io
    port map (
      rst           => rst,
      clk_200m      => clk_200m,
      led           => led,
      axi_rst_n     => axi_rst_n,
      axi_clk       => axi_clk,
      saxi4_mosi    => axi4_mosi,
      saxi4_miso    => axi4_miso,
      maxi4s_mosi   => axi4s_mosi,
      maxi4s_miso   => axi4s_miso,
      hdmi_rx_clk_p => hdmi_rx_clk_p,
      hdmi_rx_clk_n => hdmi_rx_clk_n,
      hdmi_rx_d_p   => hdmi_rx_d_p,
      hdmi_rx_d_n   => hdmi_rx_d_n,
      hdmi_tx_clk_p => hdmi_tx_clk_p,
      hdmi_tx_clk_n => hdmi_tx_clk_n,
      hdmi_tx_d_p   => hdmi_tx_d_p,
      hdmi_tx_d_n   => hdmi_tx_d_n
    );

  -- safe states for unused outputs
  led_r(6)      <= '0';
  led_g(6)      <= '0';
  led_b(6)      <= '0';
  hdmi_tx_cec   <= '0';
  ac_muten      <= '0';
  ac_pbdat      <= '0';
  eth_rst_b     <= '1'; -- beware: reset will stop clki_125m

end architecture synth;
