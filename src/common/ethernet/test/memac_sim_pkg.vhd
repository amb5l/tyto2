--------------------------------------------------------------------------------
-- memac_sim_pkg.vhd                                                          --
-- MEMAC simulation support packages: memac_queue_pkg and memac_sim_pkg       --
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
-- generic package for queue type

package memac_sim_queue_pkg is

  generic (
    type queue_item_t;
    constant EMPTY : queue_item_t
  );

  type queue_t is protected
    procedure enq(item : in queue_item_t);
    procedure enq(item : in queue_item_t; n : natural);
    procedure deq;
    procedure reset;
    impure function front return queue_item_t;
    impure function back return queue_item_t;
    impure function items return natural;
  end protected queue_t;

end package memac_sim_queue_pkg;

package body memac_sim_queue_pkg is

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

    procedure enq(item : in queue_item_t; n : natural) is
    begin
      if n > 0 then
        for i in 1 to n loop
          enq(item);
        end loop;
      end if;
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

    procedure reset is
    begin
      while front_ptr /= null loop
        deq;
      end loop;
      count := 0;
    end procedure reset;

    impure function front return queue_item_t is
    begin
      if front_ptr = null then
        return EMPTY;
      else
        return front_ptr.item;
      end if;
    end function front;

    impure function back return queue_item_t is
    begin
      assert back_ptr /= null
        report "queue is empty" severity failure;
      return back_ptr.item;
    end function back;

    impure function items return natural is
    begin
      return count;
    end function items;

  end protected body queue_t;

end package body memac_sim_queue_pkg;

--------------------------------------------------------------------------------
-- main package

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

package memac_sim_pkg is

  type prng_t is protected
    procedure rand_seed(s1, s2 : in integer);
    impure function rand_real return real;
    impure function rand_int(min, max : in integer) return integer;
    impure function rand_slv(min, max, width : in integer) return std_ulogic_vector;
  end protected prng_t;

  function valid(s : std_ulogic) return boolean;
  function valid(v : std_ulogic_vector) return boolean;

end package memac_sim_pkg;

package body memac_sim_pkg is

  type prng_t is protected body
    variable seed1, seed2 : integer := 0;
    procedure rand_seed(s1, s2 : in integer) is
    begin
      seed1 := s1;
      seed2 := s2;
    end procedure rand_seed;
    impure function rand_real return real is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return r;
    end function rand_real;
    impure function rand_int(min, max : in integer) return integer is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(r * real(max - min) + real(min));
    end function rand_int;
    impure function rand_slv(min, max, width : in integer) return std_ulogic_vector is
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return std_ulogic_vector(to_unsigned(integer(r * real(max - min) + real(min)), width));
    end function rand_slv;
  end protected body prng_t;

  function valid(s : std_ulogic) return boolean is
    variable r : boolean;
  begin
    r := true when s = '0' or s = '1' else false;
    return r;
  end function valid;

  function valid(v : std_ulogic_vector) return boolean is
    variable r : boolean;
  begin
    r := true;
    for i in v'range loop
      if v(i) /= '0' and v(i) /= '1' then
        r := false;
      end if;
    end loop;
    return r;
  end function valid;

end package body memac_sim_pkg;

--------------------------------------------------------------------------------
