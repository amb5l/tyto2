--------------------------------------------------------------------------------
-- tb_bpp_qmtech_wukong.vhd                                                   --
-- Simulation testbench for bpp_qmtech_wukong.vhd.                            --
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
use work.tyto_sim_pkg.all;
use work.model_clk_src_pkg.all;
use work.model_hdmi_decoder_pkg.all;
use work.model_vga_sink_pkg.all;

entity tb_bpp_qmtech_wukong is
end entity tb_bpp_qmtech_wukong;

architecture sim of tb_bpp_qmtech_wukong is

    signal clki_50m   : std_logic;
    signal key_n      : std_logic_vector(1 downto 0);
    signal led_n      : std_logic_vector(1 downto 0);

    signal hdmi_clk_p : std_logic;
    signal hdmi_clk_n : std_logic;
    signal hdmi_d_p   : std_logic_vector(0 to 2);
    signal hdmi_d_n   : std_logic_vector(0 to 2);

    signal data_pstb  : std_logic;
    signal data_hb    : slv_7_0_t(0 to 3);
    signal data_hb_ok : std_logic;
    signal data_sb    : slv_7_0_2d_t(0 to 3,0 to 7);
    signal data_sb_ok : std_logic_vector(0 to 3);

    signal vga_rst    : std_logic;
    signal vga_clk    : std_logic;
    signal vga_vs     : std_logic;
    signal vga_hs     : std_logic;
    signal vga_de     : std_logic;
    signal vga_r      : std_logic_vector(7 downto 0);
    signal vga_g      : std_logic_vector(7 downto 0);
    signal vga_b      : std_logic_vector(7 downto 0);

    signal cap_rst    : std_logic;
    signal cap_stb    : std_logic;

begin

    stim_reset(key_n(0), '0', 100 ns);
    stim_reset(cap_rst, '1', 100 ns);

    CLK_SRC: component model_clk_src generic map ( pn => 1, pd => 50 ) port map ( clk => clki_50m );

    UUT: entity work.bpp_qmtech_wukong
        port map (
            clki_50m    => clki_50m,
            led_n       => led_n,
            key_n       => key_n,
            ser_tx      => open,
            hdmi_clk_p  => hdmi_clk_p,
            hdmi_clk_n  => hdmi_clk_n,
            hdmi_d_p    => hdmi_d_p,
            hdmi_d_n    => hdmi_d_n,
            hdmi_scl    => open,
            hdmi_sda    => open,
            eth_rst_n   => open,
            ddr3_rst_n  => open
        );

    DECODE: entity work.model_hdmi_decoder
        port map (
            rst         => cap_rst,
            hdmi_clk    => hdmi_clk_p,
            hdmi_d      => hdmi_d_p,
            data_pstb   => data_pstb,
            data_hb     => data_hb,
            data_hb_ok  => data_hb_ok,
            data_sb     => data_sb,
            data_sb_ok  => data_sb_ok,
            vga_rst     => vga_rst,
            vga_clk     => vga_clk,
            vga_vs      => vga_vs,
            vga_hs      => vga_hs,
            vga_de      => vga_de,
            vga_p(2)    => vga_r,
            vga_p(1)    => vga_g,
            vga_p(0)    => vga_b
        );

    CAPTURE: entity work.model_vga_sink
        port map (
            vga_rst  => vga_rst,
            vga_clk  => vga_clk,
            vga_vs   => vga_vs,
            vga_hs   => vga_hs,
            vga_de   => vga_de,
            vga_r    => vga_r,
            vga_g    => vga_g,
            vga_b    => vga_b,
            cap_rst  => cap_rst,
            cap_stb  => cap_stb,
            cap_name => "tb_bpp_qmtech_wukong"
        );

end architecture sim;
