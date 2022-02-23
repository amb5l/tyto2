--------------------------------------------------------------------------------
-- saa5050.vhd                                                                --
-- SAA5050 compatible teletext character generator.                           --
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

package saa5050_pkg is

    component saa5050  is
        port (
            chr_clk   : in    std_logic;                    -- character clock        } normally
            chr_clken : in    std_logic;                    -- character clock enable }  1MHz
            chr_rst   : in    std_logic;                    -- character clock synchronous reset
            chr_f     : in    std_logic;                    -- field (0 = 1st/odd/upper, 1 = 2nd/even/lower)
            chr_vs    : in    std_logic;                    -- CRTC vertical sync
            chr_hs    : in    std_logic;                    -- CRTC horizontal sync
            chr_de    : in    std_logic;                    -- CRTC display enable
            chr_d     : in    std_logic_vector(6 downto 0); -- CRTC character code (0..127)
            pix_clk   : in    std_logic;                    -- pixel clock        } normally
            pix_clken : in    std_logic;                    -- pixel clock enable }  12MHz
            pix_rst   : in    std_logic;                    -- pixel clock synchronous reset
            pix_d     : out   std_logic_vector(2 downto 0); -- pixel data (3 bit BGR)
            pix_de    : out   std_logic                     -- pixel enable
        );
    end component saa5050;

end package saa5050_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.saa5050_rom_data_pkg.all;

entity saa5050 is
    port (
        chr_clk   : in    std_logic;                    -- character clock        } normally
        chr_clken : in    std_logic;                    -- character clock enable }  1MHz
        chr_rst   : in    std_logic;                    -- character clock synchronous reset
        chr_f     : in    std_logic;                    -- field (0 = 1st/odd/upper, 1 = 2nd/even/lower)
        chr_vs    : in    std_logic;                    -- CRTC vertical sync
        chr_hs    : in    std_logic;                    -- CRTC horizontal sync
        chr_de    : in    std_logic;                    -- CRTC display enable
        chr_d     : in    std_logic_vector(6 downto 0); -- CRTC character code (0..127)
        pix_clk   : in    std_logic;                    -- pixel clock        } normally
        pix_clken : in    std_logic;                    -- pixel clock enable }  12MHz
        pix_rst   : in    std_logic;                    -- pixel clock synchronous reset
        pix_d     : out   std_logic_vector(2 downto 0); -- pixel data (3 bit BGR)
        pix_de    : out   std_logic                     -- pixel enable
    );
end entity saa5050;

architecture synth of saa5050 is

    signal chr_di       : integer range 0 to 127;       -- integer version of input data
    signal chr_d1       : std_logic_vector(6 downto 0); -- character code, registered
    signal chr_di1      : integer range 0 to 127;       -- integer version of above
    signal chr_de1      : std_logic;                    -- chr_display enable, registered

    signal attr_fgcol   : std_logic_vector(2 downto 0); -- current foreground colour, BGR
    signal attr_bgcol   : std_logic_vector(2 downto 0); -- current background colour, BGR
    signal attr_flash   : std_logic;                    -- flash (not steady)
    signal attr_dbl     : std_logic;                    -- double height text
    signal attr_dbltop  : std_logic;                    -- latches occurence of top half of double height characters
    signal attr_dblbot  : std_logic;                    -- bottom half of double height characters
    signal attr_gfx     : std_logic;                    -- graphics (not text)
    signal attr_sep     : std_logic;                    -- separate (not contiguous) graphics
    signal attr_hold    : std_logic;                    -- graphics hold
    signal attr_hide    : std_logic;                    -- conceal chr_display

    signal row_sd       : unsigned(3 downto 0);         -- row within std def character (0..9)
    signal row_hd       : unsigned(4 downto 0);         -- row within high def (smoothed) character (0..19)
    signal col_hd       : unsigned(3 downto 0);         -- col within high def (smoothed) character (0..11)

    signal rom_row_cur  : unsigned(3 downto 0);         -- current row within ROM character pattern (0..9)
    signal rom_row_adj  : unsigned(3 downto 0);         -- adjacent row within ROM character pattern (0..9) (above or below current row for rounchr_d1ng)
    signal rom_data_cur : std_logic_vector(4 downto 0); -- pixels for current row from ROM
    signal rom_data_adj : std_logic_vector(4 downto 0); -- pixels for adjacent row from ROM
    signal held_c       : std_logic_vector(6 downto 0); -- held graphics character code
    signal held_s       : std_logic;                    -- held graphics separate state
    signal chr_g        : std_logic_vector(6 downto 0); -- graphics character code (latest or held)
    signal chr_s        : std_logic;                    -- graphics separate (latest or held)
    signal gfx_data     : std_logic_vector(5 downto 0); -- pixels for graphics pattern
    signal pix_sr_cur   : std_logic_vector(6 downto 0); -- pixel output shift register (current row)
    signal pix_sr_adj   : std_logic_vector(6 downto 0); -- pixel output shift register (adjacent row for character rounchr_ding)

begin

    chr_di <= to_integer(unsigned(chr_d));
    chr_di1 <= to_integer(unsigned(chr_d1));

    -- character clock domain
    CHAR: process(chr_clk)
    begin
        if rising_edge(chr_clk) and chr_clken = '1' then
            if chr_rst = '1' then
                chr_d1          <= (others => '0');
                chr_de1         <= '0';
                row_sd      <= (others => '0');
                attr_fgcol  <= (others => '1');
                attr_bgcol  <= (others => '0');
                attr_flash  <= '0';
                attr_dbl    <= '0';
                attr_dbltop <= '0';
                attr_dblbot <= '0';
                attr_gfx    <= '0';
                attr_sep    <= '0';
                attr_hold   <= '0';
                attr_hide   <= '0';
                held_c      <= (others => '0');
                held_s      <= '0';
            else
                chr_d1 <= chr_d;
                chr_de1 <= chr_de;
                if chr_vs = '1' then
                    row_sd      <= (others => '0');
                    attr_dbltop <= '0';
                    attr_dblbot <= '0';
                end if;
                if chr_hs = '1' then
                    attr_fgcol <= (others => '1');
                    attr_bgcol <= (others => '0');
                    attr_flash <= '0';
                    attr_dbl   <= '0';
                    attr_gfx   <= '0';
                    attr_sep   <= '0';
                    attr_hold  <= '0';
                    attr_hide  <= '0';
                    held_c     <= (others => '0');
                    held_s     <= '0';
                end if;
                if chr_de = '1' then
                    -- handle set-at codes (take effect at current character)
                    case to_integer(unsigned(chr_d)) is
                        when 12 => -- normal size
                            attr_dbl <= '0';
                            attr_hold <= '0';
                            held_c <= (others => '0');
                            held_s <= '0';
                        when 24 => -- attr_hide
                            attr_hide <= '1';
                        when 25 => -- contiguous graphics
                            attr_sep <= '0';
                        when 26 => -- separated graphics
                            attr_sep <= '1';
                        when 28 => -- black background colour
                            attr_bgcol <= (others => '0');
                        when 29 => -- new background colour
                            attr_bgcol <= attr_fgcol;
                        when 30 => -- graphics hold
                            attr_hold <= '1';
                        when others => null;
                    end case;
                    -- handle set-after codes (take effect at next character)
                    if chr_de1 = '1' then
                        case to_integer(unsigned(chr_d1)) is
                            when 1 to 7 => -- text colour
                                attr_gfx <= '0';
                                attr_fgcol <= chr_d1(2 downto 0);
                                attr_hide <= '0';
                                attr_hold <= '0';
                                held_c <= (others => '0');
                                held_s <= '0';
                            when 8 => -- flash
                                attr_flash <= '1';
                            when 13 => -- double height
                                attr_dbl <= '1';
                                attr_dbltop <= not attr_dblbot;
                                attr_hold <= '0';
                                held_c <= (others => '0');
                                held_s <= '0';
                            when 17 to 23 => -- graphics colour
                                attr_gfx <= '1';
                                attr_fgcol <= chr_d1(2 downto 0);
                                attr_hide <= '0';
                                if ((chr_di >= 32 and chr_di <= 63) or (chr_di >= 96 and chr_di <= 127)) then
                                    held_c <= chr_d;
                                    held_s <= attr_sep;
                                end if;
                            when 31 => -- graphics release
                                attr_hold <= '0';
                                held_c <= (others => '0');
                                held_s <= '0';
                            when others => null;
                        end case;
                    end if;
                    if attr_gfx = '1' and ((chr_di >= 32 and chr_di <= 63) or (chr_di >= 96 and chr_di <= 127)) then
                        held_c <= chr_d;
                        held_s <= attr_sep;
                    end if;
                elsif chr_de1 = '1' then -- trailing edge of de
                    if row_sd = 9 then
                        row_sd <= (others => '0');
                        attr_dblbot <= attr_dbltop;
                        attr_dbltop <= '0';
                    else
                        row_sd <= row_sd+1;
                    end if;
                end if; -- de = '1'
            end if; -- rst = '1'
        end if; -- rising_edge(chr_clk) and chr_clken = '1'
    end process;

    row_hd <=
        ('0' & row_sd)+10 when attr_dbl = '1' and attr_dblbot = '1' else
        '0' & row_sd      when attr_dbl = '1' else
        row_sd & chr_f;

    rom_row_cur <= row_hd(4 downto 1);
    rom_row_adj <= row_hd(4 downto 1)-1 when row_hd(0) = '0' else row_hd(4 downto 1)+1;

    -- text character pixel data (dual port synchronous ROM)
    ROM: process(chr_clk)
    begin
        if rising_edge(chr_clk) and chr_clken = '1' then
            rom_data_cur <= rom_data(to_integer(unsigned(chr_d) & rom_row_cur));
            rom_data_adj <= rom_data(to_integer(unsigned(chr_d) & rom_row_adj));
        end if;
    end process ROM;

    -- graphics character code / separation depends on hold
    chr_g <= held_c when attr_hold = '1' else chr_d1;
    chr_s <= held_s when attr_hold = '1' else attr_sep;

    -- graphics character pixel data
    gfx_data <=
        (others => '0') when chr_s = '1' and (row_sd = 2 or row_sd = 6 or row_sd = 9) else
        (chr_g(0) and not chr_s) & chr_g(0) & chr_g(0) & (chr_g(1) and not chr_s) & chr_g(1) & chr_g(1) when row_sd >= 0 and row_sd <= 2 else
        (chr_g(2) and not chr_s) & chr_g(2) & chr_g(2) & (chr_g(3) and not chr_s) & chr_g(3) & chr_g(3) when row_sd >= 3 and row_sd <= 6 else
        (chr_g(4) and not chr_s) & chr_g(4) & chr_g(4) & (chr_g(6) and not chr_s) & chr_g(6) & chr_g(6);

    -- pixel clock domain
    process(pix_clk)
        variable nn_chr_diag, nn_v, nn_h : std_logic; -- nearest neighbour pixels
    begin
        if rising_edge(pix_clk) and pix_clken = '1' then
            pix_d <= (others => '0');
            pix_de <= '0';
            if pix_rst = '1' then
                col_hd     <= (others => '0');
                pix_sr_cur <= (others => '0');
                pix_sr_adj <= (others => '0');
            else
                if chr_de1 = '1' then
                    pix_de <= '1';
                    pix_d <= attr_bgcol;
                    if col_hd = 0 then -- first pixel of 12
                        pix_sr_cur <= (others => '0');
                        pix_sr_adj <= (others => '0');
                        if attr_dblbot = '1' and attr_dbl = '0' then -- bottom double height row
                            null;
                        elsif (attr_gfx = '1' and ((chr_di1 >= 32 and chr_di1 <= 63) or (chr_di1 >= 96 and chr_di1 <= 127)))
                            or (attr_hold = '1' and (chr_di1 >= 0 and chr_di1 <= 31))
                        then
                            pix_sr_cur <= '0' & gfx_data;
                            pix_sr_adj <= '0' & gfx_data;
                            if gfx_data(5) = '1' then
                                pix_d <= attr_fgcol;
                            end if;
                        else
                            pix_sr_cur <= "00" & rom_data_cur;
                            pix_sr_adj <= "00" & rom_data_adj;
                        end if;
                        col_hd <= (col_hd+1) mod 12;
                    else
                        if pix_sr_cur(5) = '1' then -- filled pixel
                            pix_d <= attr_fgcol;
                        else -- empty pixel -> look at character rounchr_ding...
                            nn_v := pix_sr_adj(5);
                            if col_hd(0) = '0' then -- left half pixel
                                nn_chr_diag := pix_sr_adj(6);
                                nn_h := pix_sr_cur(6);
                            else -- right half pixels
                                nn_chr_diag := pix_sr_adj(4);
                                nn_h := pix_sr_cur(4);
                            end if;
                            if nn_chr_diag = '0' and nn_v = '1' and nn_h = '1' then -- rounchr_ding required
                                pix_d <= attr_fgcol;
                            end if;
                        end if;
                        if col_hd(0) = '1' then
                            pix_sr_cur <= std_logic_vector(shift_left(unsigned(pix_sr_cur),1));
                            pix_sr_adj <= std_logic_vector(shift_left(unsigned(pix_sr_adj),1));
                        end if;
                        col_hd <= (col_hd+1) mod 12;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture synth;
