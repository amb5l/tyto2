--------------------------------------------------------------------------------
-- bpp_dmac.vhd                                                               --
-- BPP DMA controller.                                                        --
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

package bpp_dmac_pkg is

    component bpp_dmac is
        generic (
            ram_size_log2 : integer
        );
        port (
            clk_96m           : in  std_logic;
            clk_8m            : in  std_logic;
            rst_96m           : in  std_logic;
            rst_8m            : in  std_logic;
            clken_96m_32m_0   : in  std_logic;
            clken_96m_8m      : in  std_logic;
            clken_8m_2m_0     : in  std_logic;
            clken_8m_2m_270   : in  std_logic;
            crtc_sa           : in  std_logic_vector(1 downto 0);               -- addressable latch: screen start address
            crtc_ma           : in  std_logic_vector(13 downto 0);              -- CRTC:
            crtc_ra           : in  std_logic_vector(4 downto 0);               -- CRTC:
            crtc_d            : out std_logic_vector(7 downto 0);               -- CRTC:
            vidproc_ttx       : in  std_logic;                                  -- VIDPROC:
            dma_en            : out std_logic;                                  -- DMA:
            dma_a             : out std_logic_vector(ram_size_log2-1 downto 3); -- DMA:
            dma_bwe           : out std_logic_vector(7 downto 0);               -- DMA:
            dma_dw            : out std_logic_vector(63 downto 0);              -- DMA:
            dma_dr            : in  std_logic_vector(63 downto 0)               -- DMA:
        );
    end component bpp_dmac;

end package bpp_dmac_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bpp_dmac is
    generic (
        ram_size_log2 : integer
    );
    port (
        clk_96m           : in  std_logic;
        clk_8m            : in  std_logic;
        rst_96m           : in  std_logic;
        rst_8m            : in  std_logic;
        clken_96m_32m_0   : in  std_logic;
        clken_96m_8m      : in  std_logic;
        clken_8m_2m_0     : in  std_logic;
        clken_8m_2m_270   : in  std_logic;
        crtc_sa           : in  std_logic_vector(1 downto 0);               -- addressable latch: screen start address
        crtc_ma           : in  std_logic_vector(13 downto 0);              -- CRTC:
        crtc_ra           : in  std_logic_vector(4 downto 0);               -- CRTC:
        crtc_d            : out std_logic_vector(7 downto 0);               -- CRTC:
        vidproc_ttx       : in  std_logic;                                  -- VIDPROC:
        dma_en            : out std_logic;                                  -- DMA:
        dma_a             : out std_logic_vector(ram_size_log2-1 downto 3); -- DMA:
        dma_bwe           : out std_logic_vector(7 downto 0);               -- DMA:
        dma_dw            : out std_logic_vector(63 downto 0);              -- DMA:
        dma_dr            : in  std_logic_vector(63 downto 0)               -- DMA:
    );
end entity bpp_dmac;

architecture synth of bpp_dmac is

    signal crtc_a     : std_logic_vector(14 downto 0);
    signal dma_en_i   : std_logic;
    signal dma_en_i_1 : std_logic;

begin

    process(clk_8m)
    begin
        if rising_edge(clk_8m) then
            if rst_8m = '1' then
            else
                if clken_8m_2m_270 = '1' then
                    if vidproc_ttx = '1' then
                        crtc_a(9 downto 0) <= crtc_ma(9 downto 0);
                        crtc_a(14 downto 10) <= (others => '1');
                    else
                        crtc_a(2 downto 0) <= crtc_ra(2 downto 0);
                        case crtc_sa is
                            when "00" => -- 16k, starting from 0x4000
                                crtc_a(14) <= '1';
                                crtc_a(13 downto 3) <= crtc_ma(10 downto 0);
                            when "01" => -- 8k, starting from 0x6000
                                crtc_a(14 downto 13) <= "11";
                                crtc_a(12 downto 3) <= crtc_ma(9 downto 0);
                            when "10" => -- 10k, starting from 0x5800
                                crtc_a(14 downto 3) <= std_logic_vector(unsigned(crtc_ma(11 downto 0))+"101100000000");
                            when "11" => -- 20k, starting from 0x3000
                                crtc_a(14 downto 3) <= std_logic_vector(unsigned(crtc_ma(11 downto 0))+"011000000000");
                            when others =>
                                crtc_a(14 downto 3) <= (others => '0');
                        end case;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(clk_96m)
        variable i  : integer range 0 to 7;
    begin
        if rising_edge(clk_96m) then
            dma_en_i_1 <= dma_en_i;
            dma_en_i <= '0';
            dma_a(14 downto 3) <= (others => '0');
            if clken_96m_8m = '1' and clken_8m_2m_0 = '1' then
                dma_en_i <= '1';
                dma_a(14 downto 3) <= crtc_a(14 downto 3);
            end if;
            if dma_en_i = '1' then
                i := to_integer(unsigned(crtc_a(2 downto 0)));
            end if;
            if dma_en_i_1 = '1' then
                crtc_d <= dma_dr(7+(8*i) downto 8*i);
            end if;
        end if;
    end process;

    dma_en <= dma_en_i;
    dma_a(ram_size_log2-1 downto 15) <= (others => '0');
    dma_bwe <= (others => '0');
    dma_dw  <= (others => '0');

end architecture synth;
