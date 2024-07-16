--------------------------------------------------------------------------------
-- mega65_r4.vhd                                                              --
-- Top level entity for MEGA65 rev 4.                                         --
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

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity mega65_r4 is
  port (

    clk_in           : in    std_ulogic;                      -- clock in (100MHz)

    rst              : in    std_ulogic;                      -- reset button

    uled             : out   std_ulogic;                      -- LED D9 "ULED"
    led_g_n          : out   std_ulogic;                      -- LED D10 (green)
    led_r_n          : out   std_ulogic;                      -- LED D12 (red)

    uart_tx          : out   std_ulogic;                      -- debug UART
    uart_rx          : in    std_ulogic;

    qspi_cs_n        : out   std_ulogic;                      -- QSPI flash
    qspi_d           : inout std_ulogic_vector(3 downto 0);

    sdi_cd_n         : inout std_ulogic;                      -- internal SD/MMC card
    sdi_wp_n         : in    std_ulogic;
    sdi_ss_n         : out   std_ulogic;
    sdi_clk          : out   std_ulogic;
    sdi_mosi         : out   std_ulogic;
    sdi_miso         : inout std_ulogic;
    sdi_d1           : inout std_ulogic;
    sdi_d2           : inout std_ulogic;

    sdx_cd_n         : inout std_ulogic;                      -- external micro SD card
    sdx_ss_n         : out   std_ulogic;
    sdx_clk          : out   std_ulogic;
    sdx_mosi         : out   std_ulogic;
    sdx_miso         : inout std_ulogic;
    sdx_d1           : inout std_ulogic;
    sdx_d2           : inout std_ulogic;

    i2c_scl          : inout std_ulogic;                      -- on-board I2C bus
    i2c_sda          : inout std_ulogic;

    grove_scl        : inout std_ulogic;                      -- Grove connector
    grove_sda        : inout std_ulogic;

    dipsw            : in    std_ulogic_vector(3 downto 0);   -- DIP switch

    rev              : in    std_ulogic_vector(3 downto 0);   -- board revision

    kb_io0           : out   std_ulogic;                      -- keyboard
    kb_io1           : out   std_ulogic;
    kb_io2           : in    std_ulogic;
    kb_jtagen        : out   std_ulogic;
    kb_tck           : out   std_ulogic;
    kb_tms           : out   std_ulogic;
    kb_tdi           : out   std_ulogic;
    kb_tdo           : in    std_ulogic;

    js_pd            : out   std_ulogic;                      -- joysticks/paddles
    js_pg            : in    std_ulogic;
    jsai_up_n        : in    std_ulogic;
    jsai_down_n      : in    std_ulogic;
    jsai_left_n      : in    std_ulogic;
    jsai_right_n     : in    std_ulogic;
    jsai_fire_n      : in    std_ulogic;
    jsbi_up_n        : in    std_ulogic;
    jsbi_down_n      : in    std_ulogic;
    jsbi_left_n      : in    std_ulogic;
    jsbi_right_n     : in    std_ulogic;
    jsbi_fire_n      : in    std_ulogic;
    jsao_up_n        : out   std_ulogic;
    jsao_down_n      : out   std_ulogic;
    jsao_left_n      : out   std_ulogic;
    jsao_right_n     : out   std_ulogic;
    jsao_fire_n      : out   std_ulogic;
    jsbo_up_n        : out   std_ulogic;
    jsbo_down_n      : out   std_ulogic;
    jsbo_left_n      : out   std_ulogic;
    jsbo_right_n     : out   std_ulogic;
    jsbo_fire_n      : out   std_ulogic;

    paddle           : in    std_ulogic_vector(3 downto 0);
    paddle_drain     : out   std_ulogic;

    audio_pd_n       : out   std_ulogic;                      -- audio codec
    audio_mclk       : out   std_ulogic;
    audio_bclk       : out   std_ulogic;
    audio_lrclk      : out   std_ulogic;
    audio_sdata      : out   std_ulogic;
    audio_smute      : out   std_ulogic;
    audio_i2c_scl    : inout std_ulogic;
    audio_i2c_sda    : inout std_ulogic;

    hdmi_clk_p       : out   std_ulogic;                      -- HDMI out
    hdmi_clk_n       : out   std_ulogic;
    hdmi_data_p      : out   std_ulogic_vector(0 to 2);
    hdmi_data_n      : out   std_ulogic_vector(0 to 2);
    hdmi_hiz_en      : out   std_ulogic;
    hdmi_hpd         : inout std_ulogic;
    hdmi_ls_oe_n     : out   std_ulogic;
    hdmi_scl         : inout std_ulogic;
    hdmi_sda         : inout std_ulogic;

    vga_psave_n      : out   std_ulogic;                      -- VGA out
    vga_clk          : out   std_ulogic;
    vga_vsync        : out   std_ulogic;
    vga_hsync        : out   std_ulogic;
    vga_sync_n       : out   std_ulogic;
    vga_blank_n      : out   std_ulogic;
    vga_r            : out   std_ulogic_vector (7 downto 0);
    vga_g            : out   std_ulogic_vector (7 downto 0);
    vga_b            : out   std_ulogic_vector (7 downto 0);
    vga_scl          : inout std_ulogic;
    vga_sda          : inout std_ulogic;

    fdd_chg_n        : in    std_ulogic;                      -- FDD
    fdd_wp_n         : in    std_ulogic;
    fdd_den          : out   std_ulogic;
    fdd_sela         : out   std_ulogic;
    fdd_selb         : out   std_ulogic;
    fdd_mota_n       : out   std_ulogic;
    fdd_motb_n       : out   std_ulogic;
    fdd_side_n       : out   std_ulogic;
    fdd_dir_n        : out   std_ulogic;
    fdd_step_n       : out   std_ulogic;
    fdd_trk0_n       : in    std_ulogic;
    fdd_idx_n        : in    std_ulogic;
    fdd_wgate_n      : out   std_ulogic;
    fdd_wdata        : out   std_ulogic;
    fdd_rdata        : in    std_ulogic;

    iec_rst_n        : out   std_ulogic;                      -- CBM-488/IEC serial port
    iec_atn_n        : out   std_ulogic;
    iec_srq_n_en_n   : out   std_ulogic;
    iec_srq_n_o      : out   std_ulogic;
    iec_srq_n_i      : in    std_ulogic;
    iec_clk_en_n     : out   std_ulogic;
    iec_clk_o        : out   std_ulogic;
    iec_clk_i        : in    std_ulogic;
    iec_data_en_n    : out   std_ulogic;
    iec_data_o       : out   std_ulogic;
    iec_data_i       : in    std_ulogic;

    eth_rst_n        : out   std_ulogic;                      -- ethernet PHY (RMII)
    eth_clk          : out   std_ulogic;
    eth_txen         : out   std_ulogic;
    eth_txd          : out   std_ulogic_vector(1 downto 0);
    eth_rxdv         : in    std_ulogic;
    eth_rxer         : in    std_ulogic;
    eth_rxd          : in    std_ulogic_vector(1 downto 0);
    eth_mdc          : out   std_ulogic;
    eth_mdio         : inout std_ulogic;
    eth_led_n        : inout std_ulogic;

    cart_dotclk      : out   std_ulogic;                      -- C64 cartridge
    cart_phi2        : out   std_ulogic;
    cart_rst_n       : out   std_ulogic;
    cart_dma_n       : in    std_ulogic;
    cart_nmi_n       : in    std_ulogic;
    cart_irq_n       : in    std_ulogic;
    cart_ba          : inout std_ulogic;
    cart_r_w         : inout std_ulogic;
    cart_exrom_n     : in    std_ulogic;
    cart_game_n      : in    std_ulogic;
    cart_io1_n       : inout std_ulogic;
    cart_io2_n       : inout std_ulogic;
    cart_roml_n      : inout std_ulogic;
    cart_romh_n      : inout std_ulogic;
    cart_a           : inout std_ulogic_vector(15 downto 0);
    cart_d           : inout std_ulogic_vector(7 downto 0);

    cart_ctrl_oe_n   : out   std_ulogic;                      -- C64 cartridge ctrl
    cart_ctrl_dir    : out   std_ulogic;
    cart_addr_oe_n   : out   std_ulogic;
    cart_laddr_dir   : out   std_ulogic;
    cart_haddr_dir   : out   std_ulogic;
    cart_data_oe_n   : out   std_ulogic;
    cart_data_dir    : out   std_ulogic;

    hr_rst_n         : out   std_ulogic;                      -- HyperRAM
    hr_clk_p         : out   std_ulogic;
    hr_cs_n          : out   std_ulogic;
    hr_rwds          : inout std_ulogic;
    hr_d             : inout std_ulogic_vector(7 downto 0);

    sdram_clk        : out   std_ulogic;                      -- SDRAM
    sdram_cke        : out   std_ulogic;
    sdram_cs_n       : out   std_ulogic;
    sdram_ras_n      : out   std_ulogic;
    sdram_cas_n      : out   std_ulogic;
    sdram_we_n       : out   std_ulogic;
    sdram_dqml       : out   std_ulogic;
    sdram_dqmh       : out   std_ulogic;
    sdram_ba         : out   std_ulogic_vector(1 downto 0);
    sdram_a          : out   std_ulogic_vector(12 downto 0);
    sdram_dq         : inout std_ulogic_vector(15 downto 0);

    pmod1en          : out   std_ulogic;                      -- PMODs
    pmod1flg         : in    std_ulogic;
    pmod1lo          : inout std_ulogic_vector(3 downto 0);
    pmod1hi          : inout std_ulogic_vector(3 downto 0);
    pmod2en          : out   std_ulogic;
    pmod2flg         : in    std_ulogic;
    pmod2lo          : inout std_ulogic_vector(3 downto 0);
    pmod2hi          : inout std_ulogic_vector(3 downto 0);

    dbg              : inout std_ulogic_vector(10 to 11)      -- debug header

  );
end entity mega65_r4;

architecture rtl of mega65_r4 is

  signal hdmi_clk  : std_ulogic;
  signal hdmi_data : std_ulogic_vector(0 to 2);

begin

  -- safe states for unused I/Os

  uled           <= '0';
  led_g_n        <= '1';
  led_r_n        <= '1';
  uart_tx        <= '1';
  qspi_cs_n      <= '1';
  qspi_d         <= (others => '1');
  sdi_cd_n       <= 'Z';
  sdi_ss_n       <= '1';
  sdi_clk        <= '0';
  sdi_mosi       <= '0';
  sdi_miso       <= 'Z';
  sdi_d1         <= 'Z';
  sdi_d2         <= 'Z';
  sdx_cd_n       <= 'Z';
  sdx_ss_n       <= '1';
  sdx_clk        <= '0';
  sdx_mosi       <= '0';
  sdx_miso       <= 'Z';
  sdx_d1         <= 'Z';
  sdx_d2         <= 'Z';
  i2c_sda        <= 'Z';
  i2c_scl        <= 'Z';
  grove_sda      <= 'Z';
  grove_scl      <= 'Z';
  kb_io0         <= '0';
  kb_io1         <= '0';
  kb_jtagen      <= '0';
  kb_tck         <= '0';
  kb_tms         <= '1';
  kb_tdi         <= '0';
  js_pd           <= '1';
  jsao_up_n       <= '1';
  jsao_down_n     <= '1';
  jsao_left_n     <= '1';
  jsao_right_n    <= '1';
  jsao_fire_n     <= '1';
  jsbo_up_n       <= '1';
  jsbo_down_n     <= '1';
  jsbo_left_n     <= '1';
  jsbo_right_n    <= '1';
  jsbo_fire_n     <= '1';
  paddle_drain   <= '0';
  audio_pd_n     <= '0';
  audio_mclk     <= '0';
  audio_bclk     <= '0';
  audio_lrclk    <= '0';
  audio_sdata    <= '0';
  audio_smute    <= '1';
  audio_i2c_scl  <= 'Z';
  audio_i2c_sda  <= 'Z';
  hdmi_clk       <= '0';
  hdmi_data      <= (others => '0');
  hdmi_hiz_en    <= '1';
  hdmi_hpd       <= 'Z';
  hdmi_ls_oe_n   <= '1';
  hdmi_scl       <= 'Z';
  hdmi_sda       <= 'Z';
  vga_psave_n    <= '0';
  vga_clk        <= '0';
  vga_vsync      <= '0';
  vga_hsync      <= '0';
  vga_sync_n     <= '1';
  vga_blank_n    <= '1';
  vga_r          <= (others => '0');
  vga_g          <= (others => '0');
  vga_b          <= (others => '0');
  vga_scl        <= 'Z';
  vga_sda        <= 'Z';
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
  sdram_clk      <= '0';
  sdram_cke      <= '0';
  sdram_cs_n     <= '1';
  sdram_ras_n    <= '1';
  sdram_cas_n    <= '1';
  sdram_we_n     <= '1';
  sdram_dqml     <= '1';
  sdram_dqmh     <= '1';
  sdram_ba       <= (others => '0');
  sdram_a        <= (others => '0');
  sdram_dq       <= (others => '0');
  pmod1en        <= '0';
  pmod1lo        <= (others => 'Z');
  pmod1hi        <= (others => 'Z');
  pmod2en        <= '0';
  pmod2lo        <= (others => 'Z');
  pmod2hi        <= (others => 'Z');
  dbg            <= (others => 'Z');

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

end architecture rtl;
