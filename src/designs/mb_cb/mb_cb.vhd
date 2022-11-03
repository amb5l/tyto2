--------------------------------------------------------------------------------
-- mb_cb.vhd                                                                  --
-- MicroBlaze CPU with character buffer.                                      --
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

package mb_cb_pkg is

  component mb_cb is
    port (

      cpu_clk  : in    std_logic;
      cpu_rst  : in    std_logic;

      pix_clk  : in    std_logic;
      pix_rst  : in    std_logic;

      uart_tx  : out   std_logic;
      uart_rx  : in    std_logic;

      pal_ntsc : out   std_logic;

      vga_vs   : out   std_logic;
      vga_hs   : out   std_logic;
      vga_de   : out   std_logic;
      vga_r    : out   std_logic_vector(7 downto 0);
      vga_g    : out   std_logic_vector(7 downto 0);
      vga_b    : out   std_logic_vector(7 downto 0)

    );
  end component mb_cb;

end package mb_cb_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.cb_pkg.all;

entity mb_cb is
  port (

    cpu_clk  : in    std_logic;                    -- CPU clock e.g. 100MHz
    cpu_rst  : in    std_logic;                    -- CPU clock synchronous reset

    pix_clk  : in    std_logic;                    -- CPU clock e.g. 100MHz
    pix_rst  : in    std_logic;                    -- CPU clock synchronous reset

    uart_tx  : out   std_logic;                    -- UART transmit
    uart_rx  : in    std_logic;                    -- UART receive

    pal_ntsc : out   std_logic;                    -- 1: 625i50,  0: 525i60

    vga_vs   : out   std_logic;                    -- vertical sync
    vga_hs   : out   std_logic;                    -- horizontal sync
    vga_de   : out   std_logic;                    -- display enable
    vga_r    : out   std_logic_vector(7 downto 0); -- red
    vga_g    : out   std_logic_vector(7 downto 0); -- green
    vga_b    : out   std_logic_vector(7 downto 0)  -- blue

  );
end entity mb_cb;

architecture synth of mb_cb is

  signal gpi       : std_logic_vector(31 downto 0);
  signal gpo       : std_logic_vector(31 downto 0);

  signal bram_addr : std_logic_vector(15 downto 0);
  signal bram_clk  : std_logic;
  signal bram_din  : std_logic_vector(31 downto 0);
  signal bram_dout : std_logic_vector(31 downto 0);
  signal bram_en   : std_logic;
  signal bram_rst  : std_logic;
  signal bram_we   : std_logic_vector(3 downto 0);

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

  pal_ntsc <= gpo(0);

  gpi <= (others => '0');

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
      pal_ntsc => gpo(0),
      border   => gpo(7 downto 4),
      vga_vs   => vga_vs,
      vga_hs   => vga_hs,
      vga_de   => vga_de,
      vga_r    => vga_r,
      vga_g    => vga_g,
      vga_b    => vga_b
    );

end architecture synth;
