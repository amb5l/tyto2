--------------------------------------------------------------------------------
-- hd6845.vhd                                                                 --
-- Hitachi HD6845 compatible CRTC.                                            --
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
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- hd6845.vhd
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package hd6845_pkg is

    component hd6845 is
        port (

            reg_clk   : in    std_logic;                     -- register clock
            reg_clken : in    std_logic;                     -- register clock enable
            reg_rst   : in    std_logic;                     -- register reset
            reg_cs    : in    std_logic;                     -- register chip select
            reg_we    : in    std_logic;                     -- register write enable
            reg_rs    : in    std_logic;                     -- register select
            reg_dw    : in    std_logic_vector(7 downto 0);  -- register write data
            reg_dr    : out   std_logic_vector(7 downto 0);  -- register read data

            crt_clk   : in    std_logic;                     -- clock        } video (character)
            crt_clken : in    std_logic;                     -- clock enable }  clock
            crt_rst   : in    std_logic;                     -- hard reset
            crt_ma    : out   std_logic_vector(13 downto 0); -- memory address
            crt_ra    : out   std_logic_vector(4 downto 0);  -- raster (scan line) address within character
            crt_vs    : out   std_logic;                     -- vertical sync
            crt_hs    : out   std_logic;                     -- horizontal sync
            crt_de    : out   std_logic;                     -- display enable
            crt_cur   : out   std_logic;                     -- cursor active
            crt_lps   : in    std_logic                      -- light pen strobe

        );
    end component hd6845;

end package hd6845_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hd6845 is
    port (

        reg_clk   : in    std_logic;                     -- register clock
        reg_clken : in    std_logic;                     -- register clock enable
        reg_rst   : in    std_logic;                     -- register reset
        reg_cs    : in    std_logic;                     -- register chip select
        reg_we    : in    std_logic;                     -- register write enable
        reg_rs    : in    std_logic;                     -- register select
        reg_dw    : in    std_logic_vector(7 downto 0);  -- register write data
        reg_dr    : out   std_logic_vector(7 downto 0);  -- register read data

        crt_clk   : in    std_logic;                     -- clock        } video (character)
        crt_clken : in    std_logic;                     -- clock enable }  clock
        crt_rst   : in    std_logic;                     -- hard reset
        crt_ma    : out   std_logic_vector(13 downto 0); -- memory address
        crt_ra    : out   std_logic_vector(4 downto 0);  -- raster (scan line) address within character
        crt_vs    : out   std_logic;                     -- vertical sync
        crt_hs    : out   std_logic;                     -- horizontal sync
        crt_de    : out   std_logic;                     -- display enable
        crt_cur   : out   std_logic;                     -- cursor active
        crt_lps   : in    std_logic                      -- light pen strobe

    );
end entity hd6845;

--------------------------------------------------------------------------------

architecture synth of hd6845 is

    signal crt_lpma   : unsigned(crt_ma'range);                     -- light pen address

    signal a          : unsigned(4 downto 0);                       -- register address
    signal r0         : unsigned(7 downto 0);                       -- register: horizontal total - 1
    signal r1         : unsigned(7 downto 0);                       -- register: horizontal displayed
    signal r2         : unsigned(7 downto 0);                       -- register: h sync position
    signal r3         : unsigned(7 downto 0);                       -- register: sync width
    alias  r3_h       : unsigned(3 downto 0) is r3(3 downto 0);     -- register: sync width (horizontal)
    alias  r3_v       : unsigned(3 downto 0) is r3(7 downto 4);     -- register: sync width (vertical)
    signal r4         : unsigned(6 downto 0);                       -- register: vertical total - 1
    signal r5         : unsigned(4 downto 0);                       -- register: v total adjust
    signal r6         : unsigned(6 downto 0);                       -- register: vertical displayed
    signal r7         : unsigned(6 downto 0);                       -- register: v sync position
    signal r8         : unsigned(1 downto 0);                       -- register: interlace mode and skew
    signal r9         : unsigned(crt_ra'range);                     -- register: max raster (scan line) address
    signal r10        : unsigned(6 downto 0);                       -- register: crt_cur start
    signal r11        : unsigned(4 downto 0);                       -- register: crt_cur end
    signal r12        : unsigned(crt_ma'length-9 downto 0);         -- register: start address high
    signal r13        : unsigned(7 downto 0);                       -- register: start address low
    signal r14        : unsigned(r12'range);                        -- register: cursor position high
    signal r15        : unsigned(7 downto 0);                       -- register: cursor position low
    alias  r16        : unsigned(r12'range) is crt_lpma(r12'range); -- register: light pen address high
    alias  r17        : unsigned(r13'range) is crt_lpma(r13'range); -- register: light pen address low
    signal rd         : unsigned(7 downto 0);                       -- register: register read data

    signal count_h    : unsigned(r0'range);                         -- horizontal position (character columns)
    signal count_hs   : unsigned(r3_h'range);                       -- h sync (character columns)
    signal count_v    : unsigned(r4'range);                         -- vertical (character rows)
    signal count_vs   : unsigned(r3_v'range);                       -- v sync position (character rows)
    signal count_ma   : unsigned(crt_ma'range);                     -- memory address
    signal count_ra   : unsigned(crt_ra'range);                     -- raster (scan line) within character
    signal count_f    : unsigned(4 downto 0);                       -- field counter for crt_cur flash
    signal count_ma_r : unsigned(crt_ma'range);                     -- memory address for row restart
    signal crt_f      : std_logic;                                  -- field: 0 = first/odd/upper, 1 = second/even/lower
    signal crt_vs_i   : std_logic;                                  -- crt_vs, internal
    signal crt_hs_i   : std_logic;                                  -- crt_hs, internal
    signal crt_de_h   : std_logic;                                  -- de horizontal
    signal crt_de_v   : std_logic;                                  -- de vertical

    type crt_vphase_t is (
            NORMAL,
            VADJ,
            INTER
        );
    signal crt_vphase : crt_vphase_t;                               -- vertical phase

    function regpad(n : integer; u : unsigned)
    return std_logic_vector is
        variable r: std_logic_vector(n-1 downto 0);
    begin
        r := (others => '0');
        r(u'length-1 downto 0) := std_logic_vector(u);
        return r;        
    end function regpad;

begin

    crt_vs <= crt_vs_i;
    crt_hs <= crt_hs_i;
    crt_de <= crt_de_v and crt_de_h;

    -- CRT control
    process(crt_clk)
    begin
        if rising_edge(crt_clk) and crt_clken = '1' then

            if crt_rst = '1' then

                count_h    <= (others => '0');
                count_hs   <= (others => '0');
                count_v    <= (others => '0');
                count_vs   <= (others => '0');
                count_ma   <= (others => '0');
                count_ra   <= (others => '0');
                count_f    <= (others => '0');
                count_ma_r <= (others => '0');
                crt_ma     <= (others => '0');
                crt_ra     <= (others => '0');
                crt_f      <= '0';
                crt_vs_i   <= '0';
                crt_hs_i   <= '0';
                crt_de_h   <= '0';
                crt_de_v   <= '1';
                crt_cur    <= '0';
                crt_vphase <= NORMAL;
                crt_lpma   <= (others => '0');

            else

                count_h <= count_h+1;
                count_ma <= count_ma+1;

                if count_h = r0 then -- end of line events
                    count_h <= (others => '0');
                    case crt_vphase is
                        when NORMAL =>
                            if r8(1 downto 0) = "11" then
                                count_ra <= count_ra+2;
                            else
                                count_ra <= count_ra+1;
                            end if;
                            if count_ra = r9 then -- r9+1 scan lines per char
                                count_ma_r <= count_ma_r+r1;
                                count_ma <= count_ma_r+r1;
                                count_ra <= (others => '0');
                                if count_v = r4 then -- all character rows scanned
                                    if r5 /= (r5'range => '0') then
                                        crt_vphase <= VADJ;
                                        count_ma_r <= count_ma_r+r1;
                                        count_ma <= count_ma_r+r1;
                                        count_ra(0) <= '1'; -- count from 1 to r5 during vertical adjust
                                    elsif r8(0) = '1' and crt_f = '0' then
                                        crt_vphase <= INTER;
                                        count_ma_r <= count_ma_r+r1;
                                        count_ma <= count_ma_r+r1;
                                        count_ra <= (others => '0');
                                    else
                                        crt_vphase <= NORMAL;
                                        crt_f <= '0';
                                        crt_de_v <= '1';
                                        count_ma_r <= r12 & r13;
                                        count_ma <= r12 & r13;
                                        count_v <= (others => '0');
                                    end if;
                                else
                                    count_v <= count_v+1;
                                end if;
                            else
                                count_ma <= count_ma_r; -- restart character row
                            end if;
                        when VADJ => -- additional r5 scan lines
                            count_ra <= count_ra+1;
                            if count_ra = r5 then
                                count_ra <= (others => '0');
                                if r8(0) = '1' and crt_f = '0' then
                                    crt_vphase <= INTER;
                                    count_ma_r <= count_ma_r+r1;
                                    count_ma <= count_ma_r+r1;
                                    count_ra <= (others => '0');
                                else
                                    crt_vphase <= NORMAL;
                                    crt_f <= '0';
                                    crt_de_v <= '1';
                                    count_ma_r <= r12 & r13;
                                    count_ma <= r12 & r13;
                                    count_v <= (others => '0');
                                end if;
                            end if;
                        when INTER => -- extra scan line for interlace
                            crt_vphase <= NORMAL;
                            crt_de_v <= '1';
                            crt_f <= '1';
                            count_ma_r <= r12 & r13;
                            count_ma <= r12 & r13;
                            count_ra <= (others => '0');
                            count_v <= (others => '0');
                    end case;
                end if;

                if count_h = 0 then
                    crt_de_h <= '1';
                elsif count_h = r1 then
                    crt_de_h <= '0';
                end if;

                if count_h = 0 then
                    if count_v = 0 then
                        crt_de_v <= '1';
                    elsif count_v = r6 then
                        crt_de_v <= '0';
                    end if;
                end if;

                if crt_hs_i = '0' then
                    if count_h = r2 or crt_hs_i = '1' then
                        count_hs <= (0 => '1', others => '0');
                        crt_hs_i <= '1';
                    end if;
                else
                    if count_hs = r3_h then
                        count_hs <= (others => '0');
                        crt_hs_i <= '0';
                    else
                        count_hs <= count_hs+1;
                    end if;
                end if;

                if ((crt_f = '0' and count_h = shift_right(r0,1)) or (crt_f = '1' and count_h = 0)) then
                    if crt_vs_i = '0' then
                        if count_v = r7 and count_ra = 0 then
                            count_vs <= (0 => '1', others => '0');
                            crt_vs_i <= '1';
                        end if;
                    else
                        if count_ra = r3_v then
                            count_vs <= (others => '0');
                            crt_vs_i <= '0';
                        else
                            count_vs <= count_vs+1;
                        end if;
                    end if;
                end if;

                crt_ma <= std_logic_vector(count_ma);
                crt_ra <= std_logic_vector(count_ra);
                if r8(1 downto 0) = "11" and crt_f = '1' then -- interlaced, 2nd (even) field
                    crt_ra(0) <= '1';
                end if;
                crt_cur <= '0';
                if count_ma = r14 & r15 then
                    crt_cur <= '1';
                end if;

                if crt_lps = '1' then
                    crt_lpma <= count_ma;
                end if;

            end if; -- crt_rst = '1'
        end if; -- rising_edge(crt_clk)
     end process;

    -- register writes
    process(reg_clk)
    begin
        if rising_edge(reg_clk) and reg_clken = '1' then
            if reg_rst = '1' then
                a   <= (others => 'U');
                r0  <= (others => 'U');
                r1  <= (others => 'U');
                r2  <= (others => 'U');
                r3  <= (others => 'U');
                r4  <= (others => 'U');
                r5  <= (others => 'U');
                r6  <= (others => 'U');
                r7  <= (others => 'U');
                r8  <= (others => 'U');
                r9  <= (others => 'U');
                r10 <= (others => 'U');
                r11 <= (others => 'U');
                r12 <= (others => 'U');
                r13 <= (others => 'U');
                r14 <= (others => 'U');
                r15 <= (others => 'U');
                r16 <= (others => 'U');
                r17 <= (others => 'U');
            else
                if reg_cs = '1' and reg_we = '1' and reg_rs = '0' then
                    a <= unsigned(reg_dw(a'range));
                elsif reg_cs = '1' and reg_we = '1' and reg_rs = '1' then
                    case to_integer(unsigned(a)) is
                        when 0  => r0  <= unsigned(reg_dw(r0'range));
                        when 1  => r1  <= unsigned(reg_dw(r1'range));
                        when 2  => r2  <= unsigned(reg_dw(r2'range));
                        when 3  => r3  <= unsigned(reg_dw(r3'range));
                        when 4  => r4  <= unsigned(reg_dw(r4'range));
                        when 5  => r5  <= unsigned(reg_dw(r5'range));
                        when 6  => r6  <= unsigned(reg_dw(r6'range));
                        when 7  => r7  <= unsigned(reg_dw(r7'range));
                        when 8  => r8  <= unsigned(reg_dw(r8'range));
                        when 9  => r9  <= unsigned(reg_dw(r9'range));
                        when 10 => r10 <= unsigned(reg_dw(r10'range));
                        when 11 => r11 <= unsigned(reg_dw(r11'range));
                        when 12 => r12 <= unsigned(reg_dw(r12'range));
                        when 13 => r13 <= unsigned(reg_dw(r13'range));
                        when 14 => r14 <= unsigned(reg_dw(r14'range));
                        when 15 => r15 <= unsigned(reg_dw(r15'range));
                        when others => null;
                    end case;
                end if;
            end if; -- hrst = '1'
        end if; -- rising_edge(clk)
    end process;

    -- register reads
    with to_integer(a) select reg_dr <=
        regpad(reg_dr'length,r14) when 14,
        regpad(reg_dr'length,r15) when 15,
        regpad(reg_dr'length,r16) when 16,
        regpad(reg_dr'length,r17) when 17,
        (others => '0') when others;

end architecture synth;