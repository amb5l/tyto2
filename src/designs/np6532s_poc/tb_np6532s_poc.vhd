--------------------------------------------------------------------------------
-- tb_np6532s_poc.vhd                                                         --
-- Simulation testbench for the np6532s_poc design.                           --
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
use work.np6532s_poc_pkg.all;

entity tb_np6532s_poc is
    generic (
        ram_size_log2 : integer
    );
end entity tb_np6532s_poc;

architecture sim of tb_np6532s_poc is

    signal clk  : std_logic;
    signal rst  : std_logic;
    signal led  : std_logic_vector(7 downto 0);

begin

    -- 50MHz (not critical)
    clk <=
        '1' after 10ns when clk = '0' else
        '0' after 10ns when clk = '1' else
        '0';

    process
    begin
        rst <= '1';
        wait for 20ns;
        rst <= '0';
        wait;
    end process;

    UUT: component np6532s_poc
        generic map (
            ram_size_log2 => ram_size_log2
        )
        port map (
            clk    => clk,
            rst    => rst,
            hold   => '0',
            irq    => '0',
            nmi    => '0',
            dma_ti => (others => '0'),
            dma_to => open,
            led    => led
        );

end architecture sim;
