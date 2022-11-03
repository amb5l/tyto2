--------------------------------------------------------------------------------
-- mb_cb_ps2.vhd                                                              --
-- MicroBlaze CPU with character buffer and PS/2 keyboard interface.          --
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

package mb_cb_ps2_pkg is

  component mb_cb_ps2 is
    port (

      cpu_clk    : in    std_logic;
      cpu_rst    : in    std_logic;

      pix_clk    : in    std_logic;
      pix_rst    : in    std_logic;

      uart_tx    : out   std_logic;
      uart_rx    : in    std_logic;

      ps2_clk_i  : in    std_logic;
      ps2_clk_o  : out   std_logic;
      ps2_data_i : in    std_logic;
      ps2_data_o : out   std_logic;

      pal_ntsc   : out   std_logic;

      vga_vs     : out   std_logic;
      vga_hs     : out   std_logic;
      vga_de     : out   std_logic;
      vga_r      : out   std_logic_vector(7 downto 0);
      vga_g      : out   std_logic_vector(7 downto 0);
      vga_b      : out   std_logic_vector(7 downto 0);

      debug      : out   std_logic_vector(15 downto 0)

    );
  end component mb_cb_ps2;

end package mb_cb_ps2_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.ps2_host_pkg.all;
  use work.ps2_to_usbhid_pkg.all;
  use work.cb_pkg.all;

entity mb_cb_ps2 is
  port (

    cpu_clk    : in    std_logic;                    -- CPU clock e.g. 100MHz
    cpu_rst    : in    std_logic;                    -- CPU clock synchronous reset

    pix_clk    : in    std_logic;                    -- CPU clock e.g. 100MHz
    pix_rst    : in    std_logic;                    -- CPU clock synchronous reset

    uart_tx    : out   std_logic;                    -- UART transmit
    uart_rx    : in    std_logic;                    -- UART receive

    ps2_clk_i  : in    std_logic;                    -- PS/2 serial clock in
    ps2_clk_o  : out   std_logic;                    -- PS/2 serial clock out
    ps2_data_i : in    std_logic;                    -- PS/2 serial data in
    ps2_data_o : out   std_logic;                    -- PS/2 serial data out

    pal_ntsc   : out   std_logic;                    -- 1: 625i50,  0: 525i60

    vga_vs     : out   std_logic;                    -- vertical sync
    vga_hs     : out   std_logic;                    -- horizontal sync
    vga_de     : out   std_logic;                    -- display enable
    vga_r      : out   std_logic_vector(7 downto 0); -- red
    vga_g      : out   std_logic_vector(7 downto 0); -- green
    vga_b      : out   std_logic_vector(7 downto 0); -- blue

    debug      : out   std_logic_vector(15 downto 0)

  );
end entity mb_cb_ps2;

architecture synth of mb_cb_ps2 is

  signal gpi        : std_logic_vector(31 downto 0);
  signal gpo        : std_logic_vector(31 downto 0);

  signal bram_addr  : std_logic_vector(15 downto 0);
  signal bram_clk   : std_logic;
  signal bram_din   : std_logic_vector(31 downto 0);
  signal bram_dout  : std_logic_vector(31 downto 0);
  signal bram_en    : std_logic;
  signal bram_rst   : std_logic;
  signal bram_we    : std_logic_vector(3 downto 0);

  signal d2h_stb    : std_logic;
  signal d2h_data   : std_logic_vector(7 downto 0);
  signal h2d_req    : std_logic;
  signal h2d_ack    : std_logic;
  signal h2d_nack   : std_logic;
  signal h2d_data   : std_logic_vector(7 downto 0);

  signal hid_stb    : std_logic;
  signal hid_make   : std_logic;
  signal hid_code   : std_logic_vector(7 downto 0);
  signal hid_req    : std_logic;
  signal hid_ack    : std_logic;

  signal pal_ntsc_i : std_logic;
  signal border     : std_logic_vector(3 downto 0);

  component microblaze is
    port (
      clk        : in    std_logic;
      lock       : in    std_logic;
      rsti_n     : in    std_logic;
      rsto       : out   std_logic_vector(0 to 0);
      uart_txd   : out   std_logic;
      uart_rxd   : in    std_logic;
      gpio_tri_i : in    std_logic_vector(31 downto 0);
      gpio_tri_o : out   std_logic_vector(31 downto 0);
      gpio_tri_t : out   std_logic_vector(31 downto 0);
      bram_clk   : out   std_logic;
      bram_rst   : out   std_logic;
      bram_en    : out   std_logic;
      bram_we    : out   std_logic_vector( 3 downto 0);
      bram_addr  : out   std_logic_vector( 15 downto 0);
      bram_din   : out   std_logic_vector( 31 downto 0);
      bram_dout  : in    std_logic_vector( 31 downto 0)
    );
  end component microblaze;

begin

  pal_ntsc <= pal_ntsc_i;

  --------------------------------------------------------------------------------
  -- CPU core

  CPU: component microblaze
    port map (
      clk        => cpu_clk,
      lock       => not cpu_rst,
      rsti_n     => '1',
      rsto       => open,
      uart_txd   => uart_tx,
      uart_rxd   => uart_rx,
      gpio_tri_i => gpi,
      gpio_tri_o => gpo,
      gpio_tri_t => open,
      bram_clk   => bram_clk,
      bram_rst   => open,
      bram_en    => bram_en,
      bram_we    => bram_we,
      bram_addr  => bram_addr,
      bram_din   => bram_din,
      bram_dout  => bram_dout
    );

  gpi(7 downto 0)   <= (others => '0');
  gpi(8)            <= hid_req;
  gpi(9)            <= h2d_ack;
  gpi(10)           <= h2d_nack;
  gpi(15 downto 11) <= (others => '0');
  gpi(23 downto 16) <= hid_code;
  gpi(24)           <= hid_make;
  gpi(31 downto 25) <= (others => '0');

  pal_ntsc_i <= gpo(0);
  border     <= gpo(7 downto 4);
  hid_ack    <= gpo(8);
  h2d_req    <= gpo(9);
  h2d_data   <= gpo(23 downto 16);

  debug <= gpo(8) & "000000" & gpo(24 downto 16);

  DO_HID_REQ: process (cpu_clk) is
  begin
    if rising_edge(cpu_clk) then
      if cpu_rst = '1' then
        hid_req <= '0';
      elsif hid_stb = '1' then
        hid_req <= '1';
      elsif hid_ack = '1' then
        hid_req <= '0';
      end if;
    end if;
  end process DO_HID_REQ;

  --------------------------------------------------------------------------------
  -- PS/2 interface

  PS2: component ps2_host
    generic map (
      fclk       => 100.0
    )
    port map (
      clk        => cpu_clk,
      rst        => cpu_rst,
      ps2_clk_i  => ps2_clk_i,
      ps2_clk_o  => ps2_clk_o,
      ps2_data_i => ps2_data_i,
      ps2_data_o => ps2_data_o,
      d2h_stb    => d2h_stb,
      d2h_data   => d2h_data,
      h2d_req    => h2d_req,
      h2d_ack    => h2d_ack,
      h2d_nack   => h2d_nack,
      h2d_data   => h2d_data
    );

  HID: component ps2_to_usbhid
    generic map (
      nonus    => true
    )
    port map (
      clk      => cpu_clk,
      rst      => cpu_rst,
      ps2_stb  => d2h_stb,
      ps2_data => d2h_data,
      hid_stb  => hid_stb,
      hid_code => hid_code,
      hid_make => hid_make
    );

  --------------------------------------------------------------------------------
  -- character display

  DISPLAY: component cb
    port map (
      cpu_clk  => bram_clk,
      cpu_en   => bram_en,
      cpu_we   => bram_we,
      cpu_addr => bram_addr,
      cpu_din  => bram_din,
      cpu_dout => bram_dout,
      pix_clk  => pix_clk,
      pix_rst  => pix_rst,
      pal_ntsc => pal_ntsc_i,
      border   => border,
      vga_vs   => vga_vs,
      vga_hs   => vga_hs,
      vga_de   => vga_de,
      vga_r    => vga_r,
      vga_g    => vga_g,
      vga_b    => vga_b
    );

--------------------------------------------------------------------------------

end architecture synth;
