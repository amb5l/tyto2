--------------------------------------------------------------------------------
-- tyto_queue_pkg.vhd                                                         --
-- Generic package: queue for simulation only.                                --
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

package tyto_queue_pkg is

  generic (
    type queue_item_t;
    constant EMPTY : queue_item_t
  );

  type queue_t is protected
    procedure enq(item : in queue_item_t);
    procedure deq;
    impure function front return queue_item_t;
    impure function items return natural;
  end protected queue_t;

end package tyto_queue_pkg;

package body tyto_queue_pkg is

  type queue_t is protected body

    type queue_entry_t;
    type queue_entry_ptr_t is access queue_entry_t;
    type queue_entry_t is record
        content    : queue_item_t;
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
      new_ptr.content := item;
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
      if front_ptr = null then
        return EMPTY;
      else
        return front_ptr.content;
      end if;
    end function front;

    impure function items return natural is
    begin
      return count;
    end function items;

  end protected body queue_t;

end package body tyto_queue_pkg;
