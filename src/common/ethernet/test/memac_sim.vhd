--------------------------------------------------------------------------------
-- memac_sim.vhd                                                              --
-- MEMAC simulation support packages: memac_queue_pkg and memac_sim_pkg       --
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
-- generic package for queue type

package memac_queue_pkg is

  generic (
    type queue_item_t
  );

  type queue_t is protected
    procedure enq(item : in queue_item_t);
    procedure deq;
    impure function front return queue_item_t;
    impure function items return natural;
  end protected queue_t;

end package memac_queue_pkg;

package body memac_queue_pkg is

  type queue_t is protected body

    type queue_entry_t;
    type queue_entry_ptr_t is access queue_entry_t;
    type queue_entry_t is record
        item       : queue_item_t;
        ahead_ptr  : queue_entry_ptr_t;
        behind_ptr : queue_entry_ptr_t;
    end record queue_entry_t;

    variable front_ptr : queue_entry_ptr_t := null;
    variable back_ptr  : queue_entry_ptr_t := null;
    variable count     : natural := 0;

    procedure enq(item : in queue_item_t) is
      variable new_ptr : queue_entry_ptr_t;
    begin
      new_ptr := new queue_entry_t;
      new_ptr.item := item;
      new_ptr.ahead_ptr := back_ptr;
      new_ptr.behind_ptr := null;
      if front_ptr = null then
        front_ptr := new_ptr;
      end if;
      if back_ptr /= null then
        back_ptr.behind_ptr := new_ptr;
      end if;
      back_ptr := new_ptr;
      count := count + 1;
    end procedure enq;

    procedure deq is
    begin
      front_ptr := front_ptr.behind_ptr;
      if front_ptr /= null then
        deallocate(front_ptr.ahead_ptr);
        front_ptr.ahead_ptr := null;
      end if;
      count := count - 1;
    end procedure deq;

    impure function front return queue_item_t is
    begin
      assert front_ptr /= null report "queue is empty" severity failure;
      return front_ptr.item;
    end function front;

    impure function items return natural is
    begin
      return count;
    end function items;

  end protected body queue_t;

end package body memac_queue_pkg;

--------------------------------------------------------------------------------
-- type package

library ieee;
  use ieee.std_logic_1164.all;

package memac_sim_type_pkg is

  subtype octet_t is std_ulogic_vector(7 downto 0); -- little endian
  type octet_array_t is array (natural range <>) of octet_t;
  type octet_array_ptr_t is access octet_array_t;

  type pktbuf_t is record
    length   : natural;
    data_ptr : octet_array_ptr_t;
  end record pktbuf_t;

  type mii4_t is record
    spd : std_ulogic;                    -- speed: 0 = 10Mbps, 1 = 100Mbps
    crs : std_ulogic;                    -- carrier sense
    dv  : std_ulogic;                    -- data valid
    er  : std_ulogic;                    -- error
    d   : std_ulogic_vector(3 downto 0); -- data
  end record mii4_t;
  type mii4_seq_t is array (positive range <>) of mii4_t;
  type mii4_seq_ptr_t is access mii4_seq_t;

  type mii8_t is record
    spd : std_ulogic_vector(1 downto 0); -- speed: 00 = 10Mbps, 01 = 100Mbps, 10 = 1000Mbps
    crs : std_ulogic;                    -- carrier sense
    dv  : std_ulogic;                    -- data valid
    er  : std_ulogic;                    -- error
    d   : std_ulogic_vector(7 downto 0); -- data
  end record mii8_t;
  type mii8_seq_t is array (positive range <>) of mii8_t;
  type mii8_seq_ptr_t is access mii8_seq_t;

end package memac_sim_type_pkg;

--------------------------------------------------------------------------------
-- queue package instance for packet queue type

use work.memac_sim_type_pkg.all;
package memac_packet_queue_pkg is
  new work.memac_queue_pkg generic map(queue_item_t => pktbuf_t);

--------------------------------------------------------------------------------
-- main simulation package

use work.memac_sim_type_pkg.all;
use work.memac_packet_queue_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package memac_sim_pkg is

  function new_pktbuf(len : natural) return pktbuf_t;

end package memac_sim_pkg;

package body memac_sim_pkg is

  function new_pktbuf(len : natural) return pktbuf_t is
    variable r : pktbuf_t;
  begin
    r.length   := len;
    r.data_ptr := new octet_array_t(0 to len-1);
    return r;
  end function new_pktbuf;

  procedure free_pktbuf(variable pktbuf : in pktbuf_t) is
  begin
    deallocate(pktbuf.data_ptr);
  end procedure free_pktbuf;

  procedure mii4_tx()

end package body memac_sim_pkg;
