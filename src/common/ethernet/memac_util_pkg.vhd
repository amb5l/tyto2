--------------------------------------------------------------------------------
-- memac_util_pkg.vhd                                                         --
-- Modular Ethernet MAC (MEMAC): utility package.                             --
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

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

package memac_util_pkg is

  constant kByte : integer := 1024;

  type prng_t is protected
    procedure rand_seed(s1, s2 : in integer);
    impure function rand_real return real;
    impure function rand_int(min, max : in integer) return integer;
    impure function rand_slv(min, max, width : in integer) return std_ulogic_vector;
  end protected prng_t;

  shared variable prng : prng_t;

  function ternary( b : boolean; t, f : integer ) return integer;
  function bool2sl( b : boolean ) return std_ulogic;
  function bin2gray( bin : std_ulogic_vector ) return std_ulogic_vector;
  function gray2bin( gray : std_ulogic_vector ) return std_ulogic_vector;
  function rev(i : std_ulogic_vector) return std_ulogic_vector;
  function log2(x : integer) return integer;

  procedure incr(signal x : inout std_ulogic_vector);
  procedure decr(signal x : inout std_ulogic_vector);

end package memac_util_pkg;

--------------------------------------------------------------------------------

package body memac_util_pkg is

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

  function ternary( b : boolean; t, f : integer ) return integer is
  begin
    if b then return t; else return f; end if;
  end function ternary;

  function bool2sl( b : boolean ) return std_ulogic is
  begin
    if b then return '1'; else return '0'; end if;
  end function bool2sl;

  function bin2gray( bin : std_ulogic_vector ) return std_ulogic_vector is
    variable gray : std_ulogic_vector(bin'range);
  begin
    gray := bin;
    for i in bin'high-1 downto bin'low loop
      gray(i) := bin(i) xor bin(i+1);
    end loop;
    return gray;
  end function bin2gray;

  function gray2bin( gray : std_ulogic_vector ) return std_ulogic_vector is
    variable bin : std_ulogic_vector( gray'length-1 downto 0 );
  begin
    bin := gray;
    for i in bin'high-1 downto bin'low loop
      bin(i) := gray(i) xor bin(i+1);
    end loop;
    return bin;
  end function gray2bin;

  function rev(i : std_ulogic_vector) return std_ulogic_vector is
    variable o : std_ulogic_vector(i'reverse_range);
  begin
    for n in i'range loop
      o(n) := i(n);
    end loop;
    return o;
  end function rev;

  -- return lowest power of 2 that is greater than or equal to x
  function log2(x : integer) return integer is
    variable i : integer := 0;
  begin
    while 2**i < x loop
      i := i + 1;
    end loop;
    return i;
  end function log2;

  procedure incr(signal x : inout std_ulogic_vector) is
  begin
    x <= std_ulogic_vector(unsigned(x)+1);
  end procedure incr;

  procedure decr(signal x : inout std_ulogic_vector) is
  begin
    x <= std_ulogic_vector(unsigned(x)-1);
  end procedure decr;

end package body memac_util_pkg;

--------------------------------------------------------------------------------
