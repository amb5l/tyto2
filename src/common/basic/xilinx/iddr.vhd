--------------------------------------------------------------------------------
-- iddr.vhd                                                                   --
-- Variable width IDDR.                                                       --
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

package iddr_pkg is

  component iddr is
    port (
      rst   : in    std_ulogic;
      set   : in    std_ulogic;
      clk   : in    std_ulogic;
      clken : in    std_ulogic;
      d     : in    std_ulogic_vector;
      q1    : out   std_ulogic_vector;
      q2    : out   std_ulogic_vector
    );
  end component iddr;

end package iddr_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity iddr is
  port (
    rst   : in    std_ulogic;
    set   : in    std_ulogic;
    clk   : in    std_ulogic;
    clken : in    std_ulogic;
    d     : in    std_ulogic_vector;
    q1    : out   std_ulogic_vector;
    q2    : out   std_ulogic_vector
  );
end entity iddr;

architecture struct of iddr is
begin

  GEN: for i in 0 to d'length-1 generate
    U_IDDR : component unisim.vcomponents.iddr
      generic map (
        DDR_CLK_EDGE => "SAME_EDGE_PIPELINED",
        INIT_Q1      => '0',
        INIT_Q2      => '0',
        SRTYPE       => "ASYNC"
      )
      port map (
        r   => rst,
        s   => set,
        c   => clk,
        ce  => clken,
        d   => d(i),
        q1  => q1(i),
        q2  => q2(i)
      );
  end generate GEN;

end architecture struct;
