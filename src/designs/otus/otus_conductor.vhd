--------------------------------------------------------------------------------
-- otus_conductor.vhd                                                         --
-- Overall timing control (reset and clock enables).                          --
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

package otus_conductor_pkg is

    component otus_conductor is
        port (

            clk_lock         : in  std_logic; -- } from clock generator
            clk_96m          : in  std_logic; -- }
            clk_48m          : in  std_logic; -- }
            clk_32m          : in  std_logic; -- }
            clk_8m           : in  std_logic; -- }

            rst_96m          : out std_logic; -- } timed carefully
            rst_48m          : out std_logic; -- } so all clock domains
            rst_32m          : out std_logic; -- } start together
            rst_8m           : out std_logic; -- }

            clken_96m_8m     : out std_logic;
            clken_48m_16m    : out std_logic;
            clken_48m_12m    : out std_logic;
            clken_48m_8m     : out std_logic;
            clken_8m_4m      : out std_logic;
            clken_8m_2m_0    : out std_logic;
            clken_8m_2m_180  : out std_logic;
            clken_8m_2m_270  : out std_logic;
            clken_8m_1m_0    : out std_logic;
            clken_8m_1m_90   : out std_logic

        );
    end component otus_conductor;

end package otus_conductor_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tyto_utils_pkg.all;

entity otus_conductor is
    port (

        clk_lock         : in  std_logic; -- } from clock generator
        clk_96m          : in  std_logic; -- }
        clk_48m          : in  std_logic; -- }
        clk_32m          : in  std_logic; -- }
        clk_8m           : in  std_logic; -- }

        rst_96m          : out std_logic; -- } timed carefully
        rst_48m          : out std_logic; -- } so all clock domains
        rst_32m          : out std_logic; -- } start together
        rst_8m           : out std_logic; -- }

        clken_96m_8m     : out std_logic;
        clken_48m_16m    : out std_logic;
        clken_48m_12m    : out std_logic;
        clken_48m_8m     : out std_logic;
        clken_8m_4m      : out std_logic;
        clken_8m_2m_0    : out std_logic;
        clken_8m_2m_180  : out std_logic;
        clken_8m_2m_270  : out std_logic;
        clken_8m_1m_0    : out std_logic;
        clken_8m_1m_90   : out std_logic

    );
end entity otus_conductor;

architecture synth of otus_conductor is

    signal clk_lock_s_8m      : std_logic_vector(0 to 1) := (others => '0');
    signal nrst               : std_logic := '0';

    signal ph_96m_8m          : integer range 0 to 11; -- phase of 96MHz clock w.r.t. 8MHz clock
    signal ph_48m_16m         : integer range 0 to 2;  -- phase of 48MHz clock w.r.t. 16MHz
    signal ph_48m_12m         : integer range 0 to 3;  -- phase of 48MHz clock w.r.t. 12MHz
    signal ph_48m_8m          : integer range 0 to 5;  -- phase of 48MHz clock w.r.t. 8MHz clock
    signal ph_32m_8m          : integer range 0 to 3;  -- phase of 32MHz clock w.r.t. 8MHz clock
    signal ph_8m_1m           : integer range 0 to 7;  -- phase of 8MHz clock w.r.t. 1MHz

    signal nrst_96m_e         : std_logic := '0'; -- } 1 clock early followed by register
    signal nrst_48m_e         : std_logic := '0'; -- }  facilitates register duplication
    signal nrst_32m_e         : std_logic := '0'; -- }   on these high fanout signals
    signal nrst_8m_e          : std_logic := '0'; -- }
    signal clken_96m_8m_e     : std_logic := '0'; -- }
    signal clken_48m_16m_e    : std_logic := '0'; -- }
    signal clken_48m_12m_e    : std_logic := '0'; -- }
    signal clken_48m_8m_e     : std_logic := '0'; -- }
    signal clken_48m_1m_0_e   : std_logic := '0'; -- }
    signal clken_8m_4m_e      : std_logic := '0'; -- }
    signal clken_8m_2m_0_e    : std_logic := '0'; -- }
    signal clken_8m_2m_180_e  : std_logic := '0'; -- }
    signal clken_8m_2m_270_e  : std_logic := '0'; -- }
    signal clken_8m_1m_0_e    : std_logic := '0'; -- }
    signal clken_8m_1m_90_e   : std_logic := '0'; -- }

begin

    process(clk_lock,clk_8m)
    begin
        if clk_lock = '0' then
            clk_lock_s_8m(0) <= '0';
            clk_lock_s_8m(1) <= '0';
        elsif rising_edge(clk_8m) then
            clk_lock_s_8m(0) <= clk_lock;
            clk_lock_s_8m(1) <= clk_lock_s_8m(0);
        end if;
        if rising_edge(clk_8m) then
            nrst <= clk_lock_s_8m(1);
        end if;
    end process;

    process(clk_96m)
    begin
        if rising_edge(clk_96m) then
            if nrst = '0' then
                ph_96m_8m <= 0;
                nrst_96m_e <= '0';
                clken_96m_8m <= '0';
            else
                ph_96m_8m <= (ph_96m_8m+1) mod 12;
                if ph_8m_1m = 7 and ph_96m_8m = 9 then
                    nrst_96m_e <= '1';
                end if;
                clken_96m_8m_e <= bool2sl(ph_96m_8m = 9);
            end if;
            rst_96m <= not nrst_96m_e;
            clken_96m_8m <= clken_96m_8m_e;
        end if;
    end process;

    process(clk_48m)
    begin
        if rising_edge(clk_48m) then
            if nrst = '0' then
                ph_48m_16m <= 0;
                ph_48m_12m <= 2;
                ph_48m_8m <= 0;
                nrst_48m_e <= '0';
                clken_48m_16m_e <= '0';
                clken_48m_12m_e <= '0';
                clken_48m_8m_e <= '0';
            else
                ph_48m_16m <= (ph_48m_16m+1) mod 3;
                ph_48m_12m <= (ph_48m_12m+1) mod 4;
                ph_48m_8m <= (ph_48m_8m+1) mod 6;
                if ph_8m_1m = 7 and ph_48m_8m = 3 then
                    nrst_48m_e <= '1';
                end if;
                clken_48m_16m_e <= bool2sl(ph_48m_16m = 0);
                clken_48m_12m_e <= bool2sl(ph_48m_12m = 1);
                clken_48m_8m_e  <= bool2sl(ph_48m_8m = 3);
            end if;
            rst_48m <= not nrst_48m_e;
            clken_48m_16m <= clken_48m_16m_e;
            clken_48m_12m <= clken_48m_12m_e;
            clken_48m_8m  <= clken_48m_8m_e;
        end if;
    end process;

    process(clk_32m)
    begin
        if rising_edge(clk_32m) then
            if nrst = '0' then
                ph_32m_8m <= 0;
                nrst_32m_e <= '0';
            else
                ph_32m_8m <= (ph_32m_8m+1) mod 4;
                if ph_8m_1m = 7 and ph_32m_8m = 1 then
                    nrst_32m_e <= '1';
                end if;
            end if;
            rst_32m <= not nrst_32m_e;
        end if;
    end process;

    process(clk_8m)
    begin
        if rising_edge(clk_8m) then
            if nrst = '0' then
                ph_8m_1m <= 5;
                nrst_8m_e <= '0';
                clken_8m_4m_e <= '0';
                clken_8m_2m_0_e <= '0';
                clken_8m_2m_180_e <= '0';
                clken_8m_2m_270_e <= '0';
                clken_8m_1m_0_e <= '0';
                clken_8m_1m_90_e <= '0';
            else
                ph_8m_1m <= (ph_8m_1m+1) mod 8;
                nrst_8m_e <= '1';
                clken_8m_4m_e <= bool2sl(ph_8m_1m mod 2 = 1);
                clken_8m_2m_0_e <= bool2sl(ph_8m_1m mod 4 = 1);
                clken_8m_2m_180_e <= bool2sl(ph_8m_1m mod 4 = 3);
                clken_8m_2m_270_e <= bool2sl(ph_8m_1m mod 4 = 0);
                clken_8m_1m_0_e <= bool2sl(ph_8m_1m = 5);
                clken_8m_1m_90_e <= bool2sl(ph_8m_1m = 7);
            end if;
            rst_8m <= not nrst_8m_e;
            clken_8m_4m <= clken_8m_4m_e;
            clken_8m_2m_0 <= clken_8m_2m_0_e;
            clken_8m_2m_180 <= clken_8m_2m_180_e;
            clken_8m_2m_270 <= clken_8m_2m_270_e;
            clken_8m_1m_0 <= clken_8m_1m_0_e;
            clken_8m_1m_90 <= clken_8m_1m_90_e;
        end if;
    end process;

end architecture synth;
