--------------------------------------------------------------------------------
-- mb_cb_qmtech_wukong.vhd                                                    --
-- Board specific top level wrapper for the mb_cb design.                     --
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
  use work.mmcm_pkg.all;
  use work.mb_cb_pkg.all;
  use work.vga_to_hdmi_pkg.all;
  use work.serialiser_10to1_selectio_pkg.all;

entity mb_cb_qmtech_wukong is
  port (

    -- clocks
    clki_50m   : in    std_logic;

    -- LEDs and keys
    led_n      : out   std_logic_vector(1 downto 0);
    key_n      : in    std_logic_vector(1 downto 0);

    -- serial (UART)
    ser_tx     : out   std_logic;
    ser_rx     : in    std_logic;

    -- HDMI output
    hdmi_clk_p : out   std_logic;
    hdmi_clk_n : out   std_logic;
    hdmi_d_p   : out   std_logic_vector(0 to 2);
    hdmi_d_n   : out   std_logic_vector(0 to 2);
    hdmi_scl   : out   std_logic;
    hdmi_sda   : inout std_logic;
    -- hdmi_cec        : out   std_logic;
    -- hdmi_hpd        : in    std_logic;

    -- ethernet
    eth_rst_n  : out   std_logic;
    -- eth_gtx_clk     : out   std_logic;
    -- eth_txclk       : out   std_logic;
    -- eth_txen        : out   std_logic;
    -- eth_txer        : out   std_logic;
    -- eth_txd         : out   std_logic_vector(7 downto 0);
    -- eth_rxclk       : in    std_logic;
    -- eth_rxdv        : in    std_logic;
    -- eth_rxer        : in    std_logic;
    -- eth_rxd         : in    std_logic_vector(7 downto 0);
    -- eth_crs         : in    std_logic;
    -- eth_col         : in    std_logic;
    -- eth_mdc         : out   std_logic;
    -- eth_mdio        : inout std_logic;

    -- DDR3
    ddr3_rst_n : out   std_logic
  -- ddr3_ck_n       : out   std_logic_vector(0 downto 0);
  -- ddr3_cke        : out   std_logic_vector(0 downto 0);
  -- ddr3_ras_n      : out   std_logic;
  -- ddr3_cas_n      : out   std_logic;
  -- ddr3_ck_p       : out   std_logic_vector(0 downto 0);
  -- ddr3_we_n       : out   std_logic;
  -- ddr3_odt        : out   std_logic_vector(0 downto 0);
  -- ddr3_addr       : out   std_logic_vector(13 downto 0);
  -- ddr3_ba         : out   std_logic_vector(2 downto 0);
  -- ddr3_dm         : out   std_logic_vector(1 downto 0);
  -- ddr3_dq         : inout std_logic_vector(15 downto 0);
  -- ddr3_dqs_p      : inout std_logic_vector(1 downto 0);
  -- ddr3_dqs_n      : inout std_logic_vector(1 downto 0)

  -- I/O connectors
  -- j10             : inout std_logic_vector(7 downto 0);
  -- j11             : inout std_logic_vector(7 downto 0);
  -- jp2             : inout std_logic_vector(15 downto 0);
  -- j12             : inout std_logic_vector(33 downto 0);

  -- MGTs
  -- mgt_clk_p       : in    std_logic_vector(0 to 1);
  -- mgt_clk_n       : in    std_logic_vector(0 to 1);
  -- mgt_tx_p        : out   std_logic_vector(3 downto 0);
  -- mgt_tx_n        : out   std_logic_vector(3 downto 0);
  -- mgt_rx_p        : out   std_logic_vector(3 downto 0);
  -- mgt_rx_n        : out   std_logic_vector(3 downto 0);

  );
end entity mb_cb_qmtech_wukong;

architecture synth of mb_cb_qmtech_wukong is

  signal cpu_clk    : std_logic;                    -- 100 MHz
  signal cpu_rst    : std_logic;

  signal pix_clk_x5 : std_logic;                    -- 135 MHz
  signal pix_clk    : std_logic;                    -- 27 MHz
  signal pix_rst    : std_logic;

  signal vga_vs     : std_logic;                    -- VGA: vertical sync
  signal vga_hs     : std_logic;                    -- VGA: horizontal sync
  signal vga_de     : std_logic;                    -- VGA: vertical blank
  signal vga_r      : std_logic_vector(7 downto 0); -- VGA: red
  signal vga_g      : std_logic_vector(7 downto 0); -- VGA: green
  signal vga_b      : std_logic_vector(7 downto 0); -- VGA: blue

  signal pal_ntsc   : std_logic;
  signal vic        : std_logic_vector(7 downto 0);

  signal tmds       : slv_9_0_t(0 to 2);            -- parallel TMDS channels

begin

  led_n <= (others => '0');

  MMCM_CPU: component mmcm
    generic map (
      mul         => 20.0,
      div         => 1,
      num_outputs => 1,
      odiv0       => 10.0
    )
    port map (
      rsti        => not key_n(0),
      clki        => clki_50m,
      rsto        => cpu_rst,
      clko(0)     => cpu_clk
    );

  MMCM_PIX: component mmcm
    generic map (
      mul         => 13.5,
      div         => 1,
      num_outputs => 2,
      odiv0       => 5.0,
      odiv        => (25,0,0,0,0,0)
    )
    port map (
      rsti        => not key_n(0),
      clki        => clki_50m,
      rsto        => pix_rst,
      clko(0)     => pix_clk_x5,
      clko(1)     => pix_clk
    );

  MAIN: component mb_cb
    port map (
      cpu_clk  => cpu_clk,
      cpu_rst  => cpu_rst,
      pix_clk  => pix_clk,
      pix_rst  => pix_rst,
      uart_tx  => ser_tx,
      uart_rx  => ser_rx,
      pal_ntsc => pal_ntsc,
      vga_vs   => vga_vs,
      vga_hs   => vga_hs,
      vga_de   => vga_de,
      vga_r    => vga_r,
      vga_g    => vga_g,
      vga_b    => vga_b
    );

  vic <= x"15" when pal_ntsc = '1' else x"06";

  HDMI_CONV: component vga_to_hdmi
    generic map (
      pcm_fs    => 48.0
    )
    port map (
      dvi       => '1',
      vic       => vic,
      pix_rep   => '1',
      aspect    => "01",
      vs_pol    => '0',
      hs_pol    => '0',
      vga_rst   => pix_rst,
      vga_clk   => pix_clk,
      vga_vs    => vga_vs,
      vga_hs    => vga_hs,
      vga_de    => vga_de,
      vga_r     => vga_r,
      vga_g     => vga_g,
      vga_b     => vga_b,
      pcm_rst   => '1',
      pcm_clk   => '0',
      pcm_clken => '0',
      pcm_l     => (others => '0'),
      pcm_r     => (others => '0'),
      pcm_acr   => '0',
      pcm_n     => (others => '0'),
      pcm_cts   => (others => '0'),
      tmds      => tmds
    );

  gen_hdmi_data: for i in 0 to 2 generate
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

  end generate gen_hdmi_data;

  HDMI_CLK: component serialiser_10to1_selectio
    port map (
      rst    => pix_rst,
      clk    => pix_clk,
      clk_x5 => pix_clk_x5,
      d      => "0000011111",
      out_p  => hdmi_clk_p,
      out_n  => hdmi_clk_n
    );

  -- unused I/Os

  hdmi_scl   <= 'Z';
  hdmi_sda   <= 'Z';
  eth_rst_n  <= '0';
  ddr3_rst_n <= '0';

end architecture synth;
