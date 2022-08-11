--------------------------------------------------------------------------------
-- bpp_kbd_bbc_pkg.vhd                                                        --
-- BPP keyboard definitions for the original BBC micro model B.               --
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

package bpp_kbd_bbc_pkg is

    -- BBC micro model A/B keyboard matrix (c3..c0,r2..r0)

    constant BBC_Shift                        : std_logic_vector(6 downto 0) := "0000000";
    constant BBC_Q                            : std_logic_vector(6 downto 0) := "0000001";
    constant BBC_F0                           : std_logic_vector(6 downto 0) := "0000010";
    constant BBC_1_ExclamationMark            : std_logic_vector(6 downto 0) := "0000011";
    constant BBC_CapsLock                     : std_logic_vector(6 downto 0) := "0000100";
    constant BBC_ShiftLock                    : std_logic_vector(6 downto 0) := "0000101";
    constant BBC_Tab                          : std_logic_vector(6 downto 0) := "0000110";
    constant BBC_Escape                       : std_logic_vector(6 downto 0) := "0000111";
    constant BBC_Ctrl                         : std_logic_vector(6 downto 0) := "0001000";
    constant BBC_3_Hash                       : std_logic_vector(6 downto 0) := "0001001";
    constant BBC_W                            : std_logic_vector(6 downto 0) := "0001010";
    constant BBC_2_DoubleQuote                : std_logic_vector(6 downto 0) := "0001011";
    constant BBC_A                            : std_logic_vector(6 downto 0) := "0001100";
    constant BBC_S                            : std_logic_vector(6 downto 0) := "0001101";
    constant BBC_Z                            : std_logic_vector(6 downto 0) := "0001110";
    constant BBC_F1                           : std_logic_vector(6 downto 0) := "0001111";
    constant BBC_SW2_8                        : std_logic_vector(6 downto 0) := "0010000";
    constant BBC_4_Dollar                     : std_logic_vector(6 downto 0) := "0010001";
    constant BBC_E                            : std_logic_vector(6 downto 0) := "0010010";
    constant BBC_D                            : std_logic_vector(6 downto 0) := "0010011";
    constant BBC_X                            : std_logic_vector(6 downto 0) := "0010100";
    constant BBC_C                            : std_logic_vector(6 downto 0) := "0010101";
    constant BBC_Space                        : std_logic_vector(6 downto 0) := "0010110";
    constant BBC_F2                           : std_logic_vector(6 downto 0) := "0010111";
    constant BBC_SW2_7                        : std_logic_vector(6 downto 0) := "0011000";
    constant BBC_5_Percent                    : std_logic_vector(6 downto 0) := "0011001";
    constant BBC_T                            : std_logic_vector(6 downto 0) := "0011010";
    constant BBC_R                            : std_logic_vector(6 downto 0) := "0011011";
    constant BBC_F                            : std_logic_vector(6 downto 0) := "0011100";
    constant BBC_G                            : std_logic_vector(6 downto 0) := "0011101";
    constant BBC_V                            : std_logic_vector(6 downto 0) := "0011110";
    constant BBC_F3                           : std_logic_vector(6 downto 0) := "0011111";
    constant BBC_SW2_6                        : std_logic_vector(6 downto 0) := "0100000";
    constant BBC_F4                           : std_logic_vector(6 downto 0) := "0100001";
    constant BBC_7_Apostrophe                 : std_logic_vector(6 downto 0) := "0100010";
    constant BBC_6_Ampersand                  : std_logic_vector(6 downto 0) := "0100011";
    constant BBC_Y                            : std_logic_vector(6 downto 0) := "0100100";
    constant BBC_H                            : std_logic_vector(6 downto 0) := "0100101";
    constant BBC_B                            : std_logic_vector(6 downto 0) := "0100110";
    constant BBC_F5                           : std_logic_vector(6 downto 0) := "0100111";
    constant BBC_SW2_5                        : std_logic_vector(6 downto 0) := "0101000";
    constant BBC_8_LRoundBracket              : std_logic_vector(6 downto 0) := "0101001";
    constant BBC_I                            : std_logic_vector(6 downto 0) := "0101010";
    constant BBC_U                            : std_logic_vector(6 downto 0) := "0101011";
    constant BBC_J                            : std_logic_vector(6 downto 0) := "0101100";
    constant BBC_N                            : std_logic_vector(6 downto 0) := "0101101";
    constant BBC_M                            : std_logic_vector(6 downto 0) := "0101110";
    constant BBC_F6                           : std_logic_vector(6 downto 0) := "0101111";
    constant BBC_SW2_4                        : std_logic_vector(6 downto 0) := "0110000";
    constant BBC_F7                           : std_logic_vector(6 downto 0) := "0110001";
    constant BBC_9_RRoundBracket              : std_logic_vector(6 downto 0) := "0110010";
    constant BBC_O                            : std_logic_vector(6 downto 0) := "0110011";
    constant BBC_K                            : std_logic_vector(6 downto 0) := "0110100";
    constant BBC_L                            : std_logic_vector(6 downto 0) := "0110101";
    constant BBC_Comma_LessThan               : std_logic_vector(6 downto 0) := "0110110";
    constant BBC_F8                           : std_logic_vector(6 downto 0) := "0110111";
    constant BBC_SW2_3                        : std_logic_vector(6 downto 0) := "0111000";
    constant BBC_Minus_Equal                  : std_logic_vector(6 downto 0) := "0111001";
    constant BBC_0                            : std_logic_vector(6 downto 0) := "0111010";
    constant BBC_P                            : std_logic_vector(6 downto 0) := "0111011";
    constant BBC_At                           : std_logic_vector(6 downto 0) := "0111100";
    constant BBC_SemiColon_Plus               : std_logic_vector(6 downto 0) := "0111101";
    constant BBC_Period_GreaterThan           : std_logic_vector(6 downto 0) := "0111110";
    constant BBC_F9                           : std_logic_vector(6 downto 0) := "0111111";
    constant BBC_SW2_2                        : std_logic_vector(6 downto 0) := "1000000";
    constant BBC_Caret_Tilde                  : std_logic_vector(6 downto 0) := "1000001";
    constant BBC_Underscore_Pound             : std_logic_vector(6 downto 0) := "1000010";
    constant BBC_LSquareBracket_LCurlyBracket : std_logic_vector(6 downto 0) := "1000011";
    constant BBC_Colon_Asterisk               : std_logic_vector(6 downto 0) := "1000100";
    constant BBC_RSquareBracket_RCurlyBracket : std_logic_vector(6 downto 0) := "1000101";
    constant BBC_Slash_QuestionMark           : std_logic_vector(6 downto 0) := "1000110";
    constant BBC_BackSlash_BrokenBar          : std_logic_vector(6 downto 0) := "1000111";
    constant BBC_SW2_1                        : std_logic_vector(6 downto 0) := "1001000";
    constant BBC_LeftArrow                    : std_logic_vector(6 downto 0) := "1001001";
    constant BBC_DownArrow                    : std_logic_vector(6 downto 0) := "1001010";
    constant BBC_UpArrow                      : std_logic_vector(6 downto 0) := "1001011";
    constant BBC_Return                       : std_logic_vector(6 downto 0) := "1001100";
    constant BBC_Delete                       : std_logic_vector(6 downto 0) := "1001101";
    constant BBC_Copy                         : std_logic_vector(6 downto 0) := "1001110";
    constant BBC_RightArrow                   : std_logic_vector(6 downto 0) := "1001111";

end package bpp_kbd_bbc_pkg;
