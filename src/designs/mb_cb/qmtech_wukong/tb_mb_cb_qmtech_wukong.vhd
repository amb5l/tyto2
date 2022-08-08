--------------------------------------------------------------------------------
-- tb_mb_cb_qmtech_wukong.vhd                                                 --
-- Simulation testbench for mb_cb_qmtech_wukong.vhd.                          --
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

entity tb_mb_cb_qmtech_wukong is
end entity tb_mb_cb_qmtech_wukong;

architecture sim of tb_mb_cb_qmtech_wukong is

    signal clki_50m         : std_logic;
    signal key_n            : std_logic_vector(1 downto 0);

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

    component mb_cb_qmtech_qukong is
        port (
            clki_50m        : in    std_logic;
            led_n           : out   std_logic_vector(1 downto 0);
            key_n           : in    std_logic_vector(1 downto 0);
            ser_tx          : out   std_logic;
            ser_rx          : in    std_logic;
            hdmi_clk_p      : out   std_logic;
            hdmi_clk_n      : out   std_logic;
            hdmi_d_p        : out   std_logic_vector(0 to 2);
            hdmi_d_n        : out   std_logic_vector(0 to 2);
            hdmi_scl        : out   std_logic;
            hdmi_sda        : inout std_logic;
            eth_rst_n       : out   std_logic;
            ddr3_reset_n    : out   std_logic
        );
    end component mb_cb_qmtech_qukong;

begin

    clki_50m <=
        '1' after 10ns when clki_50m = '0' else
        '0' after 10ns when clki_50m = '1' else
        '0';

    process
    begin
        btn_rst_n <= '0';
        wait for 20ns;
        btn_rst_n <= '1';
        wait until rising_edge(cap_stb);
        stop;
    end process;

    UUT: component mb_cb_qmtech_wukong
        port map (
            clki_50m        => clki_50m,
            led             => open,
            btn_rst_n       => key_n(0),
            ser_tx          => open,
            ser_rx          => '1',
            hdmi_clk_p      => hdmi_clk_p,
            hdmi_clk_n      => hdmi_clk_n,
            hdmi_d_p        => hdmi_d_p,
            hdmi_d_n        => hdmi_d_n,
            hdmi_scl        => open,
            hdmi_sda        => open,
            eth_rst_n       => open,
            ftdi_rd_n       => open,
            ddr3_reset_n    => open
        );

    DECODE: component model_dvi_decoder
        port map (
            dvi_clk     => hdmi_tx_clk_p,
            dvi_d       => hdmi_tx_d_p,
            vga_clk     => vga_clk,
            vga_vs      => vga_vs,
            vga_hs      => vga_hs,
            vga_de      => vga_de,
            vga_p(2)    => vga_r,
            vga_p(1)    => vga_g,
            vga_p(0)    => vga_b
        );

    CAPTURE: component model_vga_sink
        generic map (
            name        => "tb_mb_cb_qmtech_wukong"
        )
        port map (
            rst         => '0',
            clk         => vga_clk,
            vs          => vga_vs,
            hs          => vga_hs,
            de          => vga_de,
            r           => vga_r,
            g           => vga_g,
            b           => vga_b,
            stb         => cap_stb
        );

end architecture sim;
