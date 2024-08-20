--------------------------------------------------------------------------------
-- iddr.vhd                                                                   --
-- Xilinx LUT3 based 2 input multiplexer.                                     --
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

package mux2_pkg is

  component mux2 is
    port (
      s  : in    std_ulogic;
      i0 : in    std_ulogic_vector;
      i1 : in    std_ulogic_vector;
      o  : out   std_ulogic_vector
    );
  end component mux2;

end package mux2_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity mux2 is
  port (
    s  : in    std_ulogic;
    i0 : in    std_ulogic_vector;
    i1 : in    std_ulogic_vector;
    o  : out   std_ulogic_vector
  );
end entity mux2;

architecture rtl of mux2 is
begin

  GEN: for i in o'low to o'high generate
    U_LUT3: component lut3
      generic map (
        INIT => "11001010"
      )
      port map (
        i0 => i0(i),
        i1 => i1(i),
        i2 => s,
        o  => o(i)
      );
  end generate GEN;

end architecture rtl;
