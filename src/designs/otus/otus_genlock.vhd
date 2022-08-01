--------------------------------------------------------------------------------
-- otus_genlock.vhd                                                           --
-- Genlock generator.                                                         --
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

package otus_genlock_pkg is

    component otus_genlock is
        port (
            clk     : in  std_logic; -- CRTC: clock
            clken   : in  std_logic; -- CRTC: 2MHz clock enable
            rst     : in  std_logic; -- CRTC: reset
            f       : in  std_logic; -- CRTC: field ID
            vs      : in  std_logic; -- CRTC: vertical sync
            hs      : in  std_logic; -- CRTC: horizontal sync
            oe      : in  std_logic; -- CRTC: overscan display enable
            genlock : out std_logic  -- output pulse 
        );
    end component otus_genlock;

end package otus_genlock_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity otus_genlock is
    port (
        clk     : in  std_logic; -- CRTC: clock
        clken   : in  std_logic; -- CRTC: 2MHz clock enable
        rst     : in  std_logic; -- CRTC: reset
        f       : in  std_logic; -- CRTC: field ID
        vs      : in  std_logic; -- CRTC: vertical sync
        hs      : in  std_logic; -- CRTC: horizontal sync
        oe      : in  std_logic; -- CRTC: overscan display enable
        genlock : out std_logic  -- output pulse
    );
end entity otus_genlock;

architecture synth of otus_genlock is

    signal hs_1   : std_logic;
    signal enable : std_logic;
    signal done   : std_logic;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' or vs = '1' then
                hs_1    <= '0';
                enable  <= '0';
                done    <= '0';
                genlock <= '0';
            else
                hs_1 <= hs;
                if oe = '1' then
                    enable <= '1';
                end if;
                if hs = '0' and hs_1 = '1' then -- trailing edge of hsync
                    done <= enable;
                end if;
                genlock <= f and hs and enable and not done; -- start of 1st/odd/upper field
            end if;
        end if;
    end process;

end architecture synth;
