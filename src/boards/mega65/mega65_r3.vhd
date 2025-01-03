--------------------------------------------------------------------------------
-- mega65_r3.vhd                                                              --
-- Top level entity for MEGA65 rev 3.                                         --
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

entity mega65_r3 is
  port (

    clk_in           : in    std_logic;                      -- clock in (100MHz)

    max10_clk        : inout std_ulogic;                      -- MAX10 CPLD
    max10_tx         : in    std_ulogic;
    max10_rx         : out   std_ulogic;

    uled             : out   std_logic;                      -- LED D9 "ULED"

    uart_tx          : out   std_logic;                      -- debug UART
    uart_rx          : in    std_logic;

    qspi_cs_n        : out   std_logic;                      -- QSPI flash
    qspi_d           : inout std_logic_vector(3 downto 0);

    sdi_cd_n         : inout std_logic;                      -- internal SD/MMC card
    sdi_wp_n         : in    std_logic;
    sdi_ss_n         : out   std_logic;
    sdi_clk          : out   std_logic;
    sdi_mosi         : out   std_logic;
    sdi_miso         : inout std_logic;
    sdi_d1           : inout std_logic;
    sdi_d2           : inout std_logic;

    sdx_cd_n         : inout std_logic;                      -- external micro SD card
    sdx_ss_n         : out   std_logic;
    sdx_clk          : out   std_logic;
    sdx_mosi         : out   std_logic;
    sdx_miso         : inout std_logic;
    sdx_d1           : inout std_logic;
    sdx_d2           : inout std_logic;

    i2c_scl          : inout std_logic;                      -- on-board I2C bus
    i2c_sda          : inout std_logic;

    grove_scl        : inout std_logic;                      -- Grove connector
    grove_sda        : inout std_logic;

    kb_io0           : out   std_logic;                      -- keyboard
    kb_io1           : out   std_logic;
    kb_io2           : in    std_logic;
    kb_jtagen        : out   std_logic;
    kb_tck           : out   std_logic;
    kb_tms           : out   std_logic;
    kb_tdi           : out   std_logic;
    kb_tdo           : in    std_logic;

    jsa_up_n         : in    std_logic;                      -- joysticks/paddles
    jsa_down_n       : in    std_logic;
    jsa_left_n       : in    std_logic;
    jsa_right_n      : in    std_logic;
    jsa_fire_n       : in    std_logic;
    jsb_up_n         : in    std_logic;
    jsb_down_n       : in    std_logic;
    jsb_left_n       : in    std_logic;
    jsb_right_n      : in    std_logic;
    jsb_fire_n       : in    std_logic;
    paddle           : in    std_logic_vector(3 downto 0);
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
    hdmi_hpd         : inout std_ulogic;
    hdmi_ls_oe       : out   std_ulogic;
    hdmi_scl         : inout std_ulogic;
    hdmi_sda         : inout std_ulogic;
    hdmi_cec         : inout std_ulogic;

    vga_clk          : out   std_logic;                      -- VGA out
    vga_vsync        : out   std_logic;
    vga_hsync        : out   std_logic;
    vga_sync_n       : out   std_logic;
    vga_blank_n      : out   std_logic;
    vga_r            : out   std_logic_vector (7 downto 0);
    vga_g            : out   std_logic_vector (7 downto 0);
    vga_b            : out   std_logic_vector (7 downto 0);
    vga_scl          : inout std_logic;
    vga_sda          : inout std_logic;

    fdd_chg_n        : in    std_logic;                      -- FDD
    fdd_wp_n         : in    std_logic;
    fdd_den          : out   std_logic;
    fdd_sela         : out   std_logic;
    fdd_selb         : out   std_logic;
    fdd_mota_n       : out   std_logic;
    fdd_motb_n       : out   std_logic;
    fdd_side_n       : out   std_logic;
    fdd_dir_n        : out   std_logic;
    fdd_step_n       : out   std_logic;
    fdd_trk0_n       : in    std_logic;
    fdd_idx_n        : in    std_logic;
    fdd_wgate_n      : out   std_logic;
    fdd_wdata        : out   std_logic;
    fdd_rdata        : in    std_logic;

    iec_rst_n        : out   std_logic;                      -- CBM-488/IEC serial port
    iec_atn_n        : out   std_logic;
    iec_srq_n_en_n   : out   std_logic;
    iec_srq_n_o      : out   std_logic;
    iec_srq_n_i      : in    std_logic;
    iec_clk_en_n     : out   std_logic;
    iec_clk_o        : out   std_logic;
    iec_clk_i        : in    std_logic;
    iec_data_en_n    : out   std_logic;
    iec_data_o       : out   std_logic;
    iec_data_i       : in    std_logic;

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
    cart_dma_n       : in    std_logic;
    cart_nmi_n       : in    std_logic;
    cart_irq_n       : in    std_logic;
    cart_ba          : inout std_logic;
    cart_r_w         : inout std_logic;
    cart_exrom_n     : in    std_logic;
    cart_game_n      : in    std_logic;
    cart_io1_n       : inout std_logic;
    cart_io2_n       : inout std_logic;
    cart_roml_n      : inout std_logic;
    cart_romh_n      : inout std_logic;
    cart_a           : inout std_logic_vector(15 downto 0);
    cart_d           : inout std_logic_vector(7 downto 0);

    cart_ctrl_oe_n   : out   std_ulogic;                      -- C64 cartridge ctrl
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
end entity mega65_r3;

architecture rtl of mega65_r3 is

  signal hdmi_clk  : std_logic;
  signal hdmi_data : std_logic_vector(0 to 2);

begin

  -- safe states for unused I/Os

  max10_clk      <= '0';
  max10_rx       <= '0';
  uled           <= '0';
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
  hdmi_hpd       <= 'Z';
  hdmi_ls_oe     <= '0';
  hdmi_cec       <= 'Z';
  hdmi_scl       <= 'Z';
  hdmi_sda       <= 'Z';
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

end architecture rtl;
