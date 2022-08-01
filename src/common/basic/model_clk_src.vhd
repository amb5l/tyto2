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
            pn : integer;    -- numerator   } clock period in uS as a fraction
            pd : integer;    -- denominator }  e.g. 2/297 => 148.5MHz
            dc : real := 0.5 -- duty cycle
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
        pn : integer;    -- numerator   } clock period in uS as a fraction
        pd : integer;    -- denominator }  e.g. 2/297 => 148.5MHz
        dc : real := 0.5 -- duty cycle
    );
    port (
        clk : out std_logic
    );
end entity model_clk_src;

architecture model of model_clk_src is

    signal clk_i : std_logic;

    -- mark and space periods
    constant tp : time := integer(floor(1000000.0*real(pn)/real(pd))) * 1 ps;    
    constant t1 : time := integer(floor(dc*1000000.0*real(pn)/real(pd))) * 1 ps;
    constant t2 : time := tp-t1;

begin

    process
        variable tm : time;    -- milestone (last time when a whole number of ps had elapsed)
        variable te : time;    -- elapsed time since last milestone
        variable ta : time;    -- fine adjustment time
        variable ic : integer; -- # of clock periods
        variable re : real;    -- elapsed time in ps for hc half cycles, floating point
    begin
        tm := now;
        ic := 0;
        ta := 0 ps;
        clk_i <= '1';
        loop
            wait for t1;
            clk_i <= '0';
            wait for t2;
            clk_i <= '1';
            ic := ic+1;
            re := (1000000.0*real(ic)*real(pn))/real(pd);
            te := now-tm;
            if ic = pd then -- full alignment every d cycles (every pn us)
                wait for (pn * 1 us)-((pd*tp)+ta);
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