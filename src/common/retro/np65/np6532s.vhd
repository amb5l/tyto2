--------------------------------------------------------------------------------
-- np6532s.vhd                                                                --
-- np6532s CPU top level (np65 with 32 bit RAM, 64 bit SDR DMA port)          --
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

package np6532s_pkg is

    component np6532s is
        generic (
            ram_size_log2 : integer;                                   -- 16 = 64kbytes, 17 = 128kbytes...
            vector_init   : std_logic_vector(15 downto 0)              -- initialisation code (typically behind hardware registers)
        );
        port (

            clk      : in  std_logic;                                  -- clock

            hold     : in  std_logic;                                  -- pause CPU (and enable DMA) on this cycle
            rst      : in  std_logic;                                  -- reset
            nmi      : in  std_logic;                                  -- NMI
            irq      : in  std_logic;                                  -- IRQ

            if_al    : out std_logic_vector(15 downto 0);              -- instruction fetch logical address
            if_ap    : in  std_logic_vector(ram_size_log2-1 downto 0); -- instruction fetch physical address
            if_z     : in  std_logic;                                  -- instruction fetch physical address is empty/bad (reads zero)

            ls_al    : out std_logic_vector(15 downto 0);              -- load/store logical address
            ls_ap    : in  std_logic_vector(ram_size_log2-1 downto 0); -- load/store physical address of data
            ls_en    : out std_logic;                                  -- load/store enable
            ls_re    : out std_logic;                                  -- load/store read enable
            ls_we    : out std_logic;                                  -- load/store write enable
            ls_wp    : in  std_logic;                                  -- load/store physical address is write protected
            ls_ext   : in  std_logic;                                  -- load/store physical address is external (e.g. hardware register)
            ls_drx   : in  std_logic_vector(7 downto 0);               -- load/store external (hardware) read data
            ls_dwx   : out std_logic_vector(7 downto 0);               -- load/store external (hardware) write data

            trace_en : out std_logic;                                   -- trace strobe
            trace_pc : out std_logic_vector(15 downto 0);               -- trace register PC
            trace_s  : out std_logic_vector(7 downto 0);                -- trace register S
            trace_p  : out std_logic_vector(7 downto 0);                -- trace register P
            trace_a  : out std_logic_vector(7 downto 0);                -- trace register A
            trace_x  : out std_logic_vector(7 downto 0);                -- trace register X
            trace_y  : out std_logic_vector(7 downto 0);                -- trace register Y

            dma_a    : in  std_logic_vector(ram_size_log2-1 downto 3);  -- DMA address (Qword aligned)
            dma_bwe  : in  std_logic_vector(7 downto 0);                -- DMA byte write enables
            dma_dw   : in  std_logic_vector(63 downto 0);               -- DMA write data
            dma_dr   : out std_logic_vector(63 downto 0)                -- DMA read data

        );
    end component np6532s;

end package np6532s_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.np6532_core_pkg.all;
use work.np6532s_ram_pkg.all;
use work.np6532s_cache_pkg.all;

entity np6532s is
    generic (
        ram_size_log2 : integer;                                   -- 16 = 64kbytes, 17 = 128kbytes...
        vector_init   : std_logic_vector(15 downto 0)              -- initialisation code (typically behind hardware registers)
    );
    port (

        clk      : in  std_logic;                                  -- clock

        hold     : in  std_logic;                                  -- pause CPU (and enable DMA) on this cycle
        rst      : in  std_logic;                                  -- reset
        nmi      : in  std_logic;                                  -- NMI
        irq      : in  std_logic;                                  -- IRQ

        if_al    : out std_logic_vector(15 downto 0);              -- instruction fetch logical address
        if_ap    : in  std_logic_vector(ram_size_log2-1 downto 0); -- instruction fetch physical address
        if_z     : in  std_logic;                                  -- instruction fetch physical address is empty/bad (reads zero)

        ls_al    : out std_logic_vector(15 downto 0);              -- load/store logical address
        ls_ap    : in  std_logic_vector(ram_size_log2-1 downto 0); -- load/store physical address of data
        ls_en    : out std_logic;                                  -- load/store enable
        ls_re    : out std_logic;                                  -- load/store read enable
        ls_we    : out std_logic;                                  -- load/store write enable
        ls_wp    : in  std_logic;                                  -- load/store physical address is write protected
        ls_ext   : in  std_logic;                                  -- load/store physical address is external (e.g. hardware register)
        ls_drx   : in  std_logic_vector(7 downto 0);               -- load/store external (hardware) read data
        ls_dwx   : out std_logic_vector(7 downto 0);               -- load/store external (hardware) write data

        trace_en : out std_logic;                                   -- trace strobe
        trace_pc : out std_logic_vector(15 downto 0);               -- trace register PC
        trace_s  : out std_logic_vector(7 downto 0);                -- trace register S
        trace_p  : out std_logic_vector(7 downto 0);                -- trace register P
        trace_a  : out std_logic_vector(7 downto 0);                -- trace register A
        trace_x  : out std_logic_vector(7 downto 0);                -- trace register X
        trace_y  : out std_logic_vector(7 downto 0);                -- trace register Y

        dma_a    : in  std_logic_vector(ram_size_log2-1 downto 3);  -- DMA address (Qword aligned)
        dma_bwe  : in  std_logic_vector(7 downto 0);                -- DMA byte write enables
        dma_dw   : in  std_logic_vector(63 downto 0);               -- DMA write data
        dma_dr   : out std_logic_vector(63 downto 0)                -- DMA read data

    );
end entity np6532s;

architecture synth of np6532s is

    signal if_en    : std_logic;
    signal if_z_ram : std_logic;
    signal if_brk   : std_logic;
    signal if_d     : std_logic_vector(31 downto 0);
    
    signal ls_a      : std_logic_vector(15 downto 0);
    signal ls_en_cpu : std_logic;
    signal ls_we_cpu : std_logic;
    signal ls_we_ram : std_logic;
    signal ls_sz     : std_logic_vector(1 downto 0);
    signal ls_ext_1  : std_logic;
    signal ls_dr_cpu : std_logic_vector(31 downto 0);
    signal ls_dr_ram : std_logic_vector(31 downto 0);
    signal ls_dw_cpu : std_logic_vector(31 downto 0);

    signal cz_a     : std_logic_vector(7 downto 0);
    signal cz_d     : std_logic_vector(31 downto 0);
    signal cs_a     : std_logic_vector(7 downto 0);
    signal cs_d     : std_logic_vector(31 downto 0);

    constant base_z : std_logic_vector(ram_size_log2-1 downto 0) := (others => '0');
    constant base_s : std_logic_vector(ram_size_log2-1 downto 0) := (8 => '1', others => '0');

    -- Xilinx synthesis attributes
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of CPU     : label is "yes";
    attribute keep_hierarchy of RAM     : label is "yes";
    attribute keep_hierarchy of CACHE_Z : label is "yes";
    attribute keep_hierarchy of CACHE_S : label is "yes";

begin

    ls_al <= ls_a;
    ls_en <= ls_en_cpu;
    ls_we <= ls_we_cpu;
    ls_dr_cpu <= x"000000" & ls_drx when ls_ext_1 = '1' else ls_dr_ram;
    ls_dwx <= ls_dw_cpu(7 downto 0);

    process(clk)
    begin
        if rising_edge(clk) then
            ls_ext_1 <= ls_ext;
        end if;
    end process;

    CPU: component np6532_core
        generic map (
            vector_init => vector_init
        )
        port map (
            clk      => clk,
            rst      => rst,
            hold    => hold,
            nmi      => nmi,
            irq      => irq,
            if_a     => if_al,
            if_en    => if_en,
            if_brk   => if_brk,
            if_d     => if_d,
            ls_a     => ls_a,
            ls_en    => ls_en_cpu,
            ls_re    => ls_re,
            ls_we    => ls_we_cpu,
            ls_sz    => ls_sz,
            ls_dw    => ls_dw_cpu,
            ls_dr    => ls_dr_cpu,
            cz_a     => cz_a,
            cz_d     => cz_d,
            cs_a     => cs_a,
            cs_d     => cs_d,
            trace_en => trace_en,
            trace_pc => trace_pc,
            trace_s  => trace_s,
            trace_p  => trace_p,
            trace_a  => trace_a,
            trace_x  => trace_x,
            trace_y  => trace_y
        );

    if_z_ram <= if_z or if_brk;
    ls_we_ram <= ls_we_cpu and not (ls_ext or ls_wp);

    RAM: component np6532s_ram
        generic map (
            size_log2 => ram_size_log2
        )
        port map (
            clk       => clk,
            if_a      => if_ap,
            if_en     => if_en,
            if_z      => if_z_ram,
            if_d      => if_d,
            ls_a      => ls_ap,
            ls_en     => ls_en_cpu,
            ls_we     => ls_we_ram,
            ls_sz     => ls_sz,
            ls_dw     => ls_dw_cpu,
            ls_dr     => ls_dr_ram,
            dma_en    => hold,
            dma_a     => dma_a,
            dma_bwe   => dma_bwe,
            dma_dw    => dma_dw,
            dma_dr    => dma_dr
        );

    CACHE_Z: component np6532s_cache
        generic map (
            base => base_z
        )
        port map (
            clk      => clk,
            dma_en   => hold,
            dma_a    => dma_a,
            dma_bwe  => dma_bwe,
            dma_dw   => dma_dw,
            ls_a     => ls_a,
            ls_we    => ls_we_cpu,
            ls_sz    => ls_sz,
            ls_dw    => ls_dw_cpu,
            cache_a  => cz_a,
            cache_dr => cz_d
        );

    CACHE_S: component np6532s_cache
        generic map (
            base => base_s
        )
        port map (
            clk      => clk,
            dma_en   => hold,
            dma_a    => dma_a,
            dma_bwe  => dma_bwe,
            dma_dw   => dma_dw,
            ls_a     => ls_a,
            ls_we    => ls_we_cpu,
            ls_sz    => ls_sz,
            ls_dw    => ls_dw_cpu,
            cache_a  => cs_a,
            cache_dr => cs_d
        );

end architecture synth;
