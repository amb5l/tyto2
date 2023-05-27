--------------------------------------------------------------------------------
-- axi4_pkg.vhd                                                               --
-- AXI4 type definitions.                                                     --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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

package axi4_pkg is

  --------------------------------------------------------------------------------
  -- hierarchical separate (MOSI/MISO)

  type axi4_aw_mosi_t is record
    id     : std_logic_vector(7 downto 0);
    region : std_logic_vector(3 downto 0);
    addr   : std_logic_vector;
    len    : std_logic_vector(7 downto 0);
    size   : std_logic_vector(2 downto 0);
    burst  : std_logic_vector(1 downto 0);
    cache  : std_logic_vector(3 downto 0);
    prot   : std_logic_vector(2 downto 0);
    qos    : std_logic_vector(3 downto 0);
    valid  : std_logic;
  end record axi4_aw_mosi_t;

  type axi4_w_mosi_t is record
    data  : std_logic_vector;
    strb  : std_logic_vector;
    last  : std_logic;
    valid : std_logic;
  end record axi4_w_mosi_t;

  type axi4_b_mosi_t is record
    ready   : std_logic;
  end record axi4_b_mosi_t;

  type axi4_ar_mosi_t is record
    id     : std_logic_vector(7 downto 0);
    region : std_logic_vector(3 downto 0);
    addr   : std_logic_vector;
    len    : std_logic_vector(7 downto 0);
    size   : std_logic_vector(2 downto 0);
    burst  : std_logic_vector(1 downto 0);
    cache  : std_logic_vector(3 downto 0);
    prot   : std_logic_vector(2 downto 0);
    qos    : std_logic_vector(3 downto 0);
    valid  : std_logic;
  end record axi4_ar_mosi_t;

  type axi4_r_mosi_t is record
    ready  : std_logic;
  end record axi4_r_mosi_t;

  type axi4_h_mosi_t is record
    aw : axi4_aw_mosi_t;
    w  : axi4_w_mosi_t;
    b  : axi4_b_mosi_t;
    ar : axi4_ar_mosi_t;
    r  : axi4_r_mosi_t;
  end record axi4_h_mosi_t;

  subtype axi4_a32d32_h_mosi_t is axi4_h_mosi_t (
    aw (addr(31 downto 0)),
    w  (data(31 downto 0),strb(3 downto 0)),
    ar (addr(31 downto 0))
  );

  constant AXI4_A32D32_H_MOSI_DEFAULT : axi4_a32d32_h_mosi_t := (
    aw => (
      id     => (others => '0'),
      region => (others => '0'),
      addr   => (others => 'U'),
      len    => (others => '0'), -- length 1
      size   => "010",           -- 32 bits wi
      burst  => "01",            -- INCR
      cache  => (others => '0'), -- device non
      prot   => (others => 'U'),
      qos    => (others => '0'), -- no QoS sch
      valid  => 'U'
    ),
    w => (
      data    => (others => 'U'),
      strb    => (others => '1'), -- all bytes enabled
      last    => 'U',
      valid   => 'U'
    ),
    b => (
      ready   => 'U'
    ),
    ar => (
      id     => (others => '0'),
      region => (others => '0'),
      addr   => (others => 'U'),
      len    => (others => '0'), -- length 1
      size   => "010",           -- 32 bits wide = 4 bytes
      burst  => "01",            -- INCR
      cache  => "0000",          -- device non bufferable
      prot   => (others => 'U'),
      qos    => (others => 'U'),
      valid  => 'U'
    ),
    r => (
      ready   => 'U'
    )
  );

  type axi4_aw_miso_t is record
    ready : std_logic;
  end record axi4_aw_miso_t;

  type axi4_w_miso_t is record
    ready : std_logic;
  end record axi4_w_miso_t;

  type axi4_b_miso_t is record
    id    : std_logic_vector(7 downto 0);
    resp  : std_logic_vector(1 downto 0);
    valid : std_logic;
  end record axi4_b_miso_t;

  type axi4_ar_miso_t is record
    ready : std_logic;
  end record axi4_ar_miso_t;

  type axi4_r_miso_t is record
    id    : std_logic_vector(7 downto 0);
    data  : std_logic_vector;
    resp  : std_logic_vector(1 downto 0);
    last  : std_logic;
    valid : std_logic;
  end record axi4_r_miso_t;

  type axi4_h_miso_t is record
    aw : axi4_aw_miso_t;
    w  : axi4_w_miso_t;
    b  : axi4_b_miso_t;
    ar : axi4_ar_miso_t;
    r  : axi4_r_miso_t;
  end record axi4_h_miso_t;

  subtype axi4_a32d32_h_miso_t is axi4_h_miso_t(
    r (data(31 downto 0))
  );

  constant AXI4_A32D32_H_MISO_DEFAULT : axi4_a32d32_h_miso_t := (
    aw => (
      ready => 'U'
    ),
    w => (
      ready  => 'U'
    ),
    b => (
      id     => (others => 'U'),
      resp   => (others => '0'), -- OKAY
      valid  => 'U'
    ),
    ar => (
      ready => 'U'
    ),
    r => (
      id     => (others => 'U'),
      data   => (others => 'U'),
      resp   => (others => '0'), -- OKAY
      last   => 'U',
      valid  => 'U'
    )
  );

  --------------------------------------------------------------------------------
  -- flat unified

  type axi4_t is record
    awid     : std_logic_vector(7 downto 0);
    awregion : std_logic_vector(3 downto 0);
    awaddr   : std_logic_vector;
    awlen    : std_logic_vector(7 downto 0);
    awsize   : std_logic_vector(2 downto 0);
    awburst  : std_logic_vector(1 downto 0);
    awcache  : std_logic_vector(3 downto 0);
    awprot   : std_logic_vector(2 downto 0);
    awqos    : std_logic_vector(3 downto 0);
    awvalid  : std_logic;
    awready  : std_logic;
    wdata    : std_logic_vector;
    wstrb    : std_logic_vector;
    wlast    : std_logic;
    wvalid   : std_logic;
    wready   : std_logic;
    bid      : std_logic_vector(7 downto 0);
    bresp    : std_logic_vector(1 downto 0);
    bvalid   : std_logic;
    bready   : std_logic;
    arid     : std_logic_vector(7 downto 0);
    arregion : std_logic_vector(3 downto 0);
    araddr   : std_logic_vector;
    arlen    : std_logic_vector(7 downto 0);
    arsize   : std_logic_vector(2 downto 0);
    arburst  : std_logic_vector(1 downto 0);
    arcache  : std_logic_vector(3 downto 0);
    arprot   : std_logic_vector(2 downto 0);
    arqos    : std_logic_vector(3 downto 0);
    arvalid  : std_logic;
    arready  : std_logic;
    rid      : std_logic_vector(7 downto 0);
    rdata    : std_logic_vector;
    rresp    : std_logic_vector(1 downto 0);
    rlast    : std_logic;
    rvalid   : std_logic;
    rready   : std_logic;
  end record axi4_t;

  subtype axi4_a32d32_t is axi4_t(
    awaddr(31 downto 0),
    wdata(31 downto 0),
    wstrb(3 downto 0),
    araddr(31 downto 0),
    rdata(31 downto 0)
  );

  --------------------------------------------------------------------------------
  -- conversion functions

  function axi4_a32d32_hs2f (
    mosi: axi4_a32d32_h_mosi_t;
    miso: axi4_a32d32_h_miso_t
  ) return axi4_a32d32_t;

  --------------------------------------------------------------------------------

end package axi4_pkg;

library work;
  use work.axi4_pkg.all;

package body axi4_pkg is

  -- hierarchical separate to flat unified
  function axi4_a32d32_hs2f (
    mosi: axi4_a32d32_h_mosi_t;
    miso: axi4_a32d32_h_miso_t
  ) return axi4_a32d32_t is
    variable r: axi4_a32d32_t;
  begin
    r.awid     := mosi.aw.id;
    r.awregion := mosi.aw.region;
    r.awaddr   := mosi.aw.addr;
    r.awlen    := mosi.aw.len;
    r.awsize   := mosi.aw.size;
    r.awburst  := mosi.aw.burst;
    r.awcache  := mosi.aw.cache;
    r.awprot   := mosi.aw.prot;
    r.awqos    := mosi.aw.qos;
    r.awvalid  := mosi.aw.valid;
    r.awready  := miso.aw.ready;
    r.wdata    := mosi.w.data;
    r.wstrb    := mosi.w.strb;
    r.wlast    := mosi.w.last;
    r.wvalid   := mosi.w.valid;
    r.wready   := miso.w.ready;
    r.bid      := miso.b.id;
    r.bresp    := miso.b.resp;
    r.bvalid   := miso.b.valid;
    r.bready   := mosi.b.ready;
    r.arid     := mosi.ar.id;
    r.arregion := mosi.ar.region;
    r.araddr   := mosi.ar.addr;
    r.arlen    := mosi.ar.len;
    r.arsize   := mosi.ar.size;
    r.arburst  := mosi.ar.burst;
    r.arcache  := mosi.ar.cache;
    r.arprot   := mosi.ar.prot;
    r.arqos    := mosi.ar.qos;
    r.arvalid  := mosi.ar.valid;
    r.arready  := miso.ar.ready;
    r.rid      := miso.r.id;
    r.rdata    := miso.r.data;
    r.rresp    := miso.r.resp;
    r.rlast    := miso.r.last;
    r.rvalid   := miso.r.valid;
    r.rready   := mosi.r.ready;
    return r;
  end function axi4_a32d32_hs2f;

end package body axi4_pkg;
