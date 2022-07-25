--------------------------------------------------------------------------------
-- tb_saa5050d.vhd                                                            --
-- Simulation testbench for saa5050d.vhd.                                     --
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
use ieee.numeric_std.all;

library std;
use std.env.finish;

library work;
use work.sim_video_out_pkg.all;
use work.saa5050d_pkg.all;
use work.hd6845_pkg.all;

entity tb_saa5050d is
end entity tb_saa5050d;

architecture sim of tb_saa5050d is

    signal clk       : std_logic;                     -- base clock (12MHz)
    signal clk_count : integer range 0 to 11 := 0;    -- base clock divide counter

    signal pix_clk   : std_logic;                     -- pixel clock (12MHz)
    signal pix_rst   : std_logic;                     -- pixel reset

    signal reg_clk   : std_logic;                     -- CRTC register clock (2MHz)
    signal reg_rst   : std_logic;                     -- CRTC register reset
    signal reg_we    : std_logic;                     -- CRTC register write enable
    signal reg_rs    : std_logic;                     -- CRTC register select
    signal reg_dw    : std_logic_vector(7 downto 0);  -- CRTC register write data

    signal crt_clk   : std_logic;                     -- CRTC video (character) clock (1MHz)
    signal crt_rst   : std_logic;                     -- CRTC video reset
    signal crt_ma    : std_logic_vector(13 downto 0); -- CRTC memory address
    signal crt_ra    : std_logic_vector(4 downto 0);  -- CRTC raster (scan line) address within character
    signal crt_vs    : std_logic;                     -- CRTC vertical sync
    signal crt_hs    : std_logic;                     -- CRTC horizontal blank
    signal crt_vb    : std_logic;                     -- CRTC vertical blank
    signal crt_hb    : std_logic;                     -- CRTC horizontal blank
    signal crt_de    : std_logic;                     -- CRTC display enable

    signal ttx_chr   : std_logic_vector(6 downto 0);  -- character code (0..127)
    signal ttx_pixu  : std_logic_vector(2 downto 0);  -- pixel (3 bit BGR) (12 pixels per character) (upper line)
    signal ttx_pixl  : std_logic_vector(2 downto 0);  -- pixel (3 bit BGR) (12 pixels per character) (lower line)
    signal ttx_pixen : std_logic;                     -- pixel enable

    signal crt_hs_1  : std_logic;                     -- CRTC horizontal sync, delayed by 1 clock
    signal frame     : integer := 0;                  -- frame counter
    signal bmp       : bmp_t(0 to 479,0 to 499);      -- bitmap data
    signal x         : integer;                       -- bitmap X position
    signal y         : integer;                       -- bitmap Y position
    signal act       : boolean;                       -- video active region

    -- teletext engineering page data (1000 bytes)
    type ttx_data_t is array(0 to 999) of std_logic_vector(7 downto 0);
    constant ttx_data_engtest : ttx_data_t := (
        -- engineering test page
        X"41", X"42", X"43", X"00", X"00", X"00", X"00", X"00", X"43", X"45", X"45", X"46", X"41", X"58", X"20", X"31", X"35", X"32", X"20", X"20", X"46", X"72", X"69", X"20", X"32", X"35", X"20", X"41", X"75", X"67", X"20", X"83", X"32", X"33", X"3A", X"32", X"32", X"2F", X"32", X"34",
        X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"30", X"31",
        X"97", X"9E", X"0F", X"73", X"93", X"9A", X"96", X"1B", X"9F", X"10", X"84", X"8D", X"9D", X"83", X"45", X"4E", X"47", X"49", X"4E", X"45", X"45", X"52", X"49", X"4E", X"47", X"20", X"92", X"9C", X"8C", X"9E", X"73", X"95", X"1B", X"91", X"00", X"94", X"00", X"87", X"30", X"32",
        X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"84", X"8D", X"9D", X"83", X"45", X"4E", X"47", X"49", X"4E", X"45", X"45", X"52", X"49", X"4E", X"47", X"20", X"92", X"9C", X"8C", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"30", X"33",
        X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"30", X"34",
        X"94", X"9A", X"9E", X"73", X"91", X"99", X"95", X"00", X"81", X"00", X"81", X"95", X"8D", X"9D", X"82", X"54", X"65", X"73", X"74", X"20", X"50", X"61", X"67", X"65", X"20", X"20", X"9C", X"8C", X"9E", X"92", X"73", X"96", X"98", X"93", X"00", X"97", X"98", X"81", X"30", X"35",
        X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"95", X"8D", X"9D", X"82", X"54", X"65", X"73", X"74", X"20", X"50", X"61", X"67", X"65", X"20", X"20", X"9C", X"8C", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"30", X"36",
        X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"9E", X"97", X"2C", X"93", X"2C", X"96", X"2C", X"92", X"2C", X"2C", X"95", X"2C", X"91", X"2C", X"94", X"2C", X"81", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"30", X"37",
        X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"30", X"38",
        X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"30", X"39",
        X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"31", X"30",
        X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"31", X"31",
        X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"31", X"32",
        X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"31", X"33",
        X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"31", X"34",
        X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"01", X"00", X"31", X"35",
        X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"7E", X"7F", X"31", X"36",
        X"57", X"68", X"69", X"74", X"65", X"83", X"59", X"65", X"6C", X"6C", X"6F", X"77", X"86", X"43", X"79", X"61", X"6E", X"82", X"47", X"72", X"65", X"65", X"6E", X"85", X"4D", X"61", X"67", X"65", X"6E", X"74", X"61", X"81", X"52", X"65", X"64", X"84", X"42", X"6C", X"75", X"65",
        X"97", X"9A", X"21", X"22", X"23", X"93", X"24", X"25", X"26", X"27", X"96", X"28", X"29", X"2A", X"2B", X"92", X"2C", X"2D", X"2E", X"2F", X"99", X"30", X"31", X"32", X"33", X"95", X"34", X"35", X"36", X"37", X"91", X"38", X"39", X"3A", X"3B", X"94", X"3C", X"3D", X"3E", X"3F",
        X"20", X"20", X"21", X"22", X"23", X"20", X"24", X"25", X"26", X"27", X"20", X"28", X"29", X"2A", X"2B", X"20", X"2C", X"2D", X"2E", X"2F", X"20", X"30", X"31", X"32", X"33", X"20", X"34", X"35", X"36", X"37", X"20", X"38", X"39", X"3A", X"3B", X"20", X"3C", X"3D", X"3E", X"3F",
        X"20", X"40", X"41", X"42", X"43", X"20", X"44", X"45", X"46", X"47", X"20", X"48", X"49", X"4A", X"4B", X"20", X"4C", X"4D", X"4E", X"4F", X"20", X"50", X"51", X"52", X"53", X"20", X"54", X"55", X"56", X"57", X"20", X"58", X"59", X"5A", X"5B", X"20", X"5C", X"5D", X"5E", X"5F",
        X"20", X"60", X"61", X"62", X"63", X"20", X"64", X"65", X"66", X"67", X"20", X"68", X"69", X"6A", X"6B", X"20", X"6C", X"6D", X"6E", X"6F", X"20", X"70", X"71", X"72", X"73", X"20", X"74", X"75", X"76", X"77", X"20", X"78", X"79", X"7A", X"7B", X"20", X"7C", X"7D", X"7E", X"7F",
        X"94", X"60", X"61", X"62", X"63", X"91", X"64", X"65", X"66", X"67", X"95", X"68", X"69", X"6A", X"6B", X"92", X"6C", X"6D", X"6E", X"6F", X"9A", X"70", X"71", X"72", X"73", X"96", X"74", X"75", X"76", X"77", X"93", X"78", X"79", X"7A", X"7B", X"97", X"7C", X"7D", X"7E", X"7F",
        X"83", X"98", X"43", X"6F", X"6E", X"63", X"65", X"61", X"6C", X"88", X"46", X"6C", X"61", X"73", X"68", X"83", X"2A", X"8B", X"8B", X"42", X"6F", X"78", X"89", X"53", X"74", X"65", X"61", X"64", X"79", X"98", X"47", X"6F", X"6E", X"65", X"8A", X"8A", X"3F", X"86", X"5E", X"7F",
        X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20"
    );
    constant ttx_data_scarybeasts : ttx_data_t := (
        -- scarybeasts test page
        X"3E", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"56", X"31", X"2E", X"33",
        X"53", X"45", X"50", X"41", X"52", X"41", X"54", X"45", X"44", X"20", X"47", X"4C", X"59", X"50", X"48", X"20", X"53", X"48", X"4F", X"55", X"4C", X"44", X"20", X"4E", X"4F", X"54", X"20", X"54", X"4F", X"55", X"43", X"48", X"20", X"42", X"4C", X"4F", X"43", X"4B", X"20", X"20",
        X"91", X"9E", X"FF", X"9A", X"FF", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"46", X"4F", X"52", X"45", X"47", X"52", X"4F", X"55", X"4E", X"44", X"20", X"43", X"4F", X"4C", X"4F", X"52", X"20", X"49", X"53", X"20", X"53", X"45", X"54", X"2D", X"41", X"46", X"54", X"45", X"52", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"92", X"9E", X"FF", X"93", X"94", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"42", X"47", X"2D", X"3E", X"46", X"47", X"20", X"49", X"53", X"20", X"53", X"45", X"54", X"2D", X"41", X"54", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"94", X"9D", X"95", X"9E", X"FF", X"98", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"41", X"53", X"43", X"49", X"49", X"20", X"44", X"4F", X"45", X"53", X"20", X"4E", X"4F", X"54", X"20", X"41", X"46", X"46", X"45", X"43", X"54", X"20", X"48", X"45", X"4C", X"44", X"20", X"43", X"48", X"41", X"52", X"41", X"43", X"54", X"45", X"52", X"20", X"20", X"20", X"20",
        X"96", X"9E", X"FF", X"41", X"96", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"48", X"4F", X"4C", X"44", X"20", X"4F", X"4E", X"20", X"53", X"45", X"54", X"2D", X"41", X"54", X"2C", X"20", X"48", X"4F", X"4C", X"44", X"20", X"4F", X"46", X"46", X"20", X"53", X"45", X"54", X"2D", X"41", X"46", X"54", X"45", X"52", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"FF", X"9E", X"9F", X"9F", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"43", X"4C", X"45", X"41", X"52", X"20", X"48", X"45", X"4C", X"44", X"20", X"43", X"48", X"41", X"52", X"41", X"43", X"54", X"45", X"52", X"20", X"5F", X"31", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"91", X"FF", X"9E", X"81", X"81", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"43", X"4C", X"45", X"41", X"52", X"20", X"48", X"45", X"4C", X"44", X"20", X"43", X"48", X"41", X"52", X"41", X"43", X"54", X"45", X"52", X"20", X"5F", X"32", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"92", X"FF", X"92", X"9E", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"43", X"4C", X"45", X"41", X"52", X"20", X"48", X"45", X"4C", X"44", X"20", X"43", X"48", X"41", X"52", X"41", X"43", X"54", X"45", X"52", X"20", X"5F", X"33", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"8D", X"95", X"FF", X"9E", X"8D", X"8C", X"95", X"FF", X"9E", X"8C", X"8D", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"4D", X"49", X"53", X"53", X"49", X"4E", X"47", X"20", X"53", X"45", X"43", X"4F", X"4E", X"44", X"20", X"44", X"4F", X"55", X"42", X"4C", X"45", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"9A", X"8D", X"FF", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"9A", X"8C", X"FF", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"47", X"52", X"41", X"50", X"48", X"49", X"43", X"53", X"20", X"53", X"45", X"50", X"41", X"52", X"41", X"54", X"45", X"44", X"2F", X"43", X"4F", X"4E", X"54", X"49", X"47", X"55", X"4F", X"55", X"53", X"20", X"53", X"54", X"41", X"54", X"45", X"20", X"20", X"20", X"20", X"20",
        X"97", X"FF", X"87", X"FF", X"99", X"FF", X"9A", X"FF", X"97", X"FF", X"87", X"FF", X"97", X"FF", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20"
    );
    constant ttx_data_parrot : ttx_data_t := (
        -- parrot of doom
        X"97", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"60", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"70", X"9E", X"70", X"91", X"20", X"20", X"93", X"60", X"30", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"20", X"20", X"20", X"9E", X"91", X"78", X"93", X"9D", X"20", X"20", X"20", X"97", X"7F", X"6F", X"7F", X"9D", X"9C", X"7F", X"93", X"7C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"20", X"20", X"9E", X"91", X"2A", X"9D", X"97", X"60", X"70", X"7C", X"93", X"7F", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"97", X"9D", X"9C", X"75", X"30", X"20", X"93", X"60", X"30", X"20", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"20", X"20", X"20", X"20", X"20", X"7E", X"74", X"6A", X"7F", X"7C", X"9D", X"93", X"7F", X"9D", X"9E", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"35", X"20", X"92", X"23", X"2F", X"25", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"20", X"20", X"20", X"20", X"6A", X"7F", X"3D", X"2A", X"9D", X"20", X"20", X"93", X"9D", X"20", X"20", X"91", X"60", X"6C", X"7F", X"93", X"9E", X"97", X"9C", X"7D", X"74", X"70", X"20", X"28", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"20", X"20", X"20", X"20", X"22", X"7F", X"21", X"20", X"2A", X"9D", X"20", X"93", X"9D", X"91", X"7C", X"7D", X"70", X"20", X"7D", X"9D", X"97", X"2B", X"7F", X"33", X"22", X"6B", X"75", X"9C", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"20", X"20", X"20", X"20", X"91", X"72", X"7F", X"70", X"20", X"93", X"2B", X"9D", X"91", X"7E", X"7F", X"9D", X"9E", X"9C", X"9D", X"93", X"9D", X"9C", X"97", X"91", X"7F", X"93", X"97", X"75", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"2F", X"9E", X"25", X"60", X"9D", X"91", X"7F", X"9C", X"7D", X"7E", X"2F", X"2F", X"7F", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"92", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"63", X"30", X"91", X"7F", X"9D", X"9E", X"9C", X"76", X"25", X"23", X"20", X"20", X"6B", X"2F", X"3F", X"6B", X"7F", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"7F", X"93", X"92", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"70", X"91", X"6A", X"7F", X"9D", X"9E", X"9C", X"7F", X"75", X"6F", X"7D", X"20", X"6A", X"7F", X"6F", X"9D", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"9F", X"97", X"9C", X"3F", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"92", X"97", X"25", X"68", X"37", X"91", X"7F", X"9D", X"9E", X"9C", X"7F", X"30", X"20", X"2A", X"7F", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"94", X"97", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"92", X"97", X"6A", X"7E", X"91", X"7F", X"9E", X"77", X"27", X"21", X"2F", X"7D", X"60", X"7F", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"94", X"92", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"92", X"21", X"91", X"25", X"9D", X"92", X"91", X"9E", X"9C", X"20", X"20", X"20", X"7A", X"7F", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"9D", X"9C", X"30", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"92", X"7F", X"91", X"6A", X"9D", X"93", X"30", X"20", X"34", X"9C", X"20", X"91", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"37", X"7F", X"21", X"22", X"2F", X"92", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"22", X"91", X"6F", X"9D", X"20", X"20", X"93", X"69", X"9C", X"91", X"7A", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"7F", X"25", X"2F", X"92", X"28", X"6A", X"38", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"97", X"7A", X"91", X"7F", X"9E", X"35", X"3B", X"7F", X"25", X"20", X"7E", X"7F", X"7F", X"77", X"78", X"3B", X"2F", X"2F", X"2F", X"2F", X"27", X"23", X"20", X"92", X"22", X"20", X"93", X"24", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"22", X"2F", X"25", X"70", X"7A", X"7D", X"20", X"20", X"9E", X"91", X"9D", X"97", X"78", X"75", X"7F", X"9C", X"70", X"20", X"68", X"78", X"20", X"20", X"20", X"70", X"91", X"20", X"20", X"93", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"22", X"62", X"30", X"91", X"6B", X"7F", X"34", X"97", X"60", X"70", X"7C", X"7F", X"9E", X"7F", X"22", X"37", X"20", X"9F", X"22", X"28", X"96", X"23", X"22", X"2F", X"6F", X"7F", X"7C", X"93", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"93", X"6F", X"22", X"35", X"6A", X"20", X"97", X"71", X"7E", X"7F", X"9E", X"3F", X"27", X"21", X"20", X"20", X"2D", X"60", X"20", X"20", X"20", X"20", X"20", X"20", X"92", X"60", X"96", X"23", X"93", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"20", X"20", X"20", X"6A", X"7D", X"7E", X"7F", X"3F", X"27", X"91", X"6A", X"6A", X"94", X"60", X"20", X"20", X"70", X"20", X"20", X"20", X"20", X"20", X"92", X"22", X"6B", X"35", X"23", X"25", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"92", X"9E", X"97", X"78", X"7F", X"96", X"3F", X"27", X"20", X"9F", X"91", X"6A", X"7A", X"97", X"6A", X"7F", X"6E", X"35", X"91", X"30", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"9E", X"97", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"61", X"7E", X"3F", X"7F", X"27", X"20", X"20", X"20", X"20", X"91", X"7A", X"7F", X"97", X"6A", X"7F", X"3F", X"91", X"6A", X"25", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"9E", X"97", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"97", X"7F", X"7F", X"3F", X"91", X"75", X"6B", X"20", X"20", X"20", X"20", X"7F", X"9E", X"97", X"60", X"3F", X"91", X"7F", X"92", X"2F", X"23", X"20", X"20", X"20", X"20", X"20", X"20", X"9F", X"97", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20",
        X"96", X"7F", X"27", X"20", X"91", X"37", X"3E", X"7D", X"20", X"20", X"6A", X"9D", X"9E", X"94", X"97", X"75", X"20", X"9F", X"3A", X"9C", X"20", X"20", X"20", X"92", X"2C", X"20", X"20", X"20", X"94", X"9C", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20"
    );
    signal ttx_data : ttx_data_t;

begin

    -- base clock (~12MHz)
    clk <=
        '1' after 41666ps when clk = '0' else
        '0' after 41666ps when clk = '1' else
        '0';

    process(clk)
    begin
        if rising_edge(clk) then
            clk_count <= (clk_count+1) mod 12;
        end if;
        if rising_edge(clk) then
            pix_clk <= '1';
            case clk_count is
                when 3 => reg_clk <= '1';
                when 6 => reg_clk <= '0'; crt_clk <= '1';
                when 9 => reg_clk <= '1';
                when 0 => reg_clk <= '0'; crt_clk <= '0';
                when others => null;
            end case;
        elsif falling_edge(clk) then
            pix_clk <= '0';
        end if;
    end process;

    -- main test process
    process
        procedure crtc_poke_reg(
            constant a     : in  std_logic_vector(7 downto 0);
            constant d     : in  std_logic_vector(7 downto 0);
            signal   clk   : in  std_logic;
            signal   we    : out std_logic;
            signal   rs    : out std_logic;
            signal   wdata : out std_logic_vector(7 downto 0)
        ) is
        begin
            if clk = '1' then
                wait until falling_edge(clk);
            end if;
            we <= '1';
            rs <= '0';
            wdata <= a;
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            rs <= '1';
            wdata <= d;
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            we <= '0';
            rs <= '0';
            wdata <= x"00";
        end procedure crtc_poke_reg;
    begin
        reg_rst <= '1';
        crt_rst <= '1';
        pix_rst <= '1';
        reg_we <= '0';
        reg_rs <= '0';
        reg_dw <= (others => '0');
        wait until rising_edge(reg_clk);
        wait until rising_edge(crt_clk);
        reg_rst <= '0';
        -- set up 6845 for teletext display timing
        crtc_poke_reg( x"00", x"3F", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"01", x"28", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"02", x"33", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"03", x"24", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"04", x"1E", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"05", x"02", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"06", x"19", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"07", x"1B", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"08", x"93", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"09", x"12", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0A", x"72", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0B", x"13", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0C", x"20", reg_clk, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0D", x"00", reg_clk, reg_we, reg_rs, reg_dw);
        wait until rising_edge(pix_clk);
        pix_rst <= '0';
        wait until rising_edge(crt_clk);
        crt_rst <= '0';
        wait;
    end process;

    -- teletext test data
    ttx_data <=
        ttx_data_engtest     when frame = 0 else
        ttx_data_scarybeasts when frame = 1 else
        ttx_data_parrot;
    process(crt_clk)
    begin
        if rising_edge(crt_clk) then
            ttx_chr <= (others => 'U');
            if to_integer(unsigned(crt_ma(9 downto 0))) < 1000 then
                ttx_chr <= ttx_data(to_integer(unsigned(crt_ma(9 downto 0))))(6 downto 0);
            end if;
        end if;
    end process;

    -- bitmap capture
    process(pix_clk)
    begin
        if rising_edge(pix_clk) then
            if pix_rst = '1' then
                crt_hs_1 <= '0';
                x <= 0;
                y <= 0;
            else
                if crt_vs = '1' then
                    y <= 0;
                end if;
                if crt_hs = '1' and crt_hs_1 = '0' then -- leading edge of h sync
                   x <= 0;
                    if act then
                        y <= y+2;
                    end if;
                    act <= false;
                end if;
                crt_hs_1 <= crt_hs;
                if crt_de = '1' then
                    act <= true;
                end if;
                if ttx_pixen = '1' then
                    for j in 0 to 2 loop
                        if ttx_pixu(j) = '1' then
                            bmp(x,y)(j) <= 255;
                        else
                            bmp(x,y)(j) <= 0;
                        end if;
                        if ttx_pixl(j) = '1' then
                            bmp(x,y+1)(j) <= 255;
                        else
                            bmp(x,y+1)(j) <= 0;
                        end if;
                    end loop;
                    if x = 479 and y = 498 then
                        write_bmp("tb_saa5050d", bmp, frame, 480, 500, false);
                        if frame = 2 then
                            report "*** DONE ***";
                            finish;
                        end if;
                        frame <= frame+1;
                    end if;
                    x <= x+1;
                end if;
            end if;
        end if;
    end process;

    UUT: component saa5050d
        port map (
            rsta      => '0',
            debug     => '0',
            chr_clk   => crt_clk,
            chr_clken => '1',
            chr_rst   => crt_rst,
            chr_f     => crt_ra(0),
            chr_vs    => crt_vs,
            chr_hs    => crt_hs,
            chr_gp    => crt_hb,
            chr_de    => crt_de,
            chr_d     => ttx_chr,
            pix_clk   => pix_clk,
            pix_clken => '1',
            pix_rst   => pix_rst,
            pix_du    => ttx_pixu,
            pix_dl    => ttx_pixl,
            pix_gp    => open,
            pix_de    => ttx_pixen
        );

    CRTC: component hd6845
        port map (
            reg_clk   => reg_clk,
            reg_clken => '1',
            reg_rst   => reg_rst,
            reg_cs    => '1',
            reg_we    => reg_we,
            reg_rs    => reg_rs,
            reg_dw    => reg_dw,
            reg_dr    => open,
            crt_clk   => crt_clk,
            crt_clken => '1',
            crt_rst   => crt_rst,
            crt_ma    => crt_ma,
            crt_ra    => crt_ra,
            crt_f     => open,
            crt_vs    => crt_vs,
            crt_hs    => crt_hs,
            crt_vb    => crt_vb,
            crt_hb    => crt_hb,
            crt_de    => crt_de,
            crt_cur   => open,
            crt_lps   => '0'
        );

end architecture sim;