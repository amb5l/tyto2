--------------------------------------------------------------------------------
-- tyto_utils_pkg.vhd                                                         --
-- Useful functions and procedures etc.                                       --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
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
  use ieee.numeric_std.all;

package tyto_utils_pkg is

  function ternary (c : boolean; a, b : std_logic) return std_logic;
  function ternary (c : boolean; a, b : std_logic_vector) return std_logic_vector;
  function bool2sl( b : boolean ) return std_ulogic;
  function log2 (x : integer) return integer;
  function incr(x : std_ulogic_vector) return std_ulogic_vector;
  function decr(x : std_ulogic_vector) return std_ulogic_vector;

  procedure fd(
    signal c : in std_ulogic;
    signal d : in std_ulogic;
    signal q : out std_ulogic
  );

end package tyto_utils_pkg;

package body tyto_utils_pkg is

  function ternary (c : boolean; a, b : std_logic) return std_logic is
  begin
    if c then
      return a;
    else
      return b;
    end if;
  end function ternary;

  function ternary (c : boolean; a, b : std_logic_vector) return std_logic_vector is
  begin
    if c then
      return a;
    else
      return b;
    end if;
  end function ternary;

  function bool2sl( b : boolean ) return std_ulogic is
  begin
    if b then return '1'; else return '0'; end if;
  end function bool2sl;

  function log2 (x : integer) return integer is
    variable i : integer := 0;
  begin
    while 2**i < x loop
      i := i + 1;
    end loop;
    return i;
  end function log2;

  function incr(x : std_ulogic_vector) return std_ulogic_vector is
  begin
    return std_ulogic_vector(unsigned(x)+1);
  end function incr;

  function decr(x : std_ulogic_vector) return std_ulogic_vector is
  begin
    return std_ulogic_vector(unsigned(x)-1);
  end function decr;

  procedure fd(
    signal c : in std_ulogic;
    signal d : in std_ulogic;
    signal q : out std_ulogic
  ) is
  begin
    wait until rising_edge(c);
    q <= d;
  end procedure fd;

end package body tyto_utils_pkg;
