--------------------------------------------------------------------------------
-- np6532_cache.vhd                                                           --
-- 256 byte cache for np6532 CPU (32 bit CPU read port, 64 bit MDR DMA port)  --
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

package np6532_cache_pkg is

    component np6532_cache is
        generic (            
            base     : std_logic_vector                           -- base address (also indicates total RAM size)
        );
        port (
            clk_mem   : in  std_logic;                            -- clock (memory, may be multiple of CPU)
            clken_0   : in  std_logic;                            -- clock enable (for CPU clock edges)
            hold      : in  std_logic;                            -- pause execution on this cycle (and enable DMA)
            dma_a     : in  std_logic_vector(base'high downto 3);
            dma_bwe   : in  std_logic_vector(7 downto 0);
            dma_dw    : in  std_logic_vector(63 downto 0);
            ls_a      : in  std_logic_vector(15 downto 0);
            ls_we     : in  std_logic;
            ls_sz     : in  std_logic_vector(1 downto 0);
            ls_dw     : in  std_logic_vector(31 downto 0);
            cache_a   : in  std_logic_vector(7 downto 0);
            cache_dr  : out std_logic_vector(31 downto 0)
        );
    end component np6532_cache;

end package np6532_cache_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tyto_types_pkg.all;
use work.ram_sdp_a_32_pkg.all;

entity np6532_cache is
    generic (            
        base     : std_logic_vector                           -- base address (also indicates total RAM size)
    );
    port (
        clk_mem   : in  std_logic;                            -- clock (memory, may be multiple of CPU)
        clken_0   : in  std_logic;                            -- clock enable (for CPU clock edges)
        hold      : in  std_logic;                            -- pause execution on this cycle (and enable DMA)
        dma_a     : in  std_logic_vector(base'high downto 3);
        dma_bwe   : in  std_logic_vector(7 downto 0);
        dma_dw    : in  std_logic_vector(63 downto 0);
        ls_a      : in  std_logic_vector(15 downto 0);
        ls_we     : in  std_logic;
        ls_sz     : in  std_logic_vector(1 downto 0);
        ls_dw     : in  std_logic_vector(31 downto 0);
        cache_a   : in  std_logic_vector(7 downto 0);
        cache_dr  : out std_logic_vector(31 downto 0)
    );
end entity np6532_cache;

architecture synth of np6532_cache is

    signal dma_dw_v   : slv_7_0(7 downto 0);          -- DMA write data as array of bytes
    signal ls_dw_v    : slv_7_0(3 downto 0);          -- CPU write data as array of bytes
    signal cache_dr_v : slv_7_0(3 downto 0);          -- cache read data as array of bytes
    signal ls_bwe     : std_logic_vector(7 downto 0); -- CPU byte write enables (across 8 byte banks here)
    signal ce         : std_logic;                    -- chip select
    signal we         : std_logic_vector(7 downto 0); -- RAM byte bank write enable
    signal wa         : slv_7_3(7 downto 0);          -- RAM byte bank write address
    signal dw         : slv_7_0(7 downto 0);          -- RAM byte bank write data
    signal ra         : slv_7_2(3 downto 0);          -- read address, per byte bank (of 4)
    signal rd         : slv_7_0(7 downto 0);          -- raw 64 bit read data

begin

    ls_bwe(7 downto 4) <= "0000";

    ce <= '1' when
        (hold = '0' and clken_0 = '1' and ls_a(15 downto 8) = base(15 downto 8)) or
        (hold = '1' and dma_a(base'high downto 8) = base(base'high downto 8))
        else '0';

    GEN_BYTE: for i in 0 to 3 generate
        ls_dw_v(i) <= ls_dw(7+(8*i) downto 8*i);
        cache_dr(7+(8*i) downto 8*i) <= cache_dr_v(i);
        ls_bwe(i) <= ls_we when i <= to_integer(unsigned(ls_sz)) else '0';
        ra(i) <= std_logic_vector(unsigned(cache_a(7 downto 2))+1) when i < to_integer(unsigned(cache_a(1 downto 0))) else cache_a(7 downto 2);
        GEN_DWORD: for j in 0 to 1 generate
            -- Xilinx synthesis attributes
            attribute keep_hierarchy : string;
            attribute keep_hierarchy of RAM : label is "yes";        
        begin
            dma_dw_v(i+(4*j)) <= dma_dw(7+(8*(i+(4*j))) downto 8*(i+(4*j)));
            wa(i+(4*j)) <= dma_a(7 downto 3) when hold = '1' else
                std_logic_vector(unsigned(ls_a(7 downto 3))+1) when i+(4*j) < to_integer(unsigned(ls_a(2 downto 0))) else
                ls_a(7 downto 3);
            we(i+(4*j)) <= dma_bwe(i+(4*j)) when hold = '1' else
                ls_bwe(((i+(4*j))+(8-to_integer(unsigned(ls_a(2 downto 0))))) mod 8);
            dw(i+(4*j)) <= dma_dw_v(i+(4*j)) when hold = '1' else
                ls_dw_v((i+(4-to_integer(unsigned(ls_a(1 downto 0))))) mod 4);
            RAM : component ram_sdp_a_32
                generic map (
                    width => 8
                )
                port map (
                    clk => clk_mem,
                    ce  => ce,
                    we  => we(i+(4*j)),
                    wa  => wa(i+(4*j)),
                    wd  => dw(i+(4*j)),
                    ra  => ra(i)(7 downto 3),
                    rd  => rd(i+(4*j))
                );
        end generate GEN_DWORD;
    end generate GEN_BYTE;

    GEN_DR: for i in 0 to 3 generate
        cache_dr_v(i) <= rd((i+to_integer(unsigned(cache_a(2 downto 0)))) mod 8);
    end generate GEN_DR;

end architecture synth;