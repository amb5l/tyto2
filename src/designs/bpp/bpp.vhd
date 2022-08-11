--------------------------------------------------------------------------------
-- bpp.vhd                                                                    --
-- BBC Micro model B++.                                                       --
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

package bpp_pkg is

    component bpp is
        port (

            sys_rst       : in  std_logic;
            sys_clk_96m   : in  std_logic;
            sys_clk_48m   : in  std_logic;
            sys_clk_32m   : in  std_logic;
            sys_clk_8m    : in  std_logic;

            led_capslock  : out std_logic;
            led_shiftlock : out std_logic;
            led_motor     : out std_logic;

            kbd_rst       : out std_logic;                    -- keyboard: reset
            kbd_break     : in  std_logic;                    -- keyboard: BREAK pressed
            kbd_en        : out std_logic;                    -- keyboard: enable
            kbd_row       : out std_logic_vector(2 downto 0); -- keyboard: row (0-7)
            kbd_col       : out std_logic_vector(3 downto 0); -- keyboard: column (0-9)
            kbd_press     : in  std_logic;                    -- keyboard: open/broken (1) or closed/made (0)
            kbd_colact    : in  std_logic;                    -- keyboard: column active

            crtc_clksel   : out std_logic;                    -- CRTC: clock select (1 = 2 MHz, 0 = 1 MHz)
            crtc_clken    : out std_logic;                    -- CRTC: clock enable (w.r.t. sys_clk_8m)
            crtc_rst      : out std_logic;                    -- CRTC: reset
            crtc_f        : out std_logic;                    -- CRTC: field (0 = 1st/odd/upper, 1 = 2nd/even/lower)
            crtc_vs       : out std_logic;                    -- CRTC: vertical sync
            crtc_hs       : out std_logic;                    -- CRTC: horizontal sync
            crtc_de       : out std_logic;                    -- CRTC: display enable
            crtc_oe       : in  std_logic;                    -- CRTC: overscan enable

            vidproc_clken : out std_logic;                    -- VIDPROC: clock enable (w.r.t. sys_clk_48m)
            vidproc_rst   : out std_logic;                    -- VIDPROC: reset
            vidproc_ttx   : out std_logic;                    -- VIDPROC: teletext mode (scan doubling)
            vidproc_pe    : out std_logic;                    -- VIDPROC: pixel enable
            vidproc_p     : out std_logic_vector(2 downto 0); -- VIDPROC: pixel data (BGR)
            vidproc_p2    : out std_logic_vector(2 downto 0); -- VIDPROC: pixel data (BGR) (for scan doubling)

            lp_stb        : in  std_logic;

            paddle_btn    : in  std_logic_vector(1 downto 0);
            paddle_eoc    : in  std_logic;

            sg_clken      : out std_logic;                    -- sound generator: clock enable (w.r.t. clk_8m)
            sg_pcm        : out std_logic_vector(1 downto 0)  -- sound generator output

        );
    end component bpp;

end package bpp_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.bpp_conductor_pkg.all;
use work.np6532_pkg.all;
use work.bpp_dmac_pkg.all;
use work.bpp_map_pkg.all;
use work.hd6845_pkg.all;
use work.saa5050d_pkg.all;
use work.bpp_vidproc_pkg.all;
use work.bpp_sysvia_pkg.all;

entity bpp is
    port (

        sys_rst       : in  std_logic;
        sys_clk_96m   : in  std_logic;
        sys_clk_48m   : in  std_logic;
        sys_clk_32m   : in  std_logic;
        sys_clk_8m    : in  std_logic;

        led_capslock  : out std_logic;
        led_shiftlock : out std_logic;
        led_motor     : out std_logic;

        kbd_rst       : out std_logic;                    -- keyboard: reset
        kbd_break     : in  std_logic;                    -- keyboard: BREAK pressed
        kbd_en        : out std_logic;                    -- keyboard: enable
        kbd_row       : out std_logic_vector(2 downto 0); -- keyboard: row (0-7)
        kbd_col       : out std_logic_vector(3 downto 0); -- keyboard: column (0-9)
        kbd_press     : in  std_logic;                    -- keyboard: open/broken (1) or closed/made (0)
        kbd_colact    : in  std_logic;                    -- keyboard: column active

        crtc_clksel   : out std_logic;                    -- CRTC: clock select (1 = 2 MHz, 0 = 1 MHz)
        crtc_rst      : out std_logic;                    -- CRTC: reset
        crtc_clken    : out std_logic;                    -- CRTC: clock enable (w.r.t. sys_clk_8m)
        crtc_f        : out std_logic;                    -- CRTC: field (0 = 1st/odd/upper, 1 = 2nd/even/lower)
        crtc_vs       : out std_logic;                    -- CRTC: vertical sync
        crtc_hs       : out std_logic;                    -- CRTC: horizontal sync
        crtc_de       : out std_logic;                    -- CRTC: display enable
        crtc_oe       : in  std_logic;                    -- CRTC: overscan enable

        vidproc_clken : out std_logic;                    -- VIDPROC: clock enable (w.r.t. sys_clk_48m)
        vidproc_rst   : out std_logic;                    -- VIDPROC: reset
        vidproc_ttx   : out std_logic;                    -- VIDPROC: teletext mode (scan doubling)
        vidproc_pe    : out std_logic;                    -- VIDPROC: pixel enable
        vidproc_p     : out std_logic_vector(2 downto 0); -- VIDPROC: pixel data (BGR)
        vidproc_p2    : out std_logic_vector(2 downto 0); -- VIDPROC: pixel data (BGR) (for scan doubling)

        lp_stb        : in  std_logic;

        paddle_btn    : in  std_logic_vector(1 downto 0);
        paddle_eoc    : in  std_logic;

        sg_clken      : out std_logic;                    -- sound generator: clock enable (w.r.t. clk_8m)
        sg_pcm        : out std_logic_vector(1 downto 0)  -- sound generator output

    );
end entity bpp;

architecture synth of bpp is

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
    signal core_nmi              : std_logic;
    signal core_irq              : std_logic;
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
    signal crtc_clken_i          : std_logic;                                  -- CRTC: 2MHz or 1MHz clken from VIDPROC

    signal crtc_sa               : std_logic_vector(1 downto 0);               -- CRTC: screen start address (from addressable latch)
    signal crtc_ma               : std_logic_vector(13 downto 0);              -- CRTC: memory address
    signal crtc_ra               : std_logic_vector(4 downto 0);               -- CRTC: raster (scan line) address within character
    signal crtc_vs_i             : std_logic;                                  -- CRTC: vertical sync (internal)
    signal crtc_hs_i             : std_logic;                                  -- CRTC: horizontal blank (internal)
    signal crtc_vb               : std_logic;                                  -- CRTC: vertical blank
    signal crtc_hb               : std_logic;                                  -- CRTC: horizontal sync
    signal crtc_de_i             : std_logic;                                  -- CRTC: display enable (internal)
    signal crtc_cur              : std_logic;                                  -- CRTC: cursor
    signal crtc_d                : std_logic_vector(7 downto 0);               -- CRTC: data (fetched from memory)

    signal ttx_oe                : std_logic;                                  -- teletext: overscan pixel enable
    signal ttx_pe                : std_logic;                                  -- teletext: pixel enable
    signal ttx_pu                : std_logic_vector(2 downto 0);               -- teletext: pixel (3 bit BGR) (12 pixels per character) (upper line)
    signal ttx_pl                : std_logic_vector(2 downto 0);               -- teletext: pixel (3 bit BGR) (12 pixels per character) (lower line)

    signal vidproc_reg_cs        : std_logic;
    signal vidproc_ttx_i         : std_logic;                                  -- VIDPROC: teletext mode

    signal viaa_cs               : std_logic;
    signal viaa_dr               : std_logic_vector(7 downto 0);
    signal viaa_irq              : std_logic;

    signal sg_we                 : std_logic;                                  -- sound generator: write enable
    signal sg_dw                 : std_logic_vector(7 downto 0);               -- sound generator: write data

    signal sp_re                 : std_logic;                                  -- speech processor: read enable
    signal sp_we                 : std_logic;                                  -- speech processor: write enable
    signal sp_dw                 : std_logic_vector(7 downto 0);               -- speech processor: write data
    signal sp_dr                 : std_logic_vector(7 downto 0);               -- speech processor: read data
    signal sp_int                : std_logic;                                  -- speech processor: interrupt
    signal sp_rdy                : std_logic;                                  -- speech processor: ready

begin

    --------------------------------------------------------------------------------
    -- resets, clocks and clock enables

    CONDUCTOR: component bpp_conductor
        port map (
            clk_lock        => sys_rst nor kbd_break,
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

    --------------------------------------------------------------------------------
    -- interrupts

    core_nmi <= '0';

    core_irq <=
        viaa_irq;

    --------------------------------------------------------------------------------
    -- core comprising CPU and memory

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
            nmi           => core_nmi,
            irq           => core_irq,
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

    --------------------------------------------------------------------------------
    -- DMA controller

    DMAC: component bpp_dmac
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
            crtc_sa         => crtc_sa,
            crtc_ma         => crtc_ma,
            crtc_ra         => crtc_ra,
            crtc_d          => crtc_d,
            vidproc_ttx     => vidproc_ttx_i,
            dma_en          => core_dma_en,
            dma_a           => core_dma_a,
            dma_bwe         => core_dma_bwe,
            dma_dw          => core_dma_dw,
            dma_dr          => core_dma_dr
        );

    --------------------------------------------------------------------------------
    -- memory map and RAM/ROM bank control

    MEMMAP: component bpp_map
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
            viaa_cs     => viaa_cs,
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

    --------------------------------------------------------------------------------
    -- CRTC (video timing generator)

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
            crt_clken => crtc_clken_i,
            crt_rst   => sys_rst_8m,
            crt_ma    => crtc_ma,
            crt_ra    => crtc_ra,
            crt_f     => crtc_f,
            crt_vs    => crtc_vs_i,
            crt_hs    => crtc_hs_i,
            crt_vb    => crtc_vb,
            crt_hb    => crtc_hb,
            crt_de    => open, -- programmed for 1 clock skew for teletext, we don't want this, see below
            crt_cur   => crtc_cur,
            crt_lps   => '0'
        );

    crtc_clken <= crtc_clken_i;
    crtc_rst   <= sys_rst_8m;
    crtc_vs    <= crtc_vs_i;
    crtc_hs    <= crtc_hs_i;
    crtc_de_i  <= crtc_vb nor crtc_hb;
    crtc_de    <= crtc_de_i;

    --------------------------------------------------------------------------------
    -- teletext character generator

    TELETEXT: component saa5050d
        port map (
            rsta      => '0',
            debug     => '0',
            chr_clk   => sys_clk_8m,
            chr_clken => crtc_clken_i,
            chr_rst   => sys_rst_8m,
            chr_f     => crtc_ra(0),
            chr_vs    => crtc_vs_i,
            chr_hs    => crtc_hs_i,
            chr_gp    => crtc_oe,
            chr_de    => crtc_de_i,
            chr_d     => crtc_d(6 downto 0),
            pix_clk   => sys_clk_48m,
            pix_clken => sys_clken_48m_12m,
            pix_rst   => sys_rst_48m,
            pix_gp    => ttx_oe,
            pix_de    => ttx_pe,
            pix_du    => ttx_pu,
            pix_dl    => ttx_pl
        );

    --------------------------------------------------------------------------------
    -- video ULA

    VIDPROC: component bpp_vidproc
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
            crtc_clksel     => crtc_clksel,
            crtc_clken      => crtc_clken_i,
            crtc_cur        => crtc_cur,
            crtc_oe         => crtc_oe,
            crtc_de         => crtc_de_i,
            crtc_d          => crtc_d,
            ttx_en          => vidproc_ttx_i,
            ttx_oe          => ttx_oe,
            ttx_pe          => ttx_pe,
            ttx_pu          => ttx_pu,
            ttx_pl          => ttx_pl,
            out_clken       => vidproc_clken,
            out_pe          => vidproc_pe,
            out_p           => vidproc_p,
            out_p2          => vidproc_p2
        );

    vidproc_ttx   <= vidproc_ttx_i;

    --------------------------------------------------------------------------------
    -- VIA A: system VIA

    VIA_A: component bpp_sysvia
        port map (
            clk_32m     => sys_clk_32m,
            clk_8m      => sys_clk_8m,
            rst_32m     => sys_rst_32m,
            rst_8m      => sys_rst_8m,
            clken_8m_1m => sys_clken_8m_1m_0,
            reg_cs      => viaa_cs,
            reg_we      => core_ls_we,
            reg_rs      => core_ls_al(3 downto 0),
            reg_dw      => core_ls_dwx,
            reg_dr      => viaa_dr,
            reg_irq     => viaa_irq,
            kbd_en      => kbd_en,
            kbd_col     => kbd_col,
            kbd_row     => kbd_row,
            kbd_press   => kbd_press,
            kbd_colact  => kbd_colact,
            kbd_led_c   => led_capslock,
            kbd_led_s   => led_shiftlock,
            crtc_sa     => crtc_sa,
            crtc_vs     => crtc_vs_i,
            lp_stb      => lp_stb,
            paddle_eoc  => paddle_eoc,
            paddle_btn  => paddle_btn,
            sg_we       => sg_we,
            sg_dw       => sg_dw,
            sp_re       => sp_re,
            sp_we       => sp_we,
            sp_dw       => sp_dw,
            sp_dr       => sp_dr,
            sp_int      => sp_int,
            sp_rdy      => sp_rdy
        );

    --------------------------------------------------------------------------------
    -- sound generator

    sg_pcm <= "00";

    --------------------------------------------------------------------------------
    -- speech processor
    
    sp_dr <= x"00";
    sp_int <= '0';

    --------------------------------------------------------------------------------
    -- misc

    kbd_rst <= sys_rst_32m;

    --------------------------------------------------------------------------------

end architecture synth;
