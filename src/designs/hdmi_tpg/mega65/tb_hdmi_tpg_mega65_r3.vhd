--------------------------------------------------------------------------------
-- tb_hdmi_tpg_mega65_r3.vhd                                                  --
-- Simulation testbench for hdmi_tpg_mega65_r3.vhd.                           --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
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

entity tb_hdmi_tpg_mega65_r3 is
end entity tb_hdmi_tpg_mega65_r3;

architecture sim of tb_hdmi_tpg_mega65_r3 is

  signal clk_in      : std_logic;
  signal jsa_fire_n  : std_logic;
  signal jsb_fire_n  : std_logic;
  signal led         : std_logic;

  signal hdmi_clk_p  : std_logic;
  signal hdmi_clk_n  : std_logic;
  signal hdmi_data_p : std_logic_vector(0 to 2);
  signal hdmi_data_n : std_logic_vector(0 to 2);

  signal data_pstb   : std_logic;                    -- v4p ignore w-303
  signal data_hb     : slv_7_0_t(0 to 3);            -- v4p ignore w-303
  signal data_hb_ok  : std_logic;                    -- v4p ignore w-303
  signal data_sb     : slv_7_0_2d_t(0 to 3, 0 to 7); -- v4p ignore w-303
  signal data_sb_ok  : std_logic_vector(0 to 3);     -- v4p ignore w-303

  signal vga_rst     : std_logic;
  signal vga_clk     : std_logic;
  signal vga_vs      : std_logic;
  signal vga_hs      : std_logic;
  signal vga_de      : std_logic;
  signal vga_r       : std_logic_vector(7 downto 0);
  signal vga_g       : std_logic_vector(7 downto 0);
  signal vga_b       : std_logic_vector(7 downto 0);

  signal cap_rst     : std_logic;
  signal cap_stb     : std_logic;

begin

  clk_in <= '1' after 5 ns when clk_in = '0' else
            '0' after 5 ns when clk_in = '1' else
            '0';

  TEST: process is
    constant progress_interval : time := 1 ms;
    variable mode              : integer;
  begin
    mode      := 0;
    jsb_fire_n <= '0';
    jsa_fire_n <= '1';
    cap_rst   <= '1';
    wait for 20 ns;
    jsb_fire_n <= '1';
    cap_rst   <= '0';
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
      jsa_fire_n <= '0';
      wait for 100 ns;
      jsa_fire_n <= '1';
      wait for 100 ns;
    end loop;
  end process TEST;

  DUT: entity work.hdmi_tpg_mega65_r3
    port map (
      clk_in                  => clk_in,
      max10_clk               => 'Z',
      max10_tx                => '0',
      max10_rx                => open,
      led                     => led,
      uart_rx                 => '1',
      uart_tx                 => open,
      kb_io0                  => open,
      kb_io1                  => open,
      kb_io2                  => '0',
      kb_jtagen               => open,
      kb_tck                  => open,
      kb_tms                  => open,
      kb_tdi                  => open,
      kb_tdo                  => '0',
      jsa_left_n              => '1',
      jsa_right_n             => '1',
      jsa_up_n                => '1',
      jsa_down_n              => '1',
      jsa_fire_n              => jsa_fire_n,
      jsb_left_n              => '1',
      jsb_right_n             => '1',
      jsb_up_n                => '1',
      jsb_down_n              => '1',
      jsb_fire_n              => jsb_fire_n,
      paddle                  => (others => '0'),
      paddle_drain            => open,
      i2c_sda                 => 'H',
      i2c_scl                 => 'H',
      grove_sda               => 'H',
      grove_scl               => 'H',
      sd_cd_n                 => '1',
      sd_wp_n                 => '1',
      sd_ss_n                 => open,
      sd_clk                  => open,
      sd_mosi                 => open,
      sd_miso                 => '0',
      sd2_cd_n                => '1',
      sd2_ss_n                => open,
      sd2_clk                 => open,
      sd2_mosi                => open,
      sd2_miso                => '0',
      vga_clk                 => open,
      vga_sync_n              => open,
      vga_blank_n             => open,
      vga_vsync               => open,
      vga_hsync               => open,
      vga_r                   => open,
      vga_g                   => open,
      vga_b                   => open,
      hdmi_clk_p              => hdmi_clk_p,
      hdmi_clk_n              => hdmi_clk_n,
      hdmi_data_p             => hdmi_data_p,
      hdmi_data_n             => hdmi_data_n,
      hdmi_ct_hpd             => open,
      hdmi_hpd                => 'L',
      hdmi_ls_oe              => open,
      hdmi_cec                => 'L',
      hdmi_scl                => 'H',
      hdmi_sda                => 'H',
      pwm_l                   => open,
      pwm_r                   => open,
      i2s_sd_n                => open,
      i2s_mclk                => open,
      i2s_bclk                => open,
      i2s_sync                => open,
      i2s_sdata               => open,
      hr_rst_n                => open,
      hr_clk_p                => open,
      hr_cs_n                 => open,
      hr_rwds                 => 'L',
      hr_d                    => (others => 'L'),
      fdd_density             => open,
      fdd_motora              => open,
      fdd_motorb              => open,
      fdd_selecta             => open,
      fdd_selectb             => open,
      fdd_stepdir             => open,
      fdd_step                => open,
      fdd_wdata               => open,
      fdd_wgate               => open,
      fdd_side1               => open,
      fdd_index               => '0',
      fdd_track0              => '0',
      fdd_writeprotect        => '0',
      fdd_rdata               => '0',
      fdd_diskchanged         => '0',
      iec_rst_n               => open,
      iec_atn_n               => open,
      iec_srq_n_en            => open,
      iec_srq_n_o             => open,
      iec_srq_n_i             => '0',
      iec_clk_en              => open,
      iec_clk_o               => open,
      iec_clk_i               => '0',
      iec_data_en             => open,
      iec_data_o              => open,
      iec_data_i              => '0',
      eth_rst_n               => open,
      eth_clk                 => open,
      eth_txen                => open,
      eth_txd                 => open,
      eth_rxdv                => '0',
      eth_rxd                 => (others => '0'),
      eth_rxer                => '0',
      eth_mdc                 => open,
      eth_mdio                => 'H',
      eth_led                 => 'H',
      cart_ctrl_oe_n          => open,
      cart_ctrl_dir           => open,
      cart_addr_oe_n          => open,
      cart_laddr_dir          => open,
      cart_haddr_dir          => open,
      cart_data_oe_n          => open,
      cart_data_dir           => open,
      cart_phi2               => open,
      cart_dotclk             => open,
      cart_rst_n              => '1',
      cart_nmi_n              => '1',
      cart_irq_n              => '1',
      cart_dma_n              => '1',
      cart_exrom_n            => 'Z',
      cart_ba                 => 'Z',
      cart_r_w                => 'Z',
      cart_roml_n             => 'Z',
      cart_romh_n             => 'Z',
      cart_game_n             => 'Z',
      cart_io1_n              => 'Z',
      cart_io2_n              => 'Z',
      cart_a                  => (others => 'L'),
      cart_d                  => (others => 'L'),
      p1lo                    => (others => 'Z'),
      p1hi                    => (others => 'Z'),
      p2lo                    => (others => 'Z'),
      p2hi                    => (others => 'Z'),
      qspi_cs_n               => open,
      qspi_d                  => (others => 'Z'),
      tp                      => (others => 'Z')
    );

  DECODE: entity work.model_hdmi_decoder
    port map (
      rst        => cap_rst,
      hdmi_clk   => hdmi_clk_p,
      hdmi_d     => hdmi_data_p,
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
      cap_name => "tb_hdmi_tpg_mega65_r3"
    );

end architecture sim;
