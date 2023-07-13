--------------------------------------------------------------------------------
-- tb_hdmi_tpg_digilent_zybo_z7_20.vhd                                        --
-- Simulation testbench for hdmi_tpg_digilent_zybo_z7_20.vhd.                 --
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

entity tb_hdmi_tpg_digilent_zybo_z7_20 is
end entity tb_hdmi_tpg_digilent_zybo_z7_20;

architecture sim of tb_hdmi_tpg_digilent_zybo_z7_20 is

  signal clki_125m     : std_logic;
  signal sw            : std_logic_vector(3 downto 0);
  signal btn           : std_logic_vector(3 downto 0);
  signal led           : std_logic_vector(3 downto 0);
  signal led_r         : std_logic_vector(6 downto 5);
  signal led_g         : std_logic_vector(6 downto 5);
  signal led_b         : std_logic_vector(6 downto 5);

  signal hdmi_tx_clk_p : std_logic;
  signal hdmi_tx_clk_n : std_logic;
  signal hdmi_tx_d_p   : std_logic_vector(0 to 2);
  signal hdmi_tx_d_n   : std_logic_vector(0 to 2);

  signal data_pstb     : std_logic;
  signal data_hb       : slv_7_0_t(0 to 3);
  signal data_hb_ok    : std_logic;
  signal data_sb       : slv_7_0_2d_t(0 to 3, 0 to 7);
  signal data_sb_ok    : std_logic_vector(0 to 3);

  signal vga_rst       : std_logic;
  signal vga_clk       : std_logic;
  signal vga_vs        : std_logic;
  signal vga_hs        : std_logic;
  signal vga_de        : std_logic;
  signal vga_r         : std_logic_vector(7 downto 0);
  signal vga_g         : std_logic_vector(7 downto 0);
  signal vga_b         : std_logic_vector(7 downto 0);

  signal cap_rst       : std_logic;
  signal cap_stb       : std_logic;

  component hdmi_tpg_digilent_zybo_z7_20 is
    port (
    clki_125m     : in    std_logic;
    sw            : in    std_logic_vector(3 downto 0);
    btn           : in    std_logic_vector(3 downto 0);
    led           : out   std_logic_vector(3 downto 0);
    led_r         : out   std_logic_vector(6 downto 5);
    led_g         : out   std_logic_vector(6 downto 5);
    led_b         : out   std_logic_vector(6 downto 5);
    hdmi_tx_clk_p : out   std_logic;
    hdmi_tx_clk_n : out   std_logic;
    hdmi_tx_d_p   : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n   : out   std_logic_vector(0 to 2);
    hdmi_tx_cec   : out   std_logic;
    ac_muten      : out   std_logic;
    ac_pbdat      : out   std_logic;
    eth_rst_b     : out   std_logic
    );
  end component hdmi_tpg_digilent_zybo_z7_20;

begin

  clki_125m <=
               '1' after 4 ns when clki_125m = '0' else
               '0' after 4 ns when clki_125m = '1' else
               '0';

  btn(3 downto 2) <= (others => '0');
  sw <= (others => '0');

  TEST: process is
    constant progress_interval : time := 1 ms;
    variable mode              : integer;
  begin
    mode    := 0;
    btn(0)  <= '1';
    btn(1)  <= '0';
    cap_rst <= '1';
    wait for 20 ns;
    btn(0)  <= '0';
    cap_rst <= '0';
    loop
      loop
        wait until rising_edge(cap_stb) for progress_interval;
        report "waiting...";
        if cap_stb'event then
          report "capture complete - mode " & integer'image(mode);
          exit;
        end if;
      end loop;
      mode := mode + 1;
      if mode = 15 then
        finish;
      end if;
      btn(1) <= '1';
      wait for 100 ns;
      btn(1) <= '0';
      wait for 100 ns;
    end loop;
  end process TEST;

  DUT: component hdmi_tpg_digilent_zybo_z7_20
    port map (
      clki_125m     => clki_125m,
      sw            => sw,
      btn           => btn,
      led           => led,
      led_r         => led_r,
      led_g         => led_g,
      led_b         => led_b,
      hdmi_tx_clk_p => hdmi_tx_clk_p,
      hdmi_tx_clk_n => hdmi_tx_clk_n,
      hdmi_tx_d_p   => hdmi_tx_d_p,
      hdmi_tx_d_n   => hdmi_tx_d_n,
      hdmi_tx_cec   => open,
      ac_muten      => open,
      ac_pbdat      => open,
      eth_rst_b     => open
    );

  DECODE: entity work.model_hdmi_decoder
    port map (
      rst        => cap_rst,
      hdmi_clk   => hdmi_tx_clk_p,
      hdmi_d     => hdmi_tx_d_p,
      data_pstb  => data_pstb,
      data_hb    => data_hb,
      data_hb_ok => data_hb_ok,
      data_sb    => data_sb,
      data_sb_ok => data_sb_ok,
      vga_rst    => vga_rst,
      vga_clk    => vga_clk,
      vga_vs     => vga_vs,
      vga_hs     => vga_hs,
      vga_de     => vga_de,
      vga_p(2)   => vga_r,
      vga_p(1)   => vga_g,
      vga_p(0)   => vga_b
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
      cap_name => "tb_hdmi_tpg_digilent_zybo_z7_20"
    );

end architecture sim;
