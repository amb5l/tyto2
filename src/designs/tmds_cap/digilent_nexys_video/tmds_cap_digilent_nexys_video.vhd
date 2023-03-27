--------------------------------------------------------------------------------
-- tmds_cap_digilent_nexys_video.vhd                                          --
-- Board specific variant of the tmds_cap design.                             --
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

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.tyto_types_pkg.all;
  use work.axi_pkg.all;
  use work.mmcm_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;
  use work.hdmi_tx_selectio_pkg.all;
  use work.tmds_cap_mb_pkg.all;
  use work.tmds_cap_stream_pkg.all;
  use work.memac_axi4_rgmii_pkg.all;

entity tmds_cap_digilent_nexys_video is
  port (

    -- clocks
    clki_100m     : in    std_logic;
    -- gtp_clk_p       : in    std_logic;
    -- gtp_clk_n       : in    std_logic;
    -- fmc_mgt_clk_p   : in    std_logic;
    -- fmc_mgt_clk_n   : in    std_logic;

    -- LEDs, buttons and switches
    led           : out   std_logic_vector(7 downto 0);
    -- btn_c           : in    std_logic;
    -- btn_d           : in    std_logic;
    -- btn_l           : in    std_logic;
    -- btn_r           : in    std_logic;
    -- btn_u           : in    std_logic;
    btn_rst_n     : in    std_logic;
    -- sw              : in    std_logic_vector(7 downto 0);

    -- OLED
    oled_res_n    : out   std_logic;
    oled_d_c      : out   std_logic;
    oled_sclk     : out   std_logic;
    oled_sdin     : out   std_logic;
    -- oled_vbat_dis   : out   std_logic;
    -- oled_vdd_dis    : out   std_logic;

    -- HDMI RX
    hdmi_rx_clk_p : in    std_logic;
    hdmi_rx_clk_n : in    std_logic;
    hdmi_rx_d_p   : in    std_logic_vector(0 to 2);
    hdmi_rx_d_n   : in    std_logic_vector(0 to 2);
    -- hdmi_rx_scl     : in    std_logic;
    -- hdmi_rx_sda     : inout std_logic;
    -- hdmi_rx_cec     : in    std_logic;
    -- hdmi_rx_hpd     : out   std_logic;
    hdmi_rx_txen  : out   std_logic;

    -- HDMI TX
    hdmi_tx_clk_p : out   std_logic;
    hdmi_tx_clk_n : out   std_logic;
    hdmi_tx_d_p   : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n   : out   std_logic_vector(0 to 2);
    -- hdmi_tx_scl     : out   std_logic;
    -- hdmi_tx_sda     : inout std_logic;
    -- hdmi_tx_cec     : out   std_logic;
    -- hdmi_tx_hpd     : in    std_logic;

    -- DisplayPort
    -- dp_tx_p         : out   std_logic_vector(0 to 1);
    -- dp_tx_n         : out   std_logic_vector(0 to 1);
    -- dp_tx_aux_p     : inout std_logic;
    -- dp_tx_aux_n     : inout std_logic;
    -- dp_tx_aux2_p    : inout std_logic;
    -- dp_tx_aux2_n    : inout std_logic;
    -- dp_tx_hpd       : in    std_logic;

    -- audio codec
    ac_mclk       : out   std_logic;
    -- ac_lrclk        : out   std_logic;
    -- ac_bclk         : out   std_logic;
    ac_dac_sdata  : out   std_logic;
    -- ac_adc_sdata    : in    std_logic;

    -- PMODs
    -- ja              : inout std_logic_vector(7 downto 0);
    -- jb              : inout std_logic_vector(7 downto 0);
    -- jc              : inout std_logic_vector(7 downto 0);
    -- xa_p            : inout std_logic_vector(3 downto 0);
    -- xa_n            : inout std_logic_vector(3 downto 0);

    -- UART
    uart_rx_out   : out   std_logic;
    uart_tx_in    : in    std_logic;

    -- ethernet
    eth_rst_n     : out   std_logic;
    eth_txck      : out   std_logic;
    eth_txctl     : out   std_logic;
    eth_txd       : out   std_logic_vector(3 downto 0);
    eth_rxck      : in    std_logic;
    eth_rxctl     : in    std_logic;
    eth_rxd       : in    std_logic_vector(3 downto 0);
    eth_mdc       : out   std_logic;
    eth_mdio      : inout std_logic;
    -- eth_int_n     : in    std_logic;
    -- eth_pme_n       : in    std_logic;

    -- fan
    -- fan_pwm         : out   std_logic;

    -- FTDI
    -- ftdi_clko       : in    std_logic;
    -- ftdi_rxf_n      : in    std_logic;
    -- ftdi_txe_n      : in    std_logic;
    ftdi_rd_n     : out   std_logic;
    ftdi_wr_n     : out   std_logic;
    ftdi_siwu_n   : out   std_logic;
    ftdi_oe_n     : out   std_logic;
    -- ftdi_d          : inout std_logic_vector(7 downto 0);
    -- ftdi_spien      : out   std_logic;

    -- PS/2
    -- ps2_clk         : inout std_logic;
    -- ps2_data        : inout std_logic;

    -- QSPI
    qspi_cs_n     : out   std_logic;
    -- qspi_dq         : inout std_logic_vector(3 downto 0);

    -- SD
    -- sd_reset        : out   std_logic;
    -- sd_cclk         : out   std_logic;
    -- sd_cmd          : out   std_logic;
    -- sd_d            : inout std_logic_vector(3 downto 0);
    -- sd_cd           : in    std_logic;

    -- I2C
    -- i2c_scl         : inout std_logic;
    -- i2c_sda         : inout std_logic;

    -- VADJ
    -- set_vadj        : out   std_logic_vector(1 downto 0);
    -- vadj_en         : out   std_logic;

    -- FMC
    -- fmc_clk0_m2c_p  : in    std_logic;
    -- fmc_clk0_m2c_n  : in    std_logic;
    -- fmc_clk1_m2c_p  : in    std_logic;
    -- fmc_clk1_m2c_n  : in    std_logic;
    -- fmc_la_p        : inout std_logic_vector(33 downto 0);
    -- fmc_la_n        : inout std_logic_vector(33 downto 0);

    -- DDR3
    ddr3_reset_n    : out   std_logic;
    ddr3_ck_p       : out   std_logic_vector(0 downto 0);
    ddr3_ck_n       : out   std_logic_vector(0 downto 0);
    ddr3_cke        : out   std_logic_vector(0 downto 0);
    ddr3_ras_n      : out   std_logic;
    ddr3_cas_n      : out   std_logic;
    ddr3_we_n       : out   std_logic;
    ddr3_odt        : out   std_logic_vector(0 downto 0);
    ddr3_addr       : out   std_logic_vector(14 downto 0);
    ddr3_ba         : out   std_logic_vector(2 downto 0);
    ddr3_dm         : out   std_logic_vector(1 downto 0);
    ddr3_dq         : inout std_logic_vector(15 downto 0);
    ddr3_dqs_p      : inout std_logic_vector(1 downto 0);
    ddr3_dqs_n      : inout std_logic_vector(1 downto 0)

  );
end entity tmds_cap_digilent_nexys_video;

architecture synth of tmds_cap_digilent_nexys_video is

  -- basics
  signal mig_lock          : std_logic;
  signal mig_rdy           : std_logic;
  signal clk_200m          : std_logic;
  signal idelayctrl_rdy    : std_logic;

  -- HDMI I/O
  signal hdmi_rx_clku      : std_logic;
  signal hdmi_rx_clk       : std_logic;
  signal hdmi_rx_d         : std_logic_vector(0 to 2);
  signal prst              : std_logic;
  signal pclk              : std_logic;
  signal sclk              : std_logic;
  signal tmds              : slv10_vector(0 to 2);
  signal rx_status         : hdmi_rx_selectio_status_t;
  signal hdmi_tx_clk       : std_logic;
  signal hdmi_tx_d         : std_logic_vector(0 to 2);

  -- controller
  signal axi_clk           : std_logic;
  signal axi_rst_n         : std_logic;
  signal gpio_i            : std_logic_vector( 31 downto 0 );
  signal gpio_o            : std_logic_vector( 31 downto 0 );
  signal gpio_t            : std_logic_vector( 31 downto 0 );
  signal tmds_axi_mosi     : axi4_mosi_a32d32_t;
  signal tmds_axi_miso     : axi4_miso_a32d32_t;
  signal tmds_axis_mosi    : axi4s_mosi_64_t;
  signal tmds_axis_miso    : axi4s_miso_64_t;
  signal emac_axi_mosi     : axi4_mosi_a32d32_t;
  signal emac_axi_miso     : axi4_miso_a32d32_t;
  signal emac_rx_axis_mosi : axi4s_mosi_32_t;
  signal emac_rx_axis_miso : axi4s_miso_32_t;
  signal emac_tx_axis_mosi : axi4s_mosi_32_t;
  signal emac_tx_axis_miso : axi4s_miso_32_t;

begin

  led(0) <= mig_lock;
  led(1) <= mig_rdy;
  led(2) <= axi_rst_n;
  led(3) <= not prst;
  led(4) <= rx_status.align_s(0);
  led(5) <= rx_status.align_s(1);
  led(6) <= rx_status.align_s(2);
  led(7) <= rx_status.align_p;

  --------------------------------------------------------------------------------
  -- HDMI I/O

  U_HDMI_RX: component hdmi_rx_selectio
    generic map (
      fclk        => 100.0
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

  hdmi_rx_txen <= '1';

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
  -- controller core

  U_CTRL: component tmds_cap_mb
    port map (
      ref_rst_n       => btn_rst_n,
      ref_clk         => clki_100m,
      mig_lock        => mig_lock,
      mig_rdy         => mig_rdy,
      clk_200m        => clk_200m,
      uart_tx         => uart_rx_out,
      uart_rx         => uart_tx_in,
      gpio_i          => gpio_i,
      gpio_o          => gpio_o,
      gpio_t          => gpio_t,
      axi_clk         => axi_clk,
      axi_rst_n       => axi_rst_n,
      tmds_maxi_mosi  => tmds_axi_mosi,
      tmds_maxi_miso  => tmds_axi_miso,
      tmds_saxis_mosi => tmds_axis_mosi,
      tmds_saxis_miso => tmds_axis_miso,
      emac_maxi_mosi  => emac_axi_mosi,
      emac_maxi_miso  => emac_axi_miso,
      emac_maxis_mosi => emac_tx_axis_mosi,
      emac_maxis_miso => emac_tx_axis_miso,
      emac_saxis_mosi => emac_rx_axis_mosi,
      emac_saxis_miso => emac_rx_axis_miso,
      ddr3_reset_n    => ddr3_reset_n,
      ddr3_ck_p       => ddr3_ck_p,
      ddr3_ck_n       => ddr3_ck_n,
      ddr3_cke        => ddr3_cke,
      ddr3_ras_n      => ddr3_ras_n,
      ddr3_cas_n      => ddr3_cas_n,
      ddr3_we_n       => ddr3_we_n,
      ddr3_odt        => ddr3_odt,
      ddr3_addr       => ddr3_addr,
      ddr3_ba         => ddr3_ba,
      ddr3_dm         => ddr3_dm,
      ddr3_dq         => ddr3_dq,
      ddr3_dqs_p      => ddr3_dqs_p,
      ddr3_dqs_n      => ddr3_dqs_n
    );

  gpio_i <= (0 => mig_rdy,1 => idelayctrl_rdy,others => '0');

  -- TODO connect to gpo
  eth_rst_n <= '0';

  --------------------------------------------------------------------------------
  -- TMDS streaming module (TMDS to AXI4-Stream with AXI4-Lite register interface)

  U_STREAM: component tmds_cap_stream
    port map (
      prst       => prst,
      pclk       => pclk,
      tmds       => tmds,
      rx_status  => rx_status,
      axi_clk    => axi_clk,
      axi_rst_n  => axi_rst_n,
      saxi_mosi  => tmds_axi_mosi,
      saxi_miso  => tmds_axi_miso,
      maxis_mosi => tmds_axis_mosi,
      maxis_miso => tmds_axis_miso
    );

--------------------------------------------------------------------------------
-- ethernet

  U_EMAC: component memac_axi4_rgmii
    port map (
      axi_clk      => axi_clk,
      axi_rst_n    => axi_rst_n,
      saxi_mosi    => emac_axi_mosi,
      saxi_miso    => emac_axi_miso,
      maxis_mosi   => emac_rx_axis_mosi,
      maxis_miso   => emac_rx_axis_miso,
      saxis_mosi   => emac_tx_axis_mosi,
      saxis_miso   => emac_tx_axis_miso,
      rgmii_rx_clk => eth_rxck,
      rgmii_rx_ctl => eth_rxctl,
      rgmii_rx_d   => eth_rxd,
      rgmii_tx_clk => eth_txck,
      rgmii_tx_ctl => eth_txctl,
      rgmii_tx_d   => eth_txd,
      smi_clk      => eth_mdc,
      smi_dio      => eth_mdio
    );

  --------------------------------------------------------------------------------
  -- I/O primitives

  -- required to use I/O delay primitives

  U_IDELAYCTRL: idelayctrl
    port map (
      rst    => not mig_lock,
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
        i  => hdmi_rx_d_p(i),
        ib => hdmi_rx_d_n(i),
        o  => hdmi_rx_d(i)
      );

    U_OBUFDS: component obufds
      port map (
        i  => hdmi_tx_d(i),
        o  => hdmi_tx_d_p(i),
        ob => hdmi_tx_d_n(i)
      );

  end generate GEN_CH;

  --------------------------------------------------------------------------------
  -- unused I/Os

  oled_res_n   <= '0';
  oled_d_c     <= '0';
  oled_sclk    <= '0';
  oled_sdin    <= '0';
  ac_mclk      <= '0';
  ac_dac_sdata <= '0';
  ftdi_rd_n    <= '1';
  ftdi_wr_n    <= '1';
  ftdi_siwu_n  <= '1';
  ftdi_oe_n    <= '1';
  qspi_cs_n    <= '1';

  --------------------------------------------------------------------------------

end architecture synth;
