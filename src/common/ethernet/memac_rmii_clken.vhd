--------------------------------------------------------------------------------
-- memac_rmii_clken.vhd                                                       --
-- Modular Ethernet MAC (MEMAC): RMII clock enable.                           --
--------------------------------------------------------------------------------
-- (C) Copyright 2025 Adam Barnes <ambarnes@gmail.com>                        --
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

package memac_rmii_clk_pkg is

  component memac_rmii_clken is
    port (
      rst        : in    std_ulogic;
      clk        : in    std_ulogic;
      rmii_link  : in    std_ulogic;
      rmii_spd   : in    std_ulogic;
      rmii_clken : out   std_ulogic;
      umii_clken : out   std_ulogic
    );
  end component memac_rmii_clken;

end package memac_rmii_clk_pkg;

library ieee;
  use ieee.std_logic_1164.all;

entity memac_rmii_clken is
  port (
    rst        : in    std_ulogic;
    clk        : in    std_ulogic; -- 50MHz
    rmii_link  : in    std_ulogic;
    rmii_spd   : in    std_ulogic; -- 0 = 10Mbps, 1 = 100Mbps
    rmii_clken : out   std_ulogic;
    umii_clken : out   std_ulogic
  );
end entity memac_rmii_clken;

architecture rtl of memac_rmii_clken is

  signal rmii_spd_l : std_ulogic;           -- rmii_spd, latched
  signal rmii_count : integer range 0 to 9;
  signal umii_count : integer range 0 to 3;

begin

    P_MAIN: process(rst, clk)
      variable s : std_ulogic;
    begin
      if rst then
        rmii_spd_l <= '0';
        rmii_count <= 0;
        rmii_clken <= '0';
        umii_count <= 0;
        umii_clken <= '0'; -- enable synchronous reset logic
      elsif rising_edge(clk) then
        rmii_spd_l <= rmii_spd when rmii_link;
        s := rmii_spd when rmii_link else rmii_spd_l;
        rmii_count <= (rmii_count + 1) mod 10;
        rmii_clken <= '0' when s = '0' and rmii_count /= 9 else '1';
        umii_count <= (umii_count + 1) mod 4 when rmii_clken;
        umii_clken <= '1' when umii_count = 3 and (s = '1' or rmii_count = 9) else '0';
      end if;
    end process P_MAIN;

end architecture rtl;
