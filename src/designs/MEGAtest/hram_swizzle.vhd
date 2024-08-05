use work.tyto_types_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package hram_swizzle_pkg is

  impure function swizzle_table(n : integer) return sulv_vector;

end package hram_swizzle_pkg;

use work.tyto_utils_pkg.all;

library ieee;
  use ieee.numeric_std.all;

package body hram_swizzle_pkg is

  impure function swizzle_table(n : integer) return sulv_vector is
    variable r    : sulv_vector(0 to (2**n)-1)(n-1 downto 0);
    variable x    : std_ulogic_vector(n-1 downto 0);
    variable y    : std_ulogic_vector(n-1 downto 0);
    variable prng : prng_t;
    function found(x : std_ulogic_vector; v : sulv_vector) return boolean is
    begin
      for i in v'range loop
        if v(i) = x then
          return true;
        end if;
      end loop;
      return false;
    end function found;
  begin
    prng.rand_seed(123,456);
    r := (others => (others => 'X'));
    x := prng.rand_slv(0,(2**n)-1,x'length);
    for i in r'range loop
      loop
        y := prng.rand_slv(1,(2**n)-1,y'length);
        if not found(x xor y,r) then
          x := x xor y;
          r(i) := x;
          exit;
        end if;
      end loop;
    end loop;
    return r;
  end function swizzle_table;

end package body hram_swizzle_pkg;
