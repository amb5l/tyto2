--------------------------------------------------------------------------------
-- oddr.vhd                                                                   --
-- Variable width oddr.                                                       --
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

package oddr_pkg is

  component oddr is
    port (
      rst   : in    std_ulogic;
      set   : in    std_ulogic;
      clk   : in    std_ulogic;
      clken : in    std_ulogic;
      d1    : in    std_ulogic_vector;
      d2    : in    std_ulogic_vector;
      q     : out   std_ulogic_vector
    );
  end component oddr;

end package oddr_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity oddr is
  port (
    rst   : in    std_ulogic;
    set   : in    std_ulogic;
    clk   : in    std_ulogic;
    clken : in    std_ulogic;
    d1    : in    std_ulogic_vector;
    d2    : in    std_ulogic_vector;
    q     : out   std_ulogic_vector
  );
end entity oddr;

architecture struct of oddr is
begin

  GEN: for i in 0 to q'length-1 generate
    U_ODDR : component unisim.vcomponents.oddr
      generic map (
        DDR_CLK_EDGE => "SAME_EDGE",
        INIT         => '0',
        SRTYPE       => "ASYNC"
      )
      port map (
        r   => rst,
        s   => set,
        c   => clk,
        ce  => clken,
        d1  => d1(i),
        d2  => d2(i),
        q   => q(i)
      );
  end generate GEN;

end architecture struct;
