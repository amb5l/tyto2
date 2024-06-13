--------------------------------------------------------------------------------
-- mb_mcs_memac_digilent_nexys_video.vhd                                      --
-- Board specific variant of the mb_mcs_memac design.                         --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
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

use work.tyto_types_pkg.all;
use work.mmcm_v2_pkg.all;
use work.memac_pkg.all;
use work.memac_util_pkg.all;
use work.mb_mcs_wrapper_pkg.all;
use work.mb_mcs_memac_bridge_pkg.all;
use work.memac_raw_rgmii_pkg.all;

use work.sync_reg_u_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

entity mb_mcs_memac_digilent_nexys_video is
  generic (
    RGMII_TX_ALIGN : string;
    RGMII_RX_ALIGN : string;
    TX_BUF_SIZE    : integer;
    RX_BUF_SIZE    : integer
  );
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
    -- hdmi_rx_clk_p   : in    std_logic;
    -- hdmi_rx_clk_n   : in    std_logic;
    -- hdmi_rx_d_p     : in    std_logic_vector(0 to 2);
    -- hdmi_rx_d_n     : in    std_logic_vector(0 to 2);
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
    -- eth_int_n       : in    std_logic;
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
    ddr3_reset_n    : out   std_logic
    -- ddr3_ck_p       : out   std_logic_vector(0 downto 0);
    -- ddr3_ck_n       : out   std_logic_vector(0 downto 0);
    -- ddr3_cke        : out   std_logic_vector(0 downto 0);
    -- ddr3_ras_n      : out   std_logic;
    -- ddr3_cas_n      : out   std_logic;
    -- ddr3_we_n       : out   std_logic;
    -- ddr3_odt        : out   std_logic_vector(0 downto 0);
    -- ddr3_addr       : out   std_logic_vector(14 downto 0);
    -- ddr3_ba         : out   std_logic_vector(2 downto 0);
    -- ddr3_dm         : out   std_logic_vector(1 downto 0);
    -- ddr3_dq         : inout std_logic_vector(15 downto 0);
    -- ddr3_dqs_p      : inout std_logic_vector(1 downto 0);
    -- ddr3_dqs_n      : inout std_logic_vector(1 downto 0)

  );
end entity mb_mcs_memac_digilent_nexys_video;

architecture rtl of mb_mcs_memac_digilent_nexys_video is

  constant TX_BUF_SIZE_LOG2 : integer := log2(TX_BUF_SIZE);
  constant RX_BUF_SIZE_LOG2 : integer := log2(RX_BUF_SIZE);
  constant MTU              : integer := 1522;
  constant LEN_MAX_LOG2     : integer := log2(MTU); -- should equal 11

  signal clk_200m         : std_ulogic;
  signal clk_125m_0       : std_ulogic;
  signal clk_125m_90      : std_ulogic;
  signal clk_100m         : std_logic;

  signal rst_a            : std_ulogic; -- asynchronous reset from MMCM
  signal rst_100m         : std_ulogic; -- clk_100m synchronous reset
  signal rst_125m         : std_ulogic; -- clk_125m synchronous reset

  signal gpi              : sulv_vector(1 to 4)(31 downto 0);
  signal gpo              : sulv_vector(1 to 4)(31 downto 0);
  signal io_mosi          : mb_mcs_io_mosi_t;
  signal io_miso          : mb_mcs_io_miso_t;

  signal mac_md_stb       : std_ulogic;
  signal mac_md_pre       : std_ulogic;
  signal mac_md_r_w       : std_ulogic;
  signal mac_md_pa        : std_ulogic_vector(4 downto 0);
  signal mac_md_ra        : std_ulogic_vector(4 downto 0);
  signal mac_md_wd        : std_ulogic_vector(15 downto 0);
  signal mac_md_rd        : std_ulogic_vector(15 downto 0);
  signal mac_md_rdy       : std_ulogic;
  signal mac_tx_rst       : std_ulogic;
  signal mac_tx_ctrl      : tx_ctrl_t;
  signal mac_tx_prq_rdy   : std_ulogic;
  signal mac_tx_prq_len   : std_ulogic_vector(LEN_MAX_LOG2-1 downto 0);
  signal mac_tx_prq_idx   : std_ulogic_vector(log2(TX_BUF_SIZE)-1 downto 0);
  signal mac_tx_prq_tag   : std_ulogic_vector(0 downto 0);
  signal mac_tx_prq_opt   : tx_opt_t;
  signal mac_tx_prq_stb   : std_ulogic;
  signal mac_tx_pfq_rdy   : std_ulogic;
  signal mac_tx_pfq_len   : std_ulogic_vector(LEN_MAX_LOG2-1 downto 0);
  signal mac_tx_pfq_idx   : std_ulogic_vector(log2(TX_BUF_SIZE)-1 downto 0);
  signal mac_tx_pfq_tag   : std_ulogic_vector(0 downto 0);
  signal mac_tx_pfq_stb   : std_ulogic;
  signal mac_tx_buf_en    : std_ulogic;
  signal mac_tx_buf_bwe   : std_ulogic_vector(3 downto 0);
  signal mac_tx_buf_addr  : std_ulogic_vector(TX_BUF_SIZE_LOG2-1 downto 2);
  signal mac_tx_buf_din   : std_ulogic_vector(31 downto 0);
  signal mac_tx_buf_dpin  : std_ulogic_vector(3 downto 0);
  signal mac_tx_buf_dout  : std_ulogic_vector(31 downto 0);
  signal mac_tx_buf_dpout : std_ulogic_vector(3 downto 0);
  signal mac_rx_rst       : std_ulogic;
  signal mac_rx_ctrl      : rx_ctrl_t;
  signal mac_rx_stat      : rx_stat_t;
  signal mac_rx_prq_rdy   : std_ulogic;
  signal mac_rx_prq_len   : std_ulogic_vector(LEN_MAX_LOG2-1 downto 0);
  signal mac_rx_prq_idx   : std_ulogic_vector(log2(TX_BUF_SIZE)-1 downto 0);
  signal mac_rx_prq_flag  : rx_flag_t;
  signal mac_rx_prq_stb   : std_ulogic;
  signal mac_rx_pfq_rdy   : std_ulogic;
  signal mac_rx_pfq_len   : std_ulogic_vector(LEN_MAX_LOG2-1 downto 0);
  signal mac_rx_pfq_stb   : std_ulogic;
  signal mac_rx_buf_en    : std_ulogic;
  signal mac_rx_buf_bwe   : std_ulogic_vector(3 downto 0);
  signal mac_rx_buf_addr  : std_ulogic_vector(RX_BUF_SIZE_LOG2-1 downto 2);
  signal mac_rx_buf_din   : std_ulogic_vector(31 downto 0);
  signal mac_rx_buf_dpin  : std_ulogic_vector(3 downto 0);
  signal mac_rx_buf_dout  : std_ulogic_vector(31 downto 0);
  signal mac_rx_buf_dpout : std_ulogic_vector(3 downto 0);

  signal eth_rst          : std_ulogic;
  signal eth_mdi          : std_ulogic;
  signal eth_mdo          : std_ulogic;
  signal eth_mdoe         : std_ulogic;

  attribute KEEP_HIERARCHY : string;
  attribute KEEP_HIERARCHY of mb_mcs_memac_digilent_nexys_video : entity is "TRUE";

begin

  --------------------------------------------------------------------------------
  -- MMCM generates 200MHz, 125MHz and 100MHz from 100MHz reference

  U_MMCM: component mmcm_v2
    generic map (
      mul    => 10.0,
      div    => 1,
      odiv0  => 5.0,
      odiv1  => 8,
      odiv2  => ternary(RGMII_TX_ALIGN = "EDGE", 0, 8),
      odiv3  => 10,
      phase2 => 90.0
    )
    port map (
      rsti  => not btn_rst_n,
      clki  => clki_100m,
      rsto  => rst_a,
      clk0  => clk_200m,
      clk1  => clk_125m_0,
      clk2  => clk_125m_90,
      clk3  => clk_100m,
      clk4  => open,
      clk5  => open,
      clk6  => open
    );

  U_SYNC_RST_100M: component sync_reg_u
    generic map (
      stages    => 3,
      rst_state => '1'
    )
    port map (
      rst  => '0',
      clk  => clk_100m,
      i(0) => rst_a,
      o(0) => rst_100m
    );

  U_SYNC_RST_125M: component sync_reg_u
    generic map (
      stages    => 3,
      rst_state => '1'
    )
    port map (
      rst  => '0',
      clk  => clk_125m_0,
      i(0) => rst_a,
      o(0) => rst_125m
    );

  --------------------------------------------------------------------------------
  -- IDELAYCTRL for IDELAYE2 usage in RGMII RX

  U_IDELAYCTRL: component idelayctrl
    port map (
      rst    => rst_a,
      refclk => clk_200m,
      rdy    => open
    );

  --------------------------------------------------------------------------------
  -- MicroBlaze V MCS (CPU core)

  U_MCU: component mb_mcs_wrapper
    port map (
      rst      => rst_100m,
      clk      => clk_100m,
      uart_tx  => uart_rx_out,
      uart_rx  => uart_tx_in,
      gpi      => gpi,
      gpo      => gpo,
      io_mosi  => io_mosi,
      io_miso  => io_miso
    );

  --------------------------------------------------------------------------------
  -- MCS I/O to MEMAC interface

  U_BRIDGE: component mb_mcs_memac_bridge
    port map (
      rst          => rst_100m,
      clk          => clk_100m,
      io_mosi      => io_mosi,
      io_miso      => io_miso,
      tx_prq_len   => mac_tx_prq_len,
      tx_prq_idx   => mac_tx_prq_idx,
      tx_prq_tag   => mac_tx_prq_tag,
      tx_prq_opt   => mac_tx_prq_opt,
      tx_prq_stb   => mac_tx_prq_stb,
      tx_pfq_len   => mac_tx_pfq_len,
      tx_pfq_idx   => mac_tx_pfq_idx,
      tx_pfq_tag   => mac_tx_pfq_tag,
      tx_pfq_stb   => mac_tx_pfq_stb,
      tx_buf_en    => mac_tx_buf_en,
      tx_buf_bwe   => mac_tx_buf_bwe,
      tx_buf_addr  => mac_tx_buf_addr,
      tx_buf_din   => mac_tx_buf_din,
      tx_buf_dpin  => mac_tx_buf_dpin,
      tx_buf_dout  => mac_tx_buf_dout,
      tx_buf_dpout => mac_tx_buf_dpout,
      rx_prq_len   => mac_rx_prq_len,
      rx_prq_idx   => mac_rx_prq_idx,
      rx_prq_flag  => mac_rx_prq_flag,
      rx_prq_stb   => mac_rx_prq_stb,
      rx_pfq_len   => mac_rx_pfq_len,
      rx_pfq_stb   => mac_rx_pfq_stb,
      rx_buf_en    => mac_rx_buf_en,
      rx_buf_bwe   => mac_rx_buf_bwe,
      rx_buf_addr  => mac_rx_buf_addr,
      rx_buf_din   => mac_rx_buf_din,
      rx_buf_dpin  => mac_rx_buf_dpin,
      rx_buf_dout  => mac_rx_buf_dout,
      rx_buf_dpout => mac_rx_buf_dpout,
      md_stb       => mac_md_stb,
      md_r_w       => mac_md_r_w,
      md_pa        => mac_md_pa,
      md_ra        => mac_md_ra,
      md_wd        => mac_md_wd,
      md_rd        => mac_md_rd
    );

  --------------------------------------------------------------------------------
  -- integrated MEMAC with raw system interface and RGMII phy interface

  U_MAC: component memac_raw_rgmii
    generic map (
      MDIO_DIV5M => 20,
      TX_ALIGN   => RGMII_TX_ALIGN,
      RX_ALIGN   => RGMII_RX_ALIGN
    )
    port map (

      sys_rst          => rst_100m,
      sys_clk          => clk_100m,
      sys_md_stb       => mac_md_stb,
      sys_md_pre       => mac_md_pre,
      sys_md_r_w       => mac_md_r_w,
      sys_md_pa        => mac_md_pa,
      sys_md_ra        => mac_md_ra,
      sys_md_wd        => mac_md_wd,
      sys_md_rd        => mac_md_rd,
      sys_md_rdy       => mac_md_rdy,
      sys_tx_rst       => mac_tx_rst,
      sys_tx_ctrl      => mac_tx_ctrl,
      sys_tx_prq_rdy   => mac_tx_prq_rdy,
      sys_tx_prq_len   => mac_tx_prq_len,
      sys_tx_prq_idx   => mac_tx_prq_idx,
      sys_tx_prq_tag   => mac_tx_prq_tag,
      sys_tx_prq_opt   => mac_tx_prq_opt,
      sys_tx_prq_stb   => mac_tx_prq_stb,
      sys_tx_pfq_rdy   => mac_tx_pfq_rdy,
      sys_tx_pfq_len   => mac_tx_pfq_len,
      sys_tx_pfq_idx   => mac_tx_pfq_idx,
      sys_tx_pfq_tag   => mac_tx_pfq_tag,
      sys_tx_pfq_stb   => mac_tx_pfq_stb,
      sys_tx_buf_en    => mac_tx_buf_en,
      sys_tx_buf_bwe   => mac_tx_buf_bwe,
      sys_tx_buf_addr  => mac_tx_buf_addr,
      sys_tx_buf_din   => mac_tx_buf_din,
      sys_tx_buf_dpin  => mac_tx_buf_dpin,
      sys_tx_buf_dout  => mac_tx_buf_dout,
      sys_tx_buf_dpout => mac_tx_buf_dpout,
      sys_rx_rst       => mac_rx_rst,
      sys_rx_ctrl      => mac_rx_ctrl,
      sys_rx_stat      => mac_rx_stat,
      sys_rx_prq_rdy   => mac_rx_prq_rdy,
      sys_rx_prq_len   => mac_rx_prq_len,
      sys_rx_prq_idx   => mac_rx_prq_idx,
      sys_rx_prq_flag  => mac_rx_prq_flag,
      sys_rx_prq_stb   => mac_rx_prq_stb,
      sys_rx_pfq_rdy   => mac_rx_pfq_rdy,
      sys_rx_pfq_len   => mac_rx_pfq_len,
      sys_rx_pfq_stb   => mac_rx_pfq_stb,
      sys_rx_buf_en    => mac_rx_buf_en,
      sys_rx_buf_bwe   => mac_rx_buf_bwe,
      sys_rx_buf_addr  => mac_rx_buf_addr,
      sys_rx_buf_din   => mac_rx_buf_din,
      sys_rx_buf_dpin  => mac_rx_buf_dpin,
      sys_rx_buf_dout  => mac_rx_buf_dout,
      sys_rx_buf_dpout => mac_rx_buf_dpout,
      ref_rst          => rst_125m,
      ref_clk          => clk_125m_0,
      ref_clk_90       => clk_125m_90,
      phy_mdc          => eth_mdc,
      phy_mdo          => eth_mdo,
      phy_mdoe         => eth_mdoe,
      phy_mdi          => eth_mdi,
      phy_rgmii_tx_clk => eth_txck,
      phy_rgmii_tx_ctl => eth_txctl,
      phy_rgmii_tx_d   => eth_txd,
      phy_rgmii_rx_clk => eth_rxck,
      phy_rgmii_rx_ctl => eth_rxctl,
      phy_rgmii_rx_d   => eth_rxd
    );

  eth_rst_n <= not eth_rst;
  eth_mdi  <= eth_mdio;
  eth_mdio <= eth_mdo when eth_mdoe = '1' else 'Z';

  --------------------------------------------------------------------------------
  -- GPO

  eth_rst             <= rst_a or not gpo(1)(0);
  mac_tx_rst          <= rst_a or not gpo(1)(1);
  mac_rx_rst          <= rst_a or not gpo(1)(2);
  mac_md_pre          <= gpo(1)(           3);
  mac_tx_ctrl.spd     <= gpo(1)( 5 downto  4);
  mac_rx_ctrl.spd     <= gpo(1)( 7 downto  6);
  mac_rx_ctrl.ipg_min <= gpo(1)(11 downto  8);
  mac_rx_ctrl.pre_len <= gpo(1)(15 downto 12);
  mac_rx_ctrl.pre_inc <= gpo(1)(          16);
  mac_rx_ctrl.fcs_inc <= gpo(1)(          17);

  led <= gpo(4)(led'range);

  --------------------------------------------------------------------------------
  -- GPI

  gpi(1)(           0) <= mac_tx_prq_rdy;
  gpi(1)(           1) <= mac_tx_pfq_rdy;
  gpi(1)(           2) <= mac_rx_prq_rdy;
  gpi(1)(           3) <= mac_rx_pfq_rdy;
  gpi(1)(           4) <= mac_md_rdy;
  gpi(1)( 6 downto  5) <= mac_rx_stat.spd;
  gpi(1)(           7) <= mac_rx_stat.ibs_crs;
  gpi(1)(           8) <= mac_rx_stat.ibs_crx;
  gpi(1)(           9) <= mac_rx_stat.ibs_crxer;
  gpi(1)(          10) <= mac_rx_stat.ibs_crf;
  gpi(1)(          11) <= mac_rx_stat.ibs_link;
  gpi(1)(13 downto 12) <= mac_rx_stat.ibs_spd;
  gpi(1)(          14) <= mac_rx_stat.ibs_fdx;

  gpi(2) <= mac_rx_stat.drops;

  --------------------------------------------------------------------------------

  -- unused I/Os

  hdmi_rx_txen   <= '0';
  U_HDMI_TX_CLK: component obufds port map ( i => '0', o => hdmi_tx_clk_p,  ob => hdmi_tx_clk_n  );
  U_HDMI_TX_D0:  component obufds port map ( i => '0', o => hdmi_tx_d_p(0), ob => hdmi_tx_d_n(0) );
  U_HDMI_TX_D1:  component obufds port map ( i => '0', o => hdmi_tx_d_p(1), ob => hdmi_tx_d_n(1) );
  U_HDMI_TX_D2:  component obufds port map ( i => '0', o => hdmi_tx_d_p(2), ob => hdmi_tx_d_n(2) );
  oled_res_n     <= '0';
  oled_d_c       <= '0';
  oled_sclk      <= '0';
  oled_sdin      <= '0';
  ac_mclk        <= '0';
  ac_dac_sdata   <= '0';
  ftdi_rd_n      <= '1';
  ftdi_wr_n      <= '1';
  ftdi_siwu_n    <= '1';
  ftdi_oe_n      <= '1';
  qspi_cs_n      <= '1';
  ddr3_reset_n   <= '0';

  --------------------------------------------------------------------------------

end architecture rtl;
