--------------------------------------------------------------------------------
-- axi_pkg.vhd                                                                --
-- AXI type definitions.                                                      --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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

package axi_pkg is

  type axi_t is record
    awaddr  : std_logic_vector(31 downto 0);
    awprot  : std_logic_vector(2 downto 0);
    awvalid : std_logic_vector;
    awready : std_logic_vector;
    wdata   : std_logic_vector(31 downto 0);
    wstrb   : std_logic_vector(3 downto 0);
    wvalid  : std_logic_vector;
    wready  : std_logic_vector;
    bresp   : std_logic_vector(1 downto 0);
    bvalid  : std_logic_vector;
    bready  : std_logic_vector;
    araddr  : std_logic_vector(31 downto 0);
    arprot  : std_logic_vector(2 downto 0);
    arvalid : std_logic;
    arready : std_logic;
    rdata   : std_logic_vector(31 downto 0);
    rresp   : std_logic_vector(1 downto 0);
    rvalid  : std_logic;
    rready  : std_logic;
  end record axi_t;

  type axi_mosi_t is record
    awaddr  : std_logic_vector(31 downto 0);
    awprot  : std_logic_vector(2 downto 0);
    awvalid : std_logic;
    wdata   : std_logic_vector(31 downto 0);
    wstrb   : std_logic_vector(3 downto 0);
    wvalid  : std_logic;
    bready  : std_logic;
    araddr  : std_logic_vector(31 downto 0);
    arprot  : std_logic_vector(2 downto 0);
    arvalid : std_logic;
    rready  : std_logic;
  end record axi_mosi_t;

  type axi_miso_t is record
    awready : std_logic;
    wready  : std_logic;
    bresp   : std_logic_vector(1 downto 0);
    bvalid  : std_logic;
    arready : std_logic;
    rdata   : std_logic_vector(31 downto 0);
    rresp   : std_logic_vector(1 downto 0);
    rvalid  : std_logic;
  end record axi_miso_t;

end package axi_pkg;
