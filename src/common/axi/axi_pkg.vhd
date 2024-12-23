--------------------------------------------------------------------------------
-- axi_pkg.vhd                                                                --
-- AXI type definitions.                                                      --
--------------------------------------------------------------------------------
--(C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
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

  type axi4l_a32d32_t is record
    awaddr   : std_logic_vector( 31 downto 0 );
    awprot   : std_logic_vector(  2 downto 0 );
    awvalid  : std_logic;
    awready  : std_logic;
    wdata    : std_logic_vector( 31 downto 0 );
    wstrb    : std_logic_vector(  3 downto 0 );
    wvalid   : std_logic;
    wready   : std_logic;
    bid      : std_logic_vector(  7 downto 0 );
    bresp    : std_logic_vector(  1 downto 0 );
    bvalid   : std_logic;
    bready   : std_logic;
    araddr   : std_logic_vector( 31 downto 0 );
    arprot   : std_logic_vector(  2 downto 0 );
    arvalid  : std_logic;
    arready  : std_logic;
    rdata    : std_logic_vector( 31 downto 0 );
    rresp    : std_logic_vector(  1 downto 0 );
    rvalid   : std_logic;
    rready   : std_logic;
  end record axi4l_a32d32_t;

  type axi4l_a32d32_mosi_t is record
    awaddr  : std_logic_vector( 31 downto 0 );
    awprot  : std_logic_vector(  2 downto 0 );
    awvalid : std_logic;
    wdata   : std_logic_vector( 31 downto 0 );
    wstrb   : std_logic_vector(  3 downto 0 );
    wvalid  : std_logic;
    bready  : std_logic;
    araddr  : std_logic_vector( 31 downto 0 );
    arprot  : std_logic_vector(  2 downto 0 );
    arvalid : std_logic;
    rready  : std_logic;
  end record axi4l_a32d32_mosi_t;

  constant AXI4L_A32D32_MOSI_DEFAULT : axi4l_a32d32_mosi_t :=
    (
      awaddr  => (others => 'U'),
      awprot  => (others => 'U'),
      awvalid => 'U',
      wdata   => (others => 'U'),
      wstrb   => (others => '1'), -- all bytes enabled
      wvalid  => 'U',
      bready  => 'U',
      araddr  => (others => 'U'),
      arprot  => (others => 'U'),
      arvalid => 'U',
      rready  => 'U'
    );

  type axi4l_a32d32_miso_t is record
    awready : std_logic;
    wready  : std_logic;
    bresp   : std_logic_vector(  1 downto 0 );
    bvalid  : std_logic;
    arready : std_logic;
    rdata   : std_logic_vector( 31 downto 0 );
    rresp   : std_logic_vector(  1 downto 0 );
    rvalid  : std_logic;
  end record axi4l_a32d32_miso_t;

  constant AXI4L_A32D32_MISO_DEFAULT : axi4l_a32d32_miso_t :=
    (
      awready => 'U',
      wready  => 'U',
      bresp   => (others => '0'), -- OKAY
      bvalid  => 'U',
      arready => 'U',
      rdata   => (others => 'U'),
      rresp   => (others => '0'), -- OKAY
      rvalid  => 'U'
    );

  type axi4_a32d32_mosi_t is record
    awid     : std_logic_vector(  7 downto 0 );
    awregion : std_logic_vector(  3 downto 0 );
    awaddr   : std_logic_vector( 31 downto 0 );
    awlen    : std_logic_vector(  7 downto 0 );
    awsize   : std_logic_vector(  2 downto 0 );
    awburst  : std_logic_vector(  1 downto 0 );
    awcache  : std_logic_vector(  3 downto 0 );
    awprot   : std_logic_vector(  2 downto 0 );
    awqos    : std_logic_vector(  3 downto 0 );
    awvalid  : std_logic;
    wdata    : std_logic_vector( 31 downto 0 );
    wstrb    : std_logic_vector(  3 downto 0 );
    wlast    : std_logic;
    wvalid   : std_logic;
    bready   : std_logic;
    arid     : std_logic_vector(  7 downto 0 );
    arregion : std_logic_vector(  3 downto 0 );
    araddr   : std_logic_vector( 31 downto 0 );
    arlen    : std_logic_vector(  7 downto 0 );
    arsize   : std_logic_vector(  2 downto 0 );
    arburst  : std_logic_vector(  1 downto 0 );
    arcache  : std_logic_vector(  3 downto 0 );
    arprot   : std_logic_vector(  2 downto 0 );
    arqos    : std_logic_vector(  3 downto 0 );
    arvalid  : std_logic;
    rready   : std_logic;
  end record axi4_a32d32_mosi_t;

  constant AXI4_A32D32_MOSI_DEFAULT : axi4_a32d32_mosi_t :=
    (
      awid     => (others => '0'),
      awregion => (others => '0'),
      awaddr   => (others => 'U'),
      awlen    => (others => '0'), -- length 1
      awsize   => "010",           -- 32 bits wide = 4 bytes
      awburst  => "01",            -- INCR
      awcache  => (others => '0'), -- device non bufferable
      awprot   => (others => 'U'),
      awqos    => (others => '0'), -- no QoS scheme
      awvalid  => 'U',
      wdata    => (others => 'U'),
      wstrb    => (others => '1'), -- all bytes enabled
      wlast    => 'U',
      wvalid   => 'U',
      bready   => 'U',
      arid     => (others => '0'),
      arregion => (others => '0'),
      araddr   => (others => 'U'),
      arlen    => (others => '0'), -- length 1
      arsize   => "010",           -- 32 bits wide = 4 bytes
      arburst  => "01",            -- INCR
      arcache  => "0000",          -- device non bufferable
      arprot   => (others => 'U'),
      arqos    => (others => 'U'),
      arvalid  => 'U',
      rready   => 'U'
    );

  type axi4_a32d32_miso_t is record
    awready : std_logic;
    wready  : std_logic;
    bid     : std_logic_vector(  7 downto 0 );
    bresp   : std_logic_vector(  1 downto 0 );
    bvalid  : std_logic;
    arready : std_logic;
    rid     : std_logic_vector(  7 downto 0 );
    rdata   : std_logic_vector( 31 downto 0 );
    rresp   : std_logic_vector(  1 downto 0 );
    rlast   : std_logic;
    rvalid  : std_logic;
  end record axi4_a32d32_miso_t;

  constant AXI4_A32D32_MISO_DEFAULT : axi4_a32d32_miso_t :=
    (
      awready => 'U',
      wready  => 'U',
      bid     => (others => 'U'),
      bresp   => (others => '0'), -- OKAY
      bvalid  => 'U',
      arready => 'U',
      rid     => (others => 'U'),
      rdata   => (others => 'U'),
      rresp   => (others => '0'), -- OKAY
      rlast   => 'U',
      rvalid  => 'U'
    );

  type axi4_a32d64_mosi_t is record
    awid     : std_logic_vector(  7 downto 0 );
    awregion : std_logic_vector(  3 downto 0 );
    awaddr   : std_logic_vector( 31 downto 0 );
    awlen    : std_logic_vector(  7 downto 0 );
    awsize   : std_logic_vector(  2 downto 0 );
    awburst  : std_logic_vector(  1 downto 0 );
    awcache  : std_logic_vector(  3 downto 0 );
    awprot   : std_logic_vector(  2 downto 0 );
    awqos    : std_logic_vector(  3 downto 0 );
    awvalid  : std_logic;
    wdata    : std_logic_vector( 63 downto 0 );
    wstrb    : std_logic_vector(  7 downto 0 );
    wlast    : std_logic;
    wvalid   : std_logic;
    bready   : std_logic;
    arid     : std_logic_vector(  7 downto 0 );
    arregion : std_logic_vector(  3 downto 0 );
    araddr   : std_logic_vector( 31 downto 0 );
    arlen    : std_logic_vector(  7 downto 0 );
    arsize   : std_logic_vector(  2 downto 0 );
    arburst  : std_logic_vector(  1 downto 0 );
    arcache  : std_logic_vector(  3 downto 0 );
    arprot   : std_logic_vector(  2 downto 0 );
    arqos    : std_logic_vector(  3 downto 0 );
    arvalid  : std_logic;
    rready   : std_logic;
  end record axi4_a32d64_mosi_t;

  type axi4_a32d64_miso_t is record
    awready : std_logic;
    wready  : std_logic;
    bid     : std_logic_vector(  7 downto 0 );
    bresp   : std_logic_vector(  1 downto 0 );
    bvalid  : std_logic;
    arready : std_logic;
    rid     : std_logic_vector(  7 downto 0 );
    rdata   : std_logic_vector( 63 downto 0 );
    rresp   : std_logic_vector(  1 downto 0 );
    rlast   : std_logic;
    rvalid  : std_logic;
  end record axi4_a32d64_miso_t;

  type axi4_a32d128_mosi_t is record
    awid     : std_logic_vector(   7 downto 0 );
    awregion : std_logic_vector(   3 downto 0 );
    awaddr   : std_logic_vector(  31 downto 0 );
    awlen    : std_logic_vector(   7 downto 0 );
    awsize   : std_logic_vector(   2 downto 0 );
    awburst  : std_logic_vector(   1 downto 0 );
    awcache  : std_logic_vector(   3 downto 0 );
    awprot   : std_logic_vector(   2 downto 0 );
    awqos    : std_logic_vector(   3 downto 0 );
    awvalid  : std_logic;
    wdata    : std_logic_vector( 127 downto 0 );
    wstrb    : std_logic_vector(  15 downto 0 );
    wlast    : std_logic;
    wvalid   : std_logic;
    bready   : std_logic;
    arid     : std_logic_vector(   7 downto 0 );
    arregion : std_logic_vector(   3 downto 0 );
    araddr   : std_logic_vector(  31 downto 0 );
    arlen    : std_logic_vector(   7 downto 0 );
    arsize   : std_logic_vector(   2 downto 0 );
    arburst  : std_logic_vector(   1 downto 0 );
    arcache  : std_logic_vector(   3 downto 0 );
    arprot   : std_logic_vector(   2 downto 0 );
    arqos    : std_logic_vector(   3 downto 0 );
    arvalid  : std_logic;
    rready   : std_logic;
  end record axi4_a32d128_mosi_t;

  type axi4_a32d128_miso_t is record
    awready : std_logic;
    wready  : std_logic;
    bid     : std_logic_vector(   7 downto 0 );
    bresp   : std_logic_vector(   1 downto 0 );
    bvalid  : std_logic;
    arready : std_logic;
    rid     : std_logic_vector(   7 downto 0 );
    rdata   : std_logic_vector( 127 downto 0 );
    rresp   : std_logic_vector(   1 downto 0 );
    rlast   : std_logic;
    rvalid  : std_logic;
  end record axi4_a32d128_miso_t;

  type axi4s_32_mosi_t is record
    tdata   : std_logic_vector( 31 downto 0 );
    tkeep   : std_logic_vector(  3 downto 0 );
    tlast   : std_logic;
    tvalid  : std_logic;
  end record axi4s_32_mosi_t;

  type axi4s_32_miso_t is record
    tready  : std_logic;
  end record axi4s_32_miso_t;

  type axi4s_64_mosi_t is record
    tdata   : std_logic_vector( 63 downto 0 );
    tkeep   : std_logic_vector(  7 downto 0 );
    tlast   : std_logic;
    tvalid  : std_logic;
  end record axi4s_64_mosi_t;

  type axi4s_64_miso_t is record
    tready  : std_logic;
  end record axi4s_64_miso_t;

  type axi4s_128_mosi_t is record
    tdata   : std_logic_vector( 127 downto 0 );
    tkeep   : std_logic_vector(  15 downto 0 );
    tlast   : std_logic;
    tvalid  : std_logic;
  end record axi4s_128_mosi_t;

  type axi4s_128_miso_t is record
    tready  : std_logic;
  end record axi4s_128_miso_t;

end package axi_pkg;
