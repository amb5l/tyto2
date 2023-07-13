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

  type axi4s_mosi_t is record
    tid    : std_logic_vector;
    tdest  : std_logic_vector;
    tuser  : std_logic_vector;
    tdata  : std_logic_vector;
    tkeep  : std_logic_vector;
    tstrb  : std_logic_vector;
    tlast  : std_logic;
    tvalid : std_logic;
  end record axi4s_mosi_t;

  type axi4s_miso_t is record
    tready : std_logic;
  end record axi4s_miso_t;

  subtype axi4s_32_mosi_t is axi4s_mosi_t (
    tid   (  7 downto 0 ),
    tdest (  7 downto 0 ),
    tuser (  7 downto 0 ),
    tdata ( 31 downto 0 ),
    tkeep (  3 downto 0 ),
    tstrb (  3 downto 0 )
  );

  subtype axi4s_32_miso_t is axi4s_miso_t;

  constant AXI4S_32_MOSI_DEFAULT : axi4s_32_mosi_t := (
    tid    => (others => '0'),
    tdest  => (others => '0'),
    tuser  => (others => '0'),
    tdata  => (others => 'U'),
    tkeep  => (others => '1'),
    tstrb  => (others => '1'),
    tlast  => '0',
    tvalid => 'U'
  );

  constant AXI4S_32_MISO_DEFAULT : axi4s_32_miso_t := (
    tready => 'U'
  );

  subtype axi4s_64_mosi_t is axi4s_mosi_t (
    tid   (  7 downto 0 ),
    tdest (  7 downto 0 ),
    tuser (  7 downto 0 ),
    tdata ( 63 downto 0 ),
    tkeep (  7 downto 0 ),
    tstrb (  7 downto 0 )
  );

  subtype axi4s_64_miso_t is axi4s_miso_t;

  constant AXI4S_64_MOSI_DEFAULT : axi4s_64_mosi_t := (
    tid    => (others => '0'),
    tdest  => (others => '0'),
    tuser  => (others => '0'),
    tdata  => (others => 'U'),
    tkeep  => (others => '1'),
    tstrb  => (others => '1'),
    tlast  => '0',
    tvalid => 'U'
  );

  constant AXI4S_64_MISO_DEFAULT : axi4s_64_miso_t := (
    tready => 'U'
  );

  subtype axi4s_128_mosi_t is axi4s_mosi_t (
    tid   (   7 downto 0 ),
    tdest (   7 downto 0 ),
    tuser (   7 downto 0 ),
    tdata ( 127 downto 0 ),
    tkeep (  15 downto 0 ),
    tstrb (  15 downto 0 )
  );

  subtype axi4s_128_miso_t is axi4s_miso_t;

  constant AXI4S_128_MOSI_DEFAULT : axi4s_128_mosi_t := (
    tid    => (others => '0'),
    tdest  => (others => '0'),
    tuser  => (others => '0'),
    tdata  => (others => 'U'),
    tkeep  => (others => '1'),
    tstrb  => (others => '1'),
    tlast  => '0',
    tvalid => 'U'
  );

  constant AXI4S_128_MISO_DEFAULT : axi4s_128_miso_t := (
    tready => 'U'
  );

end package axi4s_pkg;
