--------------------------------------------------------------------------------
-- otus.vhd                                                                   --
-- A BBC Micro Model B restomod.                                              --
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

package otus_pkg is

    component otus is
        port (

            sys_rst     : in  std_logic;
            sys_clk_96m : in  std_logic;
            sys_clk_48m : in  std_logic;
            sys_clk_32m : in  std_logic;
            sys_clk_8m  : in  std_logic;

            vga_rst     : in  std_logic;                    -- VGA: synchronous reset
            vga_clk     : in  std_logic;                    -- VGA: pixel clock
            vga_vs      : out std_logic;                    -- VGA: vertical sync
            vga_hs      : out std_logic;                    -- VGA: horizontal sync
            vga_de      : out std_logic;                    -- VGA: display enable
            vga_r       : out std_logic_vector(7 downto 0); -- VGA: red
            vga_g       : out std_logic_vector(7 downto 0); -- VGA: green
            vga_b       : out std_logic_vector(7 downto 0); -- VGA: blue

            pcm_rst     : in  std_logic;                     -- audio: synchronous reset
            pcm_clk     : in  std_logic;                     -- audio: clock (12.288MHz)
            pcm_clken   : in  std_logic;                     -- audio: clock enable @ 48kHz
            pcm_l       : out std_logic_vector(15 downto 0); -- audio: left channel  } signed 16 bit
            pcm_r       : out std_logic_vector(15 downto 0)  -- audio: right channel }  samples

        );
    end component otus;

end package otus_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.otus_conductor_pkg.all;
use work.np6532_pkg.all;

use work.otus_dmac_pkg.all;
use work.otus_map_pkg.all;
use work.hd6845_pkg.all;
use work.otus_overscan_pkg.all;
use work.otus_genlock_pkg.all;
use work.saa5050d_pkg.all;
use work.otus_vidproc_pkg.all;
use work.otus_upscale_pkg.all;
use work.video_mode_pkg.all;
use work.video_out_timing_pkg.all;

entity otus is
    port (

            sys_rst     : in  std_logic;
            sys_clk_96m : in  std_logic;
            sys_clk_48m : in  std_logic;
            sys_clk_32m : in  std_logic;
            sys_clk_8m  : in  std_logic;

            vga_rst     : in  std_logic;                    -- VGA: synchronous reset
            vga_clk     : in  std_logic;                    -- VGA: pixel clock
            vga_vs      : out std_logic;                    -- VGA: vertical sync
            vga_hs      : out std_logic;                    -- VGA: horizontal sync
            vga_de      : out std_logic;                    -- VGA: display enable
            vga_r       : out std_logic_vector(7 downto 0); -- VGA: red
            vga_g       : out std_logic_vector(7 downto 0); -- VGA: green
            vga_b       : out std_logic_vector(7 downto 0); -- VGA: blue

            pcm_rst     : in  std_logic;                     -- audio: synchronous reset
            pcm_clk     : in  std_logic;                     -- audio: clock (12.288MHz)
            pcm_clken   : in  std_logic;                     -- audio: clock enable @ 48kHz
            pcm_l       : out std_logic_vector(15 downto 0); -- audio: left channel  } signed 16 bit
            pcm_r       : out std_logic_vector(15 downto 0)  -- audio: right channel }  samples

    );
end entity otus;

architecture synth of otus is

    --------------------------------------------------------------------------------
    -- constants

    constant ram_size_log2 : integer := 18;

    --------------------------------------------------------------------------------
    -- signals

    signal sys_rst_96m           : std_logic;                                  --
    signal sys_rst_48m           : std_logic;                                  --
    signal sys_rst_32m           : std_logic;                                  --
    signal sys_rst_8m            : std_logic;                                  --
    signal sys_clken_96m_32m_0   : std_logic;                                  --
    signal sys_clken_96m_32m_120 : std_logic;                                  --
    signal sys_clken_96m_32m_240 : std_logic;                                  --
    signal sys_clken_96m_8m      : std_logic;                                  --
    signal sys_clken_48m_16m     : std_logic;                                  --
    signal sys_clken_48m_12m     : std_logic;                                  --
    signal sys_clken_48m_8m      : std_logic;                                  --
    signal sys_clken_8m_4m       : std_logic;                                  --
    signal sys_clken_8m_2m_0     : std_logic;                                  --
    signal sys_clken_8m_2m_180   : std_logic;                                  --
    signal sys_clken_8m_2m_270   : std_logic;                                  --
    signal sys_clken_8m_1m_0     : std_logic;                                  --
    signal sys_clken_8m_1m_90    : std_logic;                                  --

    signal core_rst              : std_logic;
    signal core_if_al            : std_logic_vector(15 downto 0);              -- core:
    signal core_if_ap            : std_logic_vector(ram_size_log2-1 downto 0); -- core:
    signal core_if_z             : std_logic;                                  -- core:
    signal core_ls_al            : std_logic_vector(15 downto 0);              -- core:
    signal core_ls_ap            : std_logic_vector(ram_size_log2-1 downto 0); -- core:
    signal core_ls_en            : std_logic;                                  -- core:
    signal core_ls_re            : std_logic;                                  -- core:
    signal core_ls_we            : std_logic;                                  -- core:
    signal core_ls_wp            : std_logic;                                  -- core:
    signal core_ls_z             : std_logic;                                  -- core:
    signal core_ls_ext           : std_logic;                                  -- core:
    signal core_ls_drx           : std_logic_vector(7 downto 0);               -- core:
    signal core_ls_dwx           : std_logic_vector(7 downto 0);               -- core:

    signal core_dma_en           : std_logic;                                  -- core: DMA enable
    signal core_dma_a            : std_logic_vector(ram_size_log2-1 downto 3); -- core:
    signal core_dma_bwe          : std_logic_vector(7 downto 0);               -- core:
    signal core_dma_dw           : std_logic_vector(63 downto 0);              -- core:
    signal core_dma_dr           : std_logic_vector(63 downto 0);              -- core:

    signal crtc_reg_cs           : std_logic;                                  -- CRTC: register chip select
    signal crtc_reg_dr           : std_logic_vector(7 downto 0);               -- CRTC: register read data
    signal crtc_clken            : std_logic;                                  -- CRTC: 2MHz or 1MHz clken from VIDPROC
    signal crtc_f                : std_logic;                                  -- CRTC: field ID
    signal crtc_ma               : std_logic_vector(13 downto 0);              -- CRTC: memory address
    signal crtc_ra               : std_logic_vector(4 downto 0);               -- CRTC: raster (scan line) address within character
    signal crtc_vs               : std_logic;                                  -- CRTC: vertical sync
    signal crtc_hs               : std_logic;                                  -- CRTC: horizontal blank
    signal crtc_vb               : std_logic;                                  -- CRTC: vertical blank
    signal crtc_hb               : std_logic;                                  -- CRTC: horizontal sync
    signal crtc_de               : std_logic;                                  -- CRTC: display enable
    signal crtc_cur              : std_logic;                                  -- CRTC: cursor
    signal crtc_d                : std_logic_vector(7 downto 0);               -- CRTC: data (fetched from memory)

    signal crtc_oe               : std_logic;                                  -- CRTC: overscan display enable

    signal ttx_oe                : std_logic;                                  -- teletext: overscan pixel enable
    signal ttx_pe                : std_logic;                                  -- teletext: pixel enable
    signal ttx_pu                : std_logic_vector(2 downto 0);               -- teletext: pixel (3 bit BGR) (12 pixels per character) (upper line)
    signal ttx_pl                : std_logic_vector(2 downto 0);               -- teletext: pixel (3 bit BGR) (12 pixels per character) (lower line)

    signal vidproc_reg_cs        : std_logic;
    signal vidproc_ttx           : std_logic;                                  -- VIDPROC: teletext mode
    signal vidproc_clken         : std_logic;                                  -- VIDPROC: pixel clock enable (12/16MHz)
    signal vidproc_pe            : std_logic;                                  -- VIDPROC: pixel (display) enable
    signal vidproc_p             : std_logic_vector(2 downto 0);               -- VIDPROC: pixel data
    signal vidproc_p2            : std_logic_vector(2 downto 0);               -- VIDPROC: pixel data (2nd line for teletext scan doubling)

    signal alat                  : std_logic_vector(7 downto 0);

    signal mode_clk_sel          : std_logic_vector(1 downto 0);               -- display mode: pixel frequency select
    signal mode_dmt              : std_logic;                                  -- display mode: 1 = DMT, 0 = CEA
    signal mode_id               : std_logic_vector(7 downto 0);               -- display mode: DMT ID or CEA/CTA VIC
    signal mode_pix_rep          : std_logic;                                  -- display mode: 1 = pixel doubling/repetition
    signal mode_aspect           : std_logic_vector(1 downto 0);               -- display mode: 0x = normal, 10 = force 16:9, 11 = force 4:3
    signal mode_interlace        : std_logic;                                  -- display mode: interlaced/progressive scan
    signal mode_v_tot            : std_logic_vector(10 downto 0);              -- display mode: vertical total lines (must be odd if interlaced)
    signal mode_v_act            : std_logic_vector(10 downto 0);              -- display mode: vertical total lines (must be odd if interlaced)
    signal mode_v_sync           : std_logic_vector(2 downto 0);               -- display mode: vertical sync width
    signal mode_v_bp             : std_logic_vector(5 downto 0);               -- display mode: vertical back porch
    signal mode_h_tot            : std_logic_vector(11 downto 0);              -- display mode: horizontal total
    signal mode_h_act            : std_logic_vector(10 downto 0);              -- display mode: vertical total lines (must be odd if interlaced)
    signal mode_h_sync           : std_logic_vector(6 downto 0);               -- display mode: horizontal sync width
    signal mode_h_bp             : std_logic_vector(7 downto 0);               -- display mode: horizontal back porch
    signal mode_vs_pol           : std_logic;                                  -- display mode: vertical sync polarity (1 = high)
    signal mode_hs_pol           : std_logic;                                  -- display mode: horizontal sync polarity (1 = high)

    signal vtg_genlock           : std_logic;                                  -- genlock pulse to VTG
    signal vtg_genlocked         : std_logic;                                  -- VTG genlock status

    signal vtg_vs                : std_logic;                                  -- video timing generator: vertical sync
    signal vtg_hs                : std_logic;                                  -- video timing generator: horizontal sync
    signal vtg_vblank            : std_logic;                                  -- video timing generator: vertical blank
    signal vtg_hblank            : std_logic;                                  -- video timing generator: horizontal blank
    signal vtg_de                : std_logic;                                  -- video timing generator: display enable
    signal vtg_ax                : std_logic_vector(11 downto 0);              -- video timing generator: active area X (signed)
    signal vtg_ay                : std_logic_vector(11 downto 0);              -- video timing generator: active area Y (signed)

    --------------------------------------------------------------------------------
    -- aliases

    alias  alat_ssa              : std_logic_vector(1 downto 0) is alat(5 downto 4); -- screen start address

    --------------------------------------------------------------------------------

begin

    CONDUCTOR: component otus_conductor
        port map (
            clk_lock        => not sys_rst,
            clk_96m         => sys_clk_96m,
            clk_48m         => sys_clk_48m,
            clk_32m         => sys_clk_32m,
            clk_8m          => sys_clk_8m,
            rst_96m         => sys_rst_96m,
            rst_48m         => sys_rst_48m,
            rst_32m         => sys_rst_32m,
            rst_8m          => sys_rst_8m,
            clken_96m_8m    => sys_clken_96m_8m,
            clken_48m_16m   => sys_clken_48m_16m,
            clken_48m_12m   => sys_clken_48m_12m,
            clken_48m_8m    => sys_clken_48m_8m,
            clken_8m_4m     => sys_clken_8m_4m,
            clken_8m_2m_0   => sys_clken_8m_2m_0,
            clken_8m_2m_180 => sys_clken_8m_2m_180,
            clken_8m_2m_270 => sys_clken_8m_2m_270,
            clken_8m_1m_0   => sys_clken_8m_1m_0,
            clken_8m_1m_90  => sys_clken_8m_1m_90
        );

    CORE: component np6532
        generic map (
            clk_ratio     => 3,             -- 96MHz : 32MHz
            ram_size_log2 => ram_size_log2, -- 18 c.w. 256kbytes
            jmp_rst       => x"FC00"        -- init code goes here
        )
        port map (
            rsti          => sys_rst_32m,
            rsto          => core_rst,
            clk_cpu       => sys_clk_32m,
            clk_mem       => sys_clk_96m,
            clken(0)      => sys_clken_96m_32m_0,
            clken(1)      => sys_clken_96m_32m_120,
            clken(2)      => sys_clken_96m_32m_240,
            hold          => '0',
            nmi           => '0',
            irq           => '0',
            if_al         => core_if_al,
            if_ap         => core_if_ap,
            if_z          => core_if_z,
            ls_al         => core_ls_al,
            ls_ap         => core_ls_ap,
            ls_en         => core_ls_en,
            ls_re         => core_ls_re,
            ls_we         => core_ls_we,
            ls_wp         => core_ls_wp,
            ls_z          => core_ls_z,
            ls_ext        => core_ls_ext,
            ls_drx        => core_ls_drx,
            ls_dwx        => core_ls_dwx,
            trace_stb     => open,
            trace_op      => open,
            trace_pc      => open,
            trace_s       => open,
            trace_p       => open,
            trace_a       => open,
            trace_x       => open,
            trace_y       => open,
            dma_en        => core_dma_en,
            dma_a         => core_dma_a,
            dma_bwe       => core_dma_bwe,
            dma_dw        => core_dma_dw,
            dma_dr        => core_dma_dr
        );

    DMAC: component otus_dmac
        generic map (
            ram_size_log2   => ram_size_log2
        )
        port map (
            clk_96m         => sys_clk_96m,
            clk_8m          => sys_clk_8m,
            rst_96m         => sys_rst_96m,
            rst_8m          => sys_rst_8m,
            clken_96m_32m_0 => sys_clken_96m_32m_0,
            clken_96m_8m    => sys_clken_96m_8m,
            clken_8m_2m_0   => sys_clken_8m_2m_0,
            clken_8m_2m_270 => sys_clken_8m_2m_270,
            alat_ssa        => alat_ssa,
            crtc_ma         => crtc_ma,
            crtc_ra         => crtc_ra,
            crtc_d          => crtc_d,
            vidproc_ttx     => vidproc_ttx,
            dma_en          => core_dma_en,
            dma_a           => core_dma_a,
            dma_bwe         => core_dma_bwe,
            dma_dw          => core_dma_dw,
            dma_dr          => core_dma_dr
        );

    MEMMAP: component otus_map
        generic map (
            ram_size_log2 => ram_size_log2
        )
        port map (
            clk         => sys_clk_32m,
            clken       => '1',
            rst         => core_rst,
            core_if_al  => core_if_al,
            core_if_ap  => core_if_ap,
            core_if_z   => core_if_z,
            core_ls_al  => core_ls_al,
            core_ls_ap  => core_ls_ap,
            core_ls_we  => core_ls_we,
            core_ls_z   => core_ls_z,
            core_ls_wp  => core_ls_wp,
            core_ls_ext => core_ls_ext,
            core_ls_dwx => core_ls_dwx,
            core_ls_drx => core_ls_drx,
            crtc_cs     => crtc_reg_cs,
            crtc_dr     => crtc_reg_dr,
            acia_cs     => open,
            acia_dr     => (others => '0'),
            serproc_cs  => open,
            serproc_dr  => (others => '0'),
            vidproc_cs  => vidproc_reg_cs,
            vidproc_dr  => (others => '0'),
            viaa_cs     => open,
            viaa_dr     => (others => '0'),
            viab_cs     => open,
            viab_dr     => (others => '0'),
            fdc_cs      => open,
            fdc_dr      => (others => '0'),
            adlc_cs     => open,
            adlc_dr     => (others => '0'),
            adc_cs      => open,
            adc_dr      => (others => '0'),
            tube_cs     => open,
            tube_dr     => (others => '0')
        );

    CRTC: component hd6845
        generic map (
            rst_f     => '1',
            rst_v     => "0011001" -- 25
        )  
        port map (
            reg_clk   => sys_clk_32m,
            reg_clken => '1',
            reg_rst   => core_rst,
            reg_cs    => crtc_reg_cs,
            reg_we    => core_ls_we,
            reg_rs    => core_ls_al(0),
            reg_dw    => core_ls_dwx,
            reg_dr    => crtc_reg_dr,
            crt_clk   => sys_clk_8m,
            crt_clken => crtc_clken,
            crt_rst   => sys_rst_8m,
            crt_ma    => crtc_ma,
            crt_ra    => crtc_ra,
            crt_f     => crtc_f,
            crt_vs    => crtc_vs,
            crt_hs    => crtc_hs,
            crt_vb    => crtc_vb,
            crt_hb    => crtc_hb,
            crt_de    => open, -- programmed for 1 clock skew for teletext, we don't want this
            crt_cur   => crtc_cur,
            crt_lps   => '0'
        );

    crtc_de <= crtc_vb nor crtc_hb;

    OVERSCAN: component otus_overscan
        generic map (
            v_ovr => 7,
            h_ovr => 1
        )
        port map (
            clk   => sys_clk_8m,
            clken => sys_clken_8m_2m_180,
            rst   => sys_rst_8m,
            ttx   => vidproc_ttx,
            f     => crtc_f,
            vs    => crtc_vs,
            hs    => crtc_hs,
            en    => crtc_oe
        );

    GENLOCK: component otus_genlock
        port map (
            clk     => sys_clk_8m,
            clken   => sys_clken_8m_2m_180,
            rst     => sys_rst_8m,
            f       => crtc_f,
            vs      => crtc_vs,
            hs      => crtc_hs,
            oe      => crtc_oe,
            genlock => vtg_genlock
        );

    TELETEXT: component saa5050d
        port map (
            rsta      => '0',
            debug     => '0',
            chr_clk   => sys_clk_8m,
            chr_clken => crtc_clken,
            chr_rst   => sys_rst_8m,
            chr_f     => crtc_ra(0),
            chr_vs    => crtc_vs,
            chr_hs    => crtc_hs,
            chr_gp    => crtc_oe,
            chr_de    => crtc_de,
            chr_d     => crtc_d(6 downto 0),
            pix_clk   => sys_clk_48m,
            pix_clken => sys_clken_48m_12m,
            pix_rst   => sys_rst_48m,
            pix_gp    => ttx_oe,
            pix_de    => ttx_pe,
            pix_du    => ttx_pu,
            pix_dl    => ttx_pl
        );

    VIDPROC: component otus_vidproc
        port map (
            clk_48m         => sys_clk_48m,
            clk_32m         => sys_clk_32m,
            clk_8m          => sys_clk_8m,
            rst_48m         => sys_rst_48m,
            rst_32m         => core_rst,
            rst_8m          => sys_rst_8m,
            clken_48m_16m   => sys_clken_48m_16m,
            clken_48m_12m   => sys_clken_48m_12m,
            clken_48m_8m    => sys_clken_48m_8m,
            clken_8m_4m     => sys_clken_8m_4m,
            clken_8m_2m_0   => sys_clken_8m_2m_0,
            clken_8m_2m_180 => sys_clken_8m_2m_180,
            clken_8m_1m_90  => sys_clken_8m_1m_90,
            reg_cs          => vidproc_reg_cs,
            reg_we          => core_ls_we,
            reg_rs          => core_ls_al(0),
            reg_dw          => core_ls_dwx,
            crtc_clken      => crtc_clken,
            crtc_cur        => crtc_cur,
            crtc_oe         => crtc_oe,
            crtc_de         => crtc_de,
            crtc_d          => crtc_d,
            ttx_en          => vidproc_ttx,
            ttx_oe          => ttx_oe,
            ttx_pe          => ttx_pe,
            ttx_pu          => ttx_pu,
            ttx_pl          => ttx_pl,
            out_clken       => vidproc_clken,
            out_pe          => vidproc_pe,
            out_p           => vidproc_p,
            out_p2          => vidproc_p2
        );

    VTG_MODE: component video_mode
        port map (
            mode      => MODE_1920x1080p50,
            clk_sel   => mode_clk_sel,
            dmt       => mode_dmt,
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

    VTG: component video_out_timing
        generic map (
            hold      => true
        )
        port map (
            rst       => vga_rst,
            clk       => vga_clk,
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
            genlock   => vtg_genlock,
            genlocked => vtg_genlocked,
            f         => open,
            vs        => vtg_vs,
            hs        => vtg_hs,
            vblank    => vtg_vblank,
            hblank    => vtg_hblank,
            ax        => vtg_ax,
            ay        => vtg_ay
        );

    vtg_de <= not (vtg_vblank or vtg_hblank);

    UPSCALE: component otus_upscale
        generic map (
            v_ovr => 7,
            h_ovr => 1
        )
        port map (
            in_clk   => sys_clk_48m,
            in_clken => vidproc_clken,
            in_rst   => sys_rst_48m,
            in_ttx   => vidproc_ttx,
            in_vrst  => crtc_vs,
            in_pe    => vidproc_pe,
            in_p     => vidproc_p,
            in_p2    => vidproc_p2,
            out_clk  => vga_clk,
            out_rst  => vga_rst,
            vtg_vs   => vtg_vs,
            vtg_hs   => vtg_hs,
            vtg_de   => vtg_de,
            vtg_ax   => vtg_ax,
            vtg_ay   => vtg_ay,
            vga_vs   => vga_vs,
            vga_hs   => vga_hs,
            vga_de   => vga_de,
            vga_r    => vga_r,
            vga_g    => vga_g,
            vga_b    => vga_b
        );

    pcm_l <= (others => '0');
    pcm_r <= (others => '0');


end architecture synth;
