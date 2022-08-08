--------------------------------------------------------------------------------
-- tb_mb_cb_digilent_nexys_video.vhd                                          --
-- Simulation testbench for mb_cb_digilent_nexys_video.vhd.                   --
--------------------------------------------------------------------------------
-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --
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

library std;
use std.env.all;

library work;
use work.model_dvi_decoder_pkg.all;
use work.model_vga_sink_pkg.all;

entity tb_mb_cb_digilent_nexys_video is
end entity tb_mb_cb_digilent_nexys_video;

architecture sim of tb_mb_cb_digilent_nexys_video is

    signal clki_100m        : std_logic;
    signal btn_rst_n        : std_logic;
    signal led              : std_logic_vector(7 downto 0);

    signal hdmi_tx_clk_p    : std_logic;
    signal hdmi_tx_clk_n    : std_logic;
    signal hdmi_tx_d_p      : std_logic_vector(0 to 2);
    signal hdmi_tx_d_n      : std_logic_vector(0 to 2);

    signal vga_clk          : std_logic;
    signal vga_vs           : std_logic;
    signal vga_hs           : std_logic;
    signal vga_de           : std_logic;
    signal vga_r            : std_logic_vector(7 downto 0);
    signal vga_g            : std_logic_vector(7 downto 0);
    signal vga_b            : std_logic_vector(7 downto 0);

    signal cap_stb          : std_logic;

    component mb_cb_digilent_nexys_video is
        port (
            clki_100m     : in    std_logic;
            led           : out   std_logic_vector(7 downto 0);
            btn_rst_n     : in    std_logic;
            oled_res_n    : out   std_logic;
            oled_d_c      : out   std_logic;
            oled_sclk     : out   std_logic;
            oled_sdin     : out   std_logic;
            hdmi_tx_clk_p : out   std_logic;
            hdmi_tx_clk_n : out   std_logic;
            hdmi_tx_d_p   : out   std_logic_vector(0 to 2);
            hdmi_tx_d_n   : out   std_logic_vector(0 to 2);
            ac_mclk       : out   std_logic;
            ac_dac_sdata  : out   std_logic;
            uart_rx_out   : out   std_logic;
            uart_tx_in    : in    std_logic;
            eth_rst_n     : out   std_logic;
            ftdi_rd_n     : out   std_logic;
            ftdi_wr_n     : out   std_logic;
            ftdi_siwu_n   : out   std_logic;
            ftdi_oe_n     : out   std_logic;
            ps2_clk       : inout std_logic;
            ps2_data      : inout std_logic;
            qspi_cs_n     : out   std_logic;
            ddr3_reset_n  : out   std_logic
        );
    end component mb_cb_digilent_nexys_video;

begin

    clki_100m <=
        '1' after 5ns when clki_100m = '0' else
        '0' after 5ns when clki_100m = '1' else
        '0';

    process
    begin
        btn_rst_n <= '0';
        wait for 20ns;
        btn_rst_n <= '1';
        wait until rising_edge(cap_stb);
        stop;
    end process;

    UUT: component mb_cb_digilent_nexys_video
        port map (
            clki_100m     => clki_100m,
            led           => led,
            btn_rst_n     => btn_rst_n,
            oled_res_n    => open,
            oled_d_c      => open,
            oled_sclk     => open,
            oled_sdin     => open,
            hdmi_tx_clk_p => hdmi_tx_clk_p,
            hdmi_tx_clk_n => hdmi_tx_clk_n,
            hdmi_tx_d_p   => hdmi_tx_d_p,
            hdmi_tx_d_n   => hdmi_tx_d_n,
            ac_mclk       => open,
            ac_dac_sdata  => open,
            uart_rx_out   => open,
            uart_tx_in    => '1',
            eth_rst_n     => open,
            ftdi_rd_n     => open,
            ftdi_wr_n     => open,
            ftdi_siwu_n   => open,
            ftdi_oe_n     => open,
            ps2_clk       => open,
            ps2_data      => open,
            qspi_cs_n     => open,
            ddr3_reset_n  => open
        );

    DECODE: component model_dvi_decoder
        port map (
            dvi_clk  => hdmi_tx_clk_p,
            dvi_d    => hdmi_tx_d_p,
            vga_clk  => vga_clk,
            vga_vs   => vga_vs,
            vga_hs   => vga_hs,
            vga_de   => vga_de,
            vga_p(2) => vga_r,
            vga_p(1) => vga_g,
            vga_p(0) => vga_b
        );

    CAPTURE: component model_vga_sink
        generic map (
            name        => "tb_mb_cb_digilent_nexys_video"
        )
        port map (
            vga_rst  => '0',
            vga_clk  => vga_clk,
            vga_vs   => vga_vs,
            vga_hs   => vga_hs,
            vga_de   => vga_de,
            vga_r    => vga_r,
            vga_g    => vga_g,
            vga_b    => vga_b,
            cap_rst  => '0',
            cap_stb  => cap_stb
        );

end architecture sim;
