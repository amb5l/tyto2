--------------------------------------------------------------------------------
-- iddr.vhd                                                                   --
-- Wrapper for Xilinx 7 series IDDR.                                          --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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
      rst : in    std_logic;
      clk : in    std_logic;
      ce  : in    std_logic;
      d   : in    std_logic;
      q1  : out   std_logic;
      q2  : out   std_logic
    );
  end component iddr;

end package iddr_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  
library unisim;
  use unisim.vcomponents.iddr;
  
entity iddr is
  port (
    rst : in    std_logic;
    clk : in    std_logic;
    ce  : in    std_logic;
    d   : in    std_logic;
    q1  : out   std_logic;
    q2  : out   std_logic
  );
end entity iddr;

architecture xilinx of iddr is
begin

  REG : unisim.vcomponents.iddr
    generic map (
      ddr_clk_edge => "SAME_EDGE_PIPELINED",
      init_q1      => '0', 
      init_q2      => '0', 
      srtype       => "ASYNC"
    )
    port map (
      r  => rst,
      s  => '0',
      c  => clk,
      ce => '1',
      d  => d,
      q1 => q1,
      q2 => q2,
    );

end architecture xilinx;
