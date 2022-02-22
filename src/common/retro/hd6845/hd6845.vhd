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

            clk     : in    std_logic;                      -- clock        } character
            clken   : in    std_logic;                      -- clock enable }  clock
            hrst    : in    std_logic;                      -- hard reset
            srst    : in    std_logic;                      -- soft reset (useful for simulation)

            cs      : in    std_logic;                      -- chip select
            we      : in    std_logic;                      -- register write enable
            rs      : in    std_logic;                      -- register select
            wdata   : in    std_logic_vector(7 downto 0);   -- register write data
            rdata   : out   std_logic_vector(7 downto 0);   -- register read data

            ma      : out   std_logic_vector(13 downto 0);  -- memory address
            ra      : out   std_logic_vector(4 downto 0);   -- raster (scan line) address within character

            vs      : out   std_logic;                      -- vertical sync
            hs      : out   std_logic;                      -- horizontal sync
            de      : out   std_logic;                      -- display enable
            cursor  : out   std_logic;                      -- cursor active

            lpstb   : in    std_logic                       -- light pen strobe

        );
    end component hd6845;

end package hd6845_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hd6845 is
    port (

        clk     : in    std_logic;                      -- clock        } character
        clken   : in    std_logic;                      -- clock enable }  clock
        hrst    : in    std_logic;                      -- synchronous reset
        srst    : in    std_logic;                      -- soft reset (useful for simulation)

        cs      : in    std_logic;                      -- chip select
        we      : in    std_logic;                      -- register write enable
        rs      : in    std_logic;                      -- register select
        wdata   : in    std_logic_vector(7 downto 0);   -- register write data
        rdata   : out   std_logic_vector(7 downto 0);   -- register read data

        ma      : out   std_logic_vector(13 downto 0);  -- memory address
        ra      : out   std_logic_vector(4 downto 0);   -- raster (scan line) address within character

        vs      : out   std_logic;                      -- vertical sync
        hs      : out   std_logic;                      -- horizontal sync
        de      : out   std_logic;                      -- display enable
        cursor  : out   std_logic;                      -- cursor active

        lpstb   : in    std_logic                       -- light pen strobe

    );
end entity hd6845;

--------------------------------------------------------------------------------

architecture synth of hd6845 is

    signal a                : unsigned(4 downto 0);             -- address register
    signal r0               : unsigned(7 downto 0);             -- horizontal total - 1
    signal r1               : unsigned(7 downto 0);             -- horizontal displayed
    signal r2               : unsigned(7 downto 0);             -- h sync position
    signal r3               : unsigned(7 downto 0);             -- sync width
    signal r4               : unsigned(6 downto 0);             -- vertical total - 1
    signal r5               : unsigned(4 downto 0);             -- v total adjust
    signal r6               : unsigned(6 downto 0);             -- vertical displayed
    signal r7               : unsigned(6 downto 0);             -- v sync position
    signal r8               : unsigned(1 downto 0);             -- interlace mode and skew
    signal r9               : unsigned(ra'range);               -- max raster (scan line) address
    signal r10              : unsigned(6 downto 0);             -- cursor start
    signal r11              : unsigned(4 downto 0);             -- cursor end
    signal r12              : unsigned(ma'length-9 downto 0);   -- start address H
    signal r13              : unsigned(7 downto 0);             -- start address L
    signal r14              : unsigned(r12'range);              -- cursor H
    signal r15              : unsigned(7 downto 0);             -- cursor L
    signal r16              : unsigned(r12'range);              -- light pen H
    signal r17              : unsigned(7 downto 0);             -- light pen L
    signal rd               : unsigned(7 downto 0);             -- register read data

    alias r3_h : unsigned(3 downto 0) is r3(3 downto 0);
    alias r3_v : unsigned(3 downto 0) is r3(7 downto 4);

    signal count_h          : unsigned(r0'range);               -- horizontal position (character columns)
    signal count_hs         : unsigned(r3_h'range);             -- h sync (character columns)
    signal count_v          : unsigned(r4'range);               -- vertical (character rows)
    signal count_vs         : unsigned(r3_v'range);             -- v sync position (character rows)
    signal count_ma         : unsigned(ma'range);               -- memory address
    signal count_ra         : unsigned(ra'range);               -- raster (scan line) within character
    signal count_f          : unsigned(4 downto 0);             -- field counter for cursor flash
    signal count_ma_r       : unsigned(ma'range);               -- memory address for row restart
    signal f                : std_logic;                        -- field: 0 = first/odd/upper, 1 = second/even/lower
    signal vs_i             : std_logic;                        
    signal hs_i             : std_logic;                        
    signal de_h             : std_logic;                        -- de horizontal
    signal de_v             : std_logic;                        -- de vertical

    type vphase_t is (
            NORMAL,
            VADJ,
            INTER
        );
    signal vphase       : vphase_t;

begin

    vs <= vs_i;
    hs <= hs_i;
    de <= de_v and de_h;

    process(hrst, srst, clk)
    begin
        if rising_edge(clk) then

            if hrst = '1' or srst = '1' then

                count_h     <= (others => '0');
                count_hs    <= (others => '0');
                count_v     <= (others => '0');
                count_vs    <= (others => '0');
                count_ma    <= (others => '0');
                count_ra    <= (others => '0');
                count_f     <= (others => '0');
                count_ma_r  <= (others => '0');
                ma          <= (others => '0');
                ra          <= (others => '0');
                f           <= '0';
                vs_i        <= '0';
                hs_i        <= '0';
                de_h        <= '0';
                de_v        <= '1';
                cursor      <= '0';
                vphase      <= NORMAL;

            elsif clken = '1' then

                count_h <= count_h+1;
                count_ma <= count_ma+1;

                if count_h = r0 then -- end of line events
                    count_h <= (others => '0');
                    case vphase is
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
                                        vphase <= VADJ;
                                        count_ma_r <= count_ma_r+r1;
                                        count_ma <= count_ma_r+r1;
                                        count_ra(0) <= '1'; -- count from 1 to r5 during vertical adjust
                                    elsif r8(0) = '1' and f = '0' then
                                        vphase <= INTER;
                                        count_ma_r <= count_ma_r+r1;
                                        count_ma <= count_ma_r+r1;
                                        count_ra <= (others => '0');
                                    else
                                        vphase <= NORMAL;
                                        f <= '0';
                                        de_v <= '1';
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
                                if r8(0) = '1' and f = '0' then
                                    vphase <= INTER;
                                    count_ma_r <= count_ma_r+r1;
                                    count_ma <= count_ma_r+r1;
                                    count_ra <= (others => '0');
                                else
                                    vphase <= NORMAL;
                                    f <= '0';
                                    de_v <= '1';
                                    count_ma_r <= r12 & r13;
                                    count_ma <= r12 & r13;
                                    count_v <= (others => '0');
                                end if;
                            end if;
                        when INTER => -- extra scan line for interlace
                            vphase <= NORMAL;
                            de_v <= '1';
                            f <= '1';
                            count_ma_r <= r12 & r13;
                            count_ma <= r12 & r13;
                            count_ra <= (others => '0');
                            count_v <= (others => '0');
                    end case;
                end if;

                if count_h = 0 then
                    de_h <= '1';
                elsif count_h = r1 then
                    de_h <= '0';
                end if;

                if count_h = 0 then
                    if count_v = 0 then
                        de_v <= '1';
                    elsif count_v = r6 then
                        de_v <= '0';
                    end if;
                end if;

                if hs_i = '0' then
                    if count_h = r2 or hs_i = '1' then
                        count_hs <= (0 => '1', others => '0');
                        hs_i <= '1';
                    end if;
                else
                    if count_hs = r3_h then
                        count_hs <= (others => '0');
                        hs_i <= '0';
                    else
                        count_hs <= count_hs+1;
                    end if;
                end if;

                if ((f = '0' and count_h = shift_right(r0,1)) or (f = '1' and count_h = 0)) then
                    if vs_i = '0' then
                        if count_v = r7 and count_ra = 0 then
                            count_vs <= (0 => '1', others => '0');
                            vs_i <= '1';
                        end if;
                    else
                        if count_ra = r3_v then
                            count_vs <= (others => '0');
                            vs_i <= '0';
                        else
                            count_vs <= count_vs+1;
                        end if;
                    end if;
                end if;

                ma <= std_logic_vector(count_ma);
                ra <= std_logic_vector(count_ra);
                if r8(1 downto 0) = "11" and f = '1' then -- interlaced, 2nd (even) field
                    ra(0) <= '1';
                end if;
                cursor <= '0';
                if count_ma = r14 & r15 then
                    cursor <= '1';
                end if;

            end if; -- clken = '1'
        end if; -- rising_edge(clk)
     end process;

    -- register writes & light pen strobe
    process(hrst, clk)
    begin
        if rising_edge(clk) then
            if hrst = '1' then
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
                if cs = '1' and we = '1' and rs = '0' then
                    a <= unsigned(wdata(a'range));
                elsif cs = '1' and we = '1' and rs = '1' then
                    case to_integer(unsigned(a)) is
                        when 0  => r0  <= unsigned(wdata(r0'range));
                        when 1  => r1  <= unsigned(wdata(r1'range));
                        when 2  => r2  <= unsigned(wdata(r2'range));
                        when 3  => r3  <= unsigned(wdata(r3'range));
                        when 4  => r4  <= unsigned(wdata(r4'range));
                        when 5  => r5  <= unsigned(wdata(r5'range));
                        when 6  => r6  <= unsigned(wdata(r6'range));
                        when 7  => r7  <= unsigned(wdata(r7'range));
                        when 8  => r8  <= unsigned(wdata(r8'range));
                        when 9  => r9  <= unsigned(wdata(r9'range));
                        when 10 => r10 <= unsigned(wdata(r10'range));
                        when 11 => r11 <= unsigned(wdata(r11'range));
                        when 12 => r12 <= unsigned(wdata(r12'range));
                        when 13 => r13 <= unsigned(wdata(r13'range));
                        when 14 => r14 <= unsigned(wdata(r14'range));
                        when 15 => r15 <= unsigned(wdata(r15'range));
                        when others => null;
                    end case;
                end if;
                if clken = '1' and lpstb = '1' then
                    r16 <= count_ma(13 downto 8);
                    r17 <= count_ma(7 downto 0);
                end if;
            end if; -- hrst = '1'
        end if; -- rising_edge(clk)
    end process;

    -- register reads
    rd <=
        x"00"       when cs = '0' else
        "00" & r14  when to_integer(unsigned(a)) = 14 else
        r15         when to_integer(unsigned(a)) = 15 else
        "00" & r16  when to_integer(unsigned(a)) = 16 else
        r17         when to_integer(unsigned(a)) = 17 else
        x"00";
    rdata <= std_logic_vector(rd);


end architecture synth;
