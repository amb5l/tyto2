--------------------------------------------------------------------------------
-- mb_cb_digilent_nexys_video.vhd                                             --
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

entity mb_cb_digilent_nexys_video is
  port (

    -- clocks
    clki_100m     : in    std_logic;
    --      gtp_clk_p       : in    std_logic;
    --      gtp_clk_n       : in    std_logic;
    --      fmc_mgt_clk_p   : in    std_logic;
    --      fmc_mgt_clk_n   : in    std_logic;

    -- LEDs, buttons and switches
    led           : out   std_logic_vector(7 downto 0);
    --      btn_c           : in    std_logic;
    --      btn_d           : in    std_logic;
    --      btn_l           : in    std_logic;
    --      btn_r           : in    std_logic;
    --      btn_u           : in    std_logic;
    btn_rst_n     : in    std_logic;
    --      sw              : in    std_logic_vector(7 downto 0);

    -- OLED
    oled_res_n    : out   std_logic;
    oled_d_c      : out   std_logic;
    oled_sclk     : out   std_logic;
    oled_sdin     : out   std_logic;
    --      oled_vbat_dis   : out   std_logic;
    --      oled_vdd_dis    : out   std_logic;

    -- HDMI RX
    --      hdmi_rx_clk_p   : in    std_logic;
    --      hdmi_rx_clk_n   : in    std_logic;
    --      hdmi_rx_d_p     : in    std_logic_vector(0 to 2);
    --      hdmi_rx_d_n     : in    std_logic_vector(0 to 2);
    --      hdmi_rx_sda     : inout std_logic;
    --      hdmi_rx_cec     : in    std_logic;
    --      hdmi_rx_hpd     : out   std_logic;
    --      hdmi_rx_txen    : out   std_logic;
    --      hdmi_rx_scl     : in    std_logic;

    -- HDMI TX
    hdmi_tx_clk_p : out   std_logic;
    hdmi_tx_clk_n : out   std_logic;
    hdmi_tx_d_p   : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n   : out   std_logic_vector(0 to 2);
    --      hdmi_tx_scl     : out   std_logic;
    --      hdmi_tx_sda     : inout std_logic;
    --      hdmi_tx_cec     : out   std_logic;
    --      hdmi_tx_hpd     : in    std_logic;

    -- DisplayPort
    --      dp_tx_p         : out   std_logic_vector(0 to 1);
    --      dp_tx_n         : out   std_logic_vector(0 to 1);
    --      dp_tx_aux_p     : inout std_logic;
    --      dp_tx_aux_n     : inout std_logic;
    --      dp_tx_aux2_p    : inout std_logic;
    --      dp_tx_aux2_n    : inout std_logic;
    --      dp_tx_hpd       : in    std_logic;

    -- audio codec
    ac_mclk       : out   std_logic;
    --      ac_lrclk        : out   std_logic;
    --      ac_bclk         : out   std_logic;
    ac_dac_sdata  : out   std_logic;
    --      ac_adc_sdata    : in    std_logic;

    -- PMODs
    --      ja              : inout std_logic_vector(7 downto 0);
    --      jb              : inout std_logic_vector(7 downto 0);
    --      jc              : inout std_logic_vector(7 downto 0);
    --      xa_p            : inout std_logic_vector(3 downto 0);
    --      xa_n            : inout std_logic_vector(3 downto 0);

    -- UART
    uart_rx_out   : out   std_logic;
    uart_tx_in    : in    std_logic;

    -- ethernet
    eth_rst_n     : out   std_logic;
    --      eth_txck        : out   std_logic;
    --      eth_txctl       : out   std_logic;
    --      eth_txd         : out   std_logic_vector(3 downto 0);
    --      eth_rxck        : in    std_logic;
    --      eth_rxctl       : in    std_logic;
    --      eth_rxd         : in    std_logic_vector(3 downto 0);
    --      eth_mdc         : out   std_logic;
    --      eth_mdio        : inout std_logic;
    --      eth_int_n       : in    std_logic;
    --      eth_pme_n       : in    std_logic;

    -- fan
    --      fan_pwm         : out   std_logic;

    -- FTDI
    --      ftdi_clko       : in    std_logic;
    --      ftdi_rxf_n      : in    std_logic;
    --      ftdi_txe_n      : in    std_logic;
    ftdi_rd_n     : out   std_logic;
    ftdi_wr_n     : out   std_logic;
    ftdi_siwu_n   : out   std_logic;
    ftdi_oe_n     : out   std_logic;
    --      ftdi_d          : inout std_logic_vector(7 downto 0);
    --      ftdi_spien      : out   std_logic;

    -- PS/2
    ps2_clk       : inout std_logic;
    ps2_data      : inout std_logic;

    -- QSPI
    qspi_cs_n     : out   std_logic;
    --      qspi_dq         : inout std_logic_vector(3 downto 0);

    -- SD
    --      sd_reset        : out   std_logic;
    --      sd_cclk         : out   std_logic;
    --      sd_cmd          : out   std_logic;
    --      sd_d            : inout std_logic_vector(3 downto 0);
    --      sd_cd           : in    std_logic;

    -- I2C
    --      i2c_scl         : inout std_logic;
    --      i2c_sda         : inout std_logic;

    -- VADJ
    --      set_vadj        : out   std_logic_vector(1 downto 0);
    --      vadj_en         : out   std_logic;

    -- FMC
    --      fmc_clk0_m2c_p  : in    std_logic;
    --      fmc_clk0_m2c_n  : in    std_logic;
    --      fmc_clk1_m2c_p  : in    std_logic;
    --      fmc_clk1_m2c_n  : in    std_logic;
    --      fmc_la_p        : inout std_logic_vector(33 downto 0);
    --      fmc_la_n        : inout std_logic_vector(33 downto 0);

    -- DDR3
    ddr3_reset_n  : out   std_logic
  --      ddr3_ck_p       : out   std_logic_vector(0 downto 0);
  --      ddr3_ck_n       : out   std_logic_vector(0 downto 0);
  --      ddr3_cke        : out   std_logic_vector(0 downto 0);
  --      ddr3_ras_n      : out   std_logic;
  --      ddr3_cas_n      : out   std_logic;
  --      ddr3_we_n       : out   std_logic;
  --      ddr3_odt        : out   std_logic_vector(0 downto 0);
  --      ddr3_addr       : out   std_logic_vector(14 downto 0);
  --      ddr3_ba         : out   std_logic_vector(2 downto 0);
  --      ddr3_dm         : out   std_logic_vector(1 downto 0);
  --      ddr3_dq         : inout std_logic_vector(15 downto 0);
  --      ddr3_dqs_p      : inout std_logic_vector(1 downto 0);
  --      ddr3_dqs_n      : inout std_logic_vector(1 downto 0)

  );
end entity mb_cb_digilent_nexys_video;

architecture synth of mb_cb_digilent_nexys_video is

  signal cpu_clk    : std_logic;                    -- 100 MHz
  signal cpu_rst    : std_logic;

  signal pix_clk_x5 : std_logic;                    -- 135 MHz
  signal pix_clk    : std_logic;                    -- 27 MHz
  signal pix_rst    : std_logic;

  signal vga_vs     : std_logic;                    -- VGA: vertical sync
  signal vga_hs     : std_logic;                    -- VGA: horizontal sync
  signal vga_de     : std_logic;                    -- VGA: vertical blank
  signal vga_r      : std_logic_vector(7 downto 0); -- VGA: red
  signal vga_g      : std_logic_vector(7 downto 0); -- VGA: green
  signal vga_b      : std_logic_vector(7 downto 0); -- VGA: blue

  signal pal_ntsc   : std_logic;
  signal vic        : std_logic_vector(7 downto 0);

  signal tmds       : slv_9_0_t(0 to 2);            -- parallel TMDS channels

begin

  led <= (others => '1');

  MMCM_CPU: component mmcm
    generic map (
      mul         => 10.0,
      div         => 1,
      num_outputs => 1,
      odiv0       => 10.0
    )
    port map (
      rsti        => not btn_rst_n,
      clki        => clki_100m,
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
      rsti        => not btn_rst_n,
      clki        => clki_100m,
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
      uart_tx  => uart_rx_out,
      uart_rx  => uart_tx_in,
      pal_ntsc => pal_ntsc,
      vga_vs   => vga_vs,
      vga_hs   => vga_hs,
      vga_de   => vga_de,
      vga_r    => vga_r,
      vga_g    => vga_g,
      vga_b    => vga_b
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
      vga_vs    => vga_vs,
      vga_hs    => vga_hs,
      vga_de    => vga_de,
      vga_r     => vga_r,
      vga_g     => vga_g,
      vga_b     => vga_b,
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
        out_p  => hdmi_tx_d_p(i),
        out_n  => hdmi_tx_d_n(i)
      );

  end generate gen_hdmi_data;

  HDMI_CLK: component serialiser_10to1_selectio
    port map (
      rst    => pix_rst,
      clk    => pix_clk,
      clk_x5 => pix_clk_x5,
      d      => "0000011111",
      out_p  => hdmi_tx_clk_p,
      out_n  => hdmi_tx_clk_n
    );

  -- unused I/Os

  oled_res_n   <= '0';
  oled_d_c     <= '0';
  oled_sclk    <= '0';
  oled_sdin    <= '0';
  ac_mclk      <= '0';
  ac_dac_sdata <= '0';
  eth_rst_n    <= '0';
  ftdi_rd_n    <= '1';
  ftdi_wr_n    <= '1';
  ftdi_siwu_n  <= '1';
  ftdi_oe_n    <= '1';
  ps2_clk      <= 'Z';
  ps2_data     <= 'Z';
  qspi_cs_n    <= '1';
  ddr3_reset_n <= '0';

end architecture synth;
