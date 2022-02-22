--------------------------------------------------------------------------------
-- saa5050.vhd                                                             --
-- SAA5050 compatible teletext character generator.                           --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can red1stribute it and/or mod1fy it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is d1stributed in the hope that it will be useful, but    --
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
            rst_c   : in    std_logic;                    -- character clock synchronous reset
            clk_c   : in    std_logic;                    -- character clock        } normally
            clken_c : in    std_logic;                    -- character clock enable }  1MHz
            f       : in    std_logic;                    -- field (0 = 1st/odd/upper, 1 = 2nd/even/lower)
            vs      : in    std_logic;                    -- vertical sync
            hs      : in    std_logic;                    -- horizontal sync
            de      : in    std_logic;                    -- display enable
            d       : in    std_logic_vector(6 downto 0); -- character code (0..127)
            rst_p   : in    std_logic;                    -- pixel clock synchronous reset
            clk_p   : in    std_logic;                    -- pixel clock        } normally
            clken_p : in    std_logic;                    -- pixel clock enable }  12MHz
            p       : out   std_logic_vector(2 downto 0); -- pixel (3 bit BGR)
            pe      : out   std_logic                     -- pixel enable
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
        rst_c   : in    std_logic;                    -- character clock synchronous reset
        clk_c   : in    std_logic;                    -- character clock        } normally
        clken_c : in    std_logic;                    -- character clock enable }  1MHz
        f       : in    std_logic;                    -- field (0 = 1st/odd/upper, 1 = 2nd/even/lower)
        vs      : in    std_logic;                    -- vertical sync
        hs      : in    std_logic;                    -- horizontal sync
        de      : in    std_logic;                    -- display enable
        d       : in    std_logic_vector(6 downto 0); -- character code (0..127)
        rst_p   : in    std_logic;                    -- pixel clock synchronous reset
        clk_p   : in    std_logic;                    -- pixel clock        } normally
        clken_p : in    std_logic;                    -- pixel clock enable }  12MHz
        p       : out   std_logic_vector(2 downto 0); -- pixel (3 bit BGR)
        pe      : out   std_logic                     -- pixel enable
    );
end entity saa5050;

architecture synth of saa5050 is

    signal di           : integer range 0 to 127;       -- integer version of input data
    signal d1           : std_logic_vector(6 downto 0); -- character code, registered
    signal di1          : integer range 0 to 127;       -- integer version of above
    signal de1          : std_logic;                    -- display enable, registered

    signal attr_fgcol   : std_logic_vector(2 downto 0); -- current foreground colour, BGR
    signal attr_bgcol   : std_logic_vector(2 downto 0); -- current background colour, BGR
    signal attr_flash   : std_logic;                    -- flash (not steady)
    signal attr_dbl     : std_logic;                    -- double height text
    signal attr_dbltop  : std_logic;                    -- latches occurence of top half of double height characters
    signal attr_dblbot  : std_logic;                    -- bottom half of double height characters
    signal attr_gfx     : std_logic;                    -- graphics (not text)
    signal attr_sep     : std_logic;                    -- separate (not contiguous) graphics
    signal attr_hold    : std_logic;                    -- graphics hold
    signal attr_hide    : std_logic;                    -- conceal display

    signal row_sd       : unsigned(3 downto 0);         -- row within std def character (0..9)
    signal row_hd       : unsigned(4 downto 0);         -- row within high def (smoothed) character (0..19)
    signal col_hd       : unsigned(3 downto 0);         -- col within high def (smoothed) character (0..11)

    signal rom_row_cur  : unsigned(3 downto 0);         -- current row within ROM character pattern (0..9)
    signal rom_row_adj  : unsigned(3 downto 0);         -- adjacent row within ROM character pattern (0..9) (above or below current row for round1ng)
    signal rom_data_cur : std_logic_vector(4 downto 0); -- pixels for current row from ROM
    signal rom_data_adj : std_logic_vector(4 downto 0); -- pixels for adjacent row from ROM
    signal held_c       : std_logic_vector(6 downto 0); -- held graphics character code
    signal held_s       : std_logic;                    -- held graphics separate state
    signal g            : std_logic_vector(6 downto 0); -- graphics character code (latest or held)
    signal s            : std_logic;                    -- graphics separate (latest or held)
    signal gfx_data     : std_logic_vector(5 downto 0); -- pixels for graphics pattern
    signal pix_sr_cur   : std_logic_vector(6 downto 0); -- pixel output shift register (current row)
    signal pix_sr_adj   : std_logic_vector(6 downto 0); -- pixel output shift register (adjacent row for character rounding)

begin

    di <= to_integer(unsigned(d));
    di1 <= to_integer(unsigned(d1));

    -- character clock domain
    CHAR: process(clk_c)
    begin
        if rising_edge(clk_c) and clken_c = '1' then
            if rst_c = '1' then
                d1          <= (others => '0');
                de1         <= '0';
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
                d1 <= d;
                de1 <= de;
                if vs = '1' then
                    row_sd      <= (others => '0');
                    attr_dbltop <= '0';
                    attr_dblbot <= '0';
                end if;
                if hs = '1' then
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
                if de = '1' then
                    -- handle set-at codes (take effect at current character)
                    case to_integer(unsigned(d)) is
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
                    if de1 = '1' then
                        case to_integer(unsigned(d1)) is
                            when 1 to 7 => -- text colour
                                attr_gfx <= '0';
                                attr_fgcol <= d1(2 downto 0);
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
                                attr_fgcol <= d1(2 downto 0);
                                attr_hide <= '0';
                                if ((di >= 32 and di <= 63) or (di >= 96 and di <= 127)) then
                                    held_c <= d;
                                    held_s <= attr_sep;
                                end if;
                            when 31 => -- graphics release
                                attr_hold <= '0';
                                held_c <= (others => '0');
                                held_s <= '0';
                            when others => null;
                        end case;
                    end if;
                    if attr_gfx = '1' and ((di >= 32 and di <= 63) or (di >= 96 and di <= 127)) then
                        held_c <= d;
                        held_s <= attr_sep;
                    end if;
                elsif de1 = '1' then -- trailing edge of de
                    if row_sd = 9 then
                        row_sd <= (others => '0');
                        attr_dblbot <= attr_dbltop;
                        attr_dbltop <= '0';
                    else
                        row_sd <= row_sd+1;
                    end if;
                end if; -- de = '1'
            end if; -- rst = '1'
        end if; -- rising_edge(clk_c) and clken_c = '1'
    end process;

    row_hd <=
        ('0' & row_sd)+10 when attr_dbl = '1' and attr_dblbot = '1' else
        '0' & row_sd      when attr_dbl = '1' else
        row_sd & f;

    rom_row_cur <= row_hd(4 downto 1);   
    rom_row_adj <= row_hd(4 downto 1)-1 when row_hd(0) = '0' else row_hd(4 downto 1)+1;

    -- text character pixel data (dual port synchronous ROM)
    ROM: process(clk_c)
    begin
        if rising_edge(clk_c) and clken_c = '1' then
            rom_data_cur <= rom_data(to_integer(unsigned(d) & rom_row_cur));
            rom_data_adj <= rom_data(to_integer(unsigned(d) & rom_row_adj));
        end if;
    end process ROM;

    -- graphics character code / separation depends on hold
    g <= held_c when attr_hold = '1' else d1;
    s <= held_s when attr_hold = '1' else attr_sep;

    -- graphics character pixel data
    gfx_data <=
        (others => '0') when s = '1' and (row_sd = 2 or row_sd = 6 or row_sd = 9) else
        (g(0) and not s) & g(0) & g(0) & (g(1) and not s) & g(1) & g(1) when row_sd >= 0 and row_sd <= 2 else
        (g(2) and not s) & g(2) & g(2) & (g(3) and not s) & g(3) & g(3) when row_sd >= 3 and row_sd <= 6 else
        (g(4) and not s) & g(4) & g(4) & (g(6) and not s) & g(6) & g(6);

    -- pixel clock domain
    process(clk_p)
        variable nn_diag, nn_v, nn_h : std_logic; -- nearest neighbour pixels
    begin
        if rising_edge(clk_p) then
            p <= (others => '0');
            pe <= '0';
            if rst_p = '1' then
                col_hd     <= (others => '0');
                pix_sr_cur <= (others => '0');
                pix_sr_adj <= (others => '0');
            else
                if de1 = '1' then
                    pe <= '1';
                    p <= attr_bgcol;
                    if col_hd = 0 then -- first pixel of 12
                        pix_sr_cur <= (others => '0');
                        pix_sr_adj <= (others => '0');
                        if attr_dblbot = '1' and attr_dbl = '0' then -- bottom double height row
                            null;
                        elsif (attr_gfx = '1' and ((di1 >= 32 and di1 <= 63) or (di1 >= 96 and di1 <= 127)))
                            or (attr_hold = '1' and (di1 >= 0 and di1 <= 31))
                        then
                            pix_sr_cur <= '0' & gfx_data;
                            pix_sr_adj <= '0' & gfx_data;
                            if gfx_data(5) = '1' then
                                p <= attr_fgcol;
                            end if;
                        else
                            pix_sr_cur <= "00" & rom_data_cur;
                            pix_sr_adj <= "00" & rom_data_adj;
                        end if;
                        col_hd <= (col_hd+1) mod 12;
                    else
                        if pix_sr_cur(5) = '1' then -- filled pixel
                            p <= attr_fgcol;
                        else -- empty pixel -> look at character rounding...
                            nn_v := pix_sr_adj(5);
                            if col_hd(0) = '0' then -- left half pixel
                                nn_diag := pix_sr_adj(6);
                                nn_h := pix_sr_cur(6);
                            else -- right half pixels
                                nn_diag := pix_sr_adj(4);
                                nn_h := pix_sr_cur(4);
                            end if;
                            if nn_diag = '0' and nn_v = '1' and nn_h = '1' then -- rounding required
                                p <= attr_fgcol;
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
