--------------------------------------------------------------------------------
-- ps2.vhd                                                                    --
-- Simple PS/2 host interface.                                                --
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
use work.tyto_utils_pkg.all;

entity ps2 is
    port (
        rst   : in  std_logic;                    -- reset (asynchronous)
        sclk  : in  std_logic;                    -- PS/2 clock
        sdata : in  std_logic;                    -- PS/2 data
        pdata : out std_logic_vector(7 downto 0); -- parallel data
        stb   : out std_logic;                    -- parallel data strobe
        ack   : in  std_logic                     -- parallel data acknowledge
    );
end entity ps2;

architecture synth of ps2 is

    signal sr     : std_logic_vector(9 downto 0);
    signal count  : integer range 0 to 10;
    signal locked : boolean;
    signal parity : std_logic;

begin

    process(rst,sclk,ack)
    begin
        if rst = '1' then
            sr <= (others => '0');
            count <= 0;
            locked <= true;
            stb <= '0';
        elsif rising_edge(sclk) then
            sr(9 downto 0) <= sdata & sr(9 downto 1);
            if locked then
                count <= (count+1) mod 11;
            end if;
            if (locked and count = 9) or not locked then
                pdata <= sr(9 downto 2);
            end if;
            if (locked and count = 10) or not locked then
                if sr(0) = '0' and sr(9) = parity and sdata = '1' then
                    sr <= (others => '0');
                    locked <= true;
                    stb <= '1';
                else
                    locked <= false;
                end if;
            end if;
        end if;
        if ack = '1' then
            stb <= '0';
        end if;
    end process;

    parity <= sr(1) xor sr(2) xor sr(3) xor sr(4) xor sr(5) xor sr(6) xor sr(7) xor sr(8);

end architecture synth;
