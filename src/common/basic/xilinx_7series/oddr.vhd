--------------------------------------------------------------------------------
-- oddr.vhd                                                                   --
-- Wrapper for Xilinx 7 series ODDR.                                          --
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

package oddr_pkg is

  component oddr is
    port (
      rst : in    std_logic;
      clk : in    std_logic;
      ce  : in    std_logic;
      d1  : in    std_logic;
      d2  : in    std_logic;
      q   : out   std_logic
    );
  end component oddr;

end package oddr_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  
library unisim;
  use unisim.vcomponents.oddr;
  
entity oddr is
  port (
    rst : in    std_logic;
    clk : in    std_logic;
    ce  : in    std_logic;
    d1  : in    std_logic;
    d2  : in    std_logic;
    q   : out   std_logic
  );
end entity oddr;

architecture xilinx_7series of oddr is
begin

  REG : unisim.vcomponents.oddr
    generic map(
      ddr_clk_edge => "SAME_EDGE",
      init         => '0',
      srtype       => "ASYNC"
    )
    port map (
      r  => rst,
      s  => '0'
      c  => clk,
      ce => ce,
      d1 => d1,
      d2 => d2,
      q  => q,
    );

end architecture xilinx_7series;
