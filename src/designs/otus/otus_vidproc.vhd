--------------------------------------------------------------------------------
-- otus_vidproc.vhd                                                           --
-- VIDPROC functionality.                                                     --
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

package otus_vidproc_pkg is

    component otus_vidproc is
        port (

            reg_clk       : in  std_logic;
            reg_rst       : in  std_logic;
            reg_cs        : in  std_logic;
            reg_we        : in  std_logic;
            reg_rs        : in  std_logic;
            reg_dw        : in  std_logic_vector(7 downto 0);
            reg_dr        : out std_logic_vector(7 downto 0);

            crtc_clken_2m : in  std_logic;
            crtc_clken_1m : in  std_logic;
            crtc_clken    : out std_logic;
            crtc_cur      : in  std_logic;
            crtc_oe       : in  std_logic;
            crtc_de       : in  std_logic;
            crtc_d        : in  std_logic_vector(7 downto 0);

            pix_rst       : in  std_logic;
            pix_clk       : in  std_logic;
            pix_clken_16m : in  std_logic;
            pix_clken_12m : in  std_logic;
            pix_clken_2m  : in  std_logic;
            pix_clken_1m  : in  std_logic;

            ttx_en        : out std_logic;                    -- teletext: enable
            ttx_oe        : in  std_logic;                    -- teletext: overscan pixel enable
            ttx_pe        : in  std_logic;                    -- teletext: pixel enable
            ttx_pu        : in  std_logic_vector(2 downto 0); -- teletext: pixel data (upper line)
            ttx_pl        : in  std_logic_vector(2 downto 0); -- teletext: pixel data (lower line)

            out_clken     : out std_logic;
            out_pe        : out std_logic;
            out_p         : out std_logic_vector(2 downto 0);
            out_p2        : out std_logic_vector(2 downto 0)

        );
    end component otus_vidproc;

end package otus_vidproc_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tyto_types_pkg.all;

entity otus_vidproc is
    port (

        reg_clk       : in  std_logic;
        reg_rst       : in  std_logic;
        reg_cs        : in  std_logic;
        reg_we        : in  std_logic;
        reg_rs        : in  std_logic;
        reg_dw        : in  std_logic_vector(7 downto 0);
        reg_dr        : out std_logic_vector(7 downto 0);

        crtc_clken_2m : in  std_logic;
        crtc_clken_1m : in  std_logic;
        crtc_clken    : out std_logic;
        crtc_cur      : in  std_logic;
        crtc_oe       : in  std_logic;
        crtc_de       : in  std_logic;
        crtc_d        : in  std_logic_vector(7 downto 0);

        pix_rst       : in  std_logic;
        pix_clk       : in  std_logic;
        pix_clken_16m : in  std_logic;
        pix_clken_12m : in  std_logic;
        pix_clken_2m  : in  std_logic;
        pix_clken_1m  : in  std_logic;

        ttx_en        : out std_logic;                    -- teletext: enable
        ttx_oe        : in  std_logic;                    -- teletext: overscan pixel enable
        ttx_pe        : in  std_logic;                    -- teletext: pixel enable
        ttx_pu        : in  std_logic_vector(2 downto 0); -- teletext: pixel data (upper line)
        ttx_pl        : in  std_logic_vector(2 downto 0); -- teletext: pixel data (lower line)

        out_clken     : out std_logic;
        out_pe        : out std_logic;
        out_p         : out std_logic_vector(2 downto 0);
        out_p2        : out std_logic_vector(2 downto 0)

    );
end entity otus_vidproc;

architecture synth of otus_vidproc is

    constant RA_CONTROL : std_logic := '0';
    constant RA_PALETTE : std_logic := '1';

    signal reg_ctrl         : std_logic_vector(7 downto 0);
    alias  reg_ctrl_curseg0 : std_logic is reg_ctrl(7);
    alias  reg_ctrl_curseg1 : std_logic is reg_ctrl(6);
    alias  reg_ctrl_curseg2 : std_logic is reg_ctrl(5);
    alias  reg_ctrl_clksel  : std_logic is reg_ctrl(4);
    alias  reg_ctrl_chperln : std_logic_vector(1 downto 0) is reg_ctrl(3 downto 2);
    alias  reg_ctrl_ttx     : std_logic is reg_ctrl(1);
    alias  reg_ctrl_flash   : std_logic is reg_ctrl(0);

    signal palette          : slv_3_0_t(0 to 15);

    signal pix_clken_crtc   : std_logic; -- 2MHz or 1MHz

    signal crtc_pe          : std_logic; -- pixel enable
    signal crtc_p           : std_logic_vector(2 downto 0);

    signal shiftreg         : std_logic_vector(7 downto 0);

begin

    -- control register and palette writes

    process(reg_clk)
    begin
        if rising_edge(reg_clk) then
            if reg_cs = '1' and reg_we = '1' then
                if reg_rs = RA_CONTROL then
                    reg_ctrl <= reg_dw;
                end if;
                if reg_rs = RA_PALETTE then
                    palette(to_integer(unsigned(reg_dw(7 downto 4)))) <= reg_dw(3 downto 0);
                end if;
            end if;
            if reg_rst = '1' then
                reg_ctrl <= (others => '0');
            end if;
        end if;
    end process;

    -- CRTC interface

    pix_clken_crtc <= pix_clken_2m when reg_ctrl_clksel = '1' else pix_clken_1m;

    -- process(pix_clk)
    -- begin
        -- if rising_edge(pix_clk) then
            -- if pix_rst = '1' then
                -- shiftreg <= (others => '0');
            -- elsif pix_clken_crtc = '1' then
                -- shiftreg <= (others => '0');
                -- if crtc_pe = '1' then
                    -- if crtc_de = '1' then
                    -- end if;
                -- end if;
            -- end if;
        -- end if;
    -- end process;
    crtc_pe <= '0';
    crtc_p <= (others => '0');
    

    -- outputs

    reg_dr <= reg_ctrl;

    crtc_clken <= crtc_clken_2m when reg_ctrl_clksel = '1' else crtc_clken_1m;

    ttx_en <= reg_ctrl_ttx;

    out_clken <= pix_clken_12m when reg_ctrl_ttx = '1' else pix_clken_16m;

    out_pe <= ttx_oe when reg_ctrl_ttx = '1' else crtc_pe; 

    out_p <=
        ttx_pu          when reg_ctrl_ttx = '1' and ttx_pe = '1' else
        (others => '1') when reg_ctrl_ttx = '1' and ttx_oe = '1' else
        crtc_p          when reg_ctrl_ttx = '0' and crtc_pe = '1' else
        (others => '1') when reg_ctrl_ttx = '0' and crtc_oe = '1' else
        (others => '0');
    out_p2 <=
        ttx_pl          when reg_ctrl_ttx = '1' and ttx_pe = '1' else
        (others => '1') when reg_ctrl_ttx = '1' and ttx_oe = '1' else
        (others => '0');

end architecture synth;
