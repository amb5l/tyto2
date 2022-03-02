--------------------------------------------------------------------------------
-- np6532s_ram.vhd                                                            --
-- RAM for np6532s CPU (32 bit CPU ports, 64 bit SDR DMA port)                --
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

package np6532s_ram_pkg is

    component np6532s_ram is
        generic (
            size_log2   : integer                                           -- 16 = 64kbytes, 17 = 128kbytes...
        );
        port (

            clk         : in  std_logic;                                    -- clock

            if_a        : in  std_logic_vector(size_log2-1 downto 0);       -- instruction fetch address
            if_en       : in  std_logic;                                    -- instruction fetch enable
            if_z        : in  std_logic;                                    -- instruction fetch zero (BRK)
            if_d        : out std_logic_vector(31 downto 0);                -- instruction fetch data

            ls_a        : in  std_logic_vector(size_log2-1 downto 0);       -- load/store address
            ls_en       : in  std_logic;                                    -- load/store enable
            ls_we       : in  std_logic;                                    -- load/store write enable (indicates store)
            ls_sz       : in  std_logic_vector(1 downto 0);                 -- load/store transfer size (bytes) = 1+ls_sz
            ls_dw       : in  std_logic_vector(31 downto 0);                -- store data (writes)
            ls_dr       : out std_logic_vector(31 downto 0);                -- load data (reads)

            dma_en      : in  std_logic;                                    -- DMA enable
            dma_a       : in  std_logic_vector(size_log2-1 downto 3);       -- DMA address (Qword aligned)
            dma_bwe     : in  std_logic_vector(7 downto 0);                 -- DMA byte write enables
            dma_dw      : in  std_logic_vector(63 downto 0);                -- DMA write data
            dma_dr      : out std_logic_vector(63 downto 0)                 -- DMA read data

        );
    end component np6532s_ram;

end package np6532s_ram_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.np6532_ram_init_pkg.all;
use work.ram_tdp_sr_pkg.all;

entity np6532s_ram is
    generic (
        size_log2   : integer                                           -- 16 = 64kbytes, 17 = 128kbytes...
    );
    port (

        clk         : in  std_logic;                                    -- clock

        if_a        : in  std_logic_vector(size_log2-1 downto 0);       -- instruction fetch address
        if_en       : in  std_logic;                                    -- instruction fetch enable
        if_z        : in  std_logic;                                    -- instruction fetch zero (BRK)
        if_d        : out std_logic_vector(31 downto 0);                -- instruction fetch data

        ls_a        : in  std_logic_vector(size_log2-1 downto 0);       -- load/store address
        ls_en       : in  std_logic;                                    -- load/store enable
        ls_we       : in  std_logic;                                    -- load/store write enable (indicates store)
        ls_sz       : in  std_logic_vector(1 downto 0);                 -- load/store transfer size (bytes) = 1+ls_sz
        ls_dw       : in  std_logic_vector(31 downto 0);                -- store data (writes)
        ls_dr       : out std_logic_vector(31 downto 0);                -- load data (reads)

        dma_en      : in  std_logic;                                    -- DMA enable
        dma_a       : in  std_logic_vector(size_log2-1 downto 3);       -- DMA address (Qword aligned)
        dma_bwe     : in  std_logic_vector(7 downto 0);                 -- DMA byte write enables
        dma_dw      : in  std_logic_vector(63 downto 0);                -- DMA write data
        dma_dr      : out std_logic_vector(63 downto 0)                 -- DMA read data

    );
end entity np6532s_ram;

architecture synth of np6532s_ram is

    type ram_addr is array(natural range <>) of std_logic_vector(size_log2-1 downto 2);

    signal ls_bwe           : std_logic_vector(3 downto 0);

    signal ram_rst_a        : std_logic;
    signal ram_ce_a         : std_logic;
    signal ram_we_a         : std_logic_vector(3 downto 0);
    signal ram_addr_a       : ram_addr(3 downto 0);
    signal ram_din_a        : std_logic_vector(31 downto 0);
    signal ram_dout_a       : std_logic_vector(31 downto 0);

    signal ram_rst_b        : std_logic;
    signal ram_ce_b         : std_logic;
    signal ram_we_b         : std_logic_vector(3 downto 0);
    signal ram_addr_b       : ram_addr(3 downto 0);
    signal ram_din_b        : std_logic_vector(31 downto 0);
    signal ram_dout_b       : std_logic_vector(31 downto 0);

    signal if_i             : integer range 0 to 3;
    signal ls_i             : integer range 0 to 3;

begin

    ram_rst_a <= if_z and not dma_en;
    ram_ce_a <= if_en or dma_en;

    ram_rst_b <= '0';
    ram_ce_b <= ls_en or dma_en;

    process(clk)
    begin
        if rising_edge(clk) then
            if ram_ce_a = '1' then
                if_i <= to_integer(unsigned(if_a(1 downto 0)));
            end if;
            if ram_ce_b = '1' then
                ls_i <= to_integer(unsigned(ls_a(1 downto 0)));
            end if;
        end if;
    end process;
    


    GEN_RAM: for i in 0 to 3 generate
        -- Xilinx synthesis attributes        
        attribute keep_hierarchy : string;
        attribute keep_hierarchy of RAM : label is "yes";
    begin

        ls_bwe(i) <= ls_we when i <= to_integer(unsigned(ls_sz)) else '0';

        ram_addr_a(i) <= dma_a & '0' when dma_en = '1' else
            std_logic_vector(1+unsigned(if_a(size_log2-1 downto 2))) when i < to_integer(unsigned(if_a(1 downto 0))) else
            if_a(size_log2-1 downto 2);

        ram_addr_b(i)(size_log2-1 downto 8) <= dma_a(size_log2-1 downto 8) when dma_en = '1' else
            ls_a(size_log2-1 downto 8);

        -- multi byte writes wrap within page (because they are all stack pushes - for now)
        ram_addr_b(i)(7 downto 2) <= dma_a(7 downto 3) & '1' when dma_en = '1' else
            std_logic_vector(1+unsigned(ls_a(7 downto 2))) when i < to_integer(unsigned(ls_a(1 downto 0))) else
            ls_a(7 downto 2);

        ram_we_a(i) <= dma_bwe(i) when dma_en = '1' else '0';

        ram_we_b(i) <= dma_bwe(4+i) when dma_en = '1' else ls_bwe((i+(4-to_integer(unsigned(ls_a(1 downto 0))))) mod 4);

        ram_din_a(7+(8*i) downto 8*i) <= dma_dw(7+(8*i) downto 8*i);

        ram_din_b(7+(8*i) downto 8*i) <= dma_dw(7+(8*(4+i)) downto 8*(4+i)) when dma_en = '1' else
            ls_dw(7+(8*((i+1) mod 4)) downto 8*((i+1) mod 4)) when ls_a(1 downto 0) = "11" else
            ls_dw(7+(8*((i+2) mod 4)) downto 8*((i+2) mod 4)) when ls_a(1 downto 0) = "10" else
            ls_dw(7+(8*((i+3) mod 4)) downto 8*((i+3) mod 4)) when ls_a(1 downto 0) = "01" else
            ls_dw(7+(8*((i+0) mod 4)) downto 8*((i+0) mod 4));

        RAM: component ram_tdp_sr
            generic map (
                width      => 8,
                depth_log2 => size_log2-2,
                init       => ram_init(i)
            )
            port map (
                clk     => clk,
                rst_a   => ram_rst_a,
                ce_a    => ram_ce_a,
                we_a    => ram_we_a(i),
                addr_a  => ram_addr_a(i),
                din_a   => ram_din_a(7+(8*i) downto 8*i),
                dout_a  => ram_dout_a(7+(8*i) downto 8*i),
                rst_b   => ram_rst_b,
                ce_b    => ram_ce_b,
                we_b    => ram_we_b(i),
                addr_b  => ram_addr_b(i),
                din_b   => ram_din_b(7+(8*i) downto 8*i),
                dout_b  => ram_dout_b(7+(8*i) downto 8*i)
            );

        if_d(7+(8*i) downto 8*i) <= ram_dout_a(7+(8*((i+if_i) mod 4)) downto 8*((i+if_i) mod 4));
        ls_dr(7+(8*i) downto 8*i) <= ram_dout_b(7+(8*((i+ls_i) mod 4)) downto 8*((i+ls_i) mod 4));
        dma_dr(7+(8*i) downto 8*i) <= ram_dout_a(7+(8*i) downto 8*i);
        dma_dr(7+(8*(4+i)) downto 8*(4+i)) <= ram_dout_b(7+(8*i) downto 8*i);

    end generate gen_ram;

end architecture synth;
