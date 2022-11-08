--------------------------------------------------------------------------------
-- tb_mb_cb_ps2_digilent_nexys_video.vhd                                      --
-- Simulation testbench for mb_cb_ps2_digilent_nexys_video.vhd.               --
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
  use work.tyto_types_pkg.all;
  use work.model_dvi_decoder_pkg.all;
  use work.model_vga_sink_pkg.all;
  use work.ps2set_to_usbhid_pkg.all;

entity tb_mb_cb_ps2_digilent_nexys_video is
end entity tb_mb_cb_ps2_digilent_nexys_video;

architecture sim of tb_mb_cb_ps2_digilent_nexys_video is

  constant tps2          : time := 66 us; -- PS/2 clock period (~16.7kHz)

  signal   clki_100m     : std_logic;
  signal   btn_rst_n     : std_logic;
  signal   led           : std_logic_vector(7 downto 0);

  signal   ps2_clk       : std_logic;
  signal   ps2_data      : std_logic;

  signal   hdmi_tx_clk_p : std_logic;
  signal   hdmi_tx_clk_n : std_logic;
  signal   hdmi_tx_d_p   : std_logic_vector(0 to 2);
  signal   hdmi_tx_d_n   : std_logic_vector(0 to 2);

  signal   vga_clk       : std_logic;
  signal   vga_vs        : std_logic;
  signal   vga_hs        : std_logic;
  signal   vga_de        : std_logic;
  signal   vga_r         : std_logic_vector(7 downto 0);
  signal   vga_g         : std_logic_vector(7 downto 0);
  signal   vga_b         : std_logic_vector(7 downto 0);

  signal   cap_stb       : std_logic;

  signal   debug         : std_logic_vector(15 downto 0);
  signal   hid_code      : std_logic_vector(7 downto 0);
  signal   last          : std_logic;
  signal   pass          : integer;
  signal   fail          : integer;

  function oco (i : std_logic) return std_logic is
  begin
    if i = '0' or i = 'L' then
      return '0';
    elsif i = '1' or i = 'H' then
      return 'Z';
    else
      return 'U';
    end if;
  end function oco;

  function oci (i : std_logic) return std_logic is
  begin
    if i = '0' or i = 'L' then
      return '0';
    elsif i = '1' or i = 'H' then
      return '1';
    else
      return 'U';
    end if;
  end function oci;

  component mb_cb_ps2_digilent_nexys_video is
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
      ja            : out   std_logic_vector(7 downto 0);
      jb            : out   std_logic_vector(7 downto 0);
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
  end component mb_cb_ps2_digilent_nexys_video;

begin

  clki_100m <=
               '1' after 5 ns when clki_100m = '0' else
               '0' after 5 ns when clki_100m = '1' else
               '0';

  TEST: process is

    function parity_odd (v : std_logic_vector) return std_logic is
      variable r : std_logic := '1';
    begin
      for i in v'low to v'high loop
        r := r xor v(i);
      end loop;
      return r;
    end function parity_odd;

    procedure ps2_d2h (
      signal   ps2_clk  : out std_logic;
      signal   ps2_data : out std_logic;
      constant d2h_data : in std_logic_vector(7 downto 0);
      constant period   : in time;
      constant corrupt  : in std_logic_vector(10 downto 0) := (others => '0')
    ) is
    begin
      -- start
      wait for period/2;
      ps2_clk  <= oco ('0');
      ps2_data <= oco (corrupt(0));
      wait for period/2;
      ps2_clk  <= oco ('1');
      -- data
      for i in 0 to 7 loop
        wait for period/2;
        ps2_clk  <= oco ('0');
        ps2_data <= oco (d2h_data(i) xor corrupt(1+i));
        wait for period/2;
        ps2_clk  <= oco ('1');
      end loop;
      -- parity
      wait for period/2;
      ps2_clk  <= oco ('0');
      ps2_data <= oco (parity_odd (d2h_data) xor corrupt(9));
      wait for period/2;
      ps2_clk  <= oco ('1');
      -- stop
      wait for period/2;
      ps2_clk  <= oco ('0');
      ps2_data <= oco (not corrupt(10));
      wait for period/2;
      ps2_clk  <= oco ('1');
      ps2_data <= oco ('1');
    end procedure ps2_d2h;

    constant tbl : slv_8_0_t := ps2set_to_usbhid(true);
    variable i   : integer;

  begin
    ps2_clk  <= 'Z';
    ps2_data <= 'Z';
    pass     <= 0;
    fail     <= 0;
    i        := 0;
    wait for 1 ms;
    while true loop
      hid_code <= tbl(i)(7 downto 0);
      last     <= tbl(i)(8);
      -- make code(s)
      while true loop
        i := i+1;
        ps2_d2h (ps2_clk, ps2_data, tbl(i)(7 downto 0), tps2);
        if tbl(i)(8) = '0' then exit; end if;
      end loop;
      wait until falling_edge(debug(15));
      if debug(7 downto 0) /= hid_code or debug(8) /= '1' then
        fail <= fail+1;
        report "mismatch!" severity FAILURE;
      else
        pass <= pass+1;
      end if;
      wait for 200us;
      -- break code(s) (if they exist)
      if tbl(i+1) /= "000000000" then
        while true loop
          i := i+1;
          ps2_d2h (ps2_clk, ps2_data, tbl(i)(7 downto 0), tps2);
          if tbl(i)(8) = '0' then exit; end if;
        end loop;
        wait until falling_edge(debug(15));
        if debug(7 downto 0) /= hid_code or debug(8) /= '0' then
          fail <= fail+1;
          report "mismatch!" severity FAILURE;
        else
          pass <= pass+1;
        end if;
        wait for 200 us;
      else
        report "no break code";
        i := i+1;
      end if;
      i := i+1;
      if last = '1' then
        exit;
      end if;
    end loop;
    report "pass = " & integer'image(pass) & "  fail = " & integer'image(fail);
    finish;
    wait;

  end process TEST;

  DUT: component mb_cb_ps2_digilent_nexys_video
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
      ja            => debug(7 downto 0),
      jb            => debug(15 downto 8),
      uart_rx_out   => open,
      uart_tx_in    => '1',
      eth_rst_n     => open,
      ftdi_rd_n     => open,
      ftdi_wr_n     => open,
      ftdi_siwu_n   => open,
      ftdi_oe_n     => open,
      ps2_clk       => ps2_clk,
      ps2_data      => ps2_data,
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
      cap_stb  => cap_stb,
      cap_name => "tb_mb_cb_ps2_digilent_nexys_video"
    );

end architecture sim;
