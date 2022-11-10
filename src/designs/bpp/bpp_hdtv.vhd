--------------------------------------------------------------------------------
-- bpp_hdtv.vhd                                                               --
-- BPP HDTV converter.                                                        --
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
--
-- BBC micro video output has 256 (modes 0,1,2,4,5) or 250 (modes 3, 6 and 7)
-- active lines per field. Each line has 40 (1 MHz) or 80 (2 MHz) character
-- cells max, corresponding to 40uS of active video. Let's overscan to catch the
-- output even if s/w moves it around a bit. So, let's capture 270 lines, and
-- 42uS per line (672 pixels @ 16 MHz). (This is handled by bpp_overscan.vhd.)
--
-- 1) Vertical Scaling
--
-- output        active | normal |  ttx   | scaled
-- mode          lines  | factor | factor | lines
-- -----------------------------------------------
-- 720x576i50   |   288 |   1:1  |  *1:2  |   270
-- 720x576p50   |   576 |   2:1  |   1:1  |   540
-- 1280x720p50  |   720 |   5:2  |   5:4  |   675
-- 1920x1080i50 |   540 |   2:1  |   1:1  |   540
-- 1920x1080p50 |  1080 |   4:1  |   2:1  |  1080
--
-- * The saa5050d has a scan doubling output - it applies x2 vertical
-- scaling. The scaling applied here therefore must be halved for teletext.
--
-- 2) Horizontal Scaling
--
-- For teletext (12 MHz) there are 504 source pixels. For other (16 MHz) modes
-- there are 672 source pixels.
--
-- output        active |  16M   |  12M   | scaled
-- mode          pixels | factor | factor | pixels
-- -----------------------------------------------
-- 720x576i50   | 1440  |   2:1  |   8:3  |  1344
-- 720x576p50   |  720  |   1:1  |   4:3  |   672
-- 1280x720p50  | 1280  |   5:4  |   5:3  |   840
-- 1920x1080i50 | 1920  |   2:1  |   8:3  |  1344
-- 1920x1080p50 | 1920  |   2:1  |   8:3  |  1344
--
-- 3) Buffer Size
--
-- The difference in the total active period of the input and output must be
-- absorbed by a buffer. The worst case is 1920x1080p, where the difference
-- is ~1.93 ms = ~46 input lines = ~29.5 kpixels.
-- Round up to a power of 2, allow 3 bits per pixel => 32k x 3 bits.
-- Vertical scaling by a non-integer factor requires reading from 2 lines
-- at once, so split buffer into even and odd source lines.
--
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package bpp_hdtv_pkg is

  -- supported display modes (all 50Hz)
  constant hdtv_mode_576i  : std_logic_vector(2 downto 0) := "000";
  constant hdtv_mode_576p  : std_logic_vector(2 downto 0) := "001";
  constant hdtv_mode_720p  : std_logic_vector(2 downto 0) := "010";
  constant hdtv_mode_1080i : std_logic_vector(2 downto 0) := "011";
  constant hdtv_mode_1080p : std_logic_vector(2 downto 0) := "100";

  component bpp_hdtv is
    port (

      crtc_clk         : in    std_logic;
      crtc_clken       : in    std_logic;
      crtc_rst         : in    std_logic;
      crtc_clksel      : in    std_logic;
      crtc_f           : in    std_logic;
      crtc_vs          : in    std_logic;
      crtc_hs          : in    std_logic;
      crtc_de          : in    std_logic;
      crtc_oe          : out   std_logic;

      vidproc_clk      : in    std_logic;
      vidproc_clken    : in    std_logic;
      vidproc_rst      : in    std_logic;
      vidproc_ttx      : in    std_logic;
      vidproc_pe       : in    std_logic;
      vidproc_p        : in    std_logic_vector(2 downto 0);
      vidproc_p2       : in    std_logic_vector(2 downto 0);

      hdtv_mode        : in    std_logic_vector(2 downto 0);
      hdtv_mode_clksel : out   std_logic_vector(1 downto 0);
      hdtv_mode_vic    : out   std_logic_vector(7 downto 0);
      hdtv_mode_pixrep : out   std_logic;
      hdtv_mode_aspect : out   std_logic_vector(1 downto 0);
      hdtv_mode_vs_pol : out   std_logic;
      hdtv_mode_hs_pol : out   std_logic;

      hdtv_clk         : in    std_logic;
      hdtv_rst         : in    std_logic;
      hdtv_vs          : out   std_logic;
      hdtv_hs          : out   std_logic;
      hdtv_de          : out   std_logic;
      hdtv_r           : out   std_logic_vector(7 downto 0);
      hdtv_g           : out   std_logic_vector(7 downto 0);
      hdtv_b           : out   std_logic_vector(7 downto 0);
      hdtv_lock        : out   std_logic

    );
  end component bpp_hdtv;

end package bpp_hdtv_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;
  use work.tyto_utils_pkg.all;
  use work.bpp_hdtv_pkg.all;
  use work.bpp_overscan_pkg.all;
  use work.bpp_genlock_pkg.all;
  use work.video_mode_pkg.all;
  use work.video_out_timing_pkg.all;
  use work.sync_reg_pkg.all;
  use work.ram_tdp_ar_pkg.all;

entity bpp_hdtv is
  port (

    crtc_clk         : in    std_logic;                    -- CRTC: clock        } 2 or 1
    crtc_clken       : in    std_logic;                    -- CRTC: clock enable } MHz
    crtc_rst         : in    std_logic;                    -- CRTC: reset
    crtc_clksel      : in    std_logic;                    -- CRTC: character clock select
    crtc_f           : in    std_logic;                    -- CRTC: field (0=first/odd/upper)
    crtc_vs          : in    std_logic;                    -- CRTC: vertical sync
    crtc_hs          : in    std_logic;                    -- CRTC: horizontal sync
    crtc_de          : in    std_logic;                    -- CRTC: display enable
    crtc_oe          : out   std_logic;                    -- CRTC: overscan enable

    vidproc_clk      : in    std_logic;                    -- VIDPROC: clock        } 16 or 12
    vidproc_clken    : in    std_logic;                    -- VIDPROC: clock enable } MHz
    vidproc_rst      : in    std_logic;                    -- VIDPROC: reset
    vidproc_ttx      : in    std_logic;                    -- VIDPROC: teletext mode
    vidproc_pe       : in    std_logic;                    -- VIDPROC: pixel enable
    vidproc_p        : in    std_logic_vector(2 downto 0); -- VIDPROC: pixel data
    vidproc_p2       : in    std_logic_vector(2 downto 0); -- VIDPROC: pixel data for 2nd line (scan doubling)

    hdtv_mode        : in    std_logic_vector(2 downto 0); -- HDTV: mode select
    hdtv_mode_clksel : out   std_logic_vector(1 downto 0); -- HDTV: clock select
    hdtv_mode_vic    : out   std_logic_vector(7 downto 0); -- HDTV: mode ID code
    hdtv_mode_pixrep : out   std_logic;                    -- HDTV: 1 = pixel repetition
    hdtv_mode_aspect : out   std_logic_vector(1 downto 0); -- HDTV: aspect ratio
    hdtv_mode_vs_pol : out   std_logic;                    -- HDTV: vsync polarity
    hdtv_mode_hs_pol : out   std_logic;                    -- HDTV: hsync polarity

    hdtv_clk         : in    std_logic;                    -- HDTV: clock
    hdtv_rst         : in    std_logic;                    -- HDTV: reset
    hdtv_vs          : out   std_logic;                    -- HDTV: vertical sync
    hdtv_hs          : out   std_logic;                    -- HDTV: horizontal sync
    hdtv_de          : out   std_logic;                    -- HDTV: display enable
    hdtv_r           : out   std_logic_vector(7 downto 0); -- HDTV: red (0-255)
    hdtv_g           : out   std_logic_vector(7 downto 0); -- HDTV: green (0-255)
    hdtv_b           : out   std_logic_vector(7 downto 0); -- HDTV: blue (0-255)
    hdtv_lock        : out   std_logic                     -- HDTV: genlock status

  );
end entity bpp_hdtv;

architecture synth of bpp_hdtv is

  --------------------------------------------------------------------------------

  signal   crtc_oe_i          : std_logic;                     -- crtc_oe, internal

  signal   vidproc_pe_1       : std_logic;
  signal   vidproc_odd        : std_logic;                     -- odd source line (not related to field ID)

  --------------------------------------------------------------------------------
  -- VTG related

  signal   vtg_mode           : std_logic_vector(3 downto 0);  -- VTG mode select
  signal   vtg_mode_clk_sel   : std_logic_vector(1 downto 0);  -- VTG mode: pixel frequency select
  signal   vtg_mode_dmt       : std_logic;                     -- VTG mode: 1 = DMT, 0 = CEA
  signal   vtg_mode_id        : std_logic_vector(7 downto 0);  -- VTG mode: DMT ID or CEA/CTA VIC
  signal   vtg_mode_pix_rep   : std_logic;                     -- VTG mode: 1 = pixel doubling/repetition
  signal   vtg_mode_aspect    : std_logic_vector(1 downto 0);  -- VTG mode: 0x = normal, 10 = force 16:9, 11 = force 4:3
  signal   vtg_mode_interlace : std_logic;                     -- VTG mode: interlaced/progressive scan
  signal   vtg_mode_v_tot     : std_logic_vector(10 downto 0); -- VTG mode: vertical total lines (must be odd if interlaced)
  signal   vtg_mode_v_act     : std_logic_vector(10 downto 0); -- VTG mode: vertical total lines (must be odd if interlaced)
  signal   vtg_mode_v_sync    : std_logic_vector(2 downto 0);  -- VTG mode: vertical sync width
  signal   vtg_mode_v_bp      : std_logic_vector(5 downto 0);  -- VTG mode: vertical back porch
  signal   vtg_mode_h_tot     : std_logic_vector(11 downto 0); -- VTG mode: horizontal total
  signal   vtg_mode_h_act     : std_logic_vector(10 downto 0); -- VTG mode: vertical total lines (must be odd if interlaced)
  signal   vtg_mode_h_sync    : std_logic_vector(6 downto 0);  -- VTG mode: horizontal sync width
  signal   vtg_mode_h_bp      : std_logic_vector(7 downto 0);  -- VTG mode: horizontal back porch
  signal   vtg_mode_vs_pol    : std_logic;                     -- VTG mode: vertical sync polarity (1 = high)
  signal   vtg_mode_hs_pol    : std_logic;                     -- VTG mode: horizontal sync polarity (1 = high)

  signal   vtg_genlock        : std_logic;                     -- genlock pulse to VTG
  signal   vtg_f              : std_logic;                     -- VTG: field ID
  signal   vtg_vs             : std_logic;                     -- VTG: vertical sync
  signal   vtg_hs             : std_logic;                     -- VTG: horizontal sync
  signal   vtg_vblank         : std_logic;                     -- VTG: vertical blank
  signal   vtg_hblank         : std_logic;                     -- VTG: horizontal blank
  signal   vtg_de             : std_logic;                     -- VTG: display enable
  signal   vtg_ax             : std_logic_vector(11 downto 0); -- VTG: active area X (signed)
  signal   vtg_ay             : std_logic_vector(11 downto 0); -- VTG: active area Y (signed)

  --------------------------------------------------------------------------------
  -- scaling related

  constant v_ovr              : integer := 7;
  constant h_ovr              : integer := 1;
  constant ram_size_log2      : integer := 15;                 -- 32k

  signal   vn                 : integer range 0 to 7;          -- vertical scale factor numerator   (output pixels)
  signal   vd                 : integer range 0 to 7;          -- vertical scale factor denominator (input pixels)
  signal   hn                 : integer range 0 to 15;         -- horizontal scale factor numerator   (output pixels)
  signal   hd                 : integer range 0 to 7;          -- horizontal scale factor denominator (input pixels)

  signal   v_act              : integer range 0 to 2047;
  signal   v_vis              : integer range 0 to 2047;
  signal   h_act              : integer range 0 to 2047;
  signal   h_vis              : integer range 0 to 2047;

  signal   vis_y_start        : integer range 0 to 31;
  signal   vis_y_end          : integer range 0 to 2047;
  signal   vis_x_start        : integer range 0 to 511;
  signal   vis_x_end          : integer range 0 to 2047;

  signal   crtc_vs_s          : std_logic;

  signal   ram_we0            : std_logic;
  signal   ram_wa0            : std_logic_vector(ram_size_log2-2 downto 0);
  signal   ram_wd0            : std_logic_vector(2 downto 0);
  signal   ram_ra0            : std_logic_vector(ram_size_log2-2 downto 0);
  signal   ram_ra0_s          : std_logic_vector(ram_size_log2-2 downto 0);
  signal   ram_rd0            : std_logic_vector(2 downto 0);
  signal   ram_rd0_l          : std_logic_vector(2 downto 0);

  signal   ram_we1            : std_logic;
  signal   ram_wa1            : std_logic_vector(ram_size_log2-2 downto 0);
  signal   ram_wd1            : std_logic_vector(2 downto 0);
  signal   ram_ra1            : std_logic_vector(ram_size_log2-2 downto 0);
  signal   ram_ra1_s          : std_logic_vector(ram_size_log2-2 downto 0);
  signal   ram_rd1            : std_logic_vector(2 downto 0);
  signal   ram_rd1_l          : std_logic_vector(2 downto 0);

  signal   ram_wsel           : std_logic;
  signal   ram_rsel           : std_logic;
  signal   ram_rce            : std_logic;

  signal   vidproc_ttx_s      : std_logic;                     -- synchronised copy
  signal   vis_y              : std_logic;                     -- visible region of display (vertical)
  signal   vis_x              : std_logic;                     -- visible region of display (horizontal)
  signal   vis                : std_logic;                     -- visible region of display

  signal   vtg_vs_s           : std_logic_vector(1 to 4);      -- pipeline delayed copies
  signal   vtg_hs_s           : std_logic_vector(1 to 4);      -- "
  signal   vtg_de_s           : std_logic_vector(1 to 4);      -- "
  signal   vis_s              : std_logic_vector(1 to 4);      -- "
  signal   ram_rsel_s         : std_logic_vector(4 to 4);      -- "
  signal   vi                 : integer range 0 to 7;          -- v scaler i
  signal   vw                 : integer range 0 to 7;          -- v scaler w
  signal   vadv               : std_logic;                     -- v scaler advance input
  signal   hi                 : integer range 0 to 15;         -- h scaler i
  signal   hw                 : integer range 0 to 7;          -- h scaler w
  signal   hadv               : std_logic;                     -- h scaler advance input
  signal   hp0                : slv_7_0_t(2 downto 0);         -- h scaled pixel from buffer 0
  signal   hp1                : slv_7_0_t(2 downto 0);         -- h scaled pixel from buffer 1
  signal   hdtv_p             : slv_7_0_t(2 downto 0);         -- output pixel (RGB)

--------------------------------------------------------------------------------

begin

  --------------------------------------------------------------------------------
  -- overscan CRTC/VIDPROC output (behave like a monitor)

  OVERSCAN: component bpp_overscan
    generic map (
      v_ovr  => v_ovr,
      h_ovr  => h_ovr
    )
    port map (
      clk    => crtc_clk,
      clken  => crtc_clken,
      rst    => crtc_rst,
      clksel => crtc_clksel,
      ttx    => vidproc_ttx,
      f      => crtc_f,
      vs     => crtc_vs,
      hs     => crtc_hs,
      en     => crtc_oe_i
    );

  crtc_oe <= crtc_oe_i;

  --------------------------------------------------------------------------------
  -- align CRTC/VIDPROC output with VTG below

  GENLOCK: component bpp_genlock
    port map (
      clk     => crtc_clk,
      clken   => crtc_clken,
      rst     => crtc_rst,
      f       => crtc_f,
      vs      => crtc_vs,
      hs      => crtc_hs,
      oe      => crtc_oe_i,
      genlock => vtg_genlock
    );

  --------------------------------------------------------------------------------
  -- VTG (video timing generator) and associated parameters

  with hdtv_mode select vtg_mode <=
        MODE_1920x1080p50 when hdtv_mode_1080p,
        MODE_1920x1080i50 when hdtv_mode_1080i,
        MODE_1280x720p50  when hdtv_mode_720p,
        MODE_720x576p50   when hdtv_mode_576p,
        MODE_720x576i50   when others;

  VTG_PARAMS: component video_mode
    port map (
      mode      => vtg_mode,
      clk_sel   => vtg_mode_clk_sel,
      dmt       => vtg_mode_dmt,
      id        => vtg_mode_id,
      pix_rep   => vtg_mode_pix_rep,
      aspect    => vtg_mode_aspect,
      interlace => vtg_mode_interlace,
      v_tot     => vtg_mode_v_tot,
      v_act     => vtg_mode_v_act,
      v_sync    => vtg_mode_v_sync,
      v_bp      => vtg_mode_v_bp,
      h_tot     => vtg_mode_h_tot,
      h_act     => vtg_mode_h_act,
      h_sync    => vtg_mode_h_sync,
      h_bp      => vtg_mode_h_bp,
      vs_pol    => vtg_mode_vs_pol,
      hs_pol    => vtg_mode_hs_pol
    );

  hdtv_mode_clksel <= vtg_mode_clk_sel;
  hdtv_mode_vic    <= vtg_mode_id;
  hdtv_mode_pixrep <= vtg_mode_pix_rep;
  hdtv_mode_aspect <= vtg_mode_aspect;
  hdtv_mode_vs_pol <= vtg_mode_vs_pol;
  hdtv_mode_hs_pol <= vtg_mode_hs_pol;

  VTG: component video_out_timing
    generic map (
      hold      => true
    )
    port map (
      rst       => hdtv_rst,
      clk       => hdtv_clk,
      pix_rep   => vtg_mode_pix_rep,
      interlace => vtg_mode_interlace,
      v_tot     => vtg_mode_v_tot,
      v_act     => vtg_mode_v_act,
      v_sync    => vtg_mode_v_sync,
      v_bp      => vtg_mode_v_bp,
      h_tot     => vtg_mode_h_tot,
      h_act     => vtg_mode_h_act,
      h_sync    => vtg_mode_h_sync,
      h_bp      => vtg_mode_h_bp,
      genlock   => vtg_genlock,
      genlocked => hdtv_lock,
      f         => vtg_f,
      vs        => vtg_vs,
      hs        => vtg_hs,
      vblank    => vtg_vblank,
      hblank    => vtg_hblank,
      ax        => vtg_ax,
      ay        => vtg_ay
    );

  vtg_de <= vtg_vblank nor vtg_hblank;

  --------------------------------------------------------------------------------
  -- write VIDPROC output to buffer

  SYNC_I: component sync_reg
    port map (
      clk  => vidproc_clk,
      d(0) => crtc_vs,
      q(0) => crtc_vs_s
    );

  ram_wsel <= vidproc_odd;

  ram_we0 <= vidproc_pe and (vidproc_ttx or not ram_wsel);
  ram_we1 <= vidproc_pe and (vidproc_ttx or     ram_wsel);
  ram_wd0 <= vidproc_p;
  ram_wd1 <= vidproc_p2;

  VIDPROC: process (vidproc_clk) is
  begin
    if rising_edge(vidproc_clk) and vidproc_clken = '1' then
      vidproc_pe_1 <= vidproc_pe;
      if vidproc_rst = '1' or crtc_vs_s = '1' then
        vidproc_odd <= '0';
        ram_wa0     <= (others => '0');
        ram_wa1     <= (others => '0');
      else
        if vidproc_pe = '0' and vidproc_pe_1 = '1' then -- trailing edge
          vidproc_odd <= not vidproc_odd;
        end if;
        if vidproc_pe = '1' and (vidproc_ttx = '1' or ram_wsel = '0') then
          ram_wa0 <= std_logic_vector(unsigned(ram_wa0)+1);
        end if;
        if vidproc_pe = '1' and (vidproc_ttx = '1' or ram_wsel = '1') then
          ram_wa1 <= std_logic_vector(unsigned(ram_wa1)+1);
        end if;
      end if;
    end if;
  end process VIDPROC;

  --------------------------------------------------------------------------------
  -- read from buffer, upscale, output to display

  v_act <= to_integer(unsigned(vtg_mode_v_act));
  h_act <= to_integer(unsigned(vtg_mode_h_act));

  SYNC_O: component sync_reg
    port map (
      clk  => hdtv_clk,
      d(0) => vidproc_ttx,
      q(0) => vidproc_ttx_s
    );

  HDTV: process (hdtv_clk) is

    variable n : integer;

    --------------------------------------------------------------------------------

    -- supports /2, /3, /4
    function weighted_sum_1 (m, w:integer; a, b:std_logic) return std_logic_vector is
      variable v : std_logic_vector(1 downto 0);
      variable r : std_logic_vector(7 downto 0);
    begin
      case m is
        when 2 => -- halves
          case w is
            when 1 =>
              v := a & b;
              case v is
                when "11" => r := x"FF";
                when "10" => r := x"80";
                when "01" => r := x"80";
                when others => r := x"00";
              end case;
            when others => r := (others => a);
          end case;
        when 3 => -- thirds
          case w is
            when 2 =>
              v := a & b;
              case v is
                when "11" => r := x"FF";
                when "10" => r := x"AA";
                when "01" => r := x"55";
                when others => r := x"00";
              end case;
            when 1 =>
              v := b & a;
              case v is
                when "11" => r := x"FF";
                when "10" => r := x"AA";
                when "01" => r := x"55";
                when others => r := x"00";
              end case;
            when others => r := (others => a);
          end case;
        when 4 => -- quarters
          case w is
            when 3 =>
              v := a & b;
              case v is
                when "11" => r := x"FF";
                when "10" => r := x"C0";
                when "01" => r := x"40";
                when others => r := x"00";
              end case;
            when 2 =>
              v := a & b;
              case v is
                when "11" => r := x"FF";
                when "10" => r := x"80";
                when "01" => r := x"80";
                when others => r := x"00";
              end case;
            when 1 =>
              v := b & a;
              case v is
                when "11" => r := x"FF";
                when "10" => r := x"C0";
                when "01" => r := x"40";
                when others => r := x"00";
              end case;
            when others => r := (others => a);
          end case;
        when others => r := (others => a);
      end case;
      return r;
    end function;

    -- supports /2,/4
    function weighted_sum_8 (m, w:integer; a, b:std_logic_vector(7 downto 0)) return std_logic_vector is
      variable r : std_logic_vector(7 downto 0);
    begin
      case m is
        when 2 =>
          if w = 1 then
            r := std_logic_vector(resize(unsigned(a(7 downto 1)), 8)+resize(unsigned(b(7 downto 1)), 8));
          else
            r := a;
          end if;
        when 4 =>
          case w is
            when 1 =>
              r := std_logic_vector(resize(unsigned(a(7 downto 2)), 8)+resize(unsigned(b(7 downto 1)), 8)+resize(unsigned(b(7 downto 2)), 8));
            when 2 =>
              r := std_logic_vector(resize(unsigned(a(7 downto 1)), 8)+resize(unsigned(b(7 downto 1)), 8));
            when 3 =>
              r := std_logic_vector(resize(unsigned(a(7 downto 2)), 8)+resize(unsigned(a(7 downto 1)), 8)+resize(unsigned(b(7 downto 2)), 8));
            when others => r := a;
          end case;
        when others => r := a;
      end case;
      return r;
    end function weighted_sum_8;

  --------------------------------------------------------------------------------

  begin
    if rising_edge(hdtv_clk) then

      --------------------------------------------------------------------------------
      -- display mode specific parameters

      case hdtv_mode is
        when hdtv_mode_1080p | hdtv_mode_1080i =>
          v_vis <= 1024+(2*4*v_ovr/1);
          h_vis <= 1280+(2*16*2*h_ovr/1);
        when hdtv_mode_720p =>
          v_vis <= 640+(2*5*v_ovr/2);
          h_vis <= 800+(2*16*5*h_ovr/4);
        when hdtv_mode_576p =>
          v_vis <= 512+(2*2*v_ovr/1);
          h_vis <= 640+(2*16*1*h_ovr/1);
        when others =>                                                            -- HDTV_MODE_576i
          v_vis <= 512+(2*2*v_ovr/1);
          h_vis <= 1280+(2*16*2*h_ovr/1);
      end case;
      case hdtv_mode is
        when hdtv_mode_1080p =>
          vn <= 4; vd <= 1; hn <= 2; hd <= 1;
        when hdtv_mode_1080i =>
          vn <= 2; vd <= 1; hn <= 2; hd <= 1;
        when hdtv_mode_720p =>
          vn <= 5; vd <= 2; hn <= 5; hd <= 4;
        when hdtv_mode_576p =>
          vn <= 2; vd <= 1; hn <= 1; hd <= 1;
        when others =>                                                            -- HDTV_MODE_576i
          vn <= 1; vd <= 1; hn <= 2; hd <= 1;
      end case;
      if vidproc_ttx_s = '1' then
        case hdtv_mode is
          when hdtv_mode_1080p =>
            vn <= 2; vd <= 1; hn <= 8; hd <= 3;
          when hdtv_mode_1080i =>
            vn <= 1; vd <= 1; hn <= 8; hd <= 3;
          when hdtv_mode_720p =>
            vn <= 5; vd <= 4; hn <= 5; hd <= 3;
          when hdtv_mode_576p =>
            vn <= 1; vd <= 1; hn <= 4; hd <= 3;
          when others =>                                                          -- HDTV_MODE_576i
            vn <= 1; vd <= 1; hn <= 8; hd <= 3;
        end case;
      end if;
      vis_y_start <= (v_act-v_vis)/2;
      vis_y_end   <= vis_y_start+v_vis;
      vis_x_start <= ((h_act-h_vis)/2)-1;
      vis_x_end   <= vis_x_start+h_vis;

      --------------------------------------------------------------------------------

      if vidproc_rst = '1' then                                                   -- reset
        vis_x      <= '0';
        vis_y      <= '0';
        vis        <= '0';
        vtg_vs_s   <= (others => '0');
        vtg_hs_s   <= (others => '0');
        vtg_de_s   <= (others => '0');
        vis_s      <= (others => '0');
        ram_rsel_s <= (others => '0');
        vi         <= 0;
        vw         <= 0;
        vadv       <= '0';
        hi         <= 0;
        hw         <= 0;
        hadv       <= '0';
        ram_ra0    <= (others => '0');
        ram_ra0_s  <= (others => '0');
        ram_rd0_l  <= (others => '0');
        ram_ra1    <= (others => '0');
        ram_ra1_s  <= (others => '0');
        ram_rd1_l  <= (others => '0');
        ram_rsel   <= '0';
        hp0        <= (others => (others => '0'));
        hp1        <= (others => (others => '0'));
        hdtv_vs    <= '0';
        hdtv_hs    <= '0';
        hdtv_de    <= '0';
        hdtv_p     <= (others => (others => '0'));
      else

        --------------------------------------------------------------------------------
        -- visible region: destination display size of (overscanned) input video

        if vtg_mode_interlace = '1' then
          if to_integer(shift_right(unsigned(vtg_ay), 1)) = vis_y_start/2 then
            vis_y <= '1';
          elsif to_integer(shift_right(unsigned(vtg_ay), 1)) = vis_y_end/2 then
            vis_y <= '0';
          end if;
        else
          if to_integer(unsigned(vtg_ay)) = vis_y_start then
            vis_y <= '1';
          elsif to_integer(unsigned(vtg_ay)) = vis_y_end then
            vis_y <= '0';
          end if;
        end if;
        if to_integer(unsigned(vtg_ax)) = vis_x_start then
          vis_x <= '1'; vis <= vis_y;
        elsif to_integer(unsigned(vtg_ax)) = vis_x_end then
          vis_x <= '0'; vis <= '0';
        end if;

        --------------------------------------------------------------------------------
        -- scaling algorithm:
        -- note: ratio of output to input pixels is N/D
        --  start with i=N
        --  for each output (pixel or line):
        --      if i<=D then i=i+N-D else i=i-D
        --      if i<D then w=x/D else w=1
        --      output = (w*current) + ((1-w)*next)
        --      if i<=D then advance input (current=next, next=next but one)
        -- horizontal scaling first because the scaling fractions are more interesting,
        --  but we only have to deal with 1 bit per colour

        vtg_vs_s(1 to 4) <= vtg_vs & vtg_vs_s(1 to 3);
        vtg_hs_s(1 to 4) <= vtg_hs & vtg_hs_s(1 to 3);
        vtg_de_s(1 to 4) <= vtg_de & vtg_de_s(1 to 3);
        vis_s(1 to 4)    <= vis & vis_s(1 to 3);
        ram_rsel_s(4)    <= ram_rsel;

        -- initialise at start
        if vtg_vblank = '1' then
          vi        <= vn;
          ram_rsel  <= '0';
          ram_ra0   <= (others => '0');
          ram_ra1   <= (others => '0');
          ram_ra0_s <= (others => '0');
          ram_ra1_s <= (others => '0');
        end if;

        -- pipeline stage 1 - RAM address, data
        if vis = '1' then
          if vis_s(1) = '0' then                                                  -- start of line
            ram_ra0_s <= ram_ra0;                                                 -- remember address
            ram_ra1_s <= ram_ra1;                                                 -- "
            hi        <= hn;                                                      -- init H
          end if;
        end if;
        if (vis = '1' and vis_s(2) = '0') or (vis_s(3) = '1' and hadv = '1') then -- advance
          ram_ra0 <= std_logic_vector(unsigned(ram_ra0)+1);
          ram_ra1 <= std_logic_vector(unsigned(ram_ra1)+1);
        end if;

        -- pipeline stage 2 - RAM data latch
        if vis_s(1) = '1' then
          if vis_s(2) = '0' or (vis_s(3) = '1' and hadv = '1') then
            ram_rd0_l <= ram_rd0;
            ram_rd1_l <= ram_rd1;
          end if;
        end if;

        -- pipeline stage 3 - vi, vw, vadv, hi, hw, hadv
        if vis_s(2) = '1' then
          if vis_s(3) = '0' then                                                  -- start of line: update V
            if vi <= vd then
              vi <= vi+vn-vd;
            else
              vi <= vi-vd;
            end if;
            if vi < vd then
              vw <= vi;
            else
              vw <= vd;
            end if;
            vadv <= ternary(vi <= vd, '1', '0');
          end if;
          if hi <= hd then
            hi <= hi+hn-hd;
          else
            hi <= hi-hd;
          end if;
          if hi < hd then
            hw <= hi;
          else
            hw <= hd;
          end if;
          hadv <= ternary(hi <= hd, '1', '0');
        elsif vis_s(3) = '1' then                                                 -- end of line: advance V, rewind H
          ram_ra0 <= std_logic_vector(unsigned(ram_ra0)-1);
          ram_ra1 <= std_logic_vector(unsigned(ram_ra1)-1);
          if vidproc_ttx_s = '1' and hdtv_mode = hdtv_mode_576i then
            null;
          else
            if vadv = '1' then
              if ram_rsel = '0' then
                ram_ra1 <= ram_ra1_s;
              else
                ram_ra0 <= ram_ra0_s;
              end if;
              ram_rsel <= not ram_rsel;
            else
              ram_ra0 <= ram_ra0_s;
              ram_ra1 <= ram_ra1_s;
            end if;
          end if;
        end if;

        -- pipeline stage 4: hp0, hp1 (h scaled pixels from RAM buffers)
        for i in 0 to 2 loop
          hp0(i) <= weighted_sum_1(hd, hw, ram_rd0_l(i), ram_rd0(i));
          hp1(i) <= weighted_sum_1(hd, hw, ram_rd1_l(i), ram_rd1(i));
        end loop;

        -- pipeline stage 5: fully scaled output
        hdtv_vs <= vtg_vs_s(4);
        hdtv_hs <= vtg_hs_s(4);
        hdtv_de <= vtg_de_s(4);
        hdtv_p  <= (others => (others => '0'));
        if vis_s(4) = '1' then
          for i in 0 to 2 loop
            if vidproc_ttx_s = '1' and hdtv_mode = hdtv_mode_576i then
              -- special case - vertical downscale (interlace)
              if vtg_f = '0' then
                hdtv_p(i) <= hp0(i);
              else
                hdtv_p(i) <= hp1(i);
              end if;
            else
              if ram_rsel_s(4) = '0' then
                hdtv_p(i) <= weighted_sum_8(vd, vw, hp0(i), hp1(i));
              else
                hdtv_p(i) <= weighted_sum_8(vd, vw, hp1(i), hp0(i));
              end if;
            end if;
          end loop;
        end if;

      --------------------------------------------------------------------------------

      end if;                                                                     -- vidproc_rst
    end if;                                                                       -- rising_edge(hdtv_clk)
  end process HDTV;

  ram_rce <= (vis and not vis_s(2)) or hadv;
  hdtv_r  <= hdtv_p(0);
  hdtv_g  <= hdtv_p(1);
  hdtv_b  <= hdtv_p(2);

  --------------------------------------------------------------------------------
  -- a pair of 16k x 3 dual port RAMs with separate clocks

  -- even source lines
  BUF0: component ram_tdp_ar
    generic map (
      width      => 3,
      depth_log2 => ram_size_log2-1
    )
    port map (
      clk_a      => vidproc_clk,
      rst_a      => '0',
      ce_a       => vidproc_clken,
      we_a       => ram_we0,
      addr_a     => ram_wa0,
      din_a      => ram_wd0,
      dout_a     => open,
      clk_b      => hdtv_clk,
      rst_b      => '0',
      ce_b       => ram_rce,
      we_b       => '0',
      addr_b     => ram_ra0,
      din_b      => (others => '0'),
      dout_b     => ram_rd0
    );

  -- odd source lines

  BUF1: component ram_tdp_ar
    generic map (
      width      => 3,
      depth_log2 => ram_size_log2-1
    )
    port map (
      clk_a      => vidproc_clk,
      rst_a      => '0',
      ce_a       => vidproc_clken,
      we_a       => ram_we1,
      addr_a     => ram_wa1,
      din_a      => ram_wd1,
      dout_a     => open,
      clk_b      => hdtv_clk,
      rst_b      => '0',
      ce_b       => ram_rce,
      we_b       => '0',
      addr_b     => ram_ra1,
      din_b      => (others => '0'),
      dout_b     => ram_rd1
    );

--------------------------------------------------------------------------------

end architecture synth;
