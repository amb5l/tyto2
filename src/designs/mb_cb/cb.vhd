--------------------------------------------------------------------------------
-- cb.vhd                                                                     --
-- Character buffer subsystem for mb_cb design.                               --
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

package cb_pkg is

    component cb is
        port (

            cpu_clk  : in  std_logic;
            cpu_en   : in  std_logic;
            cpu_we   : in  std_logic_vector(3 downto 0);
            cpu_addr : in  std_logic_vector(15 downto 0);
            cpu_din  : in  std_logic_vector(31 downto 0);
            cpu_dout : out std_logic_vector(31 downto 0);

            pix_clk  : in  std_logic;
            pix_rst  : in  std_logic;

            pal_ntsc : in  std_logic;
            border   : in  std_logic_vector(3 downto 0);

            vga_vs   : out std_logic;                      -- vertical sync
            vga_hs   : out std_logic;                      -- horizontal sync
            vga_de   : out std_logic;                      -- display enable
            vga_r    : out std_logic_vector(7 downto 0);   -- red
            vga_g    : out std_logic_vector(7 downto 0);   -- green
            vga_b    : out std_logic_vector(7 downto 0)    -- blue

        );
    end component cb;

end package cb_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sync_reg_pkg.all;
use work.ram_tdp_ar_2kx32_4kx16_pkg.all;
use work.char_rom_437_8x16_pkg.all;
use work.video_out_timing_pkg.all;

entity cb is
    port (

        cpu_clk  : in  std_logic;
        cpu_en   : in  std_logic;
        cpu_we   : in  std_logic_vector(3 downto 0);
        cpu_addr : in  std_logic_vector(15 downto 0);
        cpu_din  : in  std_logic_vector(31 downto 0);
        cpu_dout : out std_logic_vector(31 downto 0);

        pix_clk  : in  std_logic;
        pix_rst  : in  std_logic;

        pal_ntsc : in  std_logic;
        border   : in  std_logic_vector(3 downto 0);

        vga_vs   : out std_logic;                      -- vertical sync
        vga_hs   : out std_logic;                      -- horizontal sync
        vga_de   : out std_logic;                      -- display enable
        vga_r    : out std_logic_vector(7 downto 0);   -- red
        vga_g    : out std_logic_vector(7 downto 0);   -- green
        vga_b    : out std_logic_vector(7 downto 0)    -- blue

    );
end entity cb;

architecture synth of cb is

    signal pal_ntsc_s      : std_logic;                      -- synchronised
    signal border_s        : std_logic_vector(3 downto 0);   -- "

    signal vtg_v_tot       : std_logic_vector(10 downto 0);  -- vertical total lines (must be odd if interlaced)
    signal vtg_v_act       : std_logic_vector(10 downto 0);  -- vertical active lines
    signal vtg_v_sync      : std_logic_vector(2 downto 0);   -- vertical sync width
    signal vtg_v_bp        : std_logic_vector(5 downto 0);   -- vertical back porch
    signal vtg_h_tot       : std_logic_vector(11 downto 0);  -- horizontal total
    signal vtg_h_act       : std_logic_vector(10 downto 0);  -- horizontal active
    signal vtg_h_sync      : std_logic_vector(6 downto 0);   -- horizontal sync width
    signal vtg_h_bp        : std_logic_vector(7 downto 0);   -- horizontal back porch
    signal vtg_f           : std_logic;                      -- field ID in
    signal vtg_vs          : std_logic;                      -- vertical sync in
    signal vtg_hs          : std_logic;                      -- horizontal sync in
    signal vtg_vblank      : std_logic;                      -- vertical blanking in
    signal vtg_hblank      : std_logic;                      -- horizontal blanking in
    signal vtg_ax          : std_logic_vector(11 downto 0);  -- active area x position in
    signal vtg_ay          : std_logic_vector(11 downto 0);  -- active area y position in

    signal vtg_v_vis       : std_logic;                      -- } visible region is
    signal vtg_h_vis       : std_logic;                      -- }  subset of active area

    signal char_buf_addr    : std_logic_vector(12 downto 1); -- 4k x 16
    signal char_buf_data    : std_logic_vector(15 downto 0); -- attribute + character code
    alias  char_buf_code    : std_logic_vector(7 downto 0) is char_buf_data(7 downto 0);
    alias  char_buf_attr    : std_logic_vector(7 downto 0) is char_buf_data(15 downto 8);

    signal char_rom_row     : std_logic_vector(3 downto 0);
    signal char_rom_data    : std_logic_vector(7 downto 0);

    signal char_sr          : std_logic_vector(7 downto 0);
    signal char_attr        : std_logic_vector(7 downto 0);

begin

    SYNC: component sync_reg
        generic map (
            width         => 5,
            depth         => 2
        )
        port map (
            clk           => pix_clk,
            d(3 downto 0) => border,
            d(4)          => pal_ntsc,
            q(3 downto 0) => border_s,
            q(4)          => pal_ntsc_s
        );

    -- main process

    -- 5 clock pipeline:
    -- ax,ay
    -- char_buf_addr
    -- char_buf_data => char_rom_addr
    -- char_rom_data
    -- shift reg, attr, vis
    -- output

    process(pix_clk)

        -- CGA palette
        function cga(c : std_logic_vector(3 downto 0)) return std_logic_vector is
            variable bgr : std_logic_vector(23 downto 0);
        begin
            case c is
                when x"0" => bgr := std_logic_vector'(x"000000");
                when x"1" => bgr := std_logic_vector'(x"AA0000");
                when x"2" => bgr := std_logic_vector'(x"00AA00");
                when x"3" => bgr := std_logic_vector'(x"AAAA00");
                when x"4" => bgr := std_logic_vector'(x"0000AA");
                when x"5" => bgr := std_logic_vector'(x"AA00AA");
                when x"6" => bgr := std_logic_vector'(x"0055AA");
                when x"7" => bgr := std_logic_vector'(x"AAAAAA");
                when x"8" => bgr := std_logic_vector'(x"555555");
                when x"9" => bgr := std_logic_vector'(x"FF5555");
                when x"A" => bgr := std_logic_vector'(x"55FF55");
                when x"B" => bgr := std_logic_vector'(x"FFFF55");
                when x"C" => bgr := std_logic_vector'(x"5555FF");
                when x"D" => bgr := std_logic_vector'(x"FF55FF");
                when x"E" => bgr := std_logic_vector'(x"55FFFF");
                when x"F" => bgr := std_logic_vector'(x"FFFFFF");
            end case;
            return bgr;
        end function cga;

        variable cx : unsigned(6 downto 0);  -- 80 columns
        variable cy : unsigned(4 downto 0);  -- 25 or 32 rows
        variable a  : unsigned(11 downto 0); -- 4k x 16

    begin
        if rising_edge(pix_clk) then
            if pix_rst = '1' then

                char_buf_addr <= (others => '0');
                char_rom_row  <= (others => '0');
                char_sr       <= (others => '0');
                char_attr     <= (others => '0');
                vtg_v_vis     <= '0';
                vtg_h_vis     <= '0';
                vga_vs        <= '0';
                vga_hs        <= '0';
                vga_de        <= '0';
                vga_r         <= (others => '0');
                vga_g         <= (others => '0');
                vga_b         <= (others => '0');

            else

                -- character buffer address
                cx := (shift_right(unsigned(vtg_ax)-75,4)(6 downto 0));    -- adjust for start pos, 5 clocks ahead, divide by char width (16 px)                
                if pal_ntsc_s = '1' then
                    cy := shift_right(unsigned(vtg_ay) - 32,4)(4 downto 0);  -- adjust for start pos, divide by char height (16) (80x32, 576i)
                else
                    cy := shift_right(unsigned(vtg_ay) - 40,4)(4 downto 0);  -- adjust for start pos, divide by char height (16) (80x25, 480i)
                end if;
                a := shift_left(resize(cy,a'length),6)
                    + shift_left(resize(cy,a'length),4)
                    + resize(cx,a'length); -- a = (y*80) + x
                char_buf_addr <= std_logic_vector(a);

                -- character row
                char_rom_row <= vtg_ay(3 downto 0) xor (not pal_ntsc_s) & "000";

                -- shift/load
                if vtg_ax(0) = '0' then
                    char_sr <= char_sr(6 downto 0) & '0';
                end if;
                if vtg_ax(3 downto 0) = "1110" then
                    char_sr <= char_rom_data;
                    char_attr <= char_buf_attr;
                end if;

                -- visible region
                if vtg_vs = '1' then
                    vtg_v_vis <= '0';
                    vtg_h_vis <= '0';
                end if;
                if pal_ntsc_s = '1' then
                    if to_integer(unsigned(vtg_ay)) = 32
                    or to_integer(unsigned(vtg_ay)) = 33
                    then
                        vtg_v_vis <= '1';
                    elsif to_integer(unsigned(vtg_ay)) = 544
                    or to_integer(unsigned(vtg_ay)) = 545 then
                        vtg_v_vis <= '0';
                    end if;
                else
                    if to_integer(unsigned(vtg_ay)) = 40
                    or to_integer(unsigned(vtg_ay)) = 41
                    then
                        vtg_v_vis <= '1';
                    elsif to_integer(unsigned(vtg_ay)) = 440
                    or to_integer(unsigned(vtg_ay)) = 441 then
                        vtg_v_vis <= '0';
                    end if;
                end if;
                if to_integer(unsigned(vtg_ax)) = 78 then
                    vtg_h_vis <= '1';
                elsif to_integer(unsigned(vtg_ax)) = 78+1280 then
                    vtg_h_vis <= '0';
                end if;

                -- outputs
                vga_vs <= vtg_vs;
                vga_hs <= vtg_hs;
                vga_de <= vtg_vblank nor vtg_hblank;
                vga_r  <= (others => '0');
                vga_g  <= (others => '0');
                vga_b  <= (others => '0');
                if vtg_vblank = '0' and vtg_hblank = '0' then
                    if vtg_v_vis = '1' and vtg_h_vis = '1' then
                        if char_sr(7) = '1' then -- character foreground colour
                            vga_r <= cga(char_attr(3 downto 0))(7 downto 0);
                            vga_g <= cga(char_attr(3 downto 0))(15 downto 8);
                            vga_b <= cga(char_attr(3 downto 0))(23 downto 16);
                        else -- character background colour
                            vga_r <= cga(char_attr(7 downto 4))(7 downto 0);
                            vga_g <= cga(char_attr(7 downto 4))(15 downto 8);
                            vga_b <= cga(char_attr(7 downto 4))(23 downto 16);
                        end if;
                    else -- border colour
                        vga_r <= cga(border_s)(7 downto 0);
                        vga_g <= cga(border_s)(15 downto 8);
                        vga_b <= cga(border_s)(23 downto 16);
                    end if;
                end if;

            end if;
        end if;
    end process;

    -- 8kByte character buffer; 2k x 32 on CPU port, 4k x 16 on display port

    RAM: component ram_tdp_ar_2kx32_4kx16
        port map (
            clk_a  => cpu_clk,
            clr_a  => '0',
            en_a   => cpu_en,
            we_a   => cpu_we,
            addr_a => cpu_addr(12 downto 2),
            din_a  => cpu_din,
            dout_a => cpu_dout,
            clk_b  => pix_clk,
            clr_b  => '0',
            en_b   => '1',
            we_b   => (others => '0'),
            addr_b => char_buf_addr,
            din_b  => (others => '0'),
            dout_b => char_buf_data
        );

    -- character ROM (256 patterns x 8 pixels wide x 16 rows high)

    CHAR_ROM: component char_rom_437_8x16
        port map (
            clk     => pix_clk,
            r       => char_rom_row,    -- character row (scan line) (0..15)
            a       => char_buf_code,   -- character code (0..255)
            d       => char_rom_data    -- character row data (8 pixels)
        );

    -- video timing generator
    -- note: pixels are repeated => h values are doubled

    process(pal_ntsc_s)
    begin
        if pal_ntsc_s = '1' then -- 720 x 576 @ 50Hz interlaced
            vtg_v_tot  <= std_logic_vector(to_unsigned(625,vtg_v_tot'length));
            vtg_v_sync <= std_logic_vector(to_unsigned(3,vtg_v_sync'length));
            vtg_v_bp   <= std_logic_vector(to_unsigned(19,vtg_v_bp'length));
            vtg_v_act  <= std_logic_vector(to_unsigned(576,vtg_v_act'length));
            vtg_h_tot  <= std_logic_vector(to_unsigned(2*864,vtg_h_tot'length));
            vtg_h_sync <= std_logic_vector(to_unsigned(2*63,vtg_h_sync'length));
            vtg_h_bp   <= std_logic_vector(to_unsigned(2*69,vtg_h_bp'length));
            vtg_h_act  <= std_logic_vector(to_unsigned(2*720,vtg_h_act'length));
        else -- 720 x 480 @ 59.94Hz interlaced
            vtg_v_tot  <= std_logic_vector(to_unsigned(525,vtg_v_tot'length));
            vtg_v_sync <= std_logic_vector(to_unsigned(3,vtg_v_sync'length));
            vtg_v_bp   <= std_logic_vector(to_unsigned(15,vtg_v_bp'length));
            vtg_v_act  <= std_logic_vector(to_unsigned(480,vtg_v_act'length));
            vtg_h_tot  <= std_logic_vector(to_unsigned(2*858,vtg_h_tot'length));
            vtg_h_sync <= std_logic_vector(to_unsigned(2*62,vtg_h_sync'length));
            vtg_h_bp   <= std_logic_vector(to_unsigned(2*57,vtg_h_bp'length));
            vtg_h_act  <= std_logic_vector(to_unsigned(2*720,vtg_h_act'length));
        end if;
    end process;

    VTG: component video_out_timing
        port map (
            clk       => pix_clk,
            rst       => pix_rst,
            pix_rep   => '1',
            interlace => '1',
            v_tot     => vtg_v_tot,
            v_act     => vtg_v_act,
            v_sync    => vtg_v_sync,
            v_bp      => vtg_v_bp,
            h_tot     => vtg_h_tot,
            h_act     => vtg_h_act,
            h_sync    => vtg_h_sync,
            h_bp      => vtg_h_bp,
            genlock   => '0',
            genlocked => open,
            f         => vtg_f,
            vs        => vtg_vs,
            hs        => vtg_hs,
            vblank    => vtg_vblank,
            hblank    => vtg_hblank,
            ax        => vtg_ax,
            ay        => vtg_ay
        );

end architecture synth;
