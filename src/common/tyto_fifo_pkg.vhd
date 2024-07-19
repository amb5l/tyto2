--------------------------------------------------------------------------------
-- tyto_fifo_pkg.vhd                                                          --
-- Generic package: FIFO for simulation only.                                 --
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

package tyto_fifo_pkg is

  generic (
    type item_t;               -- type of item to be stored
    constant EMPTY : item_t;   -- q value when empty
    constant NAME  : string    -- name of FIFO for reporting
  );

  type fifo_t is protected
    procedure reset(depth : in positive);
    procedure load(item : in item_t);
    procedure unload;
    impure function q return item_t;
    impure function level return natural;
  end protected fifo_t;

end package tyto_fifo_pkg;

package body tyto_fifo_pkg is

  type fifo_t is protected body

    type fifo_entry_t;
    type fifo_entry_ptr_t is access fifo_entry_t;
    type fifo_entry_t is record
        content    : item_t;
        ahead_ptr  : fifo_entry_ptr_t;
        behind_ptr : fifo_entry_ptr_t;
    end record fifo_entry_t;

    variable head_ptr  : fifo_entry_ptr_t := null;
    variable tail_ptr  : fifo_entry_ptr_t := null;
    variable count     : natural := 0;
    variable max_count : positive := 1;

    procedure reset(depth : in positive) is
    begin
      while count > 0 loop
        unload;
      end loop;
      max_count := depth;
    end procedure reset;

    procedure load(item : in item_t) is
      variable new_ptr : fifo_entry_ptr_t;
    begin
      assert count < max_count
        report NAME & ": overflow" severity failure;
      new_ptr := new fifo_entry_t;
      new_ptr.content := item;
      new_ptr.ahead_ptr := tail_ptr;
      new_ptr.behind_ptr := null;
      if head_ptr = null then
        head_ptr := new_ptr;
      end if;
      if tail_ptr /= null then
        tail_ptr.behind_ptr := new_ptr;
      end if;
      tail_ptr := new_ptr;
      count := count + 1;
    end procedure load;

    procedure unload is
    begin
      assert count > 0
        report NAME & ": underflow" severity failure;
      head_ptr := head_ptr.behind_ptr;
      if head_ptr /= null then
        deallocate(head_ptr.ahead_ptr);
        head_ptr.ahead_ptr := null;
      end if;
      count := count - 1;
    end procedure unload;

    impure function q return item_t is
    begin
      if head_ptr = null then
        return EMPTY;
      else
        return head_ptr.content;
      end if;
    end function q;

    impure function level return natural is
    begin
      return count;
    end function level;

  end protected body fifo_t;

end package body tyto_fifo_pkg;
