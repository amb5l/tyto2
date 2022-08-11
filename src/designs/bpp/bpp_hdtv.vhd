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

library ieee;
use ieee.std_logic_1164.all;

package bpp_hdtv_pkg is

    constant HDTV_MODE_576i50  : std_logic_vector(2 downto 0) := "000";
    constant HDTV_MODE_576p50  : std_logic_vector(2 downto 0) := "001";
    constant HDTV_MODE_720p50  : std_logic_vector(2 downto 0) := "010";
    constant HDTV_MODE_1080i50 : std_logic_vector(2 downto 0) := "011";
    constant HDTV_MODE_1080p50 : std_logic_vector(2 downto 0) := "100";

    component bpp_hdtv is
        port (

            crtc_clk         : in  std_logic;                    -- CRTC: clock        } 2 or 1
            crtc_clken       : in  std_logic;                    -- CRTC: clock enable } MHz
            crtc_rst         : in  std_logic;                    -- CRTC: reset
            crtc_f           : in  std_logic;                    -- CRTC: field (0=first/odd/upper)
            crtc_vs          : in  std_logic;                    -- CRTC: vertical sync
            crtc_hs          : in  std_logic;                    -- CRTC: horizontal sync
            crtc_de          : in  std_logic;                    -- CRTC: display enable
            crtc_oe          : out std_logic;                    -- CRTC: overscan enable

            vidproc_clk      : in  std_logic;                    -- VIDPROC: clock        } 16 or 12
            vidproc_clken    : in  std_logic;                    -- VIDPROC: clock enable } MHz
            vidproc_rst      : in  std_logic;                    -- VIDPROC: reset
            vidproc_clksel   : in  std_logic;                    -- VIDPROC: character clock select
            vidproc_ttx      : in  std_logic;                    -- VIDPROC: teletext mode
            vidproc_pe       : in  std_logic;                    -- VIDPROC: pixel enable
            vidproc_p        : in  std_logic_vector(2 downto 0); -- VIDPROC: pixel data
            vidproc_p2       : in  std_logic_vector(2 downto 0); -- VIDPROC: pixel data for 2nd line (scan doubling)

            hdtv_mode        : in  std_logic_vector(2 downto 0); -- HDTV: mode select
            hdtv_mode_clksel : out std_logic_vector(1 downto 0); -- HDTV: clock select
            hdtv_mode_vic    : out std_logic_vector(7 downto 0); 
            hdtv_mode_pixrep : out std_logic;
            hdtv_mode_aspect : out std_logic_vector(1 downto 0);
            hdtv_mode_vs_pol : out std_logic;
            hdtv_mode_hs_pol : out std_logic;

            hdtv_clk         : in  std_logic;                    -- HDTV: clock
            hdtv_rst         : in  std_logic;                    -- HDTV: reset
            hdtv_vs          : out std_logic;                    -- HDTV: vertical sync
            hdtv_hs          : out std_logic;                    -- HDTV: horizontal sync
            hdtv_de          : out std_logic;                    -- HDTV: display enable
            hdtv_r           : out std_logic_vector(7 downto 0); -- HDTV: red (0-255)
            hdtv_g           : out std_logic_vector(7 downto 0); -- HDTV: green (0-255)
            hdtv_b           : out std_logic_vector(7 downto 0); -- HDTV: blue (0-255)
            hdtv_lock        : out std_logic                     -- HDTV: genlock status

        );
    end component bpp_hdtv;

end package bpp_hdtv_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.bpp_hdtv_pkg.all;
use work.bpp_overscan_pkg.all;
use work.bpp_genlock_pkg.all;
use work.video_mode_pkg.all;
use work.video_out_timing_pkg.all;
use work.bpp_upscale_pkg.all;

entity bpp_hdtv is
    port (

        crtc_clk         : in  std_logic;                    -- CRTC: clock        } 2 or 1
        crtc_clken       : in  std_logic;                    -- CRTC: clock enable } MHz
        crtc_rst         : in  std_logic;                    -- CRTC: reset
        crtc_f           : in  std_logic;                    -- CRTC: field (0=first/odd/upper)
        crtc_vs          : in  std_logic;                    -- CRTC: vertical sync
        crtc_hs          : in  std_logic;                    -- CRTC: horizontal sync
        crtc_de          : in  std_logic;                    -- CRTC: display enable
        crtc_oe          : out std_logic;                    -- CRTC: overscan enable

        vidproc_clk      : in  std_logic;                    -- VIDPROC: clock        } 16 or 12
        vidproc_clken    : in  std_logic;                    -- VIDPROC: clock enable } MHz
        vidproc_rst      : in  std_logic;                    -- VIDPROC: reset
        vidproc_clksel   : in  std_logic;                    -- VIDPROC: character clock select
        vidproc_ttx      : in  std_logic;                    -- VIDPROC: teletext mode
        vidproc_pe       : in  std_logic;                    -- VIDPROC: pixel enable
        vidproc_p        : in  std_logic_vector(2 downto 0); -- VIDPROC: pixel data
        vidproc_p2       : in  std_logic_vector(2 downto 0); -- VIDPROC: pixel data for 2nd line (scan doubling)

        hdtv_mode        : in  std_logic_vector(2 downto 0); -- HDTV: mode select
        hdtv_mode_clksel : out std_logic_vector(1 downto 0); -- HDTV: clock select
        hdtv_mode_vic    : out std_logic_vector(7 downto 0);
        hdtv_mode_pixrep : out std_logic;
        hdtv_mode_aspect : out std_logic_vector(1 downto 0);
        hdtv_mode_vs_pol : out std_logic;
        hdtv_mode_hs_pol : out std_logic;

        hdtv_clk         : in  std_logic;                    -- HDTV: clock
        hdtv_rst         : in  std_logic;                    -- HDTV: reset
        hdtv_vs          : out std_logic;                    -- HDTV: vertical sync
        hdtv_hs          : out std_logic;                    -- HDTV: horizontal sync
        hdtv_de          : out std_logic;                    -- HDTV: display enable
        hdtv_r           : out std_logic_vector(7 downto 0); -- HDTV: red (0-255)
        hdtv_g           : out std_logic_vector(7 downto 0); -- HDTV: green (0-255)
        hdtv_b           : out std_logic_vector(7 downto 0); -- HDTV: blue (0-255)
        hdtv_lock        : out std_logic                     -- HDTV: genlock status

    );
end entity bpp_hdtv;

architecture synth of bpp_hdtv is

    signal crtc_oe_i          : std_logic;                     -- crtc_oe, internal

    signal vtg_mode           : std_logic_vector(3 downto 0);  -- VTG mode select
    signal vtg_mode_clk_sel   : std_logic_vector(1 downto 0);  -- VTG mode: pixel frequency select
    signal vtg_mode_dmt       : std_logic;                     -- VTG mode: 1 = DMT, 0 = CEA
    signal vtg_mode_id        : std_logic_vector(7 downto 0);  -- VTG mode: DMT ID or CEA/CTA VIC
    signal vtg_mode_pix_rep   : std_logic;                     -- VTG mode: 1 = pixel doubling/repetition
    signal vtg_mode_aspect    : std_logic_vector(1 downto 0);  -- VTG mode: 0x = normal, 10 = force 16:9, 11 = force 4:3
    signal vtg_mode_interlace : std_logic;                     -- VTG mode: interlaced/progressive scan
    signal vtg_mode_v_tot     : std_logic_vector(10 downto 0); -- VTG mode: vertical total lines (must be odd if interlaced)
    signal vtg_mode_v_act     : std_logic_vector(10 downto 0); -- VTG mode: vertical total lines (must be odd if interlaced)
    signal vtg_mode_v_sync    : std_logic_vector(2 downto 0);  -- VTG mode: vertical sync width
    signal vtg_mode_v_bp      : std_logic_vector(5 downto 0);  -- VTG mode: vertical back porch
    signal vtg_mode_h_tot     : std_logic_vector(11 downto 0); -- VTG mode: horizontal total
    signal vtg_mode_h_act     : std_logic_vector(10 downto 0); -- VTG mode: vertical total lines (must be odd if interlaced)
    signal vtg_mode_h_sync    : std_logic_vector(6 downto 0);  -- VTG mode: horizontal sync width
    signal vtg_mode_h_bp      : std_logic_vector(7 downto 0);  -- VTG mode: horizontal back porch
    signal vtg_mode_vs_pol    : std_logic;                     -- VTG mode: vertical sync polarity (1 = high)
    signal vtg_mode_hs_pol    : std_logic;                     -- VTG mode: horizontal sync polarity (1 = high)

    signal vtg_genlock        : std_logic;                     -- genlock pulse to VTG
    signal vtg_genlocked      : std_logic;                     -- VTG genlock status

    signal vtg_vs             : std_logic;                     -- VTG: vertical sync
    signal vtg_hs             : std_logic;                     -- VTG: horizontal sync
    signal vtg_vblank         : std_logic;                     -- VTG: vertical blank
    signal vtg_hblank         : std_logic;                     -- VTG: horizontal blank
    signal vtg_de             : std_logic;                     -- VTG: display enable
    signal vtg_ax             : std_logic_vector(11 downto 0); -- VTG: active area X (signed)
    signal vtg_ay             : std_logic_vector(11 downto 0); -- VTG: active area Y (signed)

begin

    OVERSCAN: component bpp_overscan
        generic map (
            v_ovr => 7,
            h_ovr => 1
        )
        port map (
            clk    => crtc_clk,
            clken  => crtc_clken,
            rst    => crtc_rst,
            clksel => vidproc_clksel,
            ttx    => vidproc_ttx,
            f      => crtc_f,
            vs     => crtc_vs,
            hs     => crtc_hs,
            en     => crtc_oe_i
        );

    crtc_oe <= crtc_oe_i;

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

    with hdtv_mode select vtg_mode <=
        MODE_1920x1080p50 when HDTV_MODE_1080p50,
        MODE_1920x1080i50 when HDTV_MODE_1080i50,
        MODE_1280x720p50  when HDTV_MODE_720p50,
        MODE_720x576p50   when HDTV_MODE_576p50,
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
            f         => open,
            vs        => vtg_vs,
            hs        => vtg_hs,
            vblank    => vtg_vblank,
            hblank    => vtg_hblank,
            ax        => vtg_ax,
            ay        => vtg_ay
        );

    vtg_de <= vtg_vblank nor vtg_hblank;

    UPSCALE: component bpp_upscale
        port map (
            in_clk   => vidproc_clk,
            in_clken => vidproc_clken,
            in_rst   => vidproc_rst,
            in_ttx   => vidproc_ttx,
            in_vrst  => crtc_vs,
            in_pe    => vidproc_pe,
            in_p     => vidproc_p,
            in_p2    => vidproc_p2,
            out_clk  => hdtv_clk,
            out_rst  => hdtv_rst,
            vtg_vs   => vtg_vs,
            vtg_hs   => vtg_hs,
            vtg_de   => vtg_de,
            vtg_ax   => vtg_ax,
            vtg_ay   => vtg_ay,
            hdtv_vs  => hdtv_vs,
            hdtv_hs  => hdtv_hs,
            hdtv_de  => hdtv_de,
            hdtv_r   => hdtv_r,
            hdtv_g   => hdtv_g,
            hdtv_b   => hdtv_b
        );

    hdtv_mode_clksel <= vtg_mode_clk_sel;
    hdtv_mode_vic    <= vtg_mode_id;
    hdtv_mode_pixrep <= vtg_mode_pix_rep;
    hdtv_mode_aspect <= vtg_mode_aspect;
    hdtv_mode_vs_pol <= vtg_mode_vs_pol;
    hdtv_mode_hs_pol <= vtg_mode_hs_pol;

end architecture synth;
