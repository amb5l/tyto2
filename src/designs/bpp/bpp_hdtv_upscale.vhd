--------------------------------------------------------------------------------
-- bpp_hdtv_upscale.vhd                                                       --
-- BPP HDTV upscaler.                                                         --
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
--
-- BBC micro video output has 256 (modes 0,1,2,4,5) or 250 (modes 3, 6 and 7)
-- active lines per field. Each line has 40 (1 MHz) or 80 (2 MHz) character
-- cells max, corresponding to 40uS of active video. Let's overscan to catch the
-- output even if s/w moves it around a bit. So, let's capture 270 lines, and
-- 42uS per line (672 pixels @ 16 MHz). This is handled by bpp_overscan.vhd.
--
-- 1) Vertical Scaling
--
-- Note: the saa5050d has a scan doubling output - it applies x2 vertical
-- scaling. The scaling applied here therefore has to be halved for teletext.
--
-- output        active | normal |  ttx   | scaled
-- mode          lines  | factor | factor | lines
-- -----------------------------------------------
-- 720x576i50   |   288 |    1   |   1/2  |   270
-- 720x576p50   |   576 |    2   |    1   |   540
-- 1280x720p50  |   720 |   5/2  |   5/4  |   675
-- 1920x1080i50 |   540 |    2   |    1   |   540
-- 1920x1080p50 |  1080 |    4   |    2   |  1080
--
--
-- 2) Horizontal Scaling
--
-- For teletext (12 MHz) there are 504 source pixels. For other (16 MHz) modes
-- there are 672 source pixels.
--
-- output        active |  16M   |  12M   | scaled
-- mode          pixels | factor | factor | pixels
-- -----------------------------------------------
-- 720x576i50   | 1440  |    2   |   8/3  |  1344
-- 720x576p50   |  720  |    1   |   4/3  |   672
-- 1280x720p50  | 1280  |   5/4  |   5/3  |   840
-- 1920x1080i50 | 1920  |    2   |   8/3  |  1344
-- 1920x1080p50 | 1920  |    2   |   8/3  |  1344
--
-- 3) Buffer Size
--
-- The difference in the total active period of the input and output must be
-- absorbed by a buffer. The worst case is 1920x1080p, where the difference
-- is ~1.93 ms = ~46 input lines = ~29.5 kpixels.
-- Round up to a power of 2, allow 3 bits per pixel => 32k x 3 bits.
-- Vertical scaling by a non-integer factor requires reading from 2 lines
-- at once, so split buffer into even and odd source lines.

--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package bpp_hdtv_upscale_pkg is

    component bpp_hdtv_upscale is
        generic (
            v_ovr         : integer := 7;                 -- top/bottom overscan in video lines
            h_ovr         : integer := 1;                 -- left/right overscan in 1MHz / 40 column character cells
            ram_size_log2 : integer := 15                 -- ram size (32k)
        );
        port (

            in_clk   : in  std_logic;                     -- VIDPROC: pixel clock (48MHz)
            in_clken : in  std_logic;                     -- VIDPROC: pixel clock enable (16/12MHz)
            in_rst   : in  std_logic;                     -- VIDPROC: pixel clock sychronous reset
            in_ttx   : in  std_logic;                     -- VIDPROC: format (1 = teletext/scan doubled, 0 = graphics/text)
            in_vrst  : in  std_logic;                     -- VIDPROC: vertical reset (asynchronous)
            in_pe    : in  std_logic;                     -- VIDPROC: pixel enable
            in_p     : in  std_logic_vector(2 downto 0);  -- VIDPROC: pixel data (3bpp)
            in_p2    : in  std_logic_vector(2 downto 0);  -- VIDPROC: pixel data (2nd line for scan doubling) (3bpp)

            out_clk  : in  std_logic;                     -- VTG/HDTV pixel clock
            out_rst  : in  std_logic;                     -- VTG/HDTV pixel clock sychronous reset
            vtg_vs   : in  std_logic;                     -- VTG: vertical sync
            vtg_hs   : in  std_logic;                     -- VTG: horizontal sync
            vtg_de   : in  std_logic;                     -- VTG: display enable
            vtg_ax   : in  std_logic_vector(11 downto 0); -- VTG: active area X
            vtg_ay   : in  std_logic_vector(11 downto 0); -- VTG: active area Y
            hdtv_vs  : out std_logic;                     -- HDTV: vertical sync
            hdtv_hs  : out std_logic;                     -- HDTV: horizontal sync
            hdtv_de  : out std_logic;                     -- HDTV: display enable
            hdtv_r   : out std_logic_vector(7 downto 0);  -- HDTV: pixel data, red channel
            hdtv_g   : out std_logic_vector(7 downto 0);  -- HDTV: pixel data, green channel
            hdtv_b   : out std_logic_vector(7 downto 0)   -- HDTV: pixel data, blue channel

        );
    end component bpp_hdtv_upscale;

end package bpp_hdtv_upscale_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.tyto_types_pkg.all;
use work.sync_reg_pkg.all;
use work.ram_tdp_ar_pkg.all;

entity bpp_hdtv_upscale is
    generic (
        v_ovr         : integer := 7;                 -- top/bottom overscan in video lines
        h_ovr         : integer := 1;                 -- left/right overscan in 1MHz / 40 column character cells
        ram_size_log2 : integer := 15                 -- ram size (32k)
    );
    port (

        in_clk   : in  std_logic;                     -- VIDPROC: pixel clock (48MHz)
        in_clken : in  std_logic;                     -- VIDPROC: pixel clock enable (16/12MHz)
        in_rst   : in  std_logic;                     -- VIDPROC: pixel clock sychronous reset
        in_ttx   : in  std_logic;                     -- VIDPROC: format (1 = teletext/scan doubled, 0 = graphics/text)
        in_vrst  : in  std_logic;                     -- VIDPROC: vertical reset (asynchronous)
        in_pe    : in  std_logic;                     -- VIDPROC: pixel enable
        in_p     : in  std_logic_vector(2 downto 0);  -- VIDPROC: pixel data (3bpp)
        in_p2    : in  std_logic_vector(2 downto 0);  -- VIDPROC: pixel data (2nd line for scan doubling) (3bpp)

        out_clk  : in  std_logic;                     -- VTG/HDTV pixel clock
        out_rst  : in  std_logic;                     -- VTG/HDTV pixel clock sychronous reset
        vtg_vs   : in  std_logic;                     -- VTG: vertical sync
        vtg_hs   : in  std_logic;                     -- VTG: horizontal sync
        vtg_de   : in  std_logic;                     -- VTG: display enable
        vtg_ax   : in  std_logic_vector(11 downto 0); -- VTG: active area X
        vtg_ay   : in  std_logic_vector(11 downto 0); -- VTG: active area Y
        hdtv_vs  : out std_logic;                     -- HDTV: vertical sync
        hdtv_hs  : out std_logic;                     -- HDTV: horizontal sync
        hdtv_de  : out std_logic;                     -- HDTV: display enable
        hdtv_r   : out std_logic_vector(7 downto 0);  -- HDTV: pixel data, red channel
        hdtv_g   : out std_logic_vector(7 downto 0);  -- HDTV: pixel data, green channel
        hdtv_b   : out std_logic_vector(7 downto 0)   -- HDTV: pixel data, blue channel

    );
end entity bpp_hdtv_upscale;

architecture synth of bpp_hdtv_upscale is

    constant w_gfx    : integer := 640+(2*16*h_ovr);  -- input width (text/graphics) } before
    constant w_ttx    : integer := 480+(2*12*h_ovr);  -- input width (teletext)      }  overscan
    constant v_act    : integer := 1080;              -- output active height
    constant v_vis    : integer := 1024+(2*4*v_ovr);  -- output visible height
    constant y_start  : integer := (v_act-v_vis)/2;   -- 1st visible row in active area
    constant y_end    : integer := y_start+v_vis-1;   -- last visible row in active area
    constant h_act    : integer := 1920;              -- output active width
    constant h_vis    : integer := 1280+(2*32*h_ovr); -- output visible width
    constant x_start  : integer := (h_act-h_vis)/2;   -- 1st visible col in active area
    constant x_end    : integer := x_start+h_vis-1;   -- last visible col in active area

    signal in_clken_1 : std_logic;
    signal in_clken_2 : std_logic;
    signal in_ttx_s   : std_logic;
    signal in_vrst_s  : std_logic;
    signal in_pe_1    : std_logic;
    signal in_pe_2    : std_logic;
    signal in_p2_1    : std_logic_vector(2 downto 0);
    signal waddr      : unsigned(ram_size_log2-1 downto 0);
    signal raddr      : unsigned(ram_size_log2-1 downto 0);
    signal raddr_sol  : unsigned(ram_size_log2-1 downto 0);         -- start of line
    signal ram_we     : std_logic;
    signal ram_wa     : std_logic_vector(ram_size_log2-1 downto 0);
    signal ram_wd     : std_logic_vector(2 downto 0);
    signal ram_ra     : std_logic_vector(ram_size_log2-1 downto 0);
    signal ram_rd     : std_logic_vector(2 downto 0);

    signal vis_y      : std_logic;                                  -- visible region of display (vertical)
    signal vis_x      : std_logic;                                  -- visible region of display (horizontal)

    signal f          : slv_1_0_t(2 downto 0);                      -- h scaling (fraction parts)

    signal vtg_vs_r   : std_logic_vector(1 to 2);                   -- } pipeline delay registers
    signal vtg_hs_r   : std_logic_vector(1 to 2);                   -- }
    signal vtg_de_r   : std_logic_vector(1 to 2);                   -- }
    signal vis_r      : std_logic_vector(1 to 2);                   -- }

    signal hdtv_p      : slv_7_0_t(0 to 2);

begin

    SYNC_I: component sync_reg
        port map ( clk => in_clk, d(0) => in_vrst, q(0) => in_vrst_s );

    process(in_clk)
    begin
        if rising_edge(in_clk) then
            if in_rst = '1' then
                in_clken_1 <= '0';
                in_clken_2 <= '0';
                in_pe_1 <= '0';
                in_pe_2 <= '0';
                in_p2_1 <= (others => '0');
                waddr   <= (others => '0');
                ram_we  <= '0';
                ram_wa  <= (others => '0');
                ram_wd  <= (others => '0');
            else
                in_clken_1 <= in_clken;
                in_clken_2 <= in_clken_1;
                in_pe_1 <= in_pe;
                in_pe_2 <= in_pe_1;
                ram_we  <= '0';
                ram_wa  <= (others => '0');
                ram_wd  <= (others => '0');
                if in_pe = '1' and in_clken = '1' then
                    ram_we <= '1';
                    ram_wa <= std_logic_vector(waddr);
                    ram_wd <= in_p;
                    in_p2_1 <= in_p2;
                end if;
                if in_pe_1 = '1' and in_clken_1 = '1' then
                    waddr <= waddr+1;
                    if in_ttx = '1' then
                        ram_we <= '1';
                        ram_wa <= std_logic_vector(waddr+w_ttx);
                        ram_wd <= in_p2_1;
                    end if;
                    
                end if;
                if in_pe_2 = '1' and in_clken_2 = '1' and in_pe_1 = '0' and in_ttx = '1' then
                    waddr <= waddr+w_ttx;
                end if;
            end if;
            if in_vrst_s = '1' then
                waddr   <= (others => '0');
            end if;
        end if;
    end process;

    -- 3 stage output pipeline, red channel (h scale = x8/3)
    -- stage | 0      | 1      | 2       | 3        |
    -- ------|--------+--------+----+----+----------+
    --  ax   |  raddr | ram_rd | f1 | f2 |  hdtv_r   |
    -- ------|--------+--------+----+----+----------+
    --  0    |    a   |        |    |    |          |
    --  1    |    a   |    a   |    |    |          |
    --  2    |    b   |    a   | a  | a  |          |
    --  3    |    b   |    b   | a  | a  | 2a/3+a/3 |
    --  4    |    b   |    b   | b  | a  | 2a/3+a/3 |
    --  5    |    c   |    b   | b  | b  | 2a/3+b/3 |
    --  6    |    c   |    c   | b  | b  | 2b/3+b/3 |
    --  7    |    c   |    c   | b  | c  | 2b/3+b/3 |
    --       |        |    c   | c  | c  | 2c/3+b/3 |
    --       |        |        | c  | c  | 2c/3+c/3 |
    --       |        |        |    |    | 2c/3+c/3 |

    -- 3 stage output pipeline, red channel (h scale = x2)
    -- stage | 0      | 1      | 2       | 3     |
    -- ----  |--------+--------+----+----+-------|
    --  ax   |  raddr | ram_rd | f1 | f2 | hdtv_r |
    -- ----  |--------+--------+----+----+-------|
    --  0    |    a   |        |    |    |       |
    --  1    |    a   |   a    |    |    |       |
    --  0    |    b   |   a    | a  | a  |       |
    --  1    |    b   |   b    | a  | a  |   a   |
    --       |        |   b    | b  | b  |   a   |
    --       |        |        | b  | b  |   b   |
    --       |        |        |    |    |   b   |

    SYNC_O: component sync_reg
        port map ( clk => out_clk, d(0) => in_ttx, q(0) => in_ttx_s );

    process(out_clk)
        variable n : integer;
    begin
        if rising_edge(out_clk) then
            if out_rst = '1' then -- reset or vsync
                vis_x     <= '0';
                vis_y     <= '0';
                raddr     <= (others => '0');
                raddr_sol <= (others => '0');            
                vtg_vs_r  <= (others => '0');
                vtg_hs_r  <= (others => '0');
                vtg_de_r  <= (others => '0');
                vis_r     <= (others => '0');
                hdtv_vs    <= '0';
                hdtv_hs    <= '0';
                hdtv_de    <= '0';
            else
                -- visible region
                if to_integer(unsigned(vtg_ay)) = y_start then
                    vis_y <= '1';
                elsif to_integer(unsigned(vtg_ay)) = y_end+1 then
                    vis_y <= '0';
                end if;
                if to_integer(unsigned(vtg_ax)) = x_start-1 then
                    vis_x <= '1';
                elsif to_integer(unsigned(vtg_ax)) = x_end then
                    vis_x <= '0';
                end if;
                -- vertical scaling
                if vis_y = '1' and vtg_de = '0' and vtg_de_r(1) = '1' then -- trailing edge of de
                    if in_ttx_s = '1' then -- teletext => vertical scale x2
                        if vtg_ay(0) = '1' then
                            raddr_sol <= raddr_sol+w_ttx;
                        end if;
                    else -- graphics => vertical scale x4
                        if vtg_ay(1 downto 0) = "11" then
                            raddr_sol <= raddr_sol+w_gfx;
                        end if;
                    end if;
                end if;
                -- horizontal scaling and pixel output
                if vtg_hs = '0' and vtg_hs_r(1) = '1' then -- trailing edge of hsync
                    raddr <= raddr_sol;
                elsif in_ttx_s = '1' then -- teletext => horizontal scale x8/3
                    if vis_y = '1' and vis_x = '1' then
                        case to_integer(unsigned(vtg_ax(2 downto 0))) is
                            when 1 | 4 | 7 => raddr <= raddr+1;
                            when others => null;
                        end case;
                    end if;
                    n := to_integer(unsigned(vtg_ax(2 downto 0)));
                    if n = 1 or n = 3 or n = 7 then f(0)(0) <= ram_rd(0); f(1)(0) <= ram_rd(1); f(2)(0) <= ram_rd(2); end if;
                    if n = 1 or n = 4 or n = 6 then f(0)(1) <= ram_rd(0); f(1)(1) <= ram_rd(1); f(2)(1) <= ram_rd(2); end if;
                else -- text/graphics => horizontal scale x2
                    if vis_y = '1' and vis_x = '1' and vtg_ax(0) = '1' then
                        raddr <= raddr+1;
                    end if;
                    f(0)(0) <= ram_rd(0); f(1)(0) <= ram_rd(1); f(2)(0) <= ram_rd(2);
                    f(0)(1) <= ram_rd(0); f(1)(1) <= ram_rd(1); f(2)(1) <= ram_rd(2);
                end if;
                vtg_vs_r(1 to 2) <= vtg_vs & vtg_vs_r(1);
                vtg_hs_r(1 to 2) <= vtg_hs & vtg_hs_r(1);
                vtg_de_r(1 to 2) <= vtg_de & vtg_de_r(1);
                vis_r(1 to 2) <= (vis_y and vis_x) & vis_r(1);
                hdtv_vs <= vtg_vs_r(2);
                hdtv_hs <= vtg_hs_r(2);
                hdtv_de <= vtg_de_r(2);
                for i in 0 to 2 loop
                    case f(i) is
                        when "00" => hdtv_p(i) <= x"00";
                        when "01" => hdtv_p(i) <= x"55";
                        when "10" => hdtv_p(i) <= x"AA";
                        when others => hdtv_p(i) <= x"FF";
                    end case;
                end loop;
                if vis_r(2) = '0' then
                    hdtv_p <= (others => (others => '0'));
                end if;
            end if;
        end if;
        if vtg_vs = '1' then
            vis_x     <= '0';
            vis_y     <= '0';
            raddr     <= (others => '0');
            raddr_sol <= (others => '0');
        end if;
    end process;
    ram_ra <= std_logic_vector(raddr);
    hdtv_r <= hdtv_p(0);
    hdtv_g <= hdtv_p(1);
    hdtv_b <= hdtv_p(2);

    -- a pair of 16k x 3 dual port RAMs with seperate clocks

    BUF0: component ram_tdp_ar
        generic map (
            width      => 3,
            depth_log2 => ram_size_log2-1
        )
        port map (
            clk_a  => in_clk,
            rst_a  => '0',
            ce_a   => '1',
            we_a   => ram_we,
            addr_a => ram_wa0,
            din_a  => ram_wd0,
            dout_a => open,
            clk_b  => out_clk,
            rst_b  => '0',
            ce_b   => '1',
            we_b   => '0',
            addr_b => ram_ra0,
            din_b  => (others => '0'),
            dout_b => ram_rd0
        );

    BUF1: component ram_tdp_ar
        generic map (
            width      => 3,
            depth_log2 => ram_size_log2-1
        )
        port map (
            clk_a  => in_clk,
            rst_a  => '0',
            ce_a   => '1',
            we_a   => ram_we,
            addr_a => ram_wa1,
            din_a  => ram_wd1,
            dout_a => open,
            clk_b  => out_clk,
            rst_b  => '0',
            ce_b   => '1',
            we_b   => '0',
            addr_b => ram_ra1,
            din_b  => (others => '0'),
            dout_b => ram_rd0
        );

end architecture synth;


    -- 3 stage output pipeline, red channel (h scale = x8/3)
    -- stage | 0      | 1      | 2       | 3        |
    -- ------|--------+--------+----+----+----------+
    --  ax   |  raddr | ram_rd | f1 | f2 |  hdtv_r   |
    -- ------|--------+--------+----+----+----------+
    --  0    |    a   |        |    |    |          |
    --  1    |    a   |    a   |    |    |          |
    --  2    |    b   |    a   | a  | a  |          |
    --  3    |    b   |    b   | a  | a  | 2a/3+a/3 |
    --  4    |    b   |    b   | b  | a  | 2a/3+a/3 |
    --  5    |    c   |    b   | b  | b  | 2a/3+b/3 |
    --  6    |    c   |    c   | b  | b  | 2b/3+b/3 |
    --  7    |    c   |    c   | b  | c  | 2b/3+b/3 |
    --       |        |    c   | c  | c  | 2c/3+b/3 |
    --       |        |        | c  | c  | 2c/3+c/3 |
    --       |        |        |    |    | 2c/3+c/3 |

    -- 3 stage output pipeline, red channel (h scale = x2)
    -- stage | 0      | 1      | 2       | 3     |
    -- ----  |--------+--------+----+----+-------|
    --  ax   |  raddr | ram_rd | f1 | f2 | hdtv_r |
    -- ----  |--------+--------+----+----+-------|
    --  0    |    a   |        |    |    |       |
    --  1    |    a   |   a    |    |    |       |
    --  0    |    b   |   a    | a  | a  |       |
    --  1    |    b   |   b    | a  | a  |   a   |
    --       |        |   b    | b  | b  |   a   |
    --       |        |        | b  | b  |   b   |
    --       |        |        |    |    |   b   |
