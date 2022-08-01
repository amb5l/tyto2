--------------------------------------------------------------------------------
-- otus_upscale.vhd                                                           --
-- Upscales from 625i50 to 1080p50.                                           --
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
-- 1) Scan Rates and Buffer Size
-- We upscale from 270 lines in to 1080 lines out. The input active period is
-- 270 x 64uS = 17.28mS. The output active period is 1080 x 17.777uS = 19.2mS.
-- The delta is 1.92mS = 30 input lines. Let's round this up to 32.
-- We need to buffer this delta to absorb the difference in scan rates.
-- For teletext: 32 lines x 480 pixels per line = 15,360 pixels.
-- For graphics: 32 lines x 640 pixels per line = 20,480 pixels.
-- Round up to a power of 2, allow 3 bits per pixel => 32k x 3 dual port RAM.
-- 2) Vertical Scaling
-- If we capture 270 lines this will overscan the visible picture and
-- can be scaled x4 => 1080 lines (x2 for double scanned teletext). Easy.
-- 3) Horizontal Scaling
-- If VIDPROC delivers 640 pixels we can scale this x2 for close to square
-- pixels. Teletext delivers 480 however, so we need to scale this x8/3.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package otus_upscale_pkg is

    component otus_upscale is
        generic (
            v_ovr         : integer := 0;                 -- top/bottom overscan in video lines
            h_ovr         : integer := 0;                 -- left/right overscan in 1MHz / 40 column character cells
            ram_size_log2 : integer := 15                 -- ram size (32k)
        );
        port (

            in_clk   : in  std_logic;                     -- input pixel clock (48MHz)
            in_clken : in  std_logic;                     -- input pixel clock enable (16/12MHz)
            in_rst   : in  std_logic;                     -- input pixel clock sychronous reset
            in_ttx   : in  std_logic;                     -- input format (1 = teletext/scan doubled, 0 = graphics/text)
            in_vrst  : in  std_logic;                     -- input vertical reset (asynchronous)
            in_pe    : in  std_logic;                     -- input pixel enable
            in_p     : in  std_logic_vector(2 downto 0);  -- input pixel data (3bpp)
            in_p2    : in  std_logic_vector(2 downto 0);  -- input pixel data (2nd line for scan doubling) (3bpp)

            out_clk  : in  std_logic;                     -- output pixel clock
            out_rst  : in  std_logic;                     -- output pixel clock sychronous reset
            vtg_vs   : in  std_logic;                     -- video timing generator: vertical sync
            vtg_hs   : in  std_logic;                     -- video timing generator: horizontal sync
            vtg_de   : in  std_logic;                     -- video timing generator: display enable
            vtg_ax   : in  std_logic_vector(11 downto 0); -- video timing generator: active area X
            vtg_ay   : in  std_logic_vector(11 downto 0); -- video timing generator: active area Y
            vga_vs   : out std_logic;                     -- VGA output: vertical sync
            vga_hs   : out std_logic;                     -- VGA output: horizontal sync
            vga_de   : out std_logic;                     -- VGA output: display enable
            vga_r    : out std_logic_vector(7 downto 0);  -- VGA output: pixel data, red channel
            vga_g    : out std_logic_vector(7 downto 0);  -- VGA output: pixel data, green channel
            vga_b    : out std_logic_vector(7 downto 0)   -- VGA output: pixel data, blue channel

        );
    end component otus_upscale;

end package otus_upscale_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.tyto_types_pkg.all;
use work.sync_reg_pkg.all;
use work.ram_tdp_ar_pkg.all;

entity otus_upscale is
    generic (
        v_ovr         : integer := 0;                 -- top/bottom overscan in video lines
        h_ovr         : integer := 0;                 -- left/right overscan in 1MHz / 40 column character cells
        ram_size_log2 : integer := 15                 -- ram size (32k)
    );
    port (

        in_clk   : in  std_logic;                     -- input pixel clock (48MHz)
        in_clken : in  std_logic;                     -- input pixel clock enable (16/12MHz)
        in_rst   : in  std_logic;                     -- input pixel clock sychronous reset
        in_ttx   : in  std_logic;                     -- input format (1 = teletext/scan doubled, 0 = graphics/text)
        in_vrst  : in  std_logic;                     -- input vertical reset (asynchronous)
        in_pe    : in  std_logic;                     -- input pixel enable
        in_p     : in  std_logic_vector(2 downto 0);  -- input pixel data (3bpp)
        in_p2    : in  std_logic_vector(2 downto 0);  -- input pixel data (2nd line for scan doubling) (3bpp)

        out_clk  : in  std_logic;                     -- output pixel clock
        out_rst  : in  std_logic;                     -- output pixel clock sychronous reset
        vtg_vs   : in  std_logic;                     -- video timing generator: vertical sync
        vtg_hs   : in  std_logic;                     -- video timing generator: horizontal sync
        vtg_de   : in  std_logic;                     -- video timing generator: display enable
        vtg_ax   : in  std_logic_vector(11 downto 0); -- video timing generator: active area X
        vtg_ay   : in  std_logic_vector(11 downto 0); -- video timing generator: active area Y
        vga_vs   : out std_logic;                     -- VGA output: vertical sync
        vga_hs   : out std_logic;                     -- VGA output: horizontal sync
        vga_de   : out std_logic;                     -- VGA output: display enable
        vga_r    : out std_logic_vector(7 downto 0);  -- VGA output: pixel data, red channel
        vga_g    : out std_logic_vector(7 downto 0);  -- VGA output: pixel data, green channel
        vga_b    : out std_logic_vector(7 downto 0)   -- VGA output: pixel data, blue channel

    );
end entity otus_upscale;

architecture synth of otus_upscale is

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

    signal vga_p      : slv_7_0_t(0 to 2);

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
    --  ax   |  raddr | ram_rd | f1 | f2 |  vga_r   |
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
    --  ax   |  raddr | ram_rd | f1 | f2 | vga_r |
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
                vga_vs    <= '0';
                vga_hs    <= '0';
                vga_de    <= '0';
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
                vga_vs <= vtg_vs_r(2);
                vga_hs <= vtg_hs_r(2);
                vga_de <= vtg_de_r(2);
                for i in 0 to 2 loop
                    case f(i) is
                        when "00" => vga_p(i) <= x"00";
                        when "01" => vga_p(i) <= x"55";
                        when "10" => vga_p(i) <= x"AA";
                        when others => vga_p(i) <= x"FF";
                    end case;
                end loop;
                if vis_r(2) = '0' then
                    vga_p <= (others => (others => '0'));
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
    vga_r <= vga_p(0);
    vga_g <= vga_p(1);
    vga_b <= vga_p(2);

    -- 32k x 3 dual port RAM, seperate clocks

    RAM: component ram_tdp_ar
        generic map (
            width      => 3,
            depth_log2 => ram_size_log2
        )
        port map (
            clk_a  => in_clk,
            rst_a  => '0',
            ce_a   => '1',
            we_a   => ram_we,
            addr_a => ram_wa,
            din_a  => ram_wd,
            dout_a => open,
            clk_b  => out_clk,
            rst_b  => '0',
            ce_b   => '1',
            we_b   => '0',
            addr_b => ram_ra,
            din_b  => (others => '0'),
            dout_b => ram_rd
        );

end architecture synth;
