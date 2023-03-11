--------------------------------------------------------------------------------
-- axi_pkg.vhd                                                                --
-- AXI type definitions.                                                      --
--------------------------------------------------------------------------------
--(C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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

package axi_pkg is

  type axi4_mosi_a32d32_t is record
    awid    : std_logic_vector(   3 downto 0 );
    awaddr  : std_logic_vector(  31 downto 0 );
    awlen   : std_logic_vector(   7 downto 0 );
    awsize  : std_logic_vector(   2 downto 0 );
    awburst : std_logic_vector(   1 downto 0 );
    awlock  : std_logic;
    awcache : std_logic_vector(   3 downto 0 );
    awprot  : std_logic_vector(   2 downto 0 );
    awqos   : std_logic_vector(   3 downto 0 );
    awvalid : std_logic;
    wdata   : std_logic_vector(  31 downto 0 );
    wstrb   : std_logic_vector(   3 downto 0 );
    wlast   : std_logic;
    wvalid  : std_logic;
    bready  : std_logic;
    arid    : std_logic_vector(   3 downto 0 );
    araddr  : std_logic_vector(  31 downto 0 );
    arlen   : std_logic_vector(   7 downto 0 );
    arsize  : std_logic_vector(   2 downto 0 );
    arburst : std_logic_vector(   1 downto 0 );
    arlock  : std_logic;
    arcache : std_logic_vector(   3 downto 0 );
    arprot  : std_logic_vector(   2 downto 0 );
    arqos   : std_logic_vector(   3 downto 0 );
    arvalid : std_logic;
    rready  : std_logic;
  end record axi4_mosi_a32d32_t;

  type axi4_miso_a32d32_t is record
    awready : std_logic;
    wready  : std_logic;
    bid     : std_logic_vector(   3 downto 0 );
    bresp   : std_logic_vector(   1 downto 0 );
    bvalid  : std_logic;
    arready : std_logic;
    rid     : std_logic_vector(   3 downto 0 );
    rdata   : std_logic_vector(  31 downto 0 );
    rresp   : std_logic_vector(   1 downto 0 );
    rlast   : std_logic;
    rvalid  : std_logic;
  end record axi4_miso_a32d32_t;

  type axi4_mosi_a32d64_t is record
    awid    : std_logic_vector(   3 downto 0 );
    awaddr  : std_logic_vector(  31 downto 0 );
    awlen   : std_logic_vector(   7 downto 0 );
    awsize  : std_logic_vector(   2 downto 0 );
    awburst : std_logic_vector(   1 downto 0 );
    awlock  : std_logic;
    awcache : std_logic_vector(   3 downto 0 );
    awprot  : std_logic_vector(   2 downto 0 );
    awqos   : std_logic_vector(   3 downto 0 );
    awvalid : std_logic;
    wdata   : std_logic_vector(  63 downto 0 );
    wstrb   : std_logic_vector(   7 downto 0 );
    wlast   : std_logic;
    wvalid  : std_logic;
    bready  : std_logic;
    arid    : std_logic_vector(   3 downto 0 );
    araddr  : std_logic_vector(  31 downto 0 );
    arlen   : std_logic_vector(   7 downto 0 );
    arsize  : std_logic_vector(   2 downto 0 );
    arburst : std_logic_vector(   1 downto 0 );
    arlock  : std_logic;
    arcache : std_logic_vector(   3 downto 0 );
    arprot  : std_logic_vector(   2 downto 0 );
    arqos   : std_logic_vector(   3 downto 0 );
    arvalid : std_logic;
    rready  : std_logic;
  end record axi4_mosi_a32d64_t;

  type axi4_miso_a32d64_t is record
    awready : std_logic;
    wready  : std_logic;
    bid     : std_logic_vector(   3 downto 0 );
    bresp   : std_logic_vector(   1 downto 0 );
    bvalid  : std_logic;
    arready : std_logic;
    rid     : std_logic_vector(   3 downto 0 );
    rdata   : std_logic_vector(  63 downto 0 );
    rresp   : std_logic_vector(   1 downto 0 );
    rlast   : std_logic;
    rvalid  : std_logic;
  end record axi4_miso_a32d64_t;

  type axi4_mosi_a32d128_t is record
    awid    : std_logic_vector(   3 downto 0 );
    awaddr  : std_logic_vector(  31 downto 0 );
    awlen   : std_logic_vector(   7 downto 0 );
    awsize  : std_logic_vector(   2 downto 0 );
    awburst : std_logic_vector(   1 downto 0 );
    awlock  : std_logic;
    awcache : std_logic_vector(   3 downto 0 );
    awprot  : std_logic_vector(   2 downto 0 );
    awqos   : std_logic_vector(   3 downto 0 );
    awvalid : std_logic;
    wdata   : std_logic_vector( 127 downto 0 );
    wstrb   : std_logic_vector(  15 downto 0 );
    wlast   : std_logic;
    wvalid  : std_logic;
    bready  : std_logic;
    arid    : std_logic_vector(   3 downto 0 );
    araddr  : std_logic_vector(  31 downto 0 );
    arlen   : std_logic_vector(   7 downto 0 );
    arsize  : std_logic_vector(   2 downto 0 );
    arburst : std_logic_vector(   1 downto 0 );
    arlock  : std_logic;
    arcache : std_logic_vector(   3 downto 0 );
    arprot  : std_logic_vector(   2 downto 0 );
    arqos   : std_logic_vector(   3 downto 0 );
    arvalid : std_logic;
    rready  : std_logic;
  end record axi4_mosi_a32d64_t;

  type axi4_miso_a32d128_t is record
    awready : std_logic;
    wready  : std_logic;
    bid     : std_logic_vector(   3 downto 0 );
    bresp   : std_logic_vector(   1 downto 0 );
    bvalid  : std_logic;
    arready : std_logic;
    rid     : std_logic_vector(   3 downto 0 );
    rdata   : std_logic_vector( 127 downto 0 );
    rresp   : std_logic_vector(   1 downto 0 );
    rlast   : std_logic;
    rvalid  : std_logic;
  end record axi4_miso_a32d64_t;

  type axi4s_mosi_32_t is record
    tdata   : std_logic_vector(  31 downto 0 );
    tkeep   : std_logic_vector(   3 downto 0 );
    tlast   : std_logic;
    tvalid  : std_logic;
  end record axi4s_mosi_32_t;
  
  type axi4s_miso_32_t is record
    tready  : std_logic;
  end record axi4s_miso_32_t;

  type axi4s_mosi_64_t is record
    tdata   : std_logic_vector(  63 downto 0 );
    tkeep   : std_logic_vector(   7 downto 0 );
    tlast   : std_logic;
    tvalid  : std_logic;
  end record axi4s_mosi_64_t;
  
  type axi4s_miso_64_t is record
    tready  : std_logic;
  end record axi4s_miso_64_t;

  type axi4s_mosi_128_t is record
    tdata   : std_logic_vector( 127 downto 0 );
    tkeep   : std_logic_vector(  15 downto 0 );
    tlast   : std_logic;
    tvalid  : std_logic;
  end record axi4s_mosi_128_t;
  
  type axi4s_miso_128_t is record
    tready  : std_logic;
  end record axi4s_miso_128_t;

end package axi_pkg;
