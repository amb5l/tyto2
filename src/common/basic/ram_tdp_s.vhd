--------------------------------------------------------------------------------
-- ram_tdp_s.vhd                                                              --
-- True dual port RAM, single clock.                                          --
-- Infers block RAM correctly in Vivado and Quartus.                          --
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

package ram_tdp_s_pkg is

    component ram_tdp_s is
        generic (
            width      : integer;
            depth_log2 : integer;
            init       : slv_7_0
        );
        port (
            clk     : in    std_logic;
            ce_a    : in    std_logic;
            we_a    : in    std_logic;
            addr_a  : in    std_logic_vector(depth_log2-1 downto 0);
            din_a   : in    std_logic_vector(width-1 downto 0);
            dout_a  : out   std_logic_vector(width-1 downto 0);
            ce_b    : in    std_logic;
            we_b    : in    std_logic;
            addr_b  : in    std_logic_vector(depth_log2-1 downto 0);
            din_b   : in    std_logic_vector(width-1 downto 0);
            dout_b  : out   std_logic_vector(width-1 downto 0)
        );
    end component ram_tdp_s;

end package ram_tdp_s_pkg;

--------------------------------------------------------------------------------
  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tyto_types_pkg.all;

entity ram_tdp_s is
    generic (
        width      : integer;
        depth_log2 : integer;
        init       : slv_7_0
    );
    port (
        clk     : in    std_logic;
        ce_a    : in    std_logic;
        we_a    : in    std_logic;
        addr_a  : in    std_logic_vector(depth_log2-1 downto 0);
        din_a   : in    std_logic_vector(width-1 downto 0);
        dout_a  : out   std_logic_vector(width-1 downto 0);
        ce_b    : in    std_logic;
        we_b    : in    std_logic;
        addr_b  : in    std_logic_vector(depth_log2-1 downto 0);
        din_b   : in    std_logic_vector(width-1 downto 0);
        dout_b  : out   std_logic_vector(width-1 downto 0)
    );
end entity ram_tdp_s;

architecture inferred of ram_tdp_s is

	shared variable ram : slv_7_0(0 to (2**depth_log2)-1) := init;

begin

	process(clk)
    begin
        if rising_edge(clk) and ce_a = '1' then
            if(we_a = '1') then
                ram(to_integer(unsigned(addr_a))) := din_a;
            end if;
            dout_a <= ram(to_integer(unsigned(addr_a)));
        end if;
	end process;

	process(clk)
    begin
        if rising_edge(clk) and ce_b = '1' then
            if(we_b = '1') then
                ram(to_integer(unsigned(addr_b))) := din_b;
            end if;
            dout_b <= ram(to_integer(unsigned(addr_b)));
        end if;
	end process;

end architecture inferred;
