--------------------------------------------------------------------------------
-- bpp_vidproc.vhd                                                            --
-- BPP VIDPROC (video ULA) functionality.                                     --
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

package bpp_vidproc_pkg is

    component bpp_vidproc is
        port (

            clk_48m         : in  std_logic;
            clk_32m         : in  std_logic;
            clk_8m          : in  std_logic;

            rst_48m         : in  std_logic;
            rst_32m         : in  std_logic;
            rst_8m          : in  std_logic;

            clken_48m_16m   : in  std_logic;
            clken_48m_12m   : in  std_logic;
            clken_48m_8m    : in  std_logic;
            clken_8m_4m     : in  std_logic;
            clken_8m_2m_0   : in  std_logic;
            clken_8m_2m_180 : in  std_logic;
            clken_8m_1m_90  : in  std_logic;

            reg_cs           : in  std_logic;
            reg_we           : in  std_logic;
            reg_rs           : in  std_logic;
            reg_dw           : in  std_logic_vector(7 downto 0);

            crtc_clksel      : out std_logic;
            crtc_clken       : out std_logic;
            crtc_cur         : in  std_logic;
            crtc_oe          : in  std_logic;
            crtc_de          : in  std_logic;
            crtc_d           : in  std_logic_vector(7 downto 0);

            ttx_en           : out std_logic;                    -- teletext: enable
            ttx_oe           : in  std_logic;                    -- teletext: overscan pixel enable
            ttx_pe           : in  std_logic;                    -- teletext: pixel enable
            ttx_pu           : in  std_logic_vector(2 downto 0); -- teletext: pixel data (upper line)
            ttx_pl           : in  std_logic_vector(2 downto 0); -- teletext: pixel data (lower line)

            out_clken        : out std_logic;
            out_pe           : out std_logic;
            out_p            : out std_logic_vector(2 downto 0);
            out_p2           : out std_logic_vector(2 downto 0)

        );
    end component bpp_vidproc;

end package bpp_vidproc_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tyto_types_pkg.all;

entity bpp_vidproc is
    port (

        clk_48m         : in  std_logic;
        clk_32m         : in  std_logic;
        clk_8m          : in  std_logic;

        rst_48m         : in  std_logic;
        rst_32m         : in  std_logic;
        rst_8m          : in  std_logic;

        clken_48m_16m   : in  std_logic;
        clken_48m_12m   : in  std_logic;
        clken_48m_8m    : in  std_logic;
        clken_8m_4m     : in  std_logic;
        clken_8m_2m_0   : in  std_logic;
        clken_8m_2m_180 : in  std_logic;
        clken_8m_1m_90  : in  std_logic;

        reg_cs           : in  std_logic;
        reg_we           : in  std_logic;
        reg_rs           : in  std_logic;
        reg_dw           : in  std_logic_vector(7 downto 0);

        crtc_clksel      : out std_logic;
        crtc_clken       : out std_logic;
        crtc_cur         : in  std_logic;
        crtc_oe          : in  std_logic;
        crtc_de          : in  std_logic;
        crtc_d           : in  std_logic_vector(7 downto 0);

        ttx_en           : out std_logic;                    -- teletext: enable
        ttx_oe           : in  std_logic;                    -- teletext: overscan pixel enable
        ttx_pe           : in  std_logic;                    -- teletext: pixel enable
        ttx_pu           : in  std_logic_vector(2 downto 0); -- teletext: pixel data (upper line)
        ttx_pl           : in  std_logic_vector(2 downto 0); -- teletext: pixel data (lower line)

        out_clken        : out std_logic;
        out_pe           : out std_logic;
        out_p            : out std_logic_vector(2 downto 0);
        out_p2           : out std_logic_vector(2 downto 0)

    );
end entity bpp_vidproc;

architecture synth of bpp_vidproc is

    signal reg_ctrl         : std_logic_vector(7 downto 0);
    alias  reg_ctrl_curseg0 : std_logic is reg_ctrl(7);
    alias  reg_ctrl_curseg1 : std_logic is reg_ctrl(6);
    alias  reg_ctrl_curseg2 : std_logic is reg_ctrl(5);
    alias  reg_ctrl_clksel  : std_logic is reg_ctrl(4);
    alias  reg_ctrl_chperln : std_logic_vector(1 downto 0) is reg_ctrl(3 downto 2);
    alias  reg_ctrl_ttx     : std_logic is reg_ctrl(1);
    alias  reg_ctrl_flash   : std_logic is reg_ctrl(0);

    signal palette          : slv_3_0_t(0 to 15);
    signal palette_we       : std_logic;
    signal palette_wa       : integer range 0 to 15;
    signal palette_wd       : std_logic_vector(3 downto 0);
    signal palette_ra_v     : std_logic_vector(3 downto 0);
    signal palette_ra       : integer range 0 to 15;
    signal palette_rd       : std_logic_vector(3 downto 0);

    signal out_clken_crtc   : std_logic; -- 2MHz or 1MHz } w.r.t.
    signal out_clken_pix    : std_logic; -- 16/8/4/2 MHz }  48MHz pix clk

    signal crtc_oe_1        : std_logic; -- 1 clock delayed
    signal crtc_de_1        : std_logic; -- 1 clock delayed
    signal crtc_pe          : std_logic; -- pixel enable
    signal crtc_p           : std_logic_vector(2 downto 0);

    signal shiftreg         : std_logic_vector(7 downto 0);

begin

    -- control register

    process(clk_32m)
    begin
        if rising_edge(clk_32m) then
            if rst_32m = '1' then
                reg_ctrl <= (others => '0');
            elsif reg_cs = '1' and reg_we = '1' and reg_rs = '0' then
                reg_ctrl <= reg_dw;
            end if;
        end if;
    end process;

    ttx_en <= reg_ctrl_ttx;

    -- palette (simple dual port RAM, sync write, async read)

    palette_we   <= reg_cs and reg_we and reg_rs;
    palette_wa   <= to_integer(unsigned(reg_dw(7 downto 4)));
    palette_wd   <= reg_dw(3 downto 0);
    palette_ra_v <= shiftreg(7) & shiftreg(5) & shiftreg(3) & shiftreg(1);
    palette_ra   <= to_integer(unsigned(palette_ra_v));
    palette_rd   <= palette(palette_ra);
    process(clk_32m)
    begin
        if rising_edge(clk_32m) and palette_we = '1' then
            palette(palette_wa) <= palette_wd;
        end if;
    end process;

    -- clock selection

    crtc_clksel <= reg_ctrl_clksel;

    crtc_clken <= clken_8m_2m_180 when reg_ctrl_clksel = '1' else clken_8m_1m_90;

    out_clken_crtc <=
        clken_8m_2m_180 and clken_48m_8m when reg_ctrl_clksel = '1' else
        clken_8m_1m_90  and clken_48m_8m;

    out_clken_pix <=
                          clken_48m_16m when reg_ctrl_chperln = "11" and reg_ctrl_clksel = '1' else -- 2MHz CRTC, 80 char per ln
                          clken_48m_8m  when reg_ctrl_chperln = "10" and reg_ctrl_clksel = '1' else -- 2MHz CRTC, 40 char per ln
        clken_8m_4m   and clken_48m_8m  when reg_ctrl_chperln = "01" and reg_ctrl_clksel = '1' else -- 2MHz CRTC, 20 char per ln
        clken_8m_2m_0 and clken_48m_8m  when reg_ctrl_chperln = "00" and reg_ctrl_clksel = '1' else -- 2MHz CRTC, 10 char per ln
                          clken_48m_8m  when reg_ctrl_chperln = "11" and reg_ctrl_clksel = '0' else -- 1MHz CRTC, 40 char per ln
        clken_8m_4m   and clken_48m_8m  when reg_ctrl_chperln = "10" and reg_ctrl_clksel = '0' else -- 1MHz CRTC, 20 char per ln
        clken_8m_2m_0 and clken_48m_8m  when reg_ctrl_chperln = "01" and reg_ctrl_clksel = '0' else -- 1MHz CRTC, 10 char per ln
        '0';

    -- serialiser

    process(clk_48m)
    begin
        if rising_edge(clk_48m) then
            if rst_48m = '1' then
                crtc_oe_1 <= '0';
                crtc_de_1 <= '0';
                shiftreg  <= (others => '0');
                crtc_pe   <= '0';
                crtc_p    <= (others => '0');
            else
                if out_clken_pix = '1' then
                    shiftreg <= shiftreg(6 downto 0) & '0';
                    crtc_pe  <= crtc_oe_1;
                    crtc_p   <= (others => '0');
                    if crtc_de_1 = '1' then
                        if palette_rd(3) = '0' or reg_ctrl_flash = '0' then
                            crtc_p <= not palette_rd(2 downto 0);
                        else
                            crtc_p <= palette_rd(2 downto 0);
                        end if;
                        -- crtc_p <= palette_ra_v(2 downto 0);
                        -- if palette_ra_v(3 downto 0) = "0000" then
                            -- crtc_p <= "001";
                        -- end if;
                    end if;
                end if;
                if out_clken_crtc = '1' then
                    crtc_oe_1 <= crtc_oe;
                    crtc_de_1 <= crtc_de;
                    shiftreg <= crtc_d;
                end if;
            end if;
        end if;
    end process;

    -- pixel outputs

    out_clken <= clken_48m_12m when reg_ctrl_ttx = '1' else clken_48m_16m;
    out_pe <= ttx_oe when reg_ctrl_ttx = '1' else crtc_pe;
    out_p <=
        ttx_pu when reg_ctrl_ttx = '1' and ttx_pe = '1' else
        crtc_p when reg_ctrl_ttx = '0' and crtc_pe = '1' else
        (others => '0');
    out_p2 <=
        ttx_pl when reg_ctrl_ttx = '1' and ttx_pe = '1' else
        (others => '0');

end architecture synth;
