--------------------------------------------------------------------------------
-- tmds_cap_digilent_zybo_z7_20.vhd                                           --
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
  use work.axi_pkg.all;
  use work.mmcm_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;
  use work.hdmi_tx_selectio_pkg.all;
  use work.tmds_cap_z7ps_pkg.all;
  use work.tmds_cap_csr_pkg.all;
  use work.tmds_cap_stream_pkg.all;

-- entity copied from src/boards/digilent_zybo_z7_20/digilent_zybo_z7_20.vhd
-- if it needs fixing, then so does the above file

entity tmds_cap_digilent_zybo_z7_20 is
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
end entity tmds_cap_digilent_zybo_z7_20;

architecture synth of tmds_cap_digilent_zybo_z7_20 is

  -- basics

  signal rst_a          : std_logic;
  signal clk_200m       : std_logic;
  signal rst_200m_s     : std_logic_vector(0 to 1);
  signal rst_200m       : std_logic;
  signal idelayctrl_rdy : std_logic;

  -- HDMI I/O

  signal hdmi_rx_clku   : std_logic;
  signal hdmi_rx_clk    : std_logic;
  signal hdmi_rx_d      : std_logic_vector(0 to 2);
  signal prst           : std_logic;
  signal pclk           : std_logic;
  signal sclk           : std_logic;
  signal tmds           : slv10_vector(0 to 2);
  signal rx_status      : hdmi_rx_selectio_status_t;
  signal hdmi_tx_clk    : std_logic;
  signal hdmi_tx_d      : std_logic_vector(0 to 2);

  -- controller
  signal axi_clk        : std_logic;
  signal axi_rst_n      : std_logic;
  signal gpio_i         : std_logic_vector( 31 downto 0 );
  signal gpio_o         : std_logic_vector( 31 downto 0 );
  signal gpio_t         : std_logic_vector( 31 downto 0 );
  signal tmds_axi_mosi  : axi4_mosi_a32d32_t;
  signal tmds_axi_miso  : axi4_miso_a32d32_t;
  signal tmds_axis_mosi : axi4s_mosi_64_t;
  signal tmds_axis_miso : axi4s_miso_64_t;

  signal cap_rst        : std_logic;                     -- capture reset
  signal cap_size       : std_logic_vector(31 downto 0); -- capture size (pixels)
  signal cap_go         : std_logic;                     -- capture start
  signal cap_done       : std_logic;                     -- capture done
  signal cap_error      : std_logic;                     -- capture error

begin

  led(0) <= rx_status.align_s(0);
  led(1) <= rx_status.align_s(1);
  led(2) <= rx_status.align_s(2);
  led(3) <= rx_status.align_p;

  --------------------------------------------------------------------------------
  -- clock and reset generation

  U_MMCM : component mmcm
    generic map (
      mul         => 8.0,
      div         => 1,
      num_outputs => 1,
      odiv0       => 5.0
    )
    port map (
      rsti    => btn(0),
      clki    => sysclk,
      rsto    => rst_a,
      clko(0) => clk_200m
    );

  rst_200_proc : process (rst_a, clk_200m)
  begin
    if rst_a = '1' then
      rst_200m_s(0 to 1) <= (others => '1');
      rst_200m           <= '1';
    elsif rising_edge(clk_200m) then
      rst_200m_s(0 to 1) <= rst_a & rst_200m_s(0);
      rst_200m           <= rst_200m_s(1);
    end if;
  end process rst_200_proc;

  --------------------------------------------------------------------------------
  -- HDMI I/O

  U_HDMI_RX: component hdmi_rx_selectio
    generic map (
      fclk   => 100.0
    )
    port map (
      rst    => not axi_rst_n,
      clk    => axi_clk,
      pclki  => hdmi_rx_clk,
      si     => hdmi_rx_d,
      sclko  => sclk,
      prsto  => prst,
      pclko  => pclk,
      po     => tmds,
      status => rx_status
    );

  U_HDMI_TX: component hdmi_tx_selectio
    port map (
      sclki => sclk,
      prsti => prst,
      pclki => pclk,
      pi    => tmds,
      pclko => hdmi_tx_clk,
      so    => hdmi_tx_d
    );

  --------------------------------------------------------------------------------
  -- controller

  U_CTRL: component tmds_cap_z7ps
    port map (
      axi_clk         => axi_clk,
      axi_rst_n       => axi_rst_n,
      gpio_i          => gpio_i,
      gpio_o          => gpio_o,
      gpio_t          => gpio_t,
      tmds_maxi_mosi  => tmds_axi_mosi,
      tmds_maxi_miso  => tmds_axi_miso,
      tmds_saxis_mosi => tmds_axis_mosi,
      tmds_saxis_miso => tmds_axis_miso
    );

  gpio_i <= (
    0 => idelayctrl_rdy,
    others => '0'
    );

  --------------------------------------------------------------------------------
  -- TMDS capture - control/status registers and streaming

  U_CSR: component tmds_cap_csr
    port map (
      axi_clk     => axi_clk,
      axi_rst_n   => axi_rst_n,
      saxi_mosi   => tmds_axi_mosi,
      saxi_miso   => tmds_axi_miso,
      tmds_status => rx_status,
      cap_rst     => cap_rst,
      cap_size    => cap_size,
      cap_go      => cap_go,
      cap_done    => cap_done,
      cap_error   => cap_error
    );

  U_STREAM: component tmds_cap_stream
    port map (
      prst       => prst,
      pclk       => pclk,
      tmds       => tmds,
      cap_rst    => cap_rst,
      cap_size   => cap_size,
      cap_go     => cap_go,
      cap_done   => cap_done,
      cap_error  => cap_error,
      axi_clk    => axi_clk,
      axi_rst_n  => axi_rst_n,
      maxis_mosi => tmds_axis_mosi,
      maxis_miso => tmds_axis_miso
    );

  --------------------------------------------------------------------------------
  -- I/O primitives

  -- required to use I/O delay primitives

  U_IDELAYCTRL: idelayctrl
    port map (
      rst    => rst_200m,
      refclk => clk_200m,
      rdy    => idelayctrl_rdy
    );

  -- HDMI input and output differential buffers

  U_IBUFDS: component ibufds
    port map (
      i  => hdmi_rx_clk_p,
      ib => hdmi_rx_clk_n,
      o  => hdmi_rx_clku
    );

  U_BUFG: component bufg
    port map (
      i  => hdmi_rx_clku,
      o  => hdmi_rx_clk
    );

  U_OBUFDS: component obufds
    port map (
      i  => hdmi_tx_clk,
      o  => hdmi_tx_clk_p,
      ob => hdmi_tx_clk_n
    );

  GEN_CH: for i in 0 to 2 generate

    U_IBUFDS: component ibufds
      port map (
        i  => hdmi_rx_p(i),
        ib => hdmi_rx_n(i),
        o  => hdmi_rx_d(i)
      );

    U_OBUFDS: component obufds
      port map (
        i  => hdmi_tx_d(i),
        o  => hdmi_tx_p(i),
        ob => hdmi_tx_n(i)
      );

  end generate GEN_CH;

  --------------------------------------------------------------------------------
  -- TODO: drive unused I/Os to safe states

  --------------------------------------------------------------------------------

end architecture synth;
