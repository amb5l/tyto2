--------------------------------------------------------------------------------
-- mbv_mcs_memac_digilent_nexys_video.vhd                                     --
-- Board specific variant of the mbv_mcs_memac design.                        --
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
use work.memac_tx_pkg.all;
use work.memac_rx_pkg.all;
use work.mbv_mcs_wrapper_pkg.all;
use work.mbv_mcs_memac_bridge_pkg.all;
use work.memac_tx_rgmii_pkg.all;
use work.memac_rx_rgmii_pkg.all;
use work.memac_rx_rgmii_io_pkg.all;
use work.memac_mdio_pkg.all;
use work.sync_reg_u_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

entity mb_memac_digilent_nexys_video is
  generic (
    RGMII_ALIGN : string;
    TX_BUF_SIZE : integer;
    RX_BUF_SIZE : integer
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
end entity mb_memac_digilent_nexys_video;

architecture rtl of mb_memac_digilent_nexys_video is

  signal rsta         : std_ulogic; -- asynchronous reset from MMCM
  signal clk_200m     : std_ulogic;
  signal clk_125m_0   : std_ulogic;
  signal clk_125m_90  : std_ulogic;
  signal clk_100m     : std_logic;

  signal rst_100m     : std_ulogic; -- clk_100m synchronous reset
  signal rst_125m     : std_ulogic; -- clk_125m synchronous reset

  signal gpi          : sulv_vector(1 to 4)(31 downto 0);
  signal gpo          : sulv_vector(1 to 4)(31 downto 0);
  signal io_mosi      : mbv_mcs_io_mosi_t;
  signal io_miso      : mbv_mcs_io_miso_t;

  signal tx_prq_rdy   : std_ulogic;
  signal tx_prq_len   : std_ulogic_vector(10 downto 0); -- max 2kbytes
  signal tx_prq_idx   : std_ulogic_vector(log2(TX_BUF_SIZE)-1 downto 0);
  signal tx_prq_tag   : std_ulogic_vector(0 downto 0);
  signal tx_prq_opt   : tx_opt_t;
  signal tx_prq_stb   : std_ulogic;
  signal tx_pfq_rdy   : std_ulogic;
  signal tx_pfq_len   : std_ulogic_vector(10 downto 0);
  signal tx_pfq_idx   : std_ulogic_vector(log2(TX_BUF_SIZE)-1 downto 0);
  signal tx_pfq_tag   : std_ulogic_vector(0 downto 0);
  signal tx_pfq_stb   : std_ulogic;
  signal tx_buf_en    : std_ulogic;
  signal tx_buf_bwe   : std_ulogic_vector(3 downto 0);
  signal tx_buf_addr  : std_ulogic_vector(log2(TX_BUF_SIZE)-1 downto 2);
  signal tx_buf_din   : std_ulogic_vector(31 downto 0);
  signal tx_buf_dpin  : std_ulogic_vector(3 downto 0);
  signal tx_buf_dout  : std_ulogic_vector(31 downto 0);
  signal tx_buf_dpout : std_ulogic_vector(3 downto 0);
  signal tx_umi_rst   : std_ulogic;
  signal tx_umi_clk   : std_ulogic;
  signal tx_umi_clken : std_ulogic;
  signal tx_umi_dv    : std_ulogic;
  signal tx_umi_er    : std_ulogic;
  signal tx_umi_data  : std_ulogic_vector(7 downto 0);
  signal tx_umi_spd   : std_ulogic_vector(1 downto 0);

  signal rx_opt       : rx_opt_t;
  signal rx_drops     : std_ulogic_vector(31 downto 0);
  signal rx_prq_rdy   : std_ulogic;
  signal rx_prq_len   : std_ulogic_vector(10 downto 0);
  signal rx_prq_idx   : std_ulogic_vector(log2(RX_BUF_SIZE)-1 downto 0);
  signal rx_prq_flag  : rx_flag_t;
  signal rx_prq_stb   : std_ulogic;
  signal rx_pfq_rdy   : std_ulogic;
  signal rx_pfq_len   : std_ulogic_vector(10 downto 0);
  signal rx_pfq_stb   : std_ulogic;
  signal rx_buf_en    : std_ulogic;
  signal rx_buf_bwe   : std_ulogic_vector(3 downto 0);
  signal rx_buf_addr  : std_ulogic_vector(log2(RX_BUF_SIZE)-1 downto 2);
  signal rx_buf_din   : std_ulogic_vector(31 downto 0);
  signal rx_buf_dpin  : std_ulogic_vector(3 downto 0);
  signal rx_buf_dout  : std_ulogic_vector(31 downto 0);
  signal rx_buf_dpout : std_ulogic_vector(3 downto 0);
  signal rx_umi_rst   : std_ulogic;
  signal rx_umi_clk   : std_ulogic;
  signal rx_umi_clken : std_ulogic;
  signal rx_umi_dv    : std_ulogic;
  signal rx_umi_er    : std_ulogic;
  signal rx_umi_data  : std_ulogic_vector(7 downto 0);
  signal rx_ibs_crs   : std_ulogic;
  signal rx_ibs_crx   : std_ulogic;
  signal rx_ibs_crxer : std_ulogic;
  signal rx_ibs_crf   : std_ulogic;
  signal rx_ibs_col   : std_ulogic;
  signal rx_ibs_link  : std_ulogic;
  signal rx_ibs_spd   : std_ulogic_vector(1 downto 0);
  signal rx_ibs_fdx   : std_ulogic;
  signal rx_umi_spdi  : std_ulogic_vector(1 downto 0);
  signal rx_umi_spdo  : std_ulogic_vector(1 downto 0);

  signal rgmii_tx_clk : std_ulogic;
  signal rgmii_tx_ctl : std_ulogic;
  signal rgmii_tx_d   : std_ulogic_vector(3 downto 0);
  signal rgmii_rx_clk : std_ulogic;
  signal rgmii_rx_ctl : std_ulogic;
  signal rgmii_rx_d   : std_ulogic_vector(3 downto 0);

  signal md_stb       : std_ulogic;
  signal md_pre       : std_ulogic;
  signal md_r_w       : std_ulogic;
  signal md_pa        : std_ulogic_vector(4 downto 0);
  signal md_ra        : std_ulogic_vector(4 downto 0);
  signal md_wd        : std_ulogic_vector(15 downto 0);
  signal md_rd        : std_ulogic_vector(15 downto 0);
  signal md_rdy       : std_ulogic;

  signal eth_rst     : std_ulogic;
  signal eth_mdi     : std_ulogic;
  signal eth_mdo     : std_ulogic;
  signal eth_mdoe    : std_ulogic;

begin

  --------------------------------------------------------------------------------
  -- MMCM generates 200MHz, 125MHz and 100MHz from 100MHz reference

  U_MMCM: component mmcm_v2
    generic map (
      mul    => 10.0,
      div    => 1,
      odiv0  => 5.0,
      odiv1  => 8,
      odiv2  => ternary(RGMII_ALIGN = "EDGE", 0, 8),
      odiv3  => 10,
      phase2 => 90.0
    )
    port map (
      rsti  => not btn_rst_n,
      clki  => clki_100m,
      rsto  => rsta,
      clk0  => clk_200m,
      clk1  => clk_125m_0,
      clk2  => clk_125m_90,
      clk3  => clk_100m
    );

  --------------------------------------------------------------------------------
  -- reset

  U_SYNC_RST_100M: component sync_reg_u
    generic map (
      stages    => 3,
      rst_state => '1'
    )
    port map (
      rst  => '0',
      clk  => clk_100m,
      i(0) => rsta,
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
      i(0) => rsta,
      o(0) => rst_125m
    );

  --------------------------------------------------------------------------------
  -- IDELAYCTRL for IDELAYE2 usage in RGMII RX

  U_IDELAYCTRL: component idelayctrl
    port map (
      rst    => rsta,
      refclk => clk_200m,
      rdy    => open
    );

  --------------------------------------------------------------------------------
  -- MicroBlaze V MCS (CPU core)

  U_MCU: component mbv_mcs_wrapper
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

  U_BRIDGE: component mbv_mcs_memac_bridge
    port map (
      rst          => rst_100m,
      clk          => clk_100m,
      io_mosi      => io_mosi,
      io_miso      => io_miso,
      tx_prq_len   => tx_prq_len,
      tx_prq_idx   => tx_prq_idx,
      tx_prq_tag   => tx_prq_tag,
      tx_prq_opt   => tx_prq_opt,
      tx_prq_stb   => tx_prq_stb,
      tx_pfq_len   => tx_pfq_len,
      tx_pfq_idx   => tx_pfq_idx,
      tx_pfq_tag   => tx_pfq_tag,
      tx_pfq_stb   => tx_pfq_stb,
      tx_buf_en    => tx_buf_en,
      tx_buf_bwe   => tx_buf_bwe,
      tx_buf_addr  => tx_buf_addr,
      tx_buf_din   => tx_buf_din,
      tx_buf_dpin  => tx_buf_dpin,
      tx_buf_dout  => tx_buf_dout,
      tx_buf_dpout => tx_buf_dpout,
      rx_prq_len   => rx_prq_len,
      rx_prq_idx   => rx_prq_idx,
      rx_prq_flag  => rx_prq_flag,
      rx_prq_stb   => rx_prq_stb,
      rx_pfq_len   => rx_pfq_len,
      rx_pfq_stb   => rx_pfq_stb,
      rx_buf_en    => rx_buf_en,
      rx_buf_bwe   => rx_buf_bwe,
      rx_buf_addr  => rx_buf_addr,
      rx_buf_din   => rx_buf_din,
      rx_buf_dpin  => rx_buf_dpin,
      rx_buf_dout  => rx_buf_dout,
      rx_buf_dpout => rx_buf_dpout,
      md_stb       => md_stb,
      md_r_w       => md_r_w,
      md_pa        => md_pa,
      md_ra        => md_ra,
      md_wd        => md_wd,
      md_rd        => md_rd
    );

  --------------------------------------------------------------------------------
  -- GPO

  -- reset

  -- LEDs

 -- MDIO preamble enable
  --md_pre <= gpo

  -- TX speed and options
  tx_umi_spd <= gpo(1)(9 downto 8);
  tx_prq_opt(TX_OPT_PRE_LEN_RANGE) <= gpo(1)(13 downto 10);
  tx_prq_opt(TX_OPT_PRE_AUTO_BIT)  <= gpo(1)(14);
  tx_prq_opt(TX_OPT_FCS_AUTO_BIT)  <= gpo(1)(15);


  -- RX options
  rx_umi_spdi                  <= gpo(3)( 1 downto  0);
  rx_opt(RX_OPT_IPG_MIN_RANGE) <= gpo(3)(11 downto  8);
  rx_opt(RX_OPT_PRE_LEN_RANGE) <= gpo(3)(15 downto 12);
  rx_opt(RX_OPT_PRE_INC_BIT)   <= gpo(3)(8);
  rx_opt(RX_OPT_FCS_INC_BIT)   <= gpo(3)(9);
  rx_opt(RX_OPT_CRC_INC_BIT)   <= gpo(3)(10);

  --------------------------------------------------------------------------------
  -- GPI

  -- queue and MDIO status
  gpi(1)(0) <= tx_prq_rdy;
  gpi(1)(1) <= tx_pfq_rdy;
  gpi(1)(2) <= rx_prq_rdy;
  gpi(1)(3) <= rx_pfq_rdy;
  gpi(1)(4) <= md_rdy;

    -- RX detected speed
    gpi(1)(1 downto 0) <= rx_umi_spdo;


  -- RGMII IBS
  gpi(2)(0)          <= rx_ibs_crs;
  gpi(2)(1)          <= rx_ibs_crx;
  gpi(2)(2)          <= rx_ibs_crxer;
  gpi(2)(3)          <= rx_ibs_crf;
  gpi(2)(4)          <= rx_ibs_col;
  gpi(2)(5)          <= rx_ibs_link;
  gpi(2)(7 downto 6) <= rx_ibs_spd;
  gpi(2)(8)          <= rx_ibs_fdx;

  -- RX drop count
  gpi(3) <= rx_drops;

  --------------------------------------------------------------------------------
  -- PHY and UMI reset

  --eth_rst_n <=
  --tx_umi_rst
  --rx_umi_rst

  --------------------------------------------------------------------------------
  -- MEMAC MDIO

  U_MEMAC_MDIO: component memac_mdio
    generic map (
      DIV5M => 20 -- 100 MHz / 20 = 5 MHz
    )
    port map (
      rst  => rst_100m,
      clk  => clk_100m,
      stb  => md_stb,
      pre  => md_pre,
      r_w  => md_r_w,
      pa   => md_pa,
      ra   => md_ra,
      wd   => md_wd,
      rd   => md_rd,
      rdy  => md_rdy,
      mdc  => eth_mdc,
      mdo  => eth_mdo,
      mdoe => eth_mdoe,
      mdi  => eth_mdi
    );

  eth_mdi  <= eth_mdio;
  eth_mdio <= eth_mdo when eth_mdoe = '1' else 'Z';

  --------------------------------------------------------------------------------
  -- MEMAC TX and RX

  U_MEMAC_TX: component memac_tx
    port map (
      sys_rst   => rst_100m,
      sys_clk   => clk_100m,
      prq_rdy   => tx_prq_rdy,
      prq_len   => tx_prq_len,
      prq_idx   => tx_prq_idx,
      prq_tag   => tx_prq_tag,
      prq_opt   => tx_prq_opt,
      prq_stb   => tx_prq_stb,
      pfq_rdy   => tx_pfq_rdy,
      pfq_len   => tx_pfq_len,
      pfq_idx   => tx_pfq_idx,
      pfq_tag   => tx_pfq_tag,
      pfq_stb   => tx_pfq_stb,
      buf_en    => tx_buf_en,
      buf_bwe   => tx_buf_bwe,
      buf_addr  => tx_buf_addr,
      buf_din   => tx_buf_din,
      buf_dpin  => tx_buf_dpin,
      buf_dout  => tx_buf_dout,
      buf_dpout => tx_buf_dpout,
      umi_rst   => tx_umi_rst,
      umi_clk   => tx_umi_clk,
      umi_clken => tx_umi_clken,
      umi_dv    => tx_umi_dv,
      umi_er    => tx_umi_er,
      umi_d     => tx_umi_data
    );

  U_MEMAC_RX: component memac_rx
    port map (
      sys_rst   => rst_100m,
      sys_clk   => clk_100m,
      opt       => rx_opt,
      drops     => rx_drops,
      prq_rdy   => rx_prq_rdy,
      prq_len   => rx_prq_len,
      prq_idx   => rx_prq_idx,
      prq_flag  => rx_prq_flag,
      prq_stb   => rx_prq_stb,
      pfq_rdy   => rx_pfq_rdy,
      pfq_len   => rx_pfq_len,
      pfq_stb   => rx_pfq_stb,
      buf_en    => rx_buf_en,
      buf_bwe   => rx_buf_bwe,
      buf_addr  => rx_buf_addr,
      buf_din   => rx_buf_din,
      buf_dpin  => rx_buf_dpin,
      buf_dout  => rx_buf_dout,
      buf_dpout => rx_buf_dpout,
      umi_rst   => rx_umi_rst,
      umi_clk   => rx_umi_clk,
      umi_clken => rx_umi_clken,
      umi_dv    => rx_umi_dv,
      umi_er    => rx_umi_er,
      umi_data  => rx_umi_data
    );

  --------------------------------------------------------------------------------
  -- RGMII

  U_RGMII_TX: component memac_tx_rgmii
    generic map (
      ALIGN => RGMII_ALIGN
    )
    port map (
      ref_clk    => clk_125m_0,
      ref_clk_90 => clk_125m_90,
      rst        => rst_125m,
      umi_spd    => tx_umi_spd,
      umi_clk    => tx_umi_clk,
      umi_clken  => tx_umi_clken,
      umi_dv     => tx_umi_dv,
      umi_er     => tx_umi_er,
      umi_d      => tx_umi_data,
      rgmii_clk  => rgmii_tx_clk,
      rgmii_ctl  => rgmii_tx_ctl,
      rgmii_d    => rgmii_tx_d
    );

  eth_txck  <= rgmii_tx_clk;
  eth_txctl <= rgmii_tx_ctl;
  eth_txd   <= rgmii_tx_d;

  U_RGMII_RX: component memac_rx_rgmii
    port map (
      ref_rst   => rst_125m,
      ref_clk   => clk_125m_0,
      umi_spdi  => rx_umi_spdi,
      umi_spdo  => rx_umi_spdo,
      umi_rst   => rx_umi_rst,
      umi_clk   => rx_umi_clk,
      umi_clken => rx_umi_clken,
      umi_dv    => rx_umi_dv,
      umi_er    => rx_umi_er,
      umi_d     => rx_umi_data,
      ibs_crs   => rx_ibs_crs,
      ibs_crx   => rx_ibs_crx,
      ibs_crxer => rx_ibs_crxer,
      ibs_crf   => rx_ibs_crf,
      ibs_link  => rx_ibs_link,
      ibs_spd   => rx_ibs_spd,
      ibs_fdx   => rx_ibs_fdx,
      rgmii_clk => rgmii_rx_clk,
      rgmii_ctl => rgmii_rx_ctl,
      rgmii_d   => rgmii_rx_d
    );

  U_RGMII_RX_IO: component memac_rx_rgmii_io
    generic map (
      ALIGN => RGMII_ALIGN
    )
    port map (
      i_clk   => eth_rxck,
      i_ctl   => eth_rxctl,
      i_d     => eth_rxd,
      o_clkr  => rx_umi_clk,
      o_clkio => rgmii_rx_clk,
      o_ctl   => rgmii_rx_ctl,
      o_d     => rgmii_rx_d
    );

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
