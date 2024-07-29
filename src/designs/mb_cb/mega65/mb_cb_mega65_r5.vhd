--------------------------------------------------------------------------------
-- mb_cb_mega65_r5.vhd                                                        --
-- Board specific top level wrapper for the mb_cb design.                     --
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
  use work.tyto_types_pkg.all;
  use work.mmcm_pkg.all;
  use work.mb_cb_pkg.all;
  use work.vga_to_hdmi_pkg.all;
  use work.serialiser_10to1_selectio_pkg.all;

entity mb_cb_mega65_r5 is
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

    i2c1_scl         : inout std_ulogic;                      -- on-board I2C bus #1
    i2c1_sda         : inout std_ulogic;

    i2c2_scl         : inout std_ulogic;                      -- on-board I2C bus #2
    i2c2_sda         : inout std_ulogic;

    grove_scl        : inout std_ulogic;                      -- Grove connector
    grove_sda        : inout std_ulogic;

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
    cart_rst_oe_n    : out   std_ulogic;
    cart_rst_n       : inout std_ulogic;
    cart_dma_n       : in    std_ulogic;
    cart_nmi_en_n    : out   std_ulogic;
    cart_nmi_n       : in    std_ulogic;
    cart_irq_en_n    : out   std_ulogic;
    cart_irq_n       : in    std_ulogic;
    cart_ba          : inout std_ulogic;
    cart_r_w         : inout std_ulogic;
    cart_exrom_oe_n  : out   std_ulogic;
    cart_exrom_n     : inout std_ulogic;
    cart_game_oe_n   : out   std_ulogic;
    cart_game_n      : inout std_ulogic;
    cart_io1_n       : inout std_ulogic;
    cart_io2_n       : inout std_ulogic;
    cart_roml_oe_n   : out   std_ulogic;
    cart_roml_n      : inout std_ulogic;
    cart_romh_oe_n   : out   std_ulogic;
    cart_romh_n      : inout std_ulogic;
    cart_a           : inout std_ulogic_vector(15 downto 0);
    cart_d           : inout std_ulogic_vector(7 downto 0);

    cart_en          : out   std_ulogic;                      -- C64 cartridge ctrl
    cart_ctrl_oe_n   : out   std_ulogic;
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

    dbg              : inout std_ulogic_vector(11 to 11)      -- debug header

  );
end entity mb_cb_mega65_r5;

architecture synth of mb_cb_mega65_r5 is

  signal cpu_clk    : std_logic;                    -- 100 MHz
  signal cpu_rst    : std_logic;

  signal pix_clk_x5 : std_logic;                    -- 135 MHz
  signal pix_clk    : std_logic;                    -- 27 MHz
  signal pix_rst    : std_logic;

  signal pix_vs     : std_logic;                    -- VGA: vertical sync
  signal pix_hs     : std_logic;                    -- VGA: horizontal sync
  signal pix_de     : std_logic;                    -- VGA: vertical blank
  signal pix_r      : std_logic_vector(7 downto 0); -- VGA: red
  signal pix_g      : std_logic_vector(7 downto 0); -- VGA: green
  signal pix_b      : std_logic_vector(7 downto 0); -- VGA: blue

  signal pal_ntsc   : std_logic;
  signal vic        : std_logic_vector(7 downto 0);

  signal tmds       : slv_9_0_t(0 to 2);            -- parallel TMDS channels

begin

  MMCM_CPU: component mmcm
    generic map (
      mul         => 10.0,
      div         => 1,
      num_outputs => 1,
      odiv0       => 10.0
    )
    port map (
      rsti        => rst,
      clki        => clk_in,
      rsto        => cpu_rst,
      clko(0)     => cpu_clk
    );

  MMCM_PIX: component mmcm
    generic map (
      mul         => 47.25,
      div         => 5,
      num_outputs => 2,
      odiv0       => 7.0,
      odiv        => (35,0,0,0,0,0)
    )
    port map (
      rsti        => rst,
      clki        => clk_in,
      rsto        => pix_rst,
      clko(0)     => pix_clk_x5,
      clko(1)     => pix_clk
    );

  MAIN: component mb_cb
    port map (
      cpu_clk  => cpu_clk,
      cpu_rst  => cpu_rst,
      pix_clk  => pix_clk,
      pix_rst  => pix_rst,
      uart_tx  => uart_tx,
      uart_rx  => uart_rx,
      pal_ntsc => pal_ntsc,
      vga_vs   => pix_vs,
      vga_hs   => pix_hs,
      vga_de   => pix_de,
      vga_r    => pix_r,
      vga_g    => pix_g,
      vga_b    => pix_b
    );

  vic <= x"15" when pal_ntsc = '1' else x"06";

  HDMI_CONV: component vga_to_hdmi
    generic map (
      pcm_fs    => 48.0
    )
    port map (
      dvi       => '1',
      vic       => vic,
      pix_rep   => '1',
      aspect    => "01",
      vs_pol    => '0',
      hs_pol    => '0',
      vga_rst   => pix_rst,
      vga_clk   => pix_clk,
      vga_vs    => pix_vs,
      vga_hs    => pix_hs,
      vga_de    => pix_de,
      vga_r     => pix_r,
      vga_g     => pix_g,
      vga_b     => pix_b,
      pcm_rst   => '1',
      pcm_clk   => '0',
      pcm_clken => '0',
      pcm_l     => (others => '0'),
      pcm_r     => (others => '0'),
      pcm_acr   => '0',
      pcm_n     => (others => '0'),
      pcm_cts   => (others => '0'),
      tmds      => tmds
    );

  gen_hdmi_data: for i in 0 to 2 generate
  begin

    HDMI_DATA: component serialiser_10to1_selectio
      port map (
        rst    => pix_rst,
        clk    => pix_clk,
        clk_x5 => pix_clk_x5,
        d      => tmds(i),
        out_p  => hdmi_data_p(i),
        out_n  => hdmi_data_n(i)
      );

  end generate gen_hdmi_data;

  HDMI_CLK: component serialiser_10to1_selectio
    port map (
      rst    => pix_rst,
      clk    => pix_clk,
      clk_x5 => pix_clk_x5,
      d      => "0000011111",
      out_p  => hdmi_clk_p,
      out_n  => hdmi_clk_n
    );

  hdmi_hiz_en     <= '0';
  hdmi_hpd        <= 'Z';
  hdmi_ls_oe_n    <= '0';

  -- safe states for unused I/Os

  uled            <= '0';
  led_g_n         <= '1';
  led_r_n         <= '1';
  qspi_cs_n       <= '1';
  qspi_d          <= (others => '1');
  sdi_cd_n        <= 'Z';
  sdi_ss_n        <= '1';
  sdi_clk         <= '0';
  sdi_mosi        <= '0';
  sdi_miso        <= 'Z';
  sdi_d1          <= 'Z';
  sdi_d2          <= 'Z';
  sdx_cd_n        <= 'Z';
  sdx_ss_n        <= '1';
  sdx_clk         <= '0';
  sdx_mosi        <= '0';
  sdx_miso        <= 'Z';
  sdx_d1          <= 'Z';
  sdx_d2          <= 'Z';
  i2c1_sda        <= 'Z';
  i2c1_scl        <= 'Z';
  i2c2_sda        <= 'Z';
  i2c2_scl        <= 'Z';
  grove_sda       <= 'Z';
  grove_scl       <= 'Z';
  kb_io0          <= '0';
  kb_io1          <= '0';
  kb_jtagen       <= '0';
  kb_tck          <= '0';
  kb_tms          <= '1';
  kb_tdi          <= '0';
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
  paddle_drain    <= '0';
  audio_pd_n      <= '0';
  audio_mclk      <= '0';
  audio_bclk      <= '0';
  audio_lrclk     <= '0';
  audio_sdata     <= '0';
  audio_smute     <= '1';
  audio_i2c_scl   <= 'Z';
  audio_i2c_sda   <= 'Z';
  hdmi_scl        <= 'Z';
  hdmi_sda        <= 'Z';
  vga_psave_n     <= '0';
  vga_clk         <= '0';
  vga_vsync       <= '0';
  vga_hsync       <= '0';
  vga_sync_n      <= '1';
  vga_blank_n     <= '1';
  vga_r           <= (others => '0');
  vga_g           <= (others => '0');
  vga_b           <= (others => '0');
  vga_scl         <= 'Z';
  vga_sda         <= 'Z';
  fdd_den         <= '0';
  fdd_sela        <= '0';
  fdd_selb        <= '0';
  fdd_mota_n      <= '1';
  fdd_motb_n      <= '1';
  fdd_side_n      <= '1';
  fdd_dir_n       <= '1';
  fdd_step_n      <= '1';
  fdd_wgate_n     <= '1';
  fdd_wdata       <= '1';
  iec_rst_n       <= '0';
  iec_atn_n       <= '1';
  iec_srq_n_en_n  <= '1';
  iec_srq_n_o     <= '1';
  iec_clk_en_n    <= '1';
  iec_clk_o       <= '1';
  iec_data_en_n   <= '1';
  iec_data_o      <= '1';
  eth_rst_n       <= '0';
  eth_clk         <= '0';
  eth_txen        <= '0';
  eth_txd         <= (others => '0');
  eth_mdc         <= '0';
  eth_mdio        <= 'Z';
  eth_led_n       <= '1';
  cart_dotclk     <= '0';
  cart_phi2       <= '0';
  cart_rst_oe_n   <= '1';
  cart_rst_n      <= 'Z'; -- driven by level shifter with pullup on input
  cart_nmi_en_n   <= '1';
  cart_irq_en_n   <= '1';
  cart_ba         <= 'Z'; -- pullup
  cart_r_w        <= 'Z'; -- pullup
  cart_exrom_oe_n <= '1';
  cart_exrom_n    <= 'Z'; -- driven by level shifter with pullup on input
  cart_game_oe_n  <= '1';
  cart_game_n     <= 'Z'; -- driven by level shifter with pullup on input
  cart_io1_n      <= 'Z'; -- pullup
  cart_io2_n      <= 'Z'; -- pullup
  cart_roml_oe_n  <= '1';
  cart_roml_n     <= 'Z'; -- driven by level shifter with pullup on input
  cart_romh_oe_n  <= '1';
  cart_romh_n     <= 'Z'; -- driven by level shifter with pullup on input
  cart_a          <= (others => 'Z'); -- pullup
  cart_d          <= (others => 'Z'); -- pullup
  cart_en         <= '1';
  cart_ctrl_oe_n  <= '1';
  cart_ctrl_dir   <= '1';
  cart_addr_oe_n  <= '1';
  cart_laddr_dir  <= '1';
  cart_haddr_dir  <= '1';
  cart_data_oe_n  <= '1';
  cart_data_dir   <= '1';
  hr_rst_n        <= '0';
  hr_clk_p        <= '0';
  hr_cs_n         <= '1';
  hr_rwds         <= '0';
  hr_d            <= (others => '0');
  sdram_clk       <= '0';
  sdram_cke       <= '0';
  sdram_cs_n      <= '1';
  sdram_ras_n     <= '1';
  sdram_cas_n     <= '1';
  sdram_we_n      <= '1';
  sdram_dqml      <= '1';
  sdram_dqmh      <= '1';
  sdram_ba        <= (others => '0');
  sdram_a         <= (others => '0');
  sdram_dq        <= (others => '0');
  pmod1en         <= '0';
  pmod1lo         <= (others => 'Z');
  pmod1hi         <= (others => 'Z');
  pmod2en         <= '0';
  pmod2lo         <= (others => 'Z');
  pmod2hi         <= (others => 'Z');
  dbg             <= (others => 'Z');

end architecture synth;
