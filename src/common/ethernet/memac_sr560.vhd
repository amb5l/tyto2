--------------------------------------------------------------------------------
-- memac_sr560.vhd                                                            --
-- Modular Ethernet MAC (MEMAC): 560 bit shift register.                      --
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

package memac_sr560_pkg is
  component memac_sr560 is
    port (
      clk : in    std_ulogic;
      d   : in    std_ulogic;
      q   : out   std_ulogic
    );
  end component;
end package memac_sr560_pkg;

--------------------------------------------------------------------------------

library unisim;
  use unisim.vcomponents.all;

library ieee;
  use ieee.std_logic_1164.all;

entity memac_sr560 is
    port (
      clk : in    std_ulogic;
      d   : in    std_ulogic;
      q   : out   std_ulogic
    );
end entity memac_sr560;

architecture rtl of memac_sr560 is

  signal di : std_ulogic_vector(1 to 17);
  signal qi : std_ulogic_vector(0 to 17);

begin

  qi(0) <= d;
  GEN: for i in 1 to 17 generate
    U_SRL32E: component srl32e
      port map (
        a   => "11111", -- length = 32 bits
        ce  => '1',
        clk => clk,
        d   => di(i),
        q   => qi(i)
      );
    di(i) <= qi(i-1);
  end generate GEN;
  q <= qi(17);

end architecture rtl;
