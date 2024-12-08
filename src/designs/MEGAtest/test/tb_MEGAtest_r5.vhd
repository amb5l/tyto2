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

use work.model_hram_pkg.all;
use work.model_dvi_decoder_pkg.all;
use work.model_vga_sink_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library std;
  use std.env.all;

entity tb_MEGAtest_r5 is
end entity tb_MEGAtest_r5;

architecture sim of tb_MEGAtest_r5 is

  signal clk_in      : std_logic;
  signal rst         : std_logic;

  signal hr_rst_n    : std_logic;
  signal hr_clk_p    : std_logic;
  signal hr_cs_n     : std_logic;
  signal hr_rwds     : std_logic;
  signal hr_d        : std_logic_vector(7 downto 0);

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
    generic (
      GIT_COMMIT : integer
    );
    port (
      clk_in          : in    std_logic;
      rst             : in    std_logic;
      uled            : out   std_logic;
      led_g_n         : out   std_logic;
      led_r_n         : out   std_logic;
      uart_tx         : out   std_logic;
      uart_rx         : in    std_logic;
      qspi_cs_n       : out   std_logic;
      qspi_d          : inout std_logic_vector(3 downto 0);
      sdi_cd_n        : inout std_logic;
      sdi_wp_n        : in    std_logic;
      sdi_ss_n        : out   std_logic;
      sdi_clk         : out   std_logic;
      sdi_mosi        : out   std_logic;
      sdi_miso        : inout std_logic;
      sdi_d1          : inout std_logic;
      sdi_d2          : inout std_logic;
      sdx_cd_n        : inout std_logic;
      sdx_ss_n        : out   std_logic;
      sdx_clk         : out   std_logic;
      sdx_mosi        : out   std_logic;
      sdx_miso        : inout std_logic;
      sdx_d1          : inout std_logic;
      sdx_d2          : inout std_logic;
      i2c1_scl        : inout std_logic;
      i2c1_sda        : inout std_logic;
      i2c2_scl        : inout std_logic;
      i2c2_sda        : inout std_logic;
      grove_scl       : inout std_logic;
      grove_sda       : inout std_logic;
      kb_io0          : out   std_logic;
      kb_io1          : out   std_logic;
      kb_io2          : in    std_logic;
      kb_jtagen       : out   std_logic;
      kb_tck          : out   std_logic;
      kb_tms          : out   std_logic;
      kb_tdi          : out   std_logic;
      kb_tdo          : in    std_logic;
      js_pd           : out   std_logic;
      js_pg           : in    std_logic;
      jsai_up_n       : in    std_logic;
      jsai_down_n     : in    std_logic;
      jsai_left_n     : in    std_logic;
      jsai_right_n    : in    std_logic;
      jsai_fire_n     : in    std_logic;
      jsbi_up_n       : in    std_logic;
      jsbi_down_n     : in    std_logic;
      jsbi_left_n     : in    std_logic;
      jsbi_right_n    : in    std_logic;
      jsbi_fire_n     : in    std_logic;
      jsao_up_n       : out   std_logic;
      jsao_down_n     : out   std_logic;
      jsao_left_n     : out   std_logic;
      jsao_right_n    : out   std_logic;
      jsao_fire_n     : out   std_logic;
      jsbo_up_n       : out   std_logic;
      jsbo_down_n     : out   std_logic;
      jsbo_left_n     : out   std_logic;
      jsbo_right_n    : out   std_logic;
      jsbo_fire_n     : out   std_logic;
      paddle          : in    std_logic_vector(3 downto 0);
      paddle_drain    : out   std_logic;
      audio_pd_n      : out   std_logic;
      audio_mclk      : out   std_logic;
      audio_bclk      : out   std_logic;
      audio_lrclk     : out   std_logic;
      audio_sdata     : out   std_logic;
      audio_smute     : out   std_logic;
      audio_i2c_scl   : inout std_logic;
      audio_i2c_sda   : inout std_logic;
      hdmi_clk_p      : out   std_logic;
      hdmi_clk_n      : out   std_logic;
      hdmi_data_p     : out   std_logic_vector(0 to 2);
      hdmi_data_n     : out   std_logic_vector(0 to 2);
      hdmi_hiz_en     : out   std_logic;
      hdmi_hpd        : inout std_logic;
      hdmi_ls_oe_n    : out   std_logic;
      hdmi_scl        : inout std_logic;
      hdmi_sda        : inout std_logic;
      vga_psave_n     : out   std_logic;
      vga_clk         : out   std_logic;
      vga_vsync       : out   std_logic;
      vga_hsync       : out   std_logic;
      vga_sync_n      : out   std_logic;
      vga_blank_n     : out   std_logic;
      vga_r           : out   std_logic_vector (7 downto 0);
      vga_g           : out   std_logic_vector (7 downto 0);
      vga_b           : out   std_logic_vector (7 downto 0);
      vga_scl         : inout std_logic;
      vga_sda         : inout std_logic;
      fdd_chg_n       : in    std_logic;
      fdd_wp_n        : in    std_logic;
      fdd_den         : out   std_logic;
      fdd_sela        : out   std_logic;
      fdd_selb        : out   std_logic;
      fdd_mota_n      : out   std_logic;
      fdd_motb_n      : out   std_logic;
      fdd_side_n      : out   std_logic;
      fdd_dir_n       : out   std_logic;
      fdd_step_n      : out   std_logic;
      fdd_trk0_n      : in    std_logic;
      fdd_idx_n       : in    std_logic;
      fdd_wgate_n     : out   std_logic;
      fdd_wdata       : out   std_logic;
      fdd_rdata       : in    std_logic;
      iec_rst_n       : out   std_logic;
      iec_atn_n       : out   std_logic;
      iec_srq_n_en_n  : out   std_logic;
      iec_srq_n_o     : out   std_logic;
      iec_srq_n_i     : in    std_logic;
      iec_clk_en_n    : out   std_logic;
      iec_clk_o       : out   std_logic;
      iec_clk_i       : in    std_logic;
      iec_data_en_n   : out   std_logic;
      iec_data_o      : out   std_logic;
      iec_data_i      : in    std_logic;
      eth_rst_n       : out   std_logic;
      eth_clk         : out   std_logic;
      eth_txen        : out   std_logic;
      eth_txd         : out   std_logic_vector(1 downto 0);
      eth_rxdv        : in    std_logic;
      eth_rxer        : in    std_logic;
      eth_rxd         : in    std_logic_vector(1 downto 0);
      eth_mdc         : out   std_logic;
      eth_mdio        : inout std_logic;
      eth_led_n       : inout std_logic;
      cart_dotclk     : out   std_logic;
      cart_phi2       : out   std_logic;
      cart_rst_oe_n   : out   std_logic;
      cart_rst_n      : inout std_logic;
      cart_dma_n      : in    std_logic;
      cart_nmi_en_n   : out   std_logic;
      cart_nmi_n      : in    std_logic;
      cart_irq_en_n   : out   std_logic;
      cart_irq_n      : in    std_logic;
      cart_ba         : inout std_logic;
      cart_r_w        : inout std_logic;
      cart_exrom_oe_n : out   std_logic;
      cart_exrom_n    : inout std_logic;
      cart_game_oe_n  : out   std_logic;
      cart_game_n     : inout std_logic;
      cart_io1_n      : inout std_logic;
      cart_io2_n      : inout std_logic;
      cart_roml_oe_n  : out   std_logic;
      cart_roml_n     : inout std_logic;
      cart_romh_oe_n  : out   std_logic;
      cart_romh_n     : inout std_logic;
      cart_a          : inout std_logic_vector(15 downto 0);
      cart_d          : inout std_logic_vector(7 downto 0);
      cart_en         : out   std_logic;
      cart_ctrl_oe_n  : out   std_logic;
      cart_ctrl_dir   : out   std_logic;
      cart_addr_oe_n  : out   std_logic;
      cart_laddr_dir  : out   std_logic;
      cart_haddr_dir  : out   std_logic;
      cart_data_oe_n  : out   std_logic;
      cart_data_dir   : out   std_logic;
      hr_rst_n        : out   std_logic;
      hr_clk_p        : out   std_logic;
      hr_cs_n         : out   std_logic;
      hr_rwds         : inout std_logic;
      hr_d            : inout std_logic_vector(7 downto 0);
      sdram_clk       : out   std_logic;
      sdram_cke       : out   std_logic;
      sdram_cs_n      : out   std_logic;
      sdram_ras_n     : out   std_logic;
      sdram_cas_n     : out   std_logic;
      sdram_we_n      : out   std_logic;
      sdram_dqml      : out   std_logic;
      sdram_dqmh      : out   std_logic;
      sdram_ba        : out   std_logic_vector(1 downto 0);
      sdram_a         : out   std_logic_vector(12 downto 0);
      sdram_dq        : inout std_logic_vector(15 downto 0);
      pmod1en         : out   std_logic;
      pmod1flg        : in    std_logic;
      pmod1lo         : inout std_logic_vector(3 downto 0);
      pmod1hi         : inout std_logic_vector(3 downto 0);
      pmod2en         : out   std_logic;
      pmod2flg        : in    std_logic;
      pmod2lo         : inout std_logic_vector(3 downto 0);
      pmod2hi         : inout std_logic_vector(3 downto 0);
      dbg             : inout std_logic_vector(11 to 11)
    );
  end component MEGAtest_r5;

  function hram_params(i : hram_params_t) return hram_params_t is
    variable r : hram_params_t;
  begin
    r := i;
    r.tVCS := 10.0;   -- override tVCS to shorten simulation time
    r.tCSM := 6000.0; -- override tCSM (50MHz bodge)
    r.abw  := 9;      -- report write row boundary crossing
    return r;
  end function hram_params;

begin

  U_GLBL: entity work.glbl -- v4p ignore e-202 (Verilog unit)
    generic map (
      ROC_WIDTH => 100000
    );

  clk_in <=
            '1' after 5 ns when clk_in = '0' else
            '0' after 5 ns when clk_in = '1' else
            '0';

  TEST: process is
  begin
    rst <= '1';
    wait for 200 ns;
    rst <= '0';
    wait;
    wait until rising_edge(cap_stb);
    stop;
  end process TEST;

  DUT: component MEGAtest_r5
    generic map (
      GIT_COMMIT => 16#12345678#
    )
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
      hr_rst_n        => hr_rst_n,
      hr_clk_p        => hr_clk_p,
      hr_cs_n         => hr_cs_n,
      hr_rwds         => hr_rwds,
      hr_d            => hr_d,
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

  HYPERRAM: component model_hram
    generic map (
      SIM_MEM_SIZE => 8*1024*1024,
      OUTPUT_DELAY => "UNIFORM",
      PARAMS       => hram_params(IS66WVH8M8DBLL_100B1LI)
    )
    port map (
      rst_n => hr_rst_n,
      cs_n  => hr_cs_n,
      clk   => hr_clk_p,
      rwds  => hr_rwds,
      dq    => hr_d
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
