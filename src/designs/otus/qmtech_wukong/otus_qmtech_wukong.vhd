--------------------------------------------------------------------------------
-- otus_qmtech_wukong.vhd                                                     --
-- QMTECH Wukong board wrapper for the Otus design.                           --
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
use work.otus_pkg.all;
use work.video_mode_pkg.all;
use work.vga_to_hdmi_pkg.all;
use work.serialiser_10to1_selectio_pkg.all;
use work.mmcm_pkg.all;
use work.video_out_clock_pkg.all;

entity otus_qmtech_wukong is
    port (

        -- clocks
        clki_50m        : in    std_logic;

        -- LEDs and keys
        led_n           : out   std_logic_vector(1 downto 0);
        key_n           : in    std_logic_vector(1 downto 0);

        -- serial (UART)
        ser_tx          : out   std_logic;
--      ser_rx          : in    std_logic;

        -- HDMI output
        hdmi_clk_p      : out   std_logic;
        hdmi_clk_n      : out   std_logic;
        hdmi_d_p        : out   std_logic_vector(0 to 2);
        hdmi_d_n        : out   std_logic_vector(0 to 2);
        hdmi_scl        : out   std_logic;
        hdmi_sda        : inout std_logic;
--      hdmi_cec        : out   std_logic;
--      hdmi_hpd        : in    std_logic;

        -- ethernet
        eth_rst_n       : out   std_logic;
--      eth_gtx_clk     : out   std_logic;
--      eth_txclk       : out   std_logic;
--      eth_txen        : out   std_logic;
--      eth_txer        : out   std_logic;
--      eth_txd         : out   std_logic_vector(7 downto 0);
--      eth_rxclk       : in    std_logic;
--      eth_rxdv        : in    std_logic;
--      eth_rxer        : in    std_logic;
--      eth_rxd         : in    std_logic_vector(7 downto 0);
--      eth_crs         : in    std_logic;
--      eth_col         : in    std_logic;
--      eth_mdc         : out   std_logic;
--      eth_mdio        : inout std_logic;

        -- DDR3
        ddr3_rst_n      : out   std_logic
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

        -- I/O connectors
--      j10             : inout std_logic_vector(7 downto 0);
--      j11             : inout std_logic_vector(7 downto 0);
--      jp2             : inout std_logic_vector(15 downto 0);
--      j12             : inout std_logic_vector(33 downto 0);

        -- MGTs
--      mgt_clk_p       : in    std_logic_vector(0 to 1);
--      mgt_clk_n       : in    std_logic_vector(0 to 1);
--      mgt_tx_p        : out   std_logic_vector(3 downto 0);
--      mgt_tx_n        : out   std_logic_vector(3 downto 0);
--      mgt_rx_p        : out   std_logic_vector(3 downto 0);
--      mgt_rx_n        : out   std_logic_vector(3 downto 0);

    );
end entity otus_qmtech_wukong;

architecture synth of otus_qmtech_wukong is

    signal ref_rst        : std_logic;                     -- reference reset
    signal ref_clk        : std_logic;                     -- reference clock

    signal sys_rst        : std_logic;                     -- system reset
    signal sys_clk_96m    : std_logic;                     -- system clock, 96 MHz
    signal sys_clk_48m    : std_logic;                     -- system clock, 48 MHz
    signal sys_clk_32m    : std_logic;                     -- system clock, 32 MHz
    signal sys_clk_8m     : std_logic;                     -- system clock, 8 MHz
                          
    signal pix_rst_d      : std_logic;                     -- pixel clock synchronous reset, before buffer/register
    signal pix_rst        : std_logic;                     -- pixel clock synchronous reset
    signal pix_clk        : std_logic;                     -- pixel clock (148.5 MHz for 1080p50)
    signal pix_clk_x5     : std_logic;                     -- pixel clock x5 for HDMI serialisers

    signal mode_clk_sel   : std_logic_vector(1 downto 0);  -- pixel frequency select
    signal mode_dmt       : std_logic;                     -- 1 = DMT, 0 = CEA
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

    signal vga_vs         : std_logic;                     -- VGA vertical sync
    signal vga_hs         : std_logic;                     -- VGA horizontal sync
    signal vga_de         : std_logic;                     -- VGA display enable
    signal vga_r          : std_logic_vector(7 downto 0);  -- VGA red
    signal vga_g          : std_logic_vector(7 downto 0);  -- VGA green
    signal vga_b          : std_logic_vector(7 downto 0);  -- VGA blue
                          
    signal pcm_rst        : std_logic;                     -- audio clock domain reset
    signal pcm_clk        : std_logic;                     -- audio clock (12.288 MHz)
    signal pcm_clken      : std_logic;                     -- audio clock enable @ 48kHz
    signal pcm_l          : std_logic_vector(15 downto 0); -- left channel  } audio sample,
    signal pcm_r          : std_logic_vector(15 downto 0); -- right channel } signed 16 bit
    signal pcm_acr        : std_logic;                     -- HDMI Audio Clock Regeneration packet strobe
    signal pcm_n          : std_logic_vector(19 downto 0); -- HDMI Audio Clock Regeneration packet N value
    signal pcm_cts        : std_logic_vector(19 downto 0); -- HDMI Audio Clock Regeneration packet CTS value

    signal tmds           : slv_9_0_t(0 to 2);             -- parallel TMDS channels

begin

    --------------------------------------------------------------------------------
    -- main design

    SYS: component otus
        port map (
            sys_rst     => sys_rst,
            sys_clk_96m => sys_clk_96m,
            sys_clk_48m => sys_clk_48m,
            sys_clk_32m => sys_clk_32m,
            sys_clk_8m  => sys_clk_8m,
            vga_rst     => pix_rst,
            vga_clk     => pix_clk,
            vga_vs      => vga_vs,
            vga_hs      => vga_hs,
            vga_de      => vga_de,
            vga_r       => vga_r,
            vga_g       => vga_g,
            vga_b       => vga_b,
            pcm_rst     => pcm_rst,
            pcm_clk     => pcm_clk,
            pcm_clken   => pcm_clken,
            pcm_l       => pcm_l,
            pcm_r       => pcm_r
        );

    led_n <= (others => '0');

    --------------------------------------------------------------------------------
    -- HDMI video and audio output

    HDMI_MODE: component video_mode
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

    HDMI_CONV: component vga_to_hdmi
        generic map (
            pcm_fs    => 48.0
        )
        port map (
            dvi       => '0',
            vic       => mode_id,
            pix_rep   => mode_pix_rep,
            aspect    => mode_aspect,
            vs_pol    => mode_vs_pol,
            hs_pol    => mode_hs_pol,
            vga_rst   => pix_rst,
            vga_clk   => pix_clk,
            vga_vs    => vga_vs,
            vga_hs    => vga_hs,
            vga_de    => vga_de,
            vga_r     => vga_r,
            vga_g     => vga_g,
            vga_b     => vga_b,
            pcm_rst   => pcm_rst,
            pcm_clk   => pcm_clk,
            pcm_clken => pcm_clken,
            pcm_l     => pcm_l,
            pcm_r     => pcm_r,
            pcm_acr   => pcm_acr,
            pcm_n     => pcm_n,
            pcm_cts   => pcm_cts,
            tmds      => tmds
        );

    GEN_HDMI_DATA: for i in 0 to 2 generate
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
    end generate GEN_HDMI_DATA;

    HDMI_CLK: component serialiser_10to1_selectio
        port map (
            rst    => pix_rst,
            clk    => pix_clk,
            clk_x5 => pix_clk_x5,
            d      => "0000011111",
            out_p  => hdmi_clk_p,
            out_n  => hdmi_clk_n
        );

    --------------------------------------------------------------------------------
    -- clock generation

    CLK_REF: component mmcm
        generic map (
            mul         => 20.0,
            div         => 1,
            num_outputs => 1,
            odiv0       => 10.0
        )
        port map (
            rsti        => not key_n(0),
            clki        => clki_50m,
            rsto        => ref_rst,
            clko(0)     => ref_clk
        );

    CLK_SYS: component mmcm
        generic map (
            mul         => 48.0,
            div         => 5,
            num_outputs => 4,
            odiv0       => 10.0,
            odiv        => (20,30,120,0,0,0),
            duty_cycle  => (0.5,0.5,0.3,0.5,0.5,0.5,0.5)
        )
        port map (
            rsti        => ref_rst,
            clki        => ref_clk,
            rsto        => sys_rst,
            clko(0)     => sys_clk_96m,
            clko(1)     => sys_clk_48m,
            clko(2)     => sys_clk_32m,
            clko(3)     => sys_clk_8m
        );

    CLK_PIX: component video_out_clock
        generic map (
            fref    => 100.0
        )
        port map (
            rsti    => ref_rst,
            clki    => ref_clk,
            sel     => "11", -- 148.5 MHz
            rsto    => pix_rst_d,
            clko    => pix_clk,
            clko_x5 => pix_clk_x5
        );

    process(pix_clk)
    begin
        if rising_edge(pix_clk) then
            pix_rst <= pix_rst_d; -- should allow register duplication => better timing closure
        end if;
    end process;

    CLK_PCM: component mmcm
        generic map (
            mul         => 48.0,
            div         => 5,
            num_outputs => 1,
            odiv0       => 78.125
        )
        port map (
            rsti        => ref_rst,
            clki        => ref_clk,
            rsto        => pcm_rst,
            clko(0)     => pcm_clk
        );

    --------------------------------------------------------------------------------
    -- unused I/O

    ser_tx     <= '1';
    hdmi_scl   <= 'Z';
    hdmi_sda   <= 'Z';
    eth_rst_n  <= '0';
    ddr3_rst_n <= '0';

    --------------------------------------------------------------------------------

end architecture synth;
