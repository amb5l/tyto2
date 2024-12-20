--------------------------------------------------------------------------------
-- sync_reg_u.vhd                                                             --
-- Synchronising register(s) for clock domain crossing (unconstrained I/Os).  --
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

package sync_reg_u_pkg is

  component sync_reg_u is
    generic (
      STAGES    : positive;
      RST_STATE : std_ulogic := '0'
    );
    port (
      rst : in  std_ulogic := '0';
      clk : in  std_ulogic;
      i   : in  std_ulogic_vector;
      o   : out std_ulogic_vector
    );
  end component sync_reg_u;

end package sync_reg_u_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity sync_reg_u is
  generic (
    STAGES    : positive;
    RST_STATE : std_ulogic := '0'
  );
  port (
    rst : in  std_ulogic := '0';
    clk : in  std_ulogic;
    i   : in  std_ulogic_vector;
    o   : out std_ulogic_vector
  );
end entity sync_reg_u;

architecture rtl of sync_reg_u is

  type reg_t is array (1 to STAGES) of std_ulogic_vector(i'range);
  signal reg : reg_t;

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of reg : signal is "TRUE";

begin

  process(rst,clk)
  begin
    if rst = '1' then
      reg <= (others => (others => RST_STATE));
    elsif rising_edge(clk) then
      for x in 1 to STAGES loop
        if x = 1 then
          reg(x) <= i;
        else
          reg(x) <= reg(x-1);
        end if;
      end loop;
    end if;
  end process;

  o <= reg(STAGES);

end architecture rtl;
