--------------------------------------------------------------------------------
-- sync.vhd                                                                   --
-- Synchronising register(s) for clock domain crossing.                       --
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

package sync_pkg is

  component sync is
    generic (
      STAGES : integer range 2 to 3 := 2;
      WIDTH  : integer := 1;
      SR     : bit_vector(WIDTH-1 downto 0) := (others => '0')
    );
    port (
      rst : in  std_ulogic := '0';
      clk : in  std_ulogic;
      i   : in  std_ulogic_vector(WIDTH-1 downto 0);
      o   : out std_ulogic_vector(WIDTH-1 downto 0)
    );
  end component sync;

end package sync_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity sync is
  generic (
    STAGES : integer range 2 to 3 := 2;
    WIDTH  : integer := 1;
    SR     : bit_vector(WIDTH-1 downto 0) := (others => '0')
  );
  port (
    rst : in  std_ulogic := '0';
    clk : in  std_ulogic;
    i   : in  std_ulogic_vector(WIDTH-1 downto 0);
    o   : out std_ulogic_vector(WIDTH-1 downto 0)
  );
end entity sync;

architecture rtl of sync is

  type reg_t is array (1 to STAGES) of std_ulogic_vector(WIDTH-1 downto 0);
  signal reg : reg_t;

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of reg : signal is "true";

begin

  process(rst,clk)
  begin
    if rst = '1' then
      reg <= (others => to_stdulogicvector(SR));
    elsif rising_edge(clk) then
      reg(1) <= i;
      reg(2 to STAGES) <= reg(1 to STAGES-1);
    end if;
  end process;

  o <= reg(STAGES);

end architecture rtl;
