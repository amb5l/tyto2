--------------------------------------------------------------------------------
-- tb_MEGAtest_r5.vhd                                                         --
-- Simulation testbench for MEGAtest_r5.vhd.                                  --
--------------------------------------------------------------------------------
-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --
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

library std;
  use std.env.all;

library work;
  use work.model_dvi_decoder_pkg.all;
  use work.model_vga_sink_pkg.all;

entity tb_MEGAtest_r5 is
end entity tb_MEGAtest_r5;

architecture sim of tb_MEGAtest_r5 is

  signal clk_in      : std_logic;
  signal rst         : std_logic;

  signal hdmi_clk_p  : std_logic;
  signal hdmi_clk_n  : std_logic;
  signal hdmi_data_p : std_logic_vector(0 to 2);
  signal hdmi_data_n : std_logic_vector(0 to 2);

  signal vga_clk     : std_logic;
  signal vga_vs      : std_logic;
  signal vga_hs      : std_logic;
  signal vga_de      : std_logic;
  signal vga_r       : std_logic_vector(7 downto 0);
  signal vga_g       : std_logic_vector(7 downto 0);
  signal vga_b       : std_logic_vector(7 downto 0);

  signal cap_stb       : std_logic;

  component MEGAtest_r5 is
    port (
      clk_in          : in    std_ulogic;
      rst             : in    std_ulogic;
      uled            : out   std_ulogic;
      led_g_n         : out   std_ulogic;
      led_r_n         : out   std_ulogic;
      uart_tx         : out   std_ulogic;
      uart_rx         : in    std_ulogic;
      qspi_cs_n       : out   std_ulogic;
      qspi_d          : inout std_ulogic_vector(3 downto 0);
      sdi_cd_n        : inout std_ulogic;
      sdi_wp_n        : in    std_ulogic;
      sdi_ss_n        : out   std_ulogic;
      sdi_clk         : out   std_ulogic;
      sdi_mosi        : out   std_ulogic;
      sdi_miso        : inout std_ulogic;
      sdi_d1          : inout std_ulogic;
      sdi_d2          : inout std_ulogic;
      sdx_cd_n        : inout std_ulogic;
      sdx_ss_n        : out   std_ulogic;
      sdx_clk         : out   std_ulogic;
      sdx_mosi        : out   std_ulogic;
      sdx_miso        : inout std_ulogic;
      sdx_d1          : inout std_ulogic;
      sdx_d2          : inout std_ulogic;
      i2c1_scl        : inout std_ulogic;
      i2c1_sda        : inout std_ulogic;
      i2c2_scl        : inout std_ulogic;
      i2c2_sda        : inout std_ulogic;
      grove_scl       : inout std_ulogic;
      grove_sda       : inout std_ulogic;
      kb_io0          : out   std_ulogic;
      kb_io1          : out   std_ulogic;
      kb_io2          : in    std_ulogic;
      kb_jtagen       : out   std_ulogic;
      kb_tck          : out   std_ulogic;
      kb_tms          : out   std_ulogic;
      kb_tdi          : out   std_ulogic;
      kb_tdo          : in    std_ulogic;
      js_pd           : out   std_ulogic;
      js_pg           : in    std_ulogic;
      jsai_up_n       : in    std_ulogic;
      jsai_down_n     : in    std_ulogic;
      jsai_left_n     : in    std_ulogic;
      jsai_right_n    : in    std_ulogic;
      jsai_fire_n     : in    std_ulogic;
      jsbi_up_n       : in    std_ulogic;
      jsbi_down_n     : in    std_ulogic;
      jsbi_left_n     : in    std_ulogic;
      jsbi_right_n    : in    std_ulogic;
      jsbi_fire_n     : in    std_ulogic;
      jsao_up_n       : out   std_ulogic;
      jsao_down_n     : out   std_ulogic;
      jsao_left_n     : out   std_ulogic;
      jsao_right_n    : out   std_ulogic;
      jsao_fire_n     : out   std_ulogic;
      jsbo_up_n       : out   std_ulogic;
      jsbo_down_n     : out   std_ulogic;
      jsbo_left_n     : out   std_ulogic;
      jsbo_right_n    : out   std_ulogic;
      jsbo_fire_n     : out   std_ulogic;
      paddle          : in    std_ulogic_vector(3 downto 0);
      paddle_drain    : out   std_ulogic;
      audio_pd_n      : out   std_ulogic;
      audio_mclk      : out   std_ulogic;
      audio_bclk      : out   std_ulogic;
      audio_lrclk     : out   std_ulogic;
      audio_sdata     : out   std_ulogic;
      audio_smute     : out   std_ulogic;
      audio_i2c_scl   : inout std_ulogic;
      audio_i2c_sda   : inout std_ulogic;
      hdmi_clk_p      : out   std_ulogic;
      hdmi_clk_n      : out   std_ulogic;
      hdmi_data_p     : out   std_ulogic_vector(0 to 2);
      hdmi_data_n     : out   std_ulogic_vector(0 to 2);
      hdmi_hiz_en     : out   std_ulogic;
      hdmi_hpd        : inout std_ulogic;
      hdmi_ls_oe_n    : out   std_ulogic;
      hdmi_scl        : inout std_ulogic;
      hdmi_sda        : inout std_ulogic;
      vga_psave_n     : out   std_ulogic;
      vga_clk         : out   std_ulogic;
      vga_vsync       : out   std_ulogic;
      vga_hsync       : out   std_ulogic;
      vga_sync_n      : out   std_ulogic;
      vga_blank_n     : out   std_ulogic;
      vga_r           : out   std_ulogic_vector (7 downto 0);
      vga_g           : out   std_ulogic_vector (7 downto 0);
      vga_b           : out   std_ulogic_vector (7 downto 0);
      vga_scl         : inout std_ulogic;
      vga_sda         : inout std_ulogic;
      fdd_chg_n       : in    std_ulogic;
      fdd_wp_n        : in    std_ulogic;
      fdd_den         : out   std_ulogic;
      fdd_sela        : out   std_ulogic;
      fdd_selb        : out   std_ulogic;
      fdd_mota_n      : out   std_ulogic;
      fdd_motb_n      : out   std_ulogic;
      fdd_side_n      : out   std_ulogic;
      fdd_dir_n       : out   std_ulogic;
      fdd_step_n      : out   std_ulogic;
      fdd_trk0_n      : in    std_ulogic;
      fdd_idx_n       : in    std_ulogic;
      fdd_wgate_n     : out   std_ulogic;
      fdd_wdata       : out   std_ulogic;
      fdd_rdata       : in    std_ulogic;
      iec_rst_n       : out   std_ulogic;
      iec_atn_n       : out   std_ulogic;
      iec_srq_n_en_n  : out   std_ulogic;
      iec_srq_n_o     : out   std_ulogic;
      iec_srq_n_i     : in    std_ulogic;
      iec_clk_en_n    : out   std_ulogic;
      iec_clk_o       : out   std_ulogic;
      iec_clk_i       : in    std_ulogic;
      iec_data_en_n   : out   std_ulogic;
      iec_data_o      : out   std_ulogic;
      iec_data_i      : in    std_ulogic;
      eth_rst_n       : out   std_ulogic;
      eth_clk         : out   std_ulogic;
      eth_txen        : out   std_ulogic;
      eth_txd         : out   std_ulogic_vector(1 downto 0);
      eth_rxdv        : in    std_ulogic;
      eth_rxer        : in    std_ulogic;
      eth_rxd         : in    std_ulogic_vector(1 downto 0);
      eth_mdc         : out   std_ulogic;
      eth_mdio        : inout std_ulogic;
      eth_led_n       : inout std_ulogic;
      cart_dotclk     : out   std_ulogic;
      cart_phi2       : out   std_ulogic;
      cart_rst_oe_n   : out   std_ulogic;
      cart_rst_n      : inout std_ulogic;
      cart_dma_n      : in    std_ulogic;
      cart_nmi_en_n   : out   std_ulogic;
      cart_nmi_n      : in    std_ulogic;
      cart_irq_en_n   : out   std_ulogic;
      cart_irq_n      : in    std_ulogic;
      cart_ba         : inout std_ulogic;
      cart_r_w        : inout std_ulogic;
      cart_exrom_oe_n : out   std_ulogic;
      cart_exrom_n    : inout std_ulogic;
      cart_game_oe_n  : out   std_ulogic;
      cart_game_n     : inout std_ulogic;
      cart_io1_n      : inout std_ulogic;
      cart_io2_n      : inout std_ulogic;
      cart_roml_oe_n  : out   std_ulogic;
      cart_roml_n     : inout std_ulogic;
      cart_romh_oe_n  : out   std_ulogic;
      cart_romh_n     : inout std_ulogic;
      cart_a          : inout std_ulogic_vector(15 downto 0);
      cart_d          : inout std_ulogic_vector(7 downto 0);
      cart_en         : out   std_ulogic;
      cart_ctrl_oe_n  : out   std_ulogic;
      cart_ctrl_dir   : out   std_ulogic;
      cart_addr_oe_n  : out   std_ulogic;
      cart_laddr_dir  : out   std_ulogic;
      cart_haddr_dir  : out   std_ulogic;
      cart_data_oe_n  : out   std_ulogic;
      cart_data_dir   : out   std_ulogic;
      hr_rst_n        : out   std_ulogic;
      hr_clk_p        : out   std_ulogic;
      hr_cs_n         : out   std_ulogic;
      hr_rwds         : inout std_ulogic;
      hr_d            : inout std_ulogic_vector(7 downto 0);
      sdram_clk       : out   std_ulogic;
      sdram_cke       : out   std_ulogic;
      sdram_cs_n      : out   std_ulogic;
      sdram_ras_n     : out   std_ulogic;
      sdram_cas_n     : out   std_ulogic;
      sdram_we_n      : out   std_ulogic;
      sdram_dqml      : out   std_ulogic;
      sdram_dqmh      : out   std_ulogic;
      sdram_ba        : out   std_ulogic_vector(1 downto 0);
      sdram_a         : out   std_ulogic_vector(12 downto 0);
      sdram_dq        : inout std_ulogic_vector(15 downto 0);
      pmod1en         : out   std_ulogic;
      pmod1flg        : in    std_ulogic;
      pmod1lo         : inout std_ulogic_vector(3 downto 0);
      pmod1hi         : inout std_ulogic_vector(3 downto 0);
      pmod2en         : out   std_ulogic;
      pmod2flg        : in    std_ulogic;
      pmod2lo         : inout std_ulogic_vector(3 downto 0);
      pmod2hi         : inout std_ulogic_vector(3 downto 0);
      dbg             : inout std_ulogic_vector(11 to 11)
    );
  end component MEGAtest_r5;

begin

  clk_in <=
            '1' after 5 ns when clk_in = '0' else
            '0' after 5 ns when clk_in = '1' else
            '0';

  TEST: process is
  begin
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait;
    wait until rising_edge(cap_stb);
    stop;
  end process TEST;

  DUT: component MEGAtest_r5
    port map (
      clk_in          => clk_in,
      rst             => rst,
      uled            => open,
      led_g_n         => open,
      led_r_n         => open,
      uart_tx         => open,
      uart_rx         => '1',
      qspi_cs_n       => open,
      qspi_d          => open,
      sdi_cd_n        => open,
      sdi_wp_n        => '1',
      sdi_ss_n        => open,
      sdi_clk         => open,
      sdi_mosi        => open,
      sdi_miso        => open,
      sdi_d1          => open,
      sdi_d2          => open,
      sdx_cd_n        => open,
      sdx_ss_n        => open,
      sdx_clk         => open,
      sdx_mosi        => open,
      sdx_miso        => open,
      sdx_d1          => open,
      sdx_d2          => open,
      i2c1_scl        => open,
      i2c1_sda        => open,
      i2c2_scl        => open,
      i2c2_sda        => open,
      grove_scl       => open,
      grove_sda       => open,
      kb_io0          => open,
      kb_io1          => open,
      kb_io2          => '0',
      kb_jtagen       => open,
      kb_tck          => open,
      kb_tms          => open,
      kb_tdi          => open,
      kb_tdo          => '0',
      js_pd           => open,
      js_pg           => '0',
      jsai_up_n       => '1',
      jsai_down_n     => '1',
      jsai_left_n     => '1',
      jsai_right_n    => '1',
      jsai_fire_n     => '1',
      jsbi_up_n       => '1',
      jsbi_down_n     => '1',
      jsbi_left_n     => '1',
      jsbi_right_n    => '1',
      jsbi_fire_n     => '1',
      jsao_up_n       => open,
      jsao_down_n     => open,
      jsao_left_n     => open,
      jsao_right_n    => open,
      jsao_fire_n     => open,
      jsbo_up_n       => open,
      jsbo_down_n     => open,
      jsbo_left_n     => open,
      jsbo_right_n    => open,
      jsbo_fire_n     => open,
      paddle          => (others => '0'),
      paddle_drain    => open,
      audio_pd_n      => open,
      audio_mclk      => open,
      audio_bclk      => open,
      audio_lrclk     => open,
      audio_sdata     => open,
      audio_smute     => open,
      audio_i2c_scl   => open,
      audio_i2c_sda   => open,
      hdmi_clk_p      => hdmi_clk_p,
      hdmi_clk_n      => hdmi_clk_n,
      hdmi_data_p     => hdmi_data_p,
      hdmi_data_n     => hdmi_data_n,
      hdmi_hiz_en     => open,
      hdmi_hpd        => open,
      hdmi_ls_oe_n    => open,
      hdmi_scl        => open,
      hdmi_sda        => open,
      vga_psave_n     => open,
      vga_clk         => open,
      vga_vsync       => open,
      vga_hsync       => open,
      vga_sync_n      => open,
      vga_blank_n     => open,
      vga_r           => open,
      vga_g           => open,
      vga_b           => open,
      vga_scl         => open,
      vga_sda         => open,
      fdd_chg_n       => '1',
      fdd_wp_n        => '1',
      fdd_den         => open,
      fdd_sela        => open,
      fdd_selb        => open,
      fdd_mota_n      => open,
      fdd_motb_n      => open,
      fdd_side_n      => open,
      fdd_dir_n       => open,
      fdd_step_n      => open,
      fdd_trk0_n      => '1',
      fdd_idx_n       => '1',
      fdd_wgate_n     => open,
      fdd_wdata       => open,
      fdd_rdata       => '0',
      iec_rst_n       => open,
      iec_atn_n       => open,
      iec_srq_n_en_n  => open,
      iec_srq_n_o     => open,
      iec_srq_n_i     => '1',
      iec_clk_en_n    => open,
      iec_clk_o       => open,
      iec_clk_i       => '0',
      iec_data_en_n   => open,
      iec_data_o      => open,
      iec_data_i      => '0',
      eth_rst_n       => open,
      eth_clk         => open,
      eth_txen        => open,
      eth_txd         => open,
      eth_rxdv        => '0',
      eth_rxer        => '0',
      eth_rxd         => (others => '0'),
      eth_mdc         => open,
      eth_mdio        => open,
      eth_led_n       => open,
      cart_dotclk     => open,
      cart_phi2       => open,
      cart_rst_oe_n   => open,
      cart_rst_n      => open,
      cart_dma_n      => '1',
      cart_nmi_en_n   => open,
      cart_nmi_n      => '1',
      cart_irq_en_n   => open,
      cart_irq_n      => '1',
      cart_ba         => open,
      cart_r_w        => open,
      cart_exrom_oe_n => open,
      cart_exrom_n    => open,
      cart_game_oe_n  => open,
      cart_game_n     => open,
      cart_io1_n      => open,
      cart_io2_n      => open,
      cart_roml_oe_n  => open,
      cart_roml_n     => open,
      cart_romh_oe_n  => open,
      cart_romh_n     => open,
      cart_a          => open,
      cart_d          => open,
      cart_en         => open,
      cart_ctrl_oe_n  => open,
      cart_ctrl_dir   => open,
      cart_addr_oe_n  => open,
      cart_laddr_dir  => open,
      cart_haddr_dir  => open,
      cart_data_oe_n  => open,
      cart_data_dir   => open,
      hr_rst_n        => open,
      hr_clk_p        => open,
      hr_cs_n         => open,
      hr_rwds         => open,
      hr_d            => open,
      sdram_clk       => open,
      sdram_cke       => open,
      sdram_cs_n      => open,
      sdram_ras_n     => open,
      sdram_cas_n     => open,
      sdram_we_n      => open,
      sdram_dqml      => open,
      sdram_dqmh      => open,
      sdram_ba        => open,
      sdram_a         => open,
      sdram_dq        => open,
      pmod1en         => open,
      pmod1flg        => '0',
      pmod1lo         => open,
      pmod1hi         => open,
      pmod2en         => open,
      pmod2flg        => '0',
      pmod2lo         => open,
      pmod2hi         => open,
      dbg             => open
    );

  DECODE: component model_dvi_decoder
    port map (
      dvi_clk  => hdmi_clk_p,
      dvi_d    => hdmi_data_p,
      vga_clk  => vga_clk,
      vga_vs   => vga_vs,
      vga_hs   => vga_hs,
      vga_de   => vga_de,
      vga_p(2) => vga_r,
      vga_p(1) => vga_g,
      vga_p(0) => vga_b
    );

  CAPTURE: component model_vga_sink
    port map (
      vga_rst  => '0',
      vga_clk  => vga_clk,
      vga_vs   => vga_vs,
      vga_hs   => vga_hs,
      vga_de   => vga_de,
      vga_r    => vga_r,
      vga_g    => vga_g,
      vga_b    => vga_b,
      cap_rst  => '0',
      cap_stb  => cap_stb,
      cap_name => "tb_MEGAtest_r5"
    );

end architecture sim;
