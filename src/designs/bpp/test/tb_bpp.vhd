--------------------------------------------------------------------------------
-- tb_bpp.vhd                                                                 --
-- BPP simulation testbench.                                                  --
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

library std;
use std.env.all;

library work;
use work.tyto_sim_pkg.all;
use work.model_clk_src_pkg.all;
use work.bpp_pkg.all;
use work.model_vga_sink_pkg.all;

entity tb_bpp is
end entity tb_bpp;

architecture sim of tb_bpp is

    signal sys_rst     : std_logic;
    signal sys_clk_96m : std_logic;
    signal sys_clk_48m : std_logic;
    signal sys_clk_32m : std_logic;
    signal sys_clk_8m  : std_logic;

    signal vga_rst     : std_logic;
    signal vga_clk     : std_logic;
    signal vga_vs      : std_logic;
    signal vga_hs      : std_logic;
    signal vga_de      : std_logic;
    signal vga_r       : std_logic_vector(7 downto 0);
    signal vga_g       : std_logic_vector(7 downto 0);
    signal vga_b       : std_logic_vector(7 downto 0);

    signal pcm_rst     : std_logic;
    signal pcm_clk     : std_logic;
    signal pcm_clken   : std_logic;
    signal pcm_l       : std_logic_vector(15 downto 0);
    signal pcm_r       : std_logic_vector(15 downto 0);

    signal cap_rst     : std_logic;
    signal cap_stb     : std_logic;

begin

    stim_reset(sys_rst, '1', 1 us);
    stim_reset(vga_rst, '1', 1 us);
    stim_reset(pcm_rst, '1', 1 us);

    CLK_SRC_1: component model_clk_src generic map ( pn =>   1, pd =>   96            ) port map ( clk => sys_clk_96m );
    CLK_SRC_2: component model_clk_src generic map ( pn =>   1, pd =>   48            ) port map ( clk => sys_clk_48m );
    CLK_SRC_3: component model_clk_src generic map ( pn =>   1, pd =>   32, dc => 0.3 ) port map ( clk => sys_clk_32m );
    CLK_SRC_4: component model_clk_src generic map ( pn =>   1, pd =>    8            ) port map ( clk => sys_clk_8m  );
    CLK_SRC_5: component model_clk_src generic map ( pn =>   2, pd =>  297            ) port map ( clk => vga_clk     );
    CLK_SRC_6: component model_clk_src generic map ( pn => 125, pd => 1536            ) port map ( clk => pcm_clk     );

    -- SYS: component bpp
        -- port map (
            -- sys_rst     => sys_rst,
            -- sys_clk_96m => sys_clk_96m,
            -- sys_clk_48m => sys_clk_48m,
            -- sys_clk_32m => sys_clk_32m,
            -- sys_clk_8m  => sys_clk_8m,
            -- vga_rst     => vga_rst,
            -- vga_clk     => vga_clk,
            -- vga_vs      => vga_vs,
            -- vga_hs      => vga_hs,
            -- vga_de      => vga_de,
            -- vga_r       => vga_r,
            -- vga_g       => vga_g,
            -- vga_b       => vga_b,
            -- pcm_rst     => pcm_rst,
            -- pcm_clk     => pcm_clk,
            -- pcm_clken   => pcm_clken,
            -- pcm_l       => pcm_l,
            -- pcm_r       => pcm_r
        -- );

    -- CAPTURE: component model_vga_sink
        -- port map (
            -- vga_rst  => vga_rst,
            -- vga_clk  => vga_clk,
            -- vga_vs   => vga_vs,
            -- vga_hs   => vga_hs,
            -- vga_de   => vga_de,
            -- vga_r    => vga_r,
            -- vga_g    => vga_g,
            -- vga_b    => vga_b,
            -- cap_rst  => cap_rst,
            -- cap_stb  => cap_stb,
            -- cap_name => "tb_bpp"
        -- );

end architecture sim;
