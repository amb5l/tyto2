--------------------------------------------------------------------------------
-- csr.vhd                                                                    --
-- Control and Status Register block.                                         --
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

use work.tyto_types_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package csr_pkg is

  type csr_bit_t is (RO, RW, W1);
  type csr_bits_t is array(natural range <>) of csr_bit_t;
  type csr_def_t is record
    addr : std_ulogic_vector;
    init : std_ulogic_vector;
    bits : csr_bits_t;
  end record csr_def_t;
  type csr_defs_t is array(natural range <>) of csr_def_t;

  function csr_addr_to_idx(addr : std_ulogic_vector; defs : csr_defs_t) return natural;

  component csr is
    generic (
      CSR_DEFS : csr_defs_t
    );
    port (
      rst  : in    std_ulogic;
      clk  : in    std_ulogic;
      en   : in    std_ulogic;
      we   : in    std_ulogic_vector;
      addr : in    std_ulogic_vector;
      din  : in    std_ulogic_vector;
      dout : out   std_ulogic_vector;
      w    : out   sulv_vector;
      p    : out   sulv_vector;
      r    : in    sulv_vector
    );
  end component csr;

end package csr_pkg;

package body csr_pkg is

  function csr_addr_to_idx(addr : std_ulogic_vector; defs : csr_defs_t) return natural is
  begin
    for i in defs'range loop
      if addr = defs(i).addr then
        return i;
      end if;
    end loop;
    return -1;
  end function csr_addr_to_idx;

end package body csr_pkg;

--------------------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.csr_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity csr is
  generic (
    CSR_DEFS : csr_defs_t
  );
  port (
    rst  : in    std_ulogic;
    clk  : in    std_ulogic;
    en   : in    std_ulogic;
    we   : in    std_ulogic_vector;
    addr : in    std_ulogic_vector;
    din  : in    std_ulogic_vector;
    dout : out   std_ulogic_vector;
    w    : out   sulv_vector;       -- R/W bit states
    p    : out   sulv_vector;       -- W1 pulse outputs
    r    : in    sulv_vector        -- RO/W1 inputs
  );
end entity csr;

architecture rtl of csr is
begin

  P_WRITE: process(rst,clk)
    variable b : integer;
  begin
    if rst = '1' then
      for i in CSR_DEFS'range loop
        for j in din'range loop
          case CSR_DEFS(i).bits(j) is
            when RW     => w(i)(j) <= CSR_DEFS(i).init(j);
            when W1     => p(i)(j) <= '0';
            when others => null;
          end case;
        end loop;
      end loop;
    elsif rising_edge(clk) then
      p <= (p'range => (p'element'range => '0'));
      if en ='1' then
        for i in CSR_DEFS'range loop
          if addr = CSR_DEFS(i).addr then
            for j in we'low to we'high loop -- traverse all byte lanes
              if we(j) = '1' then -- write this byte
                for k in 0 to 7 loop -- 8 bits per byte
                  b := (j*8)+k;
                  case CSR_DEFS(i).bits(b) is
                    when RW     => w(i)(b) <= din(b);
                    when W1     => p(i)(b) <= din(b);
                    when others => null;
                  end case;
                end loop;
              end if;
            end loop;
          end if;
        end loop;
      end if;
    end if;
  end process P_WRITE;

  P_READ: process(en,addr,w,r)
  begin
    if en = '1' then
      for i in CSR_DEFS'range loop
        if addr = CSR_DEFS(i).addr then
          for j in dout'range loop
            case CSR_DEFS(i).bits(j) is
              when RW      => dout(j) <= w(i)(j);
              when W1 | RO => dout(j) <= r(i)(j);
            end case;
          end loop;
          exit;
        end if;
      end loop;
    else
      dout <=  (dout'range => 'X');
    end if;
  end process P_READ;

end architecture rtl;

