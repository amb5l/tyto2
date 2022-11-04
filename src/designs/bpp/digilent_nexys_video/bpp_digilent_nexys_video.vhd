--------------------------------------------------------------------------------
-- bpp_digilent_nexys_video.vhd                                               --
-- Digilent Nexys Video board wrapper for the BPP design.                     --
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
  use work.bpp_pkg.all;
  use work.video_out_clock_pkg.all;
  use work.bpp_kbd_ps2_pkg.all;
  use work.bpp_hdtv_pkg.all;
  use work.bpp_resample_pkg.all;
  use work.bpp_hdtv_pcm_to_hdmi_pkg.all;
  use work.serialiser_10to1_selectio_pkg.all;

entity bpp_digilent_nexys_video is
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
    sw            : in    std_logic_vector(7 downto 0);

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
    -- hdmi_rx_sda     : inout std_logic;
    -- hdmi_rx_cec     : in    std_logic;
    -- hdmi_rx_hpd     : out   std_logic;
    -- hdmi_rx_txen    : out   std_logic;
    -- hdmi_rx_scl     : in    std_logic;

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
    -- ja              : in    std_logic_vector(7 downto 0);
    -- jb              : in    std_logic_vector(7 downto 0);
    -- jc              : out   std_logic_vector(7 downto 0);
    -- xa_p            : inout std_logic_vector(3 downto 0);
    -- xa_n            : inout std_logic_vector(3 downto 0);

    -- UART
    uart_rx_out   : out   std_logic;
    -- uart_tx_in      : in    std_logic;

    -- ethernet
    eth_rst_n     : out   std_logic;
    -- eth_txck        : out   std_logic;
    -- eth_txctl       : out   std_logic;
    -- eth_txd         : out   std_logic_vector(3 downto 0);
    -- eth_rxck        : in    std_logic;
    -- eth_rxctl       : in    std_logic;
    -- eth_rxd         : in    std_logic_vector(3 downto 0);
    -- eth_mdc         : out   std_logic;
    -- eth_mdio        : inout std_logic;
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
    ps2_clk       : inout std_logic;
    ps2_data      : inout std_logic;

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
    ddr3_reset_n  : out   std_logic
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
end entity bpp_digilent_nexys_video;

architecture synth of bpp_digilent_nexys_video is

  --------------------------------------------------------------------------------
  -- main system

  signal sys_rst          : std_logic;                     -- system reset
  signal sys_clk_96m      : std_logic;                     -- system clock, 96 MHz
  signal sys_clk_48m      : std_logic;                     -- system clock, 48 MHz
  signal sys_clk_32m      : std_logic;                     -- system clock, 32 MHz
  signal sys_clk_8m       : std_logic;                     -- system clock, 8 MHz
  signal led_capslock     : std_logic;
  signal led_shiftlock    : std_logic;
  signal led_motor        : std_logic;
  signal kbd_clken        : std_logic;
  signal kbd_rst          : std_logic;
  signal kbd_break        : std_logic;
  signal kbd_load         : std_logic;
  signal kbd_row          : std_logic_vector(2 downto 0);
  signal kbd_col          : std_logic_vector(3 downto 0);
  signal kbd_press        : std_logic;
  signal kbd_irq          : std_logic;

  signal crtc_clken       : std_logic;
  signal crtc_clksel      : std_logic;
  signal crtc_rst         : std_logic;
  signal crtc_f           : std_logic;
  signal crtc_vs          : std_logic;
  signal crtc_hs          : std_logic;
  signal crtc_de          : std_logic;
  signal crtc_oe          : std_logic;

  signal vidproc_clken    : std_logic;
  signal vidproc_rst      : std_logic;
  signal vidproc_clksel   : std_logic;
  signal vidproc_ttx      : std_logic;
  signal vidproc_pe       : std_logic;
  signal vidproc_p        : std_logic_vector(2 downto 0);
  signal vidproc_p2       : std_logic_vector(2 downto 0);

  signal lp_stb           : std_logic;

  signal paddle_btn       : std_logic_vector(1 downto 0);
  signal paddle_eoc       : std_logic;

  signal sg_clken         : std_logic;
  signal sg_pcm           : std_logic_vector(1 downto 0);

  signal opt_mode         : std_logic_vector(2 downto 0);  -- startup options: video mode (0-7)
  signal opt_boot         : std_logic;                     -- startup options: 1 = boot on BREAK, 0 = boot on SHIFT BREAK
  signal opt_disc         : std_logic_vector(1 downto 0);  -- startup options: disc timing
  signal opt_spare        : std_logic;                     -- startup options: spare
  signal opt_dfs_nfs      : std_logic;                     -- startup options: 1 = DFS, 0 = NFS

  --------------------------------------------------------------------------------
  -- keyboard

  signal ps2_clk_i        : std_logic;                     -- PS/2 serial clock in
  signal ps2_clk_o        : std_logic;                     -- PS/2 serial clock out
  signal ps2_data_i       : std_logic;                     -- PS/2 serial data in
  signal ps2_data_o       : std_logic;                     -- PS/2 serial data out

  --------------------------------------------------------------------------------
  -- HDMI audio and video out

  signal hdtv_rst_d       : std_logic;                     -- pixel clock synchronous reset, before buffer/register
  signal hdtv_rst         : std_logic;                     -- pixel clock synchronous reset
  signal hdtv_clk         : std_logic;                     -- pixel clock (148.5 MHz for 1080p50)
  signal hdtv_clk_x5      : std_logic;                     -- pixel clock x5 for HDMI serialisers

  signal hdtv_mode        : std_logic_vector(2 downto 0);
  signal hdtv_mode_clksel : std_logic_vector(1 downto 0);
  signal hdtv_mode_vic    : std_logic_vector(7 downto 0);
  signal hdtv_mode_pixrep : std_logic;
  signal hdtv_mode_aspect : std_logic_vector(1 downto 0);
  signal hdtv_mode_vs_pol : std_logic;
  signal hdtv_mode_hs_pol : std_logic;

  signal hdtv_vs          : std_logic;                     -- HDTV vertical sync
  signal hdtv_hs          : std_logic;                     -- HDTV horizontal sync
  signal hdtv_de          : std_logic;                     -- HDTV display enable
  signal hdtv_r           : std_logic_vector(7 downto 0);  -- HDTV red
  signal hdtv_g           : std_logic_vector(7 downto 0);  -- HDTV green
  signal hdtv_b           : std_logic_vector(7 downto 0);  -- HDTV blue

  signal hdtv_lock        : std_logic;

  signal pcm_rst          : std_logic;                     -- audio clock domain reset
  signal pcm_clk          : std_logic;                     -- audio clock (12.288 MHz)
  signal pcm_clken        : std_logic;                     -- audio clock enable @ 48kHz
  signal pcm_l            : std_logic_vector(15 downto 0); -- left channel  } audio sample,
  signal pcm_r            : std_logic_vector(15 downto 0); -- right channel } signed 16 bit

  signal tmds             : slv_9_0_t(0 to 2);             -- HDMI parallel TMDS symbols

--------------------------------------------------------------------------------

begin

  --------------------------------------------------------------------------------
  -- LEDs and switches

  led(0) <= led_capslock;
  led(1) <= led_shiftlock;
  led(2) <= led_motor;
  led(3) <= '0';
  led(4) <= '0';
  led(5) <= '0';
  led(6) <= '0';
  led(7) <= '0';

  opt_mode    <= "111"; -- mode 7
  opt_boot    <= '1';   -- boot on SHIFT BREAK
  opt_disc    <= "11";  -- default
  opt_spare   <= '1';
  opt_dfs_nfs <= '1';   -- DFS

  with sw(2 downto 0) select hdtv_mode <=
        HDTV_MODE_1080p when "100",
        HDTV_MODE_1080i when "011",
        HDTV_MODE_720p  when "010",
        HDTV_MODE_576p  when "001",
        HDTV_MODE_576i  when others;

  --------------------------------------------------------------------------------
  -- main system

  MMCM_SYS: component mmcm
    generic map (
      mul         => 48.0,
      div         => 5,
      num_outputs => 4,
      odiv0       => 10.0,
      odiv        => (20,30,120,0,0,0),
      duty_cycle  => (0.5,0.5,0.3,0.5,0.5,0.5,0.5)
    )
    port map (
      rsti        => not btn_rst_n,
      clki        => clki_100m,
      rsto        => sys_rst,
      clko(0)     => sys_clk_96m,
      clko(1)     => sys_clk_48m,
      clko(2)     => sys_clk_32m,
      clko(3)     => sys_clk_8m
    );

  MAIN: component bpp
    port map (
      sys_rst       => sys_rst,
      sys_clk_96m   => sys_clk_96m,
      sys_clk_48m   => sys_clk_48m,
      sys_clk_32m   => sys_clk_32m,
      sys_clk_8m    => sys_clk_8m,
      led_capslock  => led_capslock,
      led_shiftlock => led_shiftlock,
      led_motor     => led_motor,
      kbd_clken     => kbd_clken,
      kbd_rst       => kbd_rst,
      kbd_break     => kbd_break,
      kbd_load      => kbd_load,
      kbd_row       => kbd_row,
      kbd_col       => kbd_col,
      kbd_press     => kbd_press,
      kbd_irq       => kbd_irq,
      crtc_clken    => crtc_clken,
      crtc_clksel   => crtc_clksel,
      crtc_rst      => crtc_rst,
      crtc_f        => crtc_f,
      crtc_vs       => crtc_vs,
      crtc_hs       => crtc_hs,
      crtc_de       => crtc_de,
      crtc_oe       => crtc_oe,
      vidproc_clken => vidproc_clken,
      vidproc_rst   => vidproc_rst,
      vidproc_ttx   => vidproc_ttx,
      vidproc_pe    => vidproc_pe,
      vidproc_p     => vidproc_p,
      vidproc_p2    => vidproc_p2,
      lp_stb        => lp_stb,
      paddle_btn    => paddle_btn,
      paddle_eoc    => paddle_eoc,
      sg_clken      => sg_clken,
      sg_pcm        => sg_pcm
    );

  -- light pen and paddle not yet supported
  lp_stb     <= '0';
  paddle_btn <= (others => '0');
  paddle_eoc <= '0';

  --------------------------------------------------------------------------------
  -- PS/2 keyboard

  PS2: component bpp_kbd_ps2
    port map (
      clk           => sys_clk_8m,
      clken         => kbd_clken,
      rst           => kbd_rst,
      ps2_clk_i     => ps2_clk_i,
      ps2_clk_o     => ps2_clk_o,
      ps2_data_i    => ps2_data_i,
      ps2_data_o    => ps2_data_o,
      opt_mode      => opt_mode,
      opt_boot      => opt_boot,
      opt_disc      => opt_disc,
      opt_spare     => opt_spare,
      opt_dfs_nfs   => opt_dfs_nfs,
      led_capslock  => led_capslock,
      led_shiftlock => led_shiftlock,
      led_motor     => led_motor,
      kbd_break     => kbd_break,
      kbd_load      => kbd_load,
      kbd_row       => kbd_row,
      kbd_col       => kbd_col,
      kbd_press     => kbd_press,
      kbd_irq       => kbd_irq
    );

  ps2_clk   <= '0' when ps2_clk_o = '0' else 'Z';
  ps2_clk_i <= ps2_clk;

  ps2_data   <= '0' when ps2_data_o = '0' else 'Z';
  ps2_data_i <= ps2_data;

  --------------------------------------------------------------------------------
  -- BBC micro video out => HDTV parallel video

  MMCM_HDTV: component video_out_clock
    generic map (
      fref    => 100.0
    )
    port map (
      rsti    => not btn_rst_n,
      clki    => clki_100m,
      sel     => hdtv_mode_clksel,
      rsto    => hdtv_rst_d,
      clko    => hdtv_clk,
      clko_x5 => hdtv_clk_x5
    );

  DO_HDTV_RST: process (hdtv_clk) is
  begin
    if rising_edge(hdtv_clk) then
      hdtv_rst <= hdtv_rst_d; -- should allow register duplication => better timing closure
    end if;
  end process DO_HDTV_RST;

  HDTV: component bpp_hdtv
    port map (
      crtc_clk         => sys_clk_8m,
      crtc_clken       => crtc_clken,
      crtc_rst         => crtc_rst,
      crtc_clksel      => crtc_clksel,
      crtc_f           => crtc_f,
      crtc_vs          => crtc_vs,
      crtc_hs          => crtc_hs,
      crtc_de          => crtc_de,
      crtc_oe          => crtc_oe,
      vidproc_clk      => sys_clk_48m,
      vidproc_clken    => vidproc_clken,
      vidproc_rst      => vidproc_rst,
      vidproc_ttx      => vidproc_ttx,
      vidproc_pe       => vidproc_pe,
      vidproc_p        => vidproc_p,
      vidproc_p2       => vidproc_p2,
      hdtv_mode        => hdtv_mode,
      hdtv_mode_clksel => hdtv_mode_clksel,
      hdtv_mode_vic    => hdtv_mode_vic,
      hdtv_mode_pixrep => hdtv_mode_pixrep,
      hdtv_mode_aspect => hdtv_mode_aspect,
      hdtv_mode_vs_pol => hdtv_mode_vs_pol,
      hdtv_mode_hs_pol => hdtv_mode_hs_pol,
      hdtv_clk         => hdtv_clk,
      hdtv_rst         => hdtv_rst,
      hdtv_vs          => hdtv_vs,
      hdtv_hs          => hdtv_hs,
      hdtv_de          => hdtv_de,
      hdtv_r           => hdtv_r,
      hdtv_g           => hdtv_g,
      hdtv_b           => hdtv_b,
      hdtv_lock        => hdtv_lock
    );

  --------------------------------------------------------------------------------
  -- BBC micro sound generator => PCM audio

  MMCM_PCM: component mmcm
    generic map (
      mul         => 48.0,
      div         => 5,
      num_outputs => 1,
      odiv0       => 78.125
    )
    port map (
      rsti        => not btn_rst_n,
      clki        => clki_100m,
      rsto        => pcm_rst,
      clko(0)     => pcm_clk        -- 12.288 MHz
    );

  RESAMPLE: component bpp_resample
    port map (
      in_clk    => sys_clk_8m,
      in_clken  => sg_clken,
      in_pcm    => sg_pcm,
      out_clk   => pcm_clk,
      out_clken => pcm_clken,
      out_rst   => pcm_rst,
      out_l     => pcm_l,
      out_r     => pcm_r
    );

  --------------------------------------------------------------------------------
  -- HDTV parallel video and PCM parallel audio to HDMI parallel TMDS symbols

  HDMI: component bpp_hdtv_pcm_to_hdmi
    port map (
      mode_vic    => hdtv_mode_vic,
      mode_clksel => hdtv_mode_clksel,
      mode_pixrep => hdtv_mode_pixrep,
      mode_aspect => hdtv_mode_aspect,
      mode_vs_pol => hdtv_mode_vs_pol,
      mode_hs_pol => hdtv_mode_hs_pol,
      hdtv_clk    => hdtv_clk,
      hdtv_rst    => hdtv_rst,
      hdtv_vs     => hdtv_vs,
      hdtv_hs     => hdtv_hs,
      hdtv_de     => hdtv_de,
      hdtv_r      => hdtv_r,
      hdtv_g      => hdtv_g,
      hdtv_b      => hdtv_b,
      pcm_clk     => pcm_clk,
      pcm_clken   => pcm_clken,
      pcm_rst     => pcm_rst,
      pcm_l       => pcm_l,
      pcm_r       => pcm_r,
      hdmi_tmds   => tmds
    );

  --------------------------------------------------------------------------------
  -- TMDS parallel to serial

  HDMI_CLK: component serialiser_10to1_selectio
    port map (
      rst    => hdtv_rst,
      clk    => hdtv_clk,
      clk_x5 => hdtv_clk_x5,
      d      => "0000011111",
      out_p  => hdmi_tx_clk_p,
      out_n  => hdmi_tx_clk_n
    );

  gen_hdmi_d: for i in 0 to 2 generate

    HDMI_D: component serialiser_10to1_selectio
      port map (
        rst    => hdtv_rst,
        clk    => hdtv_clk,
        clk_x5 => hdtv_clk_x5,
        d      => tmds(i),
        out_p  => hdmi_tx_d_p(i),
        out_n  => hdmi_tx_d_n(i)
      );

  end generate gen_hdmi_d;

  --------------------------------------------------------------------------------
  -- unused I/O

  oled_res_n   <= '0';
  oled_d_c     <= '0';
  oled_sclk    <= '0';
  oled_sdin    <= '0';
  ac_mclk      <= '0';
  ac_dac_sdata <= '0';
  uart_rx_out  <= '1';
  eth_rst_n    <= '0';
  ftdi_rd_n    <= '1';
  ftdi_wr_n    <= '1';
  ftdi_siwu_n  <= '1';
  ftdi_oe_n    <= '1';
  ps2_clk      <= 'Z';
  ps2_data     <= 'Z';
  qspi_cs_n    <= '1';
  ddr3_reset_n <= '0';

--------------------------------------------------------------------------------

end architecture synth;
