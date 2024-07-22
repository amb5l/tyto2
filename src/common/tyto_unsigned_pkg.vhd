--------------------------------------------------------------------------------
-- tyto_unsigned_pkg.vhd                                                      --
-- Operator overloads for unsigned integer maths on std_logic_vectors.        --
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

  function "=" (L: std_logic; R: std_logic) return std_logic;
  function "/=" (L: std_logic; R: std_logic) return std_logic;
  function "=" (L: std_logic_vector; R: std_logic_vector) return std_logic;
  function "/=" (L: std_logic_vector; R: std_logic_vector) return std_logic;
  function "<" (L: integer; R: std_logic_vector) return boolean;
  function ">" (L: integer; R: std_logic_vector) return boolean;
  function "<=" (L: integer; R: std_logic_vector) return boolean;
  function ">=" (L: integer; R: std_logic_vector) return boolean;
  function "+" (L: integer; R: std_logic_vector) return integer;
  function "+" (L: std_logic_vector; R: std_logic_vector) return std_logic_vector;
  function "+" (L: std_logic_vector; R: integer) return std_logic_vector;
  function "+" (L: std_logic_vector; R: boolean) return std_logic_vector;
  function "-" (L: integer; R: std_logic_vector) return integer;
  function "-" (L: std_logic_vector; R: std_logic_vector) return std_logic_vector;
  function "-" (L: std_logic_vector; R: integer) return std_logic_vector;
  function "-" (L: std_logic_vector; R: boolean) return std_logic_vector;

end package tyto_utils_pkg;

package body tyto_utils_pkg is

  function "=" (L: std_logic; R: std_logic) return std_logic is
  begin
    return L xnor R;
  end function "=";

  function "/=" (L: std_logic; R: std_logic) return std_logic is
  begin
    return L xor R;
  end function "/=";

  function "=" (L: std_logic_vector; R: std_logic_vector) return std_logic is
  begin
    if L = R then
      return '1';
    else
      return '0';
    end if;
  end function "=";

  function "/=" (L: std_logic_vector; R: std_logic_vector) return std_logic is
  begin
    if L /= R then
      return '1';
    else
      return '0';
    end if;
  end function "/=";

  function "<" (L: integer; R: std_logic_vector) return boolean is
  begin
    return L < to_integer(unsigned(R));
  end function "<";

  function ">" (L: integer; R: std_logic_vector) return boolean is
  begin
    return L > to_integer(unsigned(R));
  end function ">";

  function "<=" (L: integer; R: std_logic_vector) return boolean is
  begin
    return L <= to_integer(unsigned(R));
  end function "<=";

  function ">=" (L: integer; R: std_logic_vector) return boolean is
  begin
    return L >= to_integer(unsigned(R));
  end function ">=";

  function "+" (L: integer; R: std_logic_vector) return integer is
  begin
    return L+to_integer(unsigned(R));
  end function "+";

  function "+" (L: std_logic_vector; R: std_logic_vector) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(L)+unsigned(R));
  end function "+";

  function "+" (L: std_logic_vector; R: integer) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(L)+R);
  end function "+";

  function "+" (L: std_logic_vector; R: boolean) return std_logic_vector is
  begin
    if R then
      return std_logic_vector(unsigned(L)+1);
    else
      return L;
    end if;
  end function "+";

  function "-" (L: integer; R: std_logic_vector) return integer is
  begin
    return L-to_integer(unsigned(R));
  end function "-";

  function "-" (L: std_logic_vector; R: std_logic_vector) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(L)-unsigned(R));
  end function "-";

  function "-" (L: std_logic_vector; R: integer) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(L)-R);
  end function "-";

  function "-" (L: std_logic_vector; R: boolean) return std_logic_vector is
  begin
    if R then
      return std_logic_vector(unsigned(L)-1);
    else
      return L;
    end if;
  end function "-";

end package body tyto_utils_pkg;
