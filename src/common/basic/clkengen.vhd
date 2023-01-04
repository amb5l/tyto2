--------------------------------------------------------------------------------
-- clkengen.vhd                                                               --
-- Clock enable generator for clock frequency division.                       --
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

package clkengen_pkg is

  component clkengen is
    generic (
      fclk_width   : integer;
      fclken_width : integer
    );
    port (
      fclk    : in   std_logic_vector(fclk_width-1 downto 0);
      fclken  : in   std_logic_vector(fclken_width-1 downto 0);
      clk     : in   std_logic;
      rst     : in   std_logic;
      clken   : out  std_logic
    );
  end component clkengen;

end package clkengen_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity clkengen is
  generic (
    fclk_width   : integer;
    fclken_width : integer
  );
  port (
    fclk   : in   std_logic_vector(fclk_width-1 downto 0);
    fclken : in   std_logic_vector(fclken_width-1 downto 0);
    clk    : in   std_logic;
    rst    : in   std_logic;
    clken  : out  std_logic
  );
end entity clkengen;

architecture synth of clkengen is

  signal cnt      : unsigned(fclk_width-1 downto 0);

begin

  process(clk)
    variable cnt_next : unsigned(fclk_width-1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt      <= (others => '0');
        clken    <= '0';
      else
        clken <= '0';
        cnt_next := cnt-unsigned(fclken);
        if cnt_next(fclk_width-1) = '1' then
          cnt <= cnt_next+unsigned(fclk);
          clken <= '1';
        else
          cnt <= cnt_next;
        end if;
      end if;
    end if;
  end process;

end architecture synth;
