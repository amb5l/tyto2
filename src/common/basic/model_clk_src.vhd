--------------------------------------------------------------------------------
-- model_clk_src.vhd                                                          --
-- Clock synthesiser for simulation, picosecond accurate.                     --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
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

library work;
use work.tyto_types_pkg.all;

package model_clk_src_pkg is

    component model_clk_src is
        generic (
            n : integer; -- numerator   } clock period in uS as a fraction
            d : integer  -- denominator }  e.g. 2/297 => 148.5MHz
        );
        port (
            clk : out std_logic
        );
    end component model_clk_src;

end package model_clk_src_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.tyto_types_pkg.all;

entity model_clk_src is
    generic (
        n : integer; -- numerator   } clock period in uS as a fraction
        d : integer  -- denominator }  e.g. 2/297 => 148.5MHz
    );
    port (
        clk : out std_logic
    );
end entity model_clk_src;

architecture model of model_clk_src is

    signal clk_i : std_logic;

    -- half clock period, rounded down to nearest picosecond
    constant th : time := integer(floor(500000.0 * real(n)/real(d))) * 1 ps;

begin

    process
        variable tm : time;    -- milestone (last time when a whole number of ps had elapsed)
        variable te : time;    -- elapsed time since last milestone
        variable ta : time;    -- fine adjustment time
        variable ic : integer; -- # of half clock periods
        variable re : real;    -- elapsed time in ps for hc half cycles, floating point
    begin
        tm := now;
        ic := 0;
        ta := 0 ps;
        clk_i <= '1';
        loop
            wait for th;
            clk_i <= not clk_i;
            ic := ic+1;
            re := (500000.0*real(ic)*real(n))/real(d);
            te := now-tm;
            if ic = 2*d then -- full alignment every n us / every d cycles
                wait for (n * 1 us)-((d*2*th)+ta);
                tm := now;
                ic := 0;
                ta := 0 ps;
            elsif re-real(te / 1 ps) >= 1.0 then -- fine adjustment
                wait for 1 ps;
                ta := ta + 1 ps;
            end if;
        end loop;
    end process;

    clk <= clk_i;

end architecture model;