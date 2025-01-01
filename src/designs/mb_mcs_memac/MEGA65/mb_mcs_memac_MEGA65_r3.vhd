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
use work.memac_raw_rmii_pkg.all;

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

    clk_in           : in    std_logic;                      -- clock in (100MHz)

    max10_clk        : out   std_ulogic;                     -- MAX10 CPLD
--  max10_tx         : in    std_ulogic;
    max10_rx         : out   std_ulogic;

    uled             : out   std_logic;                      -- LED D9 "ULED"

    uart_tx          : out   std_logic;                      -- debug UART
--  uart_rx          : in    std_logic;

    qspi_cs_n        : out   std_logic;                      -- QSPI flash
--  qspi_d           : inout std_logic_vector(3 downto 0);

--  sdi_cd_n         : inout std_logic;                      -- internal SD/MMC card
--  sdi_wp_n         : in    std_logic;
    sdi_ss_n         : out   std_logic;
    sdi_clk          : out   std_logic;
    sdi_mosi         : out   std_logic;
--  sdi_miso         : inout std_logic;
--  sdi_d1           : inout std_logic;
--  sdi_d2           : inout std_logic;

--  sdx_cd_n         : inout std_logic;                      -- external micro SD card
    sdx_ss_n         : out   std_logic;
    sdx_clk          : out   std_logic;
    sdx_mosi         : out   std_logic;
--  sdx_miso         : inout std_logic;
--  sdx_d1           : inout std_logic;
--  sdx_d2           : inout std_logic;

--  i2c_scl          : inout std_logic;                      -- on-board I2C bus
--  i2c_sda          : inout std_logic;

--  grove_scl        : inout std_logic;                      -- Grove connector
--  grove_sda        : inout std_logic;

    kb_io0           : out   std_logic;                      -- keyboard
    kb_io1           : out   std_logic;
--  kb_io2           : in    std_logic;
    kb_jtagen        : out   std_logic;
    kb_tck           : out   std_logic;
    kb_tms           : out   std_logic;
    kb_tdi           : out   std_logic;
--  kb_tdo           : in    std_logic;

--  jsa_up_n         : in    std_logic;                      -- joysticks/paddles
--  jsa_down_n       : in    std_logic;
--  jsa_left_n       : in    std_logic;
--  jsa_right_n      : in    std_logic;
--  jsa_fire_n       : in    std_logic;
--  jsb_up_n         : in    std_logic;
--  jsb_down_n       : in    std_logic;
--  jsb_left_n       : in    std_logic;
--  jsb_right_n      : in    std_logic;
--  jsb_fire_n       : in    std_logic;
--  paddle           : in    std_logic_vector(3 downto 0);
    paddle_drain     : out   std_logic;

    audio_pd_n       : out   std_logic;                      -- audio codec
    audio_mclk       : out   std_logic;
    audio_bclk       : out   std_logic;
    audio_lrclk      : out   std_logic;
    audio_sdata      : out   std_logic;
    audio_pwm_l      : out   std_logic;
    audio_pwm_r      : out   std_logic;

    hdmi_clk_p       : out   std_logic;                      -- HDMI out
    hdmi_clk_n       : out   std_logic;
    hdmi_data_p      : out   std_logic_vector(0 to 2);
    hdmi_data_n      : out   std_logic_vector(0 to 2);
    hdmi_ct_hpd      : out   std_ulogic;
--  hdmi_hpd         : inout std_ulogic;
    hdmi_ls_oe       : out   std_ulogic;
--  hdmi_scl         : inout std_ulogic;
--  hdmi_sda         : inout std_ulogic;
--  hdmi_cec         : inout std_ulogic;

    vga_clk          : out   std_logic;                      -- VGA out
    vga_vsync        : out   std_logic;
    vga_hsync        : out   std_logic;
    vga_sync_n       : out   std_logic;
    vga_blank_n      : out   std_logic;
    vga_r            : out   std_logic_vector (7 downto 0);
    vga_g            : out   std_logic_vector (7 downto 0);
    vga_b            : out   std_logic_vector (7 downto 0);
--  vga_scl          : inout std_logic;
--  vga_sda          : inout std_logic;

--  fdd_chg_n        : in    std_logic;                      -- FDD
--  fdd_wp_n         : in    std_logic;
    fdd_den          : out   std_logic;
    fdd_sela         : out   std_logic;
    fdd_selb         : out   std_logic;
    fdd_mota_n       : out   std_logic;
    fdd_motb_n       : out   std_logic;
    fdd_side_n       : out   std_logic;
    fdd_dir_n        : out   std_logic;
    fdd_step_n       : out   std_logic;
--  fdd_trk0_n       : in    std_logic;
--  fdd_idx_n        : in    std_logic;
    fdd_wgate_n      : out   std_logic;
    fdd_wdata        : out   std_logic;
--  fdd_rdata        : in    std_logic;

    iec_rst_n        : out   std_logic;                      -- CBM-488/IEC serial port
    iec_atn_n        : out   std_logic;
    iec_srq_n_en_n   : out   std_logic;
    iec_srq_n_o      : out   std_logic;
--  iec_srq_n_i      : in    std_logic;
    iec_clk_en_n     : out   std_logic;
    iec_clk_o        : out   std_logic;
--  iec_clk_i        : in    std_logic;
    iec_data_en_n    : out   std_logic;
    iec_data_o       : out   std_logic;
--  iec_data_i       : in    std_logic;

    eth_rst_n        : out   std_logic;                      -- ethernet PHY (RMII)
    eth_clk          : out   std_logic;
    eth_txen         : out   std_logic;
    eth_txd          : out   std_logic_vector(1 downto 0);
    eth_rxdv         : in    std_logic;
    eth_rxer         : in    std_logic;
    eth_rxd          : in    std_logic_vector(1 downto 0);
    eth_mdc          : out   std_logic;
    eth_mdio         : inout std_logic;
    eth_led_n        : inout std_logic;

    cart_dotclk      : out   std_logic;                      -- C64 cartridge
    cart_phi2        : out   std_logic;
    cart_rst_n       : out   std_logic;
--  cart_dma_n       : in    std_logic;
--  cart_nmi_n       : in    std_logic;
--  cart_irq_n       : in    std_logic;
    cart_ba          : inout std_logic;
    cart_r_w         : inout std_logic;
--  cart_exrom_n     : in    std_logic;
--  cart_game_n      : in    std_logic;
    cart_io1_n       : inout std_logic;
    cart_io2_n       : inout std_logic;
    cart_roml_n      : inout std_logic;
    cart_romh_n      : inout std_logic;
    cart_a           : inout std_logic_vector(15 downto 0);
    cart_d           : inout std_logic_vector(7 downto 0);

    cart_ctrl_oe_n   : out   std_ulogic;                     -- C64 cartridge ctrl
    cart_ctrl_dir    : out   std_ulogic;
    cart_addr_oe_n   : out   std_ulogic;
    cart_laddr_dir   : out   std_ulogic;
    cart_haddr_dir   : out   std_ulogic;
    cart_data_oe_n   : out   std_ulogic;
    cart_data_dir    : out   std_ulogic;

    hr_rst_n         : out   std_logic;                      -- HyperRAM
    hr_clk_p         : out   std_logic;
    hr_cs_n          : out   std_logic;
    hr_rwds          : inout std_logic;
    hr_d             : inout std_logic_vector(7 downto 0);

    pmod1lo          : inout std_logic_vector(3 downto 0);   -- PMODs
    pmod1hi          : inout std_logic_vector(3 downto 0);
    pmod2lo          : inout std_logic_vector(3 downto 0);
    pmod2hi          : inout std_logic_vector(3 downto 0);

    tp               : inout std_ulogic_vector(1 to 8)       -- testpoints

  );
end entity mb_mcs_memac_digilent_nexys_video;

architecture rtl of mb_mcs_memac_digilent_nexys_video is

  --------------------------------------------------------------------------------

  constant TX_BUF_SIZE_LOG2 : integer := log2(TX_BUF_SIZE);
  constant RX_BUF_SIZE_LOG2 : integer := log2(RX_BUF_SIZE);
  constant MTU              : integer := 1522;
  constant LEN_MAX_LOG2     : integer := log2(MTU); -- should equal 11

  --------------------------------------------------------------------------------

  signal rst_count        : integer range 0 to 15 := 0;
  signal rst              : std_ulogic;

  signal clk_100m         : std_logic;
  signal clk_50m          : std_ulogic;

  signal rst_a            : std_ulogic; -- asynchronous reset from MMCM
  signal rst_100m         : std_ulogic; -- clk_100m synchronous reset
  signal rst_50m          : std_ulogic; -- clk_50m synchronous reset

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
  signal mac_tx_spd       : std_ulogic_vector(1 downto 0);
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
  signal mac_rx_spdi      : std_ulogic_vector(1 downto 0);
  signal mac_rx_spdo      : std_ulogic_vector(1 downto 0);
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
  signal eth_clk_i        : std_ulogic;

  signal hdmi_clk         : std_logic;
  signal hdmi_data        : std_logic_vector(0 to 2);

  --------------------------------------------------------------------------------

  attribute KEEP_HIERARCHY : string;
  attribute KEEP_HIERARCHY of mb_mcs_memac_digilent_nexys_video : entity is "TRUE";

  --------------------------------------------------------------------------------

begin

  --------------------------------------------------------------------------------
  -- power on reset

  P_RST: process(clk_in)
  begin
    if rising_edge(clk_in) then
      if rst_count < 15 then
        rst_count <= rst_count + 1;
      end if;
    end if;
  end process P_RST;
  rst <= '0' when rst_count = 15 else '1';

  --------------------------------------------------------------------------------
  -- MMCM generates 100MHz and 50MHz from 100MHz reference

  U_MMCM: component mmcm_v2
    generic map (
      mul    => 10.0,
      div    => 1,
      odiv0  => 10.0,
      odiv1  => 20
    )
    port map (
      rsti  => rst,
      clki  => clk_in,
      rsto  => rst_a,
      clk0  => clk_100m,
      clk1  => clk_50m,
      clk2  => open,
      clk3  => open,
      clk4  => open,
      clk5  => open,
      clk6  => open
    );

  U_SYNC_RST_100M: component sync_reg_u
    generic map (
      STAGES    => 3,
      RST_STATE => '1'
    )
    port map (
      rst  => '0',
      clk  => clk_100m,
      i(0) => rst_a,
      o(0) => rst_100m
    );

  U_SYNC_RST_50M: component sync_reg_u
    generic map (
      STAGES    => 3,
      RST_STATE => '1'
    )
    port map (
      rst  => '0',
      clk  => clk_50m,
      i(0) => rst_a,
      o(0) => rst_50m
    );

  --------------------------------------------------------------------------------
  -- MicroBlaze V MCS (CPU core)

  U_MCU: component mb_mcs_wrapper
    port map (
      rst      => rst_100m,
      clk      => clk_100m,
      uart_tx  => open,
      uart_rx  => '1',
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
      md_stb       => mac_md_stb,
      md_r_w       => mac_md_r_w,
      md_pa        => mac_md_pa,
      md_ra        => mac_md_ra,
      md_wd        => mac_md_wd,
      md_rd        => mac_md_rd,
      md_rdy       => mac_md_rdy,
      tx_prq_rdy   => mac_tx_prq_rdy,
      tx_prq_len   => mac_tx_prq_len,
      tx_prq_idx   => mac_tx_prq_idx,
      tx_prq_tag   => mac_tx_prq_tag,
      tx_prq_opt   => mac_tx_prq_opt,
      tx_prq_stb   => mac_tx_prq_stb,
      tx_pfq_rdy   => mac_tx_pfq_rdy,
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
      rx_prq_rdy   => mac_rx_prq_rdy,
      rx_prq_len   => mac_rx_prq_len,
      rx_prq_idx   => mac_rx_prq_idx,
      rx_prq_flag  => mac_rx_prq_flag,
      rx_prq_stb   => mac_rx_prq_stb,
      rx_pfq_rdy   => mac_rx_pfq_rdy,
      rx_pfq_len   => mac_rx_pfq_len,
      rx_pfq_stb   => mac_rx_pfq_stb,
      rx_buf_en    => mac_rx_buf_en,
      rx_buf_bwe   => mac_rx_buf_bwe,
      rx_buf_addr  => mac_rx_buf_addr,
      rx_buf_din   => mac_rx_buf_din,
      rx_buf_dpin  => mac_rx_buf_dpin,
      rx_buf_dout  => mac_rx_buf_dout,
      rx_buf_dpout => mac_rx_buf_dpout
    );

  --------------------------------------------------------------------------------
  -- integrated MEMAC with raw system interface and RGMII phy interface

  U_MAC: component memac_raw_rmii
    generic map (
      F_SYS_CLK  => 100.0,
      MDIO_DIV5M => 20
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
      sys_tx_spd       => mac_tx_spd,
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
      sys_rx_spdi      => mac_rx_spdi,
      sys_rx_spdo      => mac_rx_spdo,
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
      phy_mdc          => eth_mdc,
      phy_mdo          => eth_mdo,
      phy_mdoe         => eth_mdoe,
      phy_mdi          => eth_mdi,
      phy_rmii_clk     => eth_clk_i,
      phy_rmii_tx_en   => eth_txen,
      phy_rmii_tx_d    => eth_txd,
      phy_rmii_rx_dv   => eth_rxdv,
      phy_rmii_rx_er   => eth_rxer,
      phy_rmii_rx_d    => eth_rxd
    );

  eth_rst_n <= not eth_rst;
  eth_mdi   <= eth_mdio;
  eth_mdio  <= eth_mdo when eth_mdoe = '1' else 'Z';

  U_ETH_CLK: component iobuf
    port map (
      i  => clk_50m,
      o  => eth_clk_i,
      io => eth_clk,
      t  => '0'
    );

  --------------------------------------------------------------------------------
  -- GPO

  eth_rst             <= rst_a or not gpo(1)(0);
  mac_tx_rst          <= rst_a or not gpo(1)(1);
  mac_rx_rst          <= rst_a or not gpo(1)(2);
  mac_md_pre          <= gpo(1)(           3);
  mac_tx_spd          <= gpo(1)( 5 downto  4);
  mac_rx_spdi         <= gpo(1)( 7 downto  6);
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
  gpi(1)( 6 downto  5) <= mac_rx_spdo;
  gpi(1)(           7) <= mac_rx_stat.ibs_crs;
  gpi(1)(           8) <= mac_rx_stat.ibs_crx;
  gpi(1)(           9) <= mac_rx_stat.ibs_crxer;
  gpi(1)(          10) <= mac_rx_stat.ibs_crf;
  gpi(1)(          11) <= mac_rx_stat.ibs_link;
  gpi(1)(13 downto 12) <= mac_rx_stat.ibs_spd;
  gpi(1)(          14) <= mac_rx_stat.ibs_fdx;

  gpi(2) <= mac_rx_stat.drops;

  --------------------------------------------------------------------------------
  -- safe states for unused I/Os

  max10_clk      <= '0';
  max10_rx       <= '0';
  uled           <= '0';
  uart_tx        <= '1';
  qspi_cs_n      <= '1';
  qspi_d         <= (others => '1');
  sdi_ss_n       <= '1';
  sdi_clk        <= '0';
  sdi_mosi       <= '0';
  sdx_ss_n       <= '1';
  sdx_clk        <= '0';
  sdx_mosi       <= '0';
  kb_io0         <= '0';
  kb_io1         <= '0';
  kb_jtagen      <= '0';
  kb_tck         <= '0';
  kb_tms         <= '1';
  kb_tdi         <= '0';
  paddle_drain   <= '0';
  audio_pd_n     <= '0';
  audio_mclk     <= '0';
  audio_bclk     <= '0';
  audio_lrclk    <= '0';
  audio_sdata    <= '0';
  audio_pwm_l    <= '0';
  audio_pwm_r    <= '0';
  hdmi_clk       <= '0';
  hdmi_data      <= (others => '0');
  hdmi_ct_hpd    <= '0';
  hdmi_ls_oe     <= '0';
  vga_clk        <= '0';
  vga_vsync      <= '0';
  vga_hsync      <= '0';
  vga_sync_n     <= '1';
  vga_blank_n    <= '1';
  vga_r          <= (others => '0');
  vga_g          <= (others => '0');
  vga_b          <= (others => '0');
  fdd_den        <= '0';
  fdd_sela       <= '0';
  fdd_selb       <= '0';
  fdd_mota_n     <= '1';
  fdd_motb_n     <= '1';
  fdd_side_n     <= '1';
  fdd_dir_n      <= '1';
  fdd_step_n     <= '1';
  fdd_wgate_n    <= '1';
  fdd_wdata      <= '1';
  iec_rst_n      <= '0';
  iec_atn_n      <= '1';
  iec_srq_n_en_n <= '1';
  iec_srq_n_o    <= '1';
  iec_clk_en_n   <= '1';
  iec_clk_o      <= '1';
  iec_data_en_n  <= '1';
  iec_data_o     <= '1';
  eth_rst_n      <= '0';
  eth_clk        <= '0';
  eth_txen       <= '0';
  eth_txd        <= (others => '0');
  eth_mdc        <= '0';
  eth_mdio       <= 'Z';
  eth_led_n      <= '1';
  cart_dotclk    <= '0';
  cart_phi2      <= '0';
  cart_rst_n     <= '0';
  cart_ba        <= 'Z'; -- pullup
  cart_r_w       <= 'Z'; -- pullup
  cart_io1_n     <= 'Z'; -- pullup
  cart_io2_n     <= 'Z'; -- pullup
  cart_roml_n    <= 'Z'; -- pullup
  cart_romh_n    <= 'Z'; -- pullup
  cart_a         <= (others => 'Z'); -- pullup
  cart_d         <= (others => 'Z'); -- pullup
  cart_ctrl_oe_n <= '1';
  cart_ctrl_dir  <= '1';
  cart_addr_oe_n <= '1';
  cart_laddr_dir <= '1';
  cart_haddr_dir <= '1';
  cart_data_oe_n <= '1';
  cart_data_dir  <= '1';
  hr_rst_n       <= '0';
  hr_clk_p       <= '0';
  hr_cs_n        <= '1';
  hr_rwds        <= '0';
  hr_d           <= (others => '0');
  pmod1lo        <= (others => 'Z');
  pmod1hi        <= (others => 'Z');
  pmod2lo        <= (others => 'Z');
  pmod2hi        <= (others => 'Z');
  tp             <= (others => 'Z');

  U_HDMI_BUF_CLK: component OBUFDS
    port map (
      i  => hdmi_clk,
      o  => hdmi_clk_p,
      ob => hdmi_clk_n
    );

  GEN: for i in 0 to 2 generate

    U_HDMI_BUF_DATA: component OBUFDS
      port map (
        i  => hdmi_data(i),
        o  => hdmi_data_p(i),
        ob => hdmi_data_n(i)
      );

  end generate GEN;

  --------------------------------------------------------------------------------

end architecture rtl;
