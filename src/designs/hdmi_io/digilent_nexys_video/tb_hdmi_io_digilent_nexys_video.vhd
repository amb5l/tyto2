--------------------------------------------------------------------------------
-- tb_hdmi_io_digilent_nexys_video.vhd                                        --
-- Simulation testbench for hdmi_io_digilent_nexys_video.vhd.                 --
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
  use ieee.numeric_std.all;

library std;
  use std.env.all;

library work;
  use work.tyto_types_pkg.all;
  use work.video_mode_pkg.all;
  use work.video_out_timing_pkg.all;
  use work.video_out_test_pattern_pkg.all;

entity tb_hdmi_io_digilent_nexys_video is
end entity tb_hdmi_io_digilent_nexys_video;

architecture sim of tb_hdmi_io_digilent_nexys_video is

  type tmds_dc_t is array(0 to 2) of integer range -4 to 4;

  constant TDELAY_HDMI : time := 1 ns; -- data delay from pixel clock
  constant TSKEW_HDMI  : time := 5 ns; -- inter channel data skew

  signal clki_100m          : std_logic;
  signal btn_rst_n          : std_logic;
  signal led                : std_logic_vector(7 downto 0);

  signal tpg_mode           : std_logic_vector(3 downto 0);
  signal tpg_mode_clk_sel   : std_logic_vector(1 downto 0);  -- pixel frequency select
  signal tpg_mode_dmt       : std_logic;                     -- 1 = DMT, 0 = CEA
  signal tpg_mode_id        : std_logic_vector(7 downto 0);  -- DMT ID or CEA/CTA VIC
  signal tpg_mode_pix_rep   : std_logic;                     -- 1 = pixel doubling/repetition
  signal tpg_mode_aspect    : std_logic_vector(1 downto 0);  -- 0x = normal, 10 = force 16:9, 11 = force 4:3
  signal tpg_mode_interlace : std_logic;                     -- interlaced/progressive scan
  signal tpg_mode_v_tot     : std_logic_vector(10 downto 0); -- vertical total lines (must be odd if interlaced)
  signal tpg_mode_v_act     : std_logic_vector(10 downto 0); -- vertical total lines (must be odd if interlaced)
  signal tpg_mode_v_sync    : std_logic_vector(2 downto 0);  -- vertical sync width
  signal tpg_mode_v_bp      : std_logic_vector(5 downto 0);  -- vertical back porch
  signal tpg_mode_h_tot     : std_logic_vector(11 downto 0); -- horizontal total
  signal tpg_mode_h_act     : std_logic_vector(10 downto 0); -- vertical total lines (must be odd if interlaced)
  signal tpg_mode_h_sync    : std_logic_vector(6 downto 0);  -- horizontal sync width
  signal tpg_mode_h_bp      : std_logic_vector(7 downto 0);  -- horizontal back porch
  signal tpg_mode_vs_pol    : std_logic;                     -- vertical sync polarity (1 = high)
  signal tpg_mode_hs_pol    : std_logic;                     -- horizontal sync polarity (1 = high)

  signal tpg_pix_rst        : std_logic;
  signal tpg_t10            : time;                          -- TMDS serial bit time (pixel period / 10)
  signal tpg_topen          : time;                          -- TMDS serial bit eye open time
  signal tpg_pix_clk        : std_logic;
  signal tpg_pix_clk_x5     : std_logic;

  signal tpg_raw_f          : std_logic;                     -- field ID
  signal tpg_raw_vs         : std_logic;                     -- vertical sync
  signal tpg_raw_hs         : std_logic;                     -- horizontal sync
  signal tpg_raw_vblank     : std_logic;                     -- vertical blank
  signal tpg_raw_hblank     : std_logic;                     -- horizontal blank
  signal tpg_raw_ax         : std_logic_vector(11 downto 0); -- active area X (signed)
  signal tpg_raw_ay         : std_logic_vector(11 downto 0); -- active area Y (signed)

  signal tpg_vga_vs         : std_logic;                     -- vertical sync
  signal tpg_vga_hs         : std_logic;                     -- horizontal sync
  signal tpg_vga_vblank     : std_logic;                     -- vertical blank
  signal tpg_vga_hblank     : std_logic;                     -- horizontal blank
  signal tpg_vga_r          : std_logic_vector(7 downto 0);  -- red
  signal tpg_vga_g          : std_logic_vector(7 downto 0);  -- green
  signal tpg_vga_b          : std_logic_vector(7 downto 0);  -- blue
  signal tpg_vga_de         : std_logic;
  signal tpg_vga_c          : std_logic_vector(1 downto 0);
  signal tpg_vga_c0         : std_logic_vector(1 downto 0);

  signal tpg_tmds_p         : slv10_vector(0 to 2);          -- TMDS parallel (character)
  signal tpg_tmds_dc        : tmds_dc_t := (others => 0);    -- TMDS encode DC balance counter
  signal tpg_tmds_sr        : slv10_vector(0 to 2);
  signal tpg_tmds_s         : std_logic_vector(0 to 2);

  signal hdmi_rx_clk_p      : std_logic;
  signal hdmi_rx_clk_n      : std_logic;
  signal hdmi_rx_d_p        : std_logic_vector(0 to 2);
  signal hdmi_rx_d_n        : std_logic_vector(0 to 2);

  signal hdmi_tx_clk_p      : std_logic;
  signal hdmi_tx_clk_n      : std_logic;
  signal hdmi_tx_d_p        : std_logic_vector(0 to 2);
  signal hdmi_tx_d_n        : std_logic_vector(0 to 2);

  signal data_pstb          : std_logic;
  signal data_hb            : slv_7_0_t(0 to 3);
  signal data_hb_ok         : std_logic;
  signal data_sb            : slv_7_0_2d_t(0 to 3, 0 to 7);
  signal data_sb_ok         : std_logic_vector(0 to 3);

  signal cap_vga_rst        : std_logic;
  signal cap_vga_clk        : std_logic;
  signal cap_vga_vs         : std_logic;
  signal cap_vga_hs         : std_logic;
  signal cap_vga_de         : std_logic;
  signal cap_vga_r          : std_logic_vector(7 downto 0);
  signal cap_vga_g          : std_logic_vector(7 downto 0);
  signal cap_vga_b          : std_logic_vector(7 downto 0);

  signal cap_rst            : std_logic;
  signal cap_stb            : std_logic;

  component hdmi_io_digilent_nexys_video is
    port (
      clki_100m     : in    std_logic;
      led           : out   std_logic_vector(7 downto 0);
      btn_rst_n     : in    std_logic;
      oled_res_n    : out   std_logic;
      oled_d_c      : out   std_logic;
      oled_sclk     : out   std_logic;
      oled_sdin     : out   std_logic;
      hdmi_rx_clk_p : in    std_logic;
      hdmi_rx_clk_n : in    std_logic;
      hdmi_rx_d_p   : in    std_logic_vector(0 to 2);
      hdmi_rx_d_n   : in    std_logic_vector(0 to 2);
      hdmi_rx_txen  : out   std_logic;
      hdmi_tx_clk_p : out   std_logic;
      hdmi_tx_clk_n : out   std_logic;
      hdmi_tx_d_p   : out   std_logic_vector(0 to 2);
      hdmi_tx_d_n   : out   std_logic_vector(0 to 2);
      ac_mclk       : out   std_logic;
      ac_dac_sdata  : out   std_logic;
      uart_rx_out   : out   std_logic;
      eth_rst_n     : out   std_logic;
      ftdi_rd_n     : out   std_logic;
      ftdi_wr_n     : out   std_logic;
      ftdi_siwu_n   : out   std_logic;
      ftdi_oe_n     : out   std_logic;
      qspi_cs_n     : out   std_logic;
      ddr3_reset_n  : out   std_logic
    );
  end component hdmi_io_digilent_nexys_video;

  function nbits(
    b : std_logic;
    v : std_logic_vector
  ) return integer is
    variable n : integer;
  begin
    n := 0;
    for i in v'low to v'high loop
      if v(i) = b then
        n := n+1;
      end if;
    end loop;
    return n;
  end function;

  function sl_to_int(b : std_logic) return integer is
  begin
    if b = '1' then return 1; else return 0; end if;
  end function sl_to_int;

  procedure dvi_encode(
    signal de  : in    std_logic;
    signal d   : in    std_logic_vector(7 downto 0);
    signal c   : in    std_logic_vector(1 downto 0);
    signal q   : out   std_logic_vector(9 downto 0);
    signal cnt : inout integer
  ) is
    variable q_m : std_logic_vector(8 downto 0);
    variable q_out : std_logic_vector(9 downto 0);
  begin
    q_m(0) := d(0);
    if (nbits('1',d) > 4)
    or ((nbits('1',d) = 4) and (d(0) = '0'))
    then
      for i in 1 to 7 loop
        q_m(i) := q_m(i-1) xnor d(i);
      end loop;
      q_m(8) := '0';
    else
      for i in 1 to 7 loop
        q_m(i) := q_m(i-1) xor d(i);
      end loop;
      q_m(8) := '1';
    end if;
    if de = '1' then
      if (cnt = 0)
      or ((nbits('1',q_m(7 downto 0)) = nbits('0',q_m(7 downto 0))))
      then
        q_out(9) := not q_m(8);
        q_out(8) := q_m(8);
        if q_m(8) = '1' then
          q_out(7 downto 0) := q_m(7 downto 0);
        else
          q_out(7 downto 0) := not q_m(7 downto 0);
        end if;
        if q_m(8) = '0' then
          cnt <= cnt + nbits('0',q_m(7 downto 0)) - nbits('1',q_m(7 downto 0));
        else
          cnt <= cnt + nbits('1',q_m(7 downto 0)) - nbits('0',q_m(7 downto 0));
        end if;
      else
        if ((cnt > 0) and (nbits('1',q_m(7 downto 0)) > nbits('0',q_m(7 downto 0))))
        or ((cnt < 0) and (nbits('0',q_m(7 downto 0)) > nbits('1',q_m(7 downto 0))))
        then
          q_out(9) := '1';
          q_out(8) := q_m(8);
          q_out(7 downto 0) := not q_m(7 downto 0);
          cnt <= cnt + (2 * sl_to_int(q_m(8))) + nbits('0',q_m(7 downto 0)) - nbits('1',q_m(7 downto 0));
        else
          q_out(9) := '0';
          q_out(8) := q_m(8);
          q_out(7 downto 0) := q_m(7 downto 0);
          cnt <= cnt - (2 * sl_to_int(not q_m(8))) + nbits('1',q_m(7 downto 0)) - nbits('0',q_m(7 downto 0));
        end if;
      end if;
    else
      case c is
        when "00"   => q_out := "1101010100";
        when "01"   => q_out := "0010101011";
        when "10"   => q_out := "0101010100";
        when "11"   => q_out := "1010101011";
        when others => q_out := "XXXXXXXXXX";
      end case;
    end if;
    q <= q_out;
  end procedure dvi_encode;

begin

  clki_100m <=
               '1' after 5 ns when clki_100m = '0' else
               '0' after 5 ns when clki_100m = '1' else
               '0';

  -- main process
  TEST: process is
    constant progress_interval : time := 1 ms;
  begin
    tpg_mode <= mode_640x480p60;
    btn_rst_n <= '0';
    cap_rst   <= '1';
    wait for 20 ns;
    btn_rst_n <= '1';
    cap_rst   <= '0';
    loop
      wait until rising_edge(cap_stb) for progress_interval;
      report "waiting...";
      if cap_stb'event then
        report "capture complete";
        exit;
      end if;
    end loop;
    finish;
  end process TEST;

  -- lookup table: expand mode number to detailed timings for that mode
  VIDEO_MODE: entity work.video_mode
    port map (
      mode      => tpg_mode,
      clk_sel   => tpg_mode_clk_sel,
      dmt       => tpg_mode_dmt,
      id        => tpg_mode_id,
      pix_rep   => tpg_mode_pix_rep,
      aspect    => tpg_mode_aspect,
      interlace => tpg_mode_interlace,
      v_tot     => tpg_mode_v_tot,
      v_act     => tpg_mode_v_act,
      v_sync    => tpg_mode_v_sync,
      v_bp      => tpg_mode_v_bp,
      h_tot     => tpg_mode_h_tot,
      h_act     => tpg_mode_h_act,
      h_sync    => tpg_mode_h_sync,
      h_bp      => tpg_mode_h_bp,
      vs_pol    => tpg_mode_vs_pol,
      hs_pol    => tpg_mode_hs_pol
    );

  -- video clock (25.2MHz, 27MHz, 74.25MHz or 148.5MHz)

  with tpg_mode_clk_sel select tpg_t10 <=
      673 ps  when "11",
      1347 ps when "10",
      3705 ps when "01",
      3968 ps when others;

  tpg_topen <= tpg_t10 / 4; -- 25% is aggressive!

  tpg_pix_clk <=
          '1' after 5*tpg_t10 when tpg_pix_clk = '0' else
          '0' after 5*tpg_t10 when tpg_pix_clk = '1' else
          '0';

  tpg_pix_clk_x5 <=
             '1' after tpg_t10 when tpg_pix_clk_x5 = '0' else
             '0' after tpg_t10 when tpg_pix_clk_x5 = '1' else
             '0';

  process(tpg_mode_clk_sel)
  begin
    if tpg_mode_clk_sel'event then
      tpg_pix_rst <= '1', '0' after 100 ns;
    end if;
  end process;

  -- basic video timing generation
  VIDEO_TIMING: component video_out_timing
    port map (
      rst       => tpg_pix_rst,
      clk       => tpg_pix_clk,
      pix_rep   => tpg_mode_pix_rep,
      interlace => tpg_mode_interlace,
      v_tot     => tpg_mode_v_tot,
      v_act     => tpg_mode_v_act,
      v_sync    => tpg_mode_v_sync,
      v_bp      => tpg_mode_v_bp,
      h_tot     => tpg_mode_h_tot,
      h_act     => tpg_mode_h_act,
      h_sync    => tpg_mode_h_sync,
      h_bp      => tpg_mode_h_bp,
      genlock   => '0',
      genlocked => open,
      f         => tpg_raw_f,
      vs        => tpg_raw_vs,
      hs        => tpg_raw_hs,
      vblank    => tpg_raw_vblank,
      hblank    => tpg_raw_hblank,
      ax        => tpg_raw_ax,
      ay        => tpg_raw_ay
    );

  -- test pattern generator
  TEST_PATTERN: component video_out_test_pattern
    port map (
      rst        => tpg_pix_rst,
      clk        => tpg_pix_clk,
      pix_rep    => tpg_mode_pix_rep,
      v_act      => tpg_mode_v_act,
      h_act      => tpg_mode_h_act,
      raw_vs     => tpg_raw_vs,
      raw_hs     => tpg_raw_hs,
      raw_vblank => tpg_raw_vblank,
      raw_hblank => tpg_raw_hblank,
      raw_ax     => tpg_raw_ax,
      raw_ay     => tpg_raw_ay,
      vga_vs     => tpg_vga_vs,
      vga_hs     => tpg_vga_hs,
      vga_vblank => tpg_vga_vblank,
      vga_hblank => tpg_vga_hblank,
      vga_r      => tpg_vga_r,
      vga_g      => tpg_vga_g,
      vga_b      => tpg_vga_b,
      vga_ax     => open,
      vga_ay     => open
    );
  tpg_vga_de <= tpg_vga_vblank nor tpg_vga_hblank;

  -- TMDS encode
  process(tpg_vga_de,tpg_vga_b,tpg_vga_g,tpg_vga_r,tpg_vga_vs,tpg_vga_hs)
  begin
    tpg_vga_c  <= tpg_vga_vs & tpg_vga_hs;
    tpg_vga_c0 <= "00";
    dvi_encode(tpg_vga_de, tpg_vga_b, tpg_vga_c,  tpg_tmds_p(0), tpg_tmds_dc(0));
    dvi_encode(tpg_vga_de, tpg_vga_g, tpg_vga_c0, tpg_tmds_p(1), tpg_tmds_dc(1));
    dvi_encode(tpg_vga_de, tpg_vga_r, tpg_vga_c0, tpg_tmds_p(2), tpg_tmds_dc(2));
  end process;

  -- TMDS serialise
  process(tpg_pix_clk,tpg_pix_clk_x5)
  begin
    if rising_edge(tpg_pix_clk) then
      tpg_tmds_sr <= tpg_tmds_p;
    elsif tpg_pix_clk_x5'event then
      for i in 0 to 2 loop
        tpg_tmds_sr(i) <= tpg_tmds_sr(i)(8 downto 0) & 'X';
      end loop;
    end if;
  end process;

  -- TMDS serial eye open/close
  process(tpg_pix_clk_x5)
  begin
    for i in 0 to 2 loop
      -- tpg_tmds_s(i) <= tpg_tmds_sr(i)(9), 'X' after tpg_topen;
      tpg_tmds_s(i) <= tpg_tmds_sr(i)(9);
    end loop;
  end process;

  -- HDMI clock and data (with skew)
  hdmi_rx_clk_p  <=     tpg_pix_clk;
  hdmi_rx_clk_n  <= not tpg_pix_clk;
  hdmi_rx_d_p(0) <= transport     tpg_tmds_s(0) after TDELAY_HDMI;
  hdmi_rx_d_n(0) <= transport not tpg_tmds_s(0) after TDELAY_HDMI;
  hdmi_rx_d_p(1) <= transport     tpg_tmds_s(1) after TDELAY_HDMI+TSKEW_HDMI;
  hdmi_rx_d_n(1) <= transport not tpg_tmds_s(1) after TDELAY_HDMI+TSKEW_HDMI;
  hdmi_rx_d_p(2) <= transport     tpg_tmds_s(2) after TDELAY_HDMI+TSKEW_HDMI+TSKEW_HDMI;
  hdmi_rx_d_n(2) <= transport not tpg_tmds_s(2) after TDELAY_HDMI+TSKEW_HDMI+TSKEW_HDMI;

  -- design under test
  DUT: component hdmi_io_digilent_nexys_video
    port map (
      clki_100m     => clki_100m,
      led           => led,
      btn_rst_n     => btn_rst_n,
      oled_res_n    => open,
      oled_d_c      => open,
      oled_sclk     => open,
      oled_sdin     => open,
      hdmi_rx_clk_p => hdmi_rx_clk_p,
      hdmi_rx_clk_n => hdmi_rx_clk_n,
      hdmi_rx_d_p   => hdmi_rx_d_p,
      hdmi_rx_d_n   => hdmi_rx_d_n,
      hdmi_rx_txen  => open,
      hdmi_tx_clk_p => hdmi_tx_clk_p,
      hdmi_tx_clk_n => hdmi_tx_clk_n,
      hdmi_tx_d_p   => hdmi_tx_d_p,
      hdmi_tx_d_n   => hdmi_tx_d_n,
      ac_mclk       => open,
      ac_dac_sdata  => open,
      uart_rx_out   => open,
      eth_rst_n     => open,
      ftdi_rd_n     => open,
      ftdi_wr_n     => open,
      ftdi_siwu_n   => open,
      ftdi_oe_n     => open,
      qspi_cs_n     => open,
      ddr3_reset_n  => open
    );

  DECODE: entity work.model_hdmi_decoder
    port map (
      rst        => cap_rst,
      hdmi_clk   => hdmi_tx_clk_p,
      hdmi_d     => hdmi_tx_d_p,
      data_pstb  => data_pstb,
      data_hb    => data_hb,
      data_hb_ok => data_hb_ok,
      data_sb    => data_sb,
      data_sb_ok => data_sb_ok,
      vga_rst    => cap_vga_rst,
      vga_clk    => cap_vga_clk,
      vga_vs     => cap_vga_vs,
      vga_hs     => cap_vga_hs,
      vga_de     => cap_vga_de,
      vga_p(2)   => cap_vga_r,
      vga_p(1)   => cap_vga_g,
      vga_p(0)   => cap_vga_b
    );

  CAPTURE: entity work.model_vga_sink
    port map (
      vga_rst  => cap_vga_rst,
      vga_clk  => cap_vga_clk,
      vga_vs   => cap_vga_vs,
      vga_hs   => cap_vga_hs,
      vga_de   => cap_vga_de,
      vga_r    => cap_vga_r,
      vga_g    => cap_vga_g,
      vga_b    => cap_vga_b,
      cap_rst  => cap_rst,
      cap_stb  => cap_stb,
      cap_name => "tb_hdmi_io_digilent_nexys_video"
    );

end architecture sim;
