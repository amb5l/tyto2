--------------------------------------------------------------------------------
-- axi4s_pkg.vhd                                                              --
-- AXI4-Stream types.                                                         --
--------------------------------------------------------------------------------
--(C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                         --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or(at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package axi4s_pkg is

  type axi4s_32_mosi_t is record
    tdata  : std_logic_vector(  31 downto 0 );
    tkeep  : std_logic_vector(   3 downto 0 );
    tlast  : std_logic;
    tvalid : std_logic;
  end record axi4s_32_mosi_t;

  type axi4s_32_miso_t is record
    tready : std_logic;
  end record axi4s_32_miso_t;

  type axi4s_64_mosi_t is record
    tdata  : std_logic_vector(  63 downto 0 );
    tkeep  : std_logic_vector(   7 downto 0 );
    tlast  : std_logic;
    tvalid : std_logic;
  end record axi4s_64_mosi_t;

  type axi4s_64_miso_t is record
    tready  : std_logic;
  end record axi4s_64_miso_t;

  type axi4s_128_mosi_t is record
    tdata  : std_logic_vector( 127 downto 0 );
    tkeep  : std_logic_vector(  15 downto 0 );
    tlast  : std_logic;
    tvalid : std_logic;
  end record axi4s_128_mosi_t;

  type axi4s_128_miso_t is record
    tready : std_logic;
  end record axi4s_128_miso_t;

end package axi4s_pkg;
