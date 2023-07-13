--------------------------------------------------------------------------------
-- hdmi_tpg_digilent_zybo_z7_20.vhd                                           --
-- Board specific top level wrapper for the hdmi_tpg design.                  --
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

library work;
  use work.hdmi_tpg_pkg.all;
  use work.mmcm_pkg.all;

entity hdmi_tpg_digilent_zybo_z7_20 is
  port (

    -- clock
    clki_125m           : in    std_logic;

    -- LEDs, buttons and switches
    sw                  : in    std_logic_vector(3 downto 0);
    btn                 : in    std_logic_vector(3 downto 0);
    led                 : out   std_logic_vector(3 downto 0);
    led_r               : out   std_logic_vector(6 downto 5);
    led_g               : out   std_logic_vector(6 downto 5);
    led_b               : out   std_logic_vector(6 downto 5);

    -- HDMI RX
    -- hdmi_rx_hpd         : out   std_logic;
    -- hdmi_rx_scl         : inout std_logic;
    -- hdmi_rx_sda         : inout std_logic;
    -- hdmi_rx_clk_p       : in    std_logic;
    -- hdmi_rx_clk_n       : in    std_logic;
    -- hdmi_rx_d_p         : in    std_logic_vector(0 to 2);
    -- hdmi_rx_d_n         : in    std_logic_vector(0 to 2);
    -- hdmi_rx_cec         : in    std_logic;

    -- HDMI TX
    -- hdmi_tx_hpd         : in    std_logic;
    -- hdmi_tx_scl         : inout std_logic;
    -- hdmi_tx_sda         : inout std_logic;
    hdmi_tx_clk_p       : out   std_logic;
    hdmi_tx_clk_n       : out   std_logic;
    hdmi_tx_d_p         : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n         : out   std_logic_vector(0 to 2);
    hdmi_tx_cec         : out   std_logic;

    -- PMODs
    -- ja                  : inout std_logic_vector(7 downto 0);
    -- jb                  : inout std_logic_vector(7 downto 0);
    -- jc                  : inout std_logic_vector(7 downto 0);
    -- jd                  : inout std_logic_vector(7 downto 0);
    -- je                  : inout std_logic_vector(7 downto 0);

    -- Audio codec (SSM2603CPZ, I2C address 0011010)
    -- ac_bclk             : inout std_logic;
    -- ac_mclk             : in    std_logic;
    ac_muten            : out   std_logic;
    ac_pbdat            : out   std_logic;
    -- ac_pblrc            : inout std_logic;
    -- ac_recdat           : in    std_logic;
    -- ac_reclrc           : inout std_logic;
    -- ac_scl              : out   std_logic;
    -- ac_sda              : inout std_logic;

    -- RTL8211E-VL
    -- eth_int_pu_b        : in    std_logic; -- pin 20, INTB
    eth_rst_b           : out   std_logic  -- pin 29, PHYRSTB

    -- Jumper J14
    -- fan_fb_pu           : in    std_logic;

    -- Jumper J2
    -- cam_clk             : in    std_logic;
    -- cam_gpio            : in    std_logic;
    -- cam_scl             : in    std_logic;
    -- cam_sda             : inout std_logic;

    -- ATSHA204A-SSHCZ-T
    -- crypto_sda          : inout std_logic;

    -- USB OTG
    -- otg_oc              : in    std_logic;

    -- MIPI
    -- dphy_clk_lp_p       : in    std_logic;
    -- dphy_clk_lp_n       : in    std_logic;
    -- dphy_data_lp_p      : in    std_logic_vector(1 downto 0);
    -- dphy_data_lp_n      : in    std_logic_vector(1 downto 0);
    -- dphy_hs_clock_clk_p : in    std_logic;
    -- dphy_hs_clock_clk_n : in    std_logic;
    -- dphy_data_hs_p      : in    std_logic_vector(1 downto 0);
    -- dphy_data_hs_n      : in    std_logic_vector(1 downto 0)

  );
end entity hdmi_tpg_digilent_zybo_z7_20;

architecture synth of hdmi_tpg_digilent_zybo_z7_20 is

  signal rst_100m  : std_logic;
  signal clk_100m  : std_logic;
  signal mode_step : std_logic;
  signal mode      : std_logic_vector(3 downto 0);
  signal dvi       : std_logic;
  signal steady    : std_logic;
  signal heartbeat : std_logic_vector(3 downto 0);
  signal status    : std_logic_vector(1 downto 0);
  signal pulse     : std_logic;

begin

  -- user interface:
  -- button BTN0 = reset
  -- button BTN1 = press to increment video mode (0..14 then wrap)
  -- switch SW0 = HDMI/DVI mode
  -- switch SW1 = steady audio
  -- leds LD3..LD0 = display mode (binary, 0000..1110) AND heartbeat
  -- led LD4: fixed white
  -- led LD5: R = clk_100m lock, G = pixel clock MMCM lock, B = audio clock MMCM lock

  -- 100MHz from 125MHz
  REF_CLOCK: component mmcm
    generic map (
      mul         => 8.0,
      div         => 1,
      num_outputs => 1,
      odiv0       => 10.0
    )
    port map (
      rsti        => btn(0),
      clki        => clki_125m,
      rsto        => rst_100m,
      clko(0)     => clk_100m
    );

  mode_step       <= btn(1);
  dvi             <= sw(0);
  steady          <= sw(1);

  led(3 downto 0) <= mode;

  led_r(5)        <= '1';
  led_g(5)        <= '1';
  led_b(5)        <= '1';

  pulse <= heartbeat(2) when dvi = '1' else heartbeat(0);
  
  led_r(6)        <= pulse and not rst_100m;
  led_g(6)        <= pulse and status(0);
  led_b(6)        <= pulse and status(1);

  MAIN: component hdmi_tpg
    generic map (
      fclk       => 100.0 -- 100MHz
    )
    port map (
      rst        => rst_100m,
      clk        => clk_100m,
      mode_step  => mode_step,
      mode       => mode,
      dvi        => dvi,
      steady     => steady,
      heartbeat  => heartbeat,
      status     => status,
      hdmi_clk_p => hdmi_tx_clk_p,
      hdmi_clk_n => hdmi_tx_clk_n,
      hdmi_d_p   => hdmi_tx_d_p,
      hdmi_d_n   => hdmi_tx_d_n
    );

  -- unused I/Os

  hdmi_tx_cec   <= '0';
  ac_muten      <= '0';
  ac_pbdat      <= '0';
  eth_rst_b     <= '1';

end architecture synth;
