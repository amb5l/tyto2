--------------------------------------------------------------------------------
-- hdmi_tpg.vhd                                                               --
-- HDMI video test pattern generator with audio test tone.                    --
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

package hdmi_tpg_pkg is

  component hdmi_tpg is
    generic (
      fclk       : real
    );
    port (

      rst        : in    std_logic;
      clk        : in    std_logic;

      mode_step  : in    std_logic;
      mode       : out   std_logic_vector(3 downto 0);
      dvi        : in    std_logic;

      heartbeat  : out   std_logic_vector(3 downto 0);
      status     : out   std_logic;

      hdmi_clk_p : out   std_logic;
      hdmi_clk_n : out   std_logic;
      hdmi_d_p   : out   std_logic_vector(0 to 2);
      hdmi_d_n   : out   std_logic_vector(0 to 2)

    );
  end component hdmi_tpg;

end package hdmi_tpg_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;
  use work.video_mode_pkg.all;
  use work.video_out_clock_pkg.all;
  use work.video_out_timing_pkg.all;
  use work.video_out_test_pattern_pkg.all;
  use work.sync_reg_pkg.all;
  use work.clkengen_pkg.all;
  use work.audio_out_test_tone_pkg.all;
  use work.vga_to_hdmi_pkg.all;
  use work.serialiser_10to1_selectio_pkg.all;

entity hdmi_tpg is
  generic (
    fclk       : real                                -- clock frequency (MHz), typically 100.0
  );
  port (

    rst        : in    std_logic;                    -- reference/system reset (synchronous)
    clk        : in    std_logic;                    -- reference/system clock

    mode_step  : in    std_logic;                    -- video mode step (e.g. button)
    mode       : out   std_logic_vector(3 downto 0); -- current video mode
    dvi        : in    std_logic;                    -- 1 = DVI, 0 = HDMI

    heartbeat  : out   std_logic_vector(3 downto 0); -- 4 bit count @ 8Hz (heartbeat for LEDs)
    status     : out   std_logic;                    -- MMCM lock status

    hdmi_clk_p : out   std_logic;                    -- HDMI (TMDS) clock output (+ve)
    hdmi_clk_n : out   std_logic;                    -- HDMI (TMDS) clock output (-ve)
    hdmi_d_p   : out   std_logic_vector(0 to 2);     -- HDMI (TMDS) data output channels 0..2 (+ve)
    hdmi_d_n   : out   std_logic_vector(0 to 2)      -- HDMI (TMDS) data output channels 0..2 (-ve)

  );
end entity hdmi_tpg;

architecture synth of hdmi_tpg is

  signal f_pix          : std_logic_vector(28 downto 0); -- pixel clock frequency (Hz)
  signal f_pcm          : std_logic_vector(19 downto 0); -- PCM sample frequency (Hz)
  signal f_pix_s        : std_logic_vector(28 downto 0); -- pixel clock frequency (Hz) synchronised

  signal clken_1khz     : std_logic;                     -- 1kHz clock enable

  signal heartbeat_i    : std_logic_vector(3 downto 0);  -- internal copy

  signal pix_rst        : std_logic;                     -- pixel clock domain reset
  signal pix_clk        : std_logic;                     -- pixel clock (25.2/27/74.25/148.5 MHz)
  signal pix_clk_a      : std_logic;                     -- additional/duplicate pixel clock for PCM, makes timing exceptions easier
  signal pix_clk_x5     : std_logic;                     -- serial clock = pixel clock x5

  signal mode_i         : std_logic_vector(3 downto 0);  -- internal copy
  signal mode_step_s    : std_logic_vector(0 to 1);      -- mode step input synchroniser
  signal mode_step_f    : std_logic;                     -- mode step input, filtered (debounced)
  signal mode_step_d    : std_logic;                     -- mode step input, filtered, delayed
  signal mode_rst       : std_logic;                     -- mode step related reset

  signal mode_clk_sel   : std_logic_vector(1 downto 0);  -- pixel frequency select
  signal mode_id        : std_logic_vector(7 downto 0);  -- DMT ID or CEA/CTA VIC
  signal mode_pix_rep   : std_logic;                     -- 1 = pixel doubling/repetition
  signal mode_aspect    : std_logic_vector(1 downto 0);  -- 0x = normal, 10 = force 16:9, 11 = force 4:3
  signal mode_interlace : std_logic;                     -- interlaced/progressive scan
  signal mode_v_tot     : std_logic_vector(10 downto 0); -- vertical total lines (must be odd if interlaced)
  signal mode_v_act     : std_logic_vector(10 downto 0); -- vertical total lines (must be odd if interlaced)
  signal mode_v_sync    : std_logic_vector(2 downto 0);  -- vertical sync width
  signal mode_v_bp      : std_logic_vector(5 downto 0);  -- vertical back porch
  signal mode_h_tot     : std_logic_vector(11 downto 0); -- horizontal total
  signal mode_h_act     : std_logic_vector(10 downto 0); -- vertical total lines (must be odd if interlaced)
  signal mode_h_sync    : std_logic_vector(6 downto 0);  -- horizontal sync width
  signal mode_h_bp      : std_logic_vector(7 downto 0);  -- horizontal back porch
  signal mode_vs_pol    : std_logic;                     -- vertical sync polarity (1 = high)
  signal mode_hs_pol    : std_logic;                     -- horizontal sync polarity (1 = high)

  signal raw_vs         : std_logic;                     -- vertical sync
  signal raw_hs         : std_logic;                     -- horizontal sync
  signal raw_vblank     : std_logic;                     -- vertical blank
  signal raw_hblank     : std_logic;                     -- horizontal blank
  signal raw_ax         : std_logic_vector(11 downto 0); -- active area X (signed)
  signal raw_ay         : std_logic_vector(11 downto 0); -- active area Y (signed)

  signal vga_vs         : std_logic;                     -- vertical sync
  signal vga_hs         : std_logic;                     -- horizontal sync
  signal vga_vblank     : std_logic;                     -- vertical blank
  signal vga_hblank     : std_logic;                     -- horizontal blank
  signal vga_r          : std_logic_vector(7 downto 0);  -- red
  signal vga_g          : std_logic_vector(7 downto 0);  -- green
  signal vga_b          : std_logic_vector(7 downto 0);  -- blue

  signal pcm_clken      : std_logic;                     -- audio clock enable @ 48kHz
  signal pcm_l          : std_logic_vector(15 downto 0); -- left channel  } audio sample,
  signal pcm_r          : std_logic_vector(15 downto 0); -- right channel } signed 16 bit
  signal pcm_acr        : std_logic;                     -- HDMI Audio Clock Regeneration packet strobe
  signal pcm_n          : std_logic_vector(19 downto 0); -- HDMI Audio Clock Regeneration packet N value
  signal pcm_cts        : std_logic_vector(19 downto 0); -- HDMI Audio Clock Regeneration packet CTS value

  signal tmds           : slv_9_0_t(0 to 2);             -- parallel TMDS channels

begin

  status <= not pix_rst; -- pixel clock MMCM locked

  DO_1KHZ: process (rst, clk) is
    variable counter : integer range 0 to 99999;
  begin
    if rst = '1' then
      counter    := 0;
      clken_1khz <= '0';
    elsif rising_edge(clk) then
      if counter = (1000*integer(fclk))-1 then
        counter    := 0;
        clken_1khz <= '1';
      else
        counter    := counter + 1;
        clken_1khz <= '0';
      end if;
    end if;
  end process DO_1KHZ;

  -- 4 bit counter @ 1Hz => 0.5Hz, 1Hz, 2Hz and 4Hz heartbeat pulses for LEDs
  DO_HEARTBEAT: process (rst, clk, clken_1khz) is
    variable counter : integer range 0 to 124;
  begin
    if rst = '1' then
      counter     := 0;
      heartbeat_i <= (others => '0');
    elsif rising_edge(clk) and clken_1khz = '1' then
      if counter = 124 then
        counter     := 0;
        heartbeat_i <= std_logic_vector(unsigned(heartbeat_i)+1);
      else
        counter := counter + 1;
      end if;
    end if;
  end process DO_HEARTBEAT;

  heartbeat <= heartbeat_i;

  -- increment mode on button press
  DO_MODE_STEP: process (rst, clk, clken_1khz) is
    variable counter : integer range 0 to 10; -- 10ms debounce
  begin
    if rst = '1' then
      counter     := 0;
      mode_step_s <= (others => '0');
      mode_step_f <= '0';
      mode_step_d <= '0';
      mode_i      <= x"0";
    elsif rising_edge(clk) then
      mode_rst    <= '0';
      mode_step_s <= mode_step & mode_step_s(0);
      if counter /= 0 then
        if clken_1khz = '1' then
          if counter = 5 then
            counter := 0;
          else
            counter := counter + 1;
          end if;
        end if;
      else
        if mode_step_s(1) /= mode_step_f then
          mode_step_f <= mode_step_s(1);
          counter     := 1;
        end if;
      end if;
      mode_step_d <= mode_step_f;
      if mode_step_d = '0' and mode_step_f = '1' then -- leading edge of button press
        mode_rst <= '1';
        if mode_i = x"E" then
          mode_i <= x"0";
        else
          mode_i <= std_logic_vector(unsigned(mode_i)+1);
        end if;
      end if;
    end if;
  end process DO_MODE_STEP;

  mode <= mode_i;

  -- lookup table: expand mode number to detailed timings for that mode
  VIDEO_MODE: entity work.video_mode
    port map (
      mode      => mode_i,
      clk_sel   => mode_clk_sel,
      dmt       => open,
      id        => mode_id,
      pix_rep   => mode_pix_rep,
      aspect    => mode_aspect,
      interlace => mode_interlace,
      v_tot     => mode_v_tot,
      v_act     => mode_v_act,
      v_sync    => mode_v_sync,
      v_bp      => mode_v_bp,
      h_tot     => mode_h_tot,
      h_act     => mode_h_act,
      h_sync    => mode_h_sync,
      h_bp      => mode_h_bp,
      vs_pol    => mode_vs_pol,
      hs_pol    => mode_hs_pol
    );

  -- reconfigurable MMCM: 25.2MHz, 27MHz, 74.25MHz or 148.5MHz
  VIDEO_CLOCK: component video_out_clock
    generic map (
      fref    => fclk
    )
    port map (
      rsti      => rst or mode_rst,
      clki      => clk,
      sel       => mode_clk_sel,
      rsto      => pix_rst,
      clko      => pix_clk,
      clko_a    => pix_clk_a,
      clko_x5   => pix_clk_x5
    );

  -- basic video timing generation
  VIDEO_TIMING: component video_out_timing
    port map (
      rst       => pix_rst,
      clk       => pix_clk,
      pix_rep   => mode_pix_rep,
      interlace => mode_interlace,
      v_tot     => mode_v_tot,
      v_act     => mode_v_act,
      v_sync    => mode_v_sync,
      v_bp      => mode_v_bp,
      h_tot     => mode_h_tot,
      h_act     => mode_h_act,
      h_sync    => mode_h_sync,
      h_bp      => mode_h_bp,
      genlock   => '0',
      genlocked => open,
      f         => open,
      vs        => raw_vs,
      hs        => raw_hs,
      vblank    => raw_vblank,
      hblank    => raw_hblank,
      ax        => raw_ax,
      ay        => raw_ay
    );

  -- test pattern generator
  TEST_PATTERN: component video_out_test_pattern
    port map (
      rst        => pix_rst,
      clk        => pix_clk,
      pix_rep    => mode_pix_rep,
      v_act      => mode_v_act,
      h_act      => mode_h_act,
      raw_vs     => raw_vs,
      raw_hs     => raw_hs,
      raw_vblank => raw_vblank,
      raw_hblank => raw_hblank,
      raw_ax     => raw_ax,
      raw_ay     => raw_ay,
      vga_vs     => vga_vs,
      vga_hs     => vga_hs,
      vga_vblank => vga_vblank,
      vga_hblank => vga_hblank,
      vga_r      => vga_r,
      vga_g      => vga_g,
      vga_b      => vga_b,
      vga_ax     => open,
      vga_ay     => open
    );

  with mode_clk_sel select f_pix <=
    std_logic_vector(to_unsigned(148500000,f_pix'length)) when "11",
    std_logic_vector(to_unsigned( 74250000,f_pix'length)) when "10",
    std_logic_vector(to_unsigned( 27000000,f_pix'length)) when "01",
    std_logic_vector(to_unsigned( 25200000,f_pix'length)) when others;

  SYNC: component sync_reg
    generic map (
      width => f_pix'length,
      depth => 2
    )
    port map (
      clk   => pix_clk,
      d     => f_pix,
      q     => f_pix_s
    );

  f_pcm <= std_logic_vector(to_unsigned(48000,f_pcm'length));

  AUDIO_CLKEN: component clkengen
    generic map (
      fclk_width   => f_pix'length,
      fclken_width => f_pcm'length
    )
    port map (
      fclk   => f_pix_s,
      fclken => f_pcm,
      rst    => pix_rst,
      clk    => pix_clk,
      clken  => pcm_clken
    );

  -- simple audio test tone
  AUDIO_TONE: component audio_out_test_tone
    port map (
      rst   => pix_rst,
      clk   => pix_clk_a,
      clken => pcm_clken,
      l     => pcm_l,
      r     => pcm_r
    );

  -- N and CTS values for HDMI Audio Clock Regeneration; depends on pixel clock
  -- these values correspond to 48kHz audio sample rate
  pcm_n <= std_logic_vector(to_unsigned(6144, pcm_n'length));
  with mode_clk_sel select pcm_cts <=
        std_logic_vector(to_unsigned(148500, pcm_cts'length)) when "11",
        std_logic_vector(to_unsigned(74250, pcm_cts'length)) when "10",
        std_logic_vector(to_unsigned(27000, pcm_cts'length)) when "01",
        std_logic_vector(to_unsigned(25200, pcm_cts'length)) when others;

  -- ACR packet rate should be 128fs/N = 1kHz
  DO_ACR: process (pix_rst, pix_clk_a, pcm_clken) is
    variable count : integer range 0 to 47;
  begin
    if pix_rst = '1' then
      count   := 0;
      pcm_acr <= '0';
    elsif rising_edge(pix_clk_a) and pcm_clken = '1' then
      pcm_acr <= '0';
      if count = 47 then
        count   := 0;
        pcm_acr <= '1';
      else
        count := count+1;
      end if;
    end if;
  end process DO_ACR;

  -- VGA to HDMI converter
  HDMI_CONVERTER: component vga_to_hdmi
    generic map (
      pcm_fs    => 48.0
    )
    port map (
      dvi       => dvi,
      vic       => mode_id,
      pix_rep   => mode_pix_rep,
      aspect    => mode_aspect,
      vs_pol    => mode_vs_pol,
      hs_pol    => mode_hs_pol,
      vga_rst   => pix_rst,
      vga_clk   => pix_clk,
      vga_vs    => vga_vs,
      vga_hs    => vga_hs,
      vga_de    => vga_vblank nor vga_hblank,
      vga_r     => vga_r,
      vga_g     => vga_g,
      vga_b     => vga_b,
      pcm_rst   => pix_rst,
      pcm_clk   => pix_clk_a,
      pcm_clken => pcm_clken,
      pcm_l     => pcm_l,
      pcm_r     => pcm_r,
      pcm_acr   => pcm_acr,
      pcm_n     => pcm_n,
      pcm_cts   => pcm_cts,
      tmds      => tmds
    );

  -- serialiser: in this design we use TMDS SelectIO outputs

  gen_hdmi_data: for i in 0 to 2 generate
  begin

    HDMI_DATA: component serialiser_10to1_selectio
      port map (
        rst    => pix_rst,
        clk    => pix_clk,
        clk_x5 => pix_clk_x5,
        d      => tmds(i),
        out_p  => hdmi_d_p(i),
        out_n  => hdmi_d_n(i)
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

end architecture synth;
