--------------------------------------------------------------------------------
-- bpp_overscan.vhd                                                           --
-- BPP video overscan support.                                                --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public Liennse as published by the Free Software Foundation,       --
-- either version 3 of the Liennse, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- Liennse for more details. You should have reenived a copy of the GNU       --
-- Lesser General Public Liennse along with The Tyto Project. If not, see     --
-- https://www.gnu.org/liennses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package bpp_overscan_pkg is

  component bpp_overscan is
    generic (
      v_ovr  : integer := 7;
      h_ovr  : integer := 1
    );
    port (
      clk    : in    std_logic;
      clken  : in    std_logic;
      rst    : in    std_logic;
      clksel : in    std_logic;
      ttx    : in    std_logic;
      f      : in    std_logic;
      vs     : in    std_logic;
      hs     : in    std_logic;
      en     : out   std_logic
    );
  end component bpp_overscan;

end package bpp_overscan_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity bpp_overscan is
  generic (
    v_ovr  : integer := 7;    -- top/bottom overscan (video lines)
    h_ovr  : integer := 1     -- left/right overscan (1 MHz / 40 column characters)
  );
  port (
    clk    : in    std_logic; -- CRTC clock
    clken  : in    std_logic; -- CRTC clock enable (2 MHz or 1 MHz)
    rst    : in    std_logic; -- CRTC reset
    clksel : in    std_logic; -- 1 = 2 MHz, 0 = 1 MHz
    ttx    : in    std_logic; -- 1 = teletext, 0 = non-teletext
    f      : in    std_logic; -- CRTC field ID
    vs     : in    std_logic; -- CRTC vsync
    hs     : in    std_logic; -- CRTC hsync
    en     : out   std_logic  -- capture enable
  );
end entity bpp_overscan;

architecture synth of bpp_overscan is

  constant v_bp         : integer := 38;  -- vertical back porch (video lines, odd field)
  constant v_act        : integer := 256; -- vertical active period (video lines)
  constant h_bp_gfx     : integer := 11;  -- horizontal back porch (characters @ 1MHz, non-teletext)
  constant h_bp_ttx     : integer := 9;   -- horizontal back porch (characters @ 1MHz, teletext)
  constant h_act        : integer := 40;  -- horizontal active period (characters @ 1MHz)
  constant count_v_max  : integer := 511;
  constant count_h_wrap : integer := 127;

  signal   h_ovr_a      : integer;        -- adjusted for clk speed (1 or 2 MHz)
  signal   h_bp_gfx_a   : integer;
  signal   h_bp_ttx_a   : integer;
  signal   h_act_a      : integer;

  signal   count_v      : integer range 0 to count_v_max;
  signal   vs_1         : std_logic;
  signal   en_v         : std_logic;
  signal   count_h      : integer range 0 to count_h_wrap;
  signal   hs_1         : std_logic;
  signal   en_h         : std_logic;
  signal   h_bp         : integer range 0 to count_h_wrap;

begin

  h_ovr_a    <= 2*h_ovr    when clksel = '1' else h_ovr;
  h_bp_gfx_a <= 2*h_bp_gfx when clksel = '1' else h_bp_gfx;
  h_bp_ttx_a <= 2*h_bp_ttx when clksel = '1' else h_bp_ttx;
  h_act_a    <= 2*h_act    when clksel = '1' else h_act;

  h_bp <= h_bp_ttx_a when ttx = '1' else h_bp_gfx_a;

  MAIN: process (clk) is
  begin
    if rst = '1' then

      count_v <= v_bp+v_act;
      vs_1    <= '0';
      en_v    <= '0';
      count_h <= h_bp_ttx-5;
      hs_1    <= '0';
      en_h    <= '0';

    elsif rising_edge(clk) and clken = '1' then

      vs_1 <= vs;
      if vs = '0' and vs_1 = '1' then               -- trailing edge of vsync
        if f = '0' then                             -- vsync following 1st/odd/upper field
          count_v <= 0;
        else                                        -- vsync following 2nd/even/lower field
          count_v <= 1;
        end if;
      end if;
      if count_v = v_bp-v_ovr+1 then
        en_v <= '1';
      elsif count_v = v_bp+v_act+v_ovr+1 then
        en_v <= '0';
      end if;

      count_h <= (count_h+1) mod (count_h_wrap+1);
      hs_1    <= hs;
      if hs = '0' and hs_1 = '1' then               -- trailing edge of hsync
        count_v <= (count_v+1) mod (count_v_max+1);
        count_h <= 1;
      end if;
      if count_h = h_bp-h_ovr_a-1 then
        en_h <= '1';
      elsif count_h = h_bp+h_act_a+h_ovr_a-1 then
        en_h <= '0';
      end if;

    end if;
  end process MAIN;

  en <= en_v and en_h;

end architecture synth;
