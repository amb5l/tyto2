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

            --
            -- raw video out


        );
    end component otus;

end package otus_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.np6532s_pkg.all;

entity otus is
    port (

        rst         : in  std_logic;    -- reset (asynchronous)

        clk_96m     : in  std_logic;    -- fast system clock
        clk_48m     : in  std_logic;    -- master pixel clock
        clk_32m     : in  std_logic;    -- CPU clock
        clk_8m      : in  std_logic;    -- I/O clock

        pix_clken   : out std_logic;    -- pixel rate is 16/12/8/4/2 MHz
        pix_de      : out std_logic;
        pix_d       : out std_logic_vector(2 downto 0); -- BGR

        kbd_rst     : in  std_logic;
        kbd_en      : out std_logic;
        kbd_col     : out std_logic_vector(3 downto 0);
        kbd_row     : out std_logic_vector(2 downto 0);
        kbd_press   : in  std_logic;

        mmc_sel_n   : out std_logic;    -- MMC select
        mmc_sclk    : out std_logic;    -- MMC serial clock
        mmc_mosi    : out std_logic;    -- MMC serial out
        mmc_miso    : in  std_logic     -- MMC serial in

    );
end entity otus;

architecture synth of otus is

    constant ram_size_log2  : integer := 18; -- 256kbytes

    signal clken_48m_16m    : std_logic;    -- base pixel rate for modes 0..6
    signal clken_48m_12m    : std_logic;    -- base pixel rate for mode 7

    signal clken_32m_2m     : std_logic;    -- 2MHz CPU (in legacy speed mode)
    signal clken_8m_2m      : std_logic;    -- 2MHz misc I/O devices
    signal clken_8m_crtc    : std_logic;    -- 2MHz/1MHz character rate to 6845 (interleaved with 2MHz CPU)
    signal clken_8m_1m      : std_logic;    -- 1MHz misc I/O devices


    signal core_if_al       : std_logic_vector(15 downto 0);
    signal core_if_ap       : std_logic_vector(ram_size_log2-1 downto 0);
    signal core_if_z        : std_logic;
    signal core_ls_al       : std_logic_vector(15 downto 0);
    signal core_ls_ap       : std_logic_vector(ram_size_log2-1 downto 0);
    signal core_ls_en       : std_logic;
    signal core_ls_re       : std_logic;
    signal core_ls_we       : std_logic;
    signal core_ls_z        : std_logic;
    signal core_ls_wp       : std_logic;
    signal core_ls_ext      : std_logic;
    signal core_ls_drx      : std_logic_vector(7 downto 0);
    signal core_ls_dwx      : std_logic_vector(7 downto 0);
    signal core_trace_stb   : std_logic;
    signal core_trace_pc    : std_logic_vector(15 downto 0);
    signal core_dma_a       : std_logic_vector(ram_size_log2-1 downto 3);
    signal core_dma_bwe     : std_logic_vector(7 downto 0);
    signal core_dma_dw      : std_logic_vector(63 downto 0);
    signal core_dma_dr      : std_logic_vector(63 downto 0);


    signal crtc_clken       : std_logic;
    signal crtc_reg_cs      : std_logic;
    signal crtc_reg_dr      : std_logic_vector(7 downto 0);
    signal crtc_ra          : std_logic_vector(4 downto 0);
    signal crtc_a           : std_logic_vector(14 downto 0);
    signal crtc_vs          : std_logic;
    signal crtc_hs          : std_logic;
    signal crtc_de          : std_logic;
    signal crtc_cur         : std_logic;
    signal crtc_ttx         : std_logic;

    signal acia_reg_cs      : std_logic;
    signal acia_reg_dr      : std_logic_vector(7 downto 0);

    signal serproc_reg_cs   : std_logic;
    signal serproc_reg_dr   : std_logic_vector(7 downto 0);

    signal ttx_tn           : std_logic_vector(5 downto 0); -- teletext pixel tile number (0-63)
    signal ttx_tf           : std_logic_vector(2 downto 0); -- teletext pixel tile foreground colour
    signal ttx_tb           : std_logic_vector(2 downto 0); -- teletext pixel tile background colour
    signal ttx_te           : std_logic;                    -- teletext pixel tile enable

    signal vidproc_reg_cs   : std_logic;
    signal vidproc_reg_dr   : std_logic_vector(7 downto 0);

    signal viaa_cs          : std_logic;
    signal viaa_dr          : std_logic_vector(7 downto 0);

    signal viab_reg_cs      : std_logic;
    signal viab_reg_dr      : std_logic_vector(7 downto 0);

    signal fdc_reg_cs       : std_logic;
    signal fdc_reg_dr       : std_logic_vector(7 downto 0);

    signal adlc_reg_cs      : std_logic;
    signal adlc_reg_dr      : std_logic_vector(7 downto 0);

    signal adc_reg_cs       : std_logic;
    signal adc_reg_dr       : std_logic_vector(7 downto 0);

    signal tube_reg_cs      : std_logic;
    signal tube_reg_dr      : std_logic_vector(7 downto 0);


    attribute keep_hierarchy : string;
    attribute keep_hierarchy of CORE : label is "yes";



begin

    --------------------------------------------------------------------------------
    -- timing (resets and clock enables)

    U_TIMING: component otus_conductor
        port map (

            rst           => rst or kbd_rst,
            clk_48m       => clk_48m,
            clk_32m       => clk_32m,
            clk_8m        => clk_8m,

            rst_48m       => rst_48m,
            clken_48m_16m => clken_48m_16m,
            clken_48m_12m => clken_48m_12m,

            rst_32m       => rst_32m,
            clken_32m_2m  => clken_cpu_2m,

            rst_8m        => rst_8m,
            clken_8m_4m   => clk_8m_4m,
            clken_8m_2m   => clk_8m_4m,
            clken_8m_1m   => clk_8m_1m

        );

    --------------------------------------------------------------------------------

    U_CORE: component np6532
        generic map (
            clk_ratio     => 3,             -- 96MHz : 32 MHz
            ram_size_log2 => ram_size_log2, -- 18 c.w. 256k
            vector_init   => x"FC00"        -- init code goes here
        )
        port map (
            rsti        => rst_32m,
            rsto        => open,
            clk_cpu     => clk_32m,
            clk_mem     => clk_96m,
            clken       => clken_cpu,
            hold        => core_hold,
            nmi         => core_nmi,
            irq         => core_irq,
            if_al       => core_if_al,
            if_ap       => core_if_ap(ram_size_log2-1 downto 0),
            if_z        => core_if_z,
            ls_al       => core_ls_al,
            ls_ap       => core_ls_ap(ram_size_log2-1 downto 0),
            ls_en       => core_ls_en,
            ls_re       => core_ls_re,
            ls_we       => core_ls_we,
            ls_wp       => core_ls_wp,
            ls_ext      => core_ls_ext,
            ls_drx      => core_ls_drx,
            ls_dwx      => core_ls_dwx,
            trace_stb   => core_trace_stb,
            trace_op    => core_trace_op,
            trace_pc    => core_trace_pc,
            trace_s     => core_trace_s,
            trace_p     => core_trace_p,
            trace_a     => core_trace_a,
            trace_x     => core_trace_x,
            trace_y     => core_trace_y,
            dma_en      =>
            dma_a       => core_dma_a,
            dma_bwe     => core_dma_bwe,
            dma_dw      => core_dma_dw,
            dma_dr      => core_dma_dr
        );

    --------------------------------------------------------------------------------
    -- memory and I/O mapping, including sideways bank switching

    U_MAP: component otus_map
        generic map (
            ram_size_log2 => ram_size_log2
        )
        port map (
            clk            => clk_cpu,
            clken          => clken_cpu,
            rst            => rst_cpu,
            core_if_al     => core_if_al,
            core_if_ap     => core_if_ap,
            core_if_z      => core_if_z,
            core_ls_al     => core_ls_al,
            core_ls_ap     => core_ls_ap,
            core_ls_we     => core_ls_we,
            core_ls_z      => core_ls_z,
            core_ls_wp     => core_ls_wp,
            core_ls_ext    => core_ls_ext,
            core_ls_dwx    => core_ls_dwx,
            core_ls_drx    => core_ls_drx,
            crtc_reg_cs    => crtc_reg_cs,
            crtc_reg_dr    => crtc_reg_dr,
            acia_reg_cs    => acia_reg_cs,
            acia_reg_dr    => acia_reg_dr,
            serproc_reg_cs => serproc_reg_cs,
            serproc_reg_dr => serproc_reg_dr,
            vidproc_reg_cs => vidproc_reg_cs,
            vidproc_reg_dr => vidproc_reg_dr,
            viaa_reg_cs    => viaa_reg_cs,
            viaa_reg_dr    => viaa_reg_dr,
            viab_reg_cs    => viab_reg_cs,
            viab_reg_dr    => viab_reg_dr,
            fdc_reg_cs     => fdc_reg_cs,
            fdc_reg_dr     => fdc_reg_dr,
            adlc_reg_cs    => adlc_reg_cs,
            adlc_reg_dr    => adlc_reg_dr,
            adc_reg_cs     => adc_reg_cs,
            adc_reg_dr     => adc_reg_dr,
            tube_reg_cs    => tube_reg_cs,
            tube_reg_dr    => tube_reg_dr
        );

    --------------------------------------------------------------------------------
    -- DMA bridge including CRTC addressing/wrapping

    U_DMAB: component otus_dmab
        port map (
            cpu_clk     => cpu_clk,
            cpu_clken   => cpu_clken,
            cpu_rst     => cpu_rst
            cpu_hold    => cpu_hold,
            dma_a       => dma_a,
            dma_bwe     => dma_bwe,
            dma_dw      => dma_dw,
            dma_dr      => dma_dr
            crt_map     => crt_map,
            crt_clk     => clk_8m,
            crt_clken   => clken_8m_2m,
            crt_ma      => crt_ma,
            crt_ra      => crt_ra,
            crt_d       => crt_d,
        );

    --------------------------------------------------------------------------------

    U_CRTC: component hd6845
        port map (
            reg_clk   => cpu_clk,
            reg_clken => cpu_clken,
            reg_rst   => cpu_rst,
            reg_cs    => crtc_reg_cs,
            reg_we    => ls_we,
            reg_rs    => ls_al(0),
            reg_dw    => ls_dwx,
            reg_dr    => crtc_reg_dr,
            crtc_clk   => clk_8m,
            crtc_clken => crt_clken,
            crtc_rst   => rst_1m,
            crtc_ma    => crt_ma,
            crtc_ra    => crt_ra,
            crtc_vs    => crt_vs,
            crtc_hs    => crt_hs,
            crtc_vb    => open,
            crtc_hb    => open,
            crtc_de    => crt_de,
            crtc_cur   => crt_cur,
            crtc_lps   => '0'
        );

    --------------------------------------------------------------------------------

    U_TTX: component saa5050
        port map (
            chr_clk   => clk_8m,
            chr_clken => clken_8m_1m,
            chr_rst   => rst_1m,
            chr_f     => crt_ra(0),
            chr_vs    => crt_vs,
            chr_hs    => crt_hs,
            chr_de    => crt_de,
            chr_d     => crt_d,
            pix_clk   => clk_48m,
            pix_clken => clken_48m_12m,
            pix_rst   => crt_rst,
            pix_d     => ttx_pix_d,
            pix_de    => ttx_pix_de
        );

    --------------------------------------------------------------------------------

    U_VIDPROC: component otus_vidproc
        port map (

            reg_clk       => cpu_clk,       -- register access by CPU
            reg_clken     => cpu_clken,     --
            reg_rst       => cpu_rst,       --
            reg_cs        => vidproc_cs,    --
            reg_we        => ls_we,         --
            reg_rs        => ls_al(0),      --
            reg_dw        => ls_dwx,        --
            reg_dr        => vidproc_dr,    --

            crt_clk       => clk_8m,        -- CRTC clock switching
            crt_clken_2m  => clken_8m_2m,   --
            crt_clken_1m  => clken_8m_1m,   --
            crt_clken     => crt_clken,     --
            crt_cur       => crt_cur,       -- cursor active
            crt_de        => crt_d,         -- CRTC data enable
            crt_d         => crt_d,         -- CRTC data (from DMA bridge)

            pix_clk       => clk_48m,       -- master pixel clock (48MHz)

            pix_clken_16m => clken_48m_16m, -- sets pixel rate (16/12/8/4/2 MHz)
            pix_clken_12m => clken_48m_12m, -- sets pixel rate (16/12/8/4/2 MHz)
            pix_clken_8m  => clken_48m_8m,  -- sets pixel rate (16/12/8/4/2 MHz)
            pix_clken_4m  => clken_48m_4m,  -- sets pixel rate (16/12/8/4/2 MHz)
            pix_clken_2m  => clken_48m_2m,  -- sets pixel rate (16/12/8/4/2 MHz)
            pix_clken     =>

            pix_rst       => rst_48m,       -- pixel clock domain reset
            pix_de        => pix_de         -- pixel data enable
            pix_d         => pix_d          -- pixel data (BGR until we implement VideoNULA)

            ttx_pix_de    => ttx_pix_de,    -- teletext pixel data enable
            ttx_pix_d     => ttx_pix_d,     -- teletext pixel data (BGR)

        );

    --------------------------------------------------------------------------------

    -- U_FDC:

    --------------------------------------------------------------------------------

    -- U_VIAA:

        kbd_en      : out std_logic;
        kbd_col     : out std_logic_vector(3 downto 0);
        kbd_row     : out std_logic_vector(2 downto 0);
        kbd_press   : in  std_logic;

    --------------------------------------------------------------------------------

    -- U_VIAB:
    -- U_ADC:
    -- U_ACIA:
    -- U_SERPROC:
    -- U_ADLC:
    -- U_TUBE:

    --------------------------------------------------------------------------------

end architecture synth;
