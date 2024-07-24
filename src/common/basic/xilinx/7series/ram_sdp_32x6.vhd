--------------------------------------------------------------------------------
-- ram_sdp_32x6.vhd                                                           --
-- Simple 32x6 dual port RAM, sync write, async read.                         --
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

package ram_sdp_32x6_pkg is

  component ram_sdp_32x6 is
    generic (
      CLK_EDGE : string := "rising"
    );
    port (
      clk   : in    std_logic;
      we    : in    std_logic;
      wa    : in    std_logic_vector(4 downto 0);
      wd    : in    std_logic_vector(5 downto 0);
      ra    : in    std_logic_vector(4 downto 0);
      rd    : out   std_logic_vector(5 downto 0)
    );
  end component ram_sdp_32x6;

end package ram_sdp_32x6_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity ram_sdp_32x6 is
  generic (
    CLK_EDGE : string := "rising"
  );
  port (
    clk   : in    std_logic;
    we    : in    std_logic;
    wa    : in    std_logic_vector(4 downto 0);
    wd    : in    std_logic_vector(5 downto 0);
    ra    : in    std_logic_vector(4 downto 0);
    rd    : out   std_logic_vector(5 downto 0)
  );
end entity ram_sdp_32x6;

architecture rtl of ram_sdp_32x6 is

  function is_wclk_inverted return bit is
  begin
    assert CLK_EDGE = "rising" or CLK_EDGE = "falling"
      report "CLK_EDGE must be 'rising' or 'falling'" severity failure;
    if CLK_EDGE = "falling" then return '1'; else return '0'; end if;
  end function is_wclk_inverted;

begin

  RAM: component ram32m
    generic map (
      IS_WCLK_INVERTED => is_wclk_inverted
    )
    port map (
      wclk  => clk,
      we    => we,
      addra => ra,
      addrb => ra,
      addrc => ra,
      addrd => wa,
      dia   => wd(1 downto 0),
      dib   => wd(3 downto 2),
      dic   => wd(5 downto 4),
      did   => (others => '0'),
      doa   => rd(1 downto 0),
      dob   => rd(3 downto 2),
      doc   => rd(5 downto 4),
      dod   => open
    );

end architecture rtl;
