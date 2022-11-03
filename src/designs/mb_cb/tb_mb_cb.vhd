--------------------------------------------------------------------------------
-- tb_mb_cb.vhd                                                               --
-- Simulation testbench for mb_cb.vhd.                                        --
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
  use std.env.finish;

library work;
  use work.tyto_sim_pkg.all;
  use work.mb_cb_pkg.all;
  use work.model_vga_sink_pkg.all;

entity tb_mb_cb is
end entity tb_mb_cb;

architecture sim of tb_mb_cb is

  signal cpu_clk  : std_logic;
  signal cpu_rst  : std_logic;

  signal pix_clk  : std_logic;
  signal pix_rst  : std_logic;

  signal uart_tx  : std_logic;
  signal uart_rx  : std_logic;

  signal pal_ntsc : std_logic;

  signal vga_vs   : std_logic;
  signal vga_hs   : std_logic;
  signal vga_de   : std_logic;
  signal vga_r    : std_logic_vector(7 downto 0);
  signal vga_g    : std_logic_vector(7 downto 0);
  signal vga_b    : std_logic_vector(7 downto 0);

  signal cap_stb  : std_logic;

begin

  stim_clock(cpu_clk, 10 ns);  -- 100 MHz
  stim_reset(cpu_rst, '1', 200 ns);
  stim_clock(pix_clk, 37037 ps); -- ~27 MHz
  stim_reset(pix_rst, '1', 200 ns);

  TEST: process is
  begin
    wait until rising_edge(cap_stb);
    finish;
  end process TEST;

  DUT: component mb_cb
    port map (
      cpu_clk  => cpu_clk,
      cpu_rst  => cpu_rst,
      pix_clk  => pix_clk,
      pix_rst  => pix_rst,
      uart_tx  => uart_tx,
      uart_rx  => uart_rx,
      pal_ntsc => pal_ntsc,
      vga_vs   => vga_vs,
      vga_hs   => vga_hs,
      vga_de   => vga_de,
      vga_r    => vga_r,
      vga_g    => vga_g,
      vga_b    => vga_b
    );

  CAPTURE: component model_vga_sink
    port map (
      vga_rst  => '0',
      vga_clk  => pix_clk,
      vga_vs   => vga_vs,
      vga_hs   => vga_hs,
      vga_de   => vga_de,
      vga_r    => vga_r,
      vga_g    => vga_g,
      vga_b    => vga_b,
      cap_rst  => '0',
      cap_stb  => cap_stb,
      cap_name => "tb_mb_cb"
    );

end architecture sim;
