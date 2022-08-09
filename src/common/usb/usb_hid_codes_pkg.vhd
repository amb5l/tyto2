--------------------------------------------------------------------------------
-- usb_hid_codes.vhd                                                          --
-- From USB HID Usage Tables.                                                 --
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

package usb_hid_codes_pkg is

    constant KEY_A                            : std_logic_vector(7 downto 0) := x"04";
    constant KEY_B                            : std_logic_vector(7 downto 0) := x"05";
    constant KEY_C                            : std_logic_vector(7 downto 0) := x"06";
    constant KEY_D                            : std_logic_vector(7 downto 0) := x"07";
    constant KEY_E                            : std_logic_vector(7 downto 0) := x"08";
    constant KEY_F                            : std_logic_vector(7 downto 0) := x"09";
    constant KEY_G                            : std_logic_vector(7 downto 0) := x"0a";
    constant KEY_H                            : std_logic_vector(7 downto 0) := x"0b";
    constant KEY_I                            : std_logic_vector(7 downto 0) := x"0c";
    constant KEY_J                            : std_logic_vector(7 downto 0) := x"0d";
    constant KEY_K                            : std_logic_vector(7 downto 0) := x"0e";
    constant KEY_L                            : std_logic_vector(7 downto 0) := x"0f";
    constant KEY_M                            : std_logic_vector(7 downto 0) := x"10";
    constant KEY_N                            : std_logic_vector(7 downto 0) := x"11";
    constant KEY_O                            : std_logic_vector(7 downto 0) := x"12";
    constant KEY_P                            : std_logic_vector(7 downto 0) := x"13";
    constant KEY_Q                            : std_logic_vector(7 downto 0) := x"14";
    constant KEY_R                            : std_logic_vector(7 downto 0) := x"15";
    constant KEY_S                            : std_logic_vector(7 downto 0) := x"16";
    constant KEY_T                            : std_logic_vector(7 downto 0) := x"17";
    constant KEY_U                            : std_logic_vector(7 downto 0) := x"18";
    constant KEY_V                            : std_logic_vector(7 downto 0) := x"19";
    constant KEY_W                            : std_logic_vector(7 downto 0) := x"1a";
    constant KEY_X                            : std_logic_vector(7 downto 0) := x"1b";
    constant KEY_Y                            : std_logic_vector(7 downto 0) := x"1c";
    constant KEY_Z                            : std_logic_vector(7 downto 0) := x"1d";
    constant KEY_1_ExclamationMark            : std_logic_vector(7 downto 0) := x"1e";
    constant KEY_2_At_US                      : std_logic_vector(7 downto 0) := x"1f";
    constant KEY_2_DoubleQuote_UK             : std_logic_vector(7 downto 0) := x"1f";
    constant KEY_3_Hash_US                    : std_logic_vector(7 downto 0) := x"20";
    constant KEY_3_Pound_UK                   : std_logic_vector(7 downto 0) := x"20";
    constant KEY_4_Dollar                     : std_logic_vector(7 downto 0) := x"21";
    constant KEY_5_Percent                    : std_logic_vector(7 downto 0) := x"22";
    constant KEY_6_Caret                      : std_logic_vector(7 downto 0) := x"23";
    constant KEY_7_Ampersand                  : std_logic_vector(7 downto 0) := x"24";
    constant KEY_8_Asterisk                   : std_logic_vector(7 downto 0) := x"25";
    constant KEY_9_LRoundBracket              : std_logic_vector(7 downto 0) := x"26";
    constant KEY_0_RRoundBracket              : std_logic_vector(7 downto 0) := x"27";
    constant KEY_Enter                        : std_logic_vector(7 downto 0) := x"28";
    constant KEY_Escape                       : std_logic_vector(7 downto 0) := x"29";
    constant KEY_Backspace                    : std_logic_vector(7 downto 0) := x"2a";
    constant KEY_SemiColon_Colon              : std_logic_vector(7 downto 0) := x"2a";
    constant KEY_Tab                          : std_logic_vector(7 downto 0) := x"2b";
    constant KEY_Space                        : std_logic_vector(7 downto 0) := x"2c";
    constant KEY_Minus_Underscore             : std_logic_vector(7 downto 0) := x"2d";
    constant KEY_Equal_Plus                   : std_logic_vector(7 downto 0) := x"2e";
    constant KEY_LSquareBracket_LCurlyBracket : std_logic_vector(7 downto 0) := x"2F";
    constant KEY_RSquareBracket_RCurlyBracket : std_logic_vector(7 downto 0) := x"30";
    constant KEY_Backslash_Pipe_US            : std_logic_vector(7 downto 0) := x"31";
    constant KEY_Hash_Tilde_UK                : std_logic_vector(7 downto 0) := x"32";
    constant KEY_Apostrophe_DoubleQuote_US    : std_logic_vector(7 downto 0) := x"34";
    constant KEY_Apostrophe_At_UK             : std_logic_vector(7 downto 0) := x"34";
    constant KEY_Grave_Negate_BrokenBar       : std_logic_vector(7 downto 0) := x"35";
    constant KEY_Comma_LessThan               : std_logic_vector(7 downto 0) := x"36";
    constant KEY_Period_GreaterThan           : std_logic_vector(7 downto 0) := x"37";
    constant KEY_Slash_QuestionMark           : std_logic_vector(7 downto 0) := x"38";
    constant KEY_CapsLock                     : std_logic_vector(7 downto 0) := x"39";
    constant KEY_F1                           : std_logic_vector(7 downto 0) := x"3a";
    constant KEY_F2                           : std_logic_vector(7 downto 0) := x"3b";
    constant KEY_F3                           : std_logic_vector(7 downto 0) := x"3c";
    constant KEY_F4                           : std_logic_vector(7 downto 0) := x"3d";
    constant KEY_F5                           : std_logic_vector(7 downto 0) := x"3e";
    constant KEY_F6                           : std_logic_vector(7 downto 0) := x"3f";
    constant KEY_F7                           : std_logic_vector(7 downto 0) := x"40";
    constant KEY_F8                           : std_logic_vector(7 downto 0) := x"41";
    constant KEY_F9                           : std_logic_vector(7 downto 0) := x"42";
    constant KEY_F10                          : std_logic_vector(7 downto 0) := x"43";
    constant KEY_F11                          : std_logic_vector(7 downto 0) := x"44";
    constant KEY_F12                          : std_logic_vector(7 downto 0) := x"45";
    constant KEY_PrtScr_SysRq                 : std_logic_vector(7 downto 0) := x"46";
    constant KEY_ScrollLock                   : std_logic_vector(7 downto 0) := x"47";
    constant KEY_Pause_Break                  : std_logic_vector(7 downto 0) := x"48";
    constant KEY_Insert                       : std_logic_vector(7 downto 0) := x"49";
    constant KEY_Home                         : std_logic_vector(7 downto 0) := x"4a";
    constant KEY_PgUp                         : std_logic_vector(7 downto 0) := x"4b";
    constant KEY_Delete                       : std_logic_vector(7 downto 0) := x"4c";
    constant KEY_End                          : std_logic_vector(7 downto 0) := x"4d";
    constant KEY_PgDn                         : std_logic_vector(7 downto 0) := x"4e";
    constant KEY_RightArrow                   : std_logic_vector(7 downto 0) := x"4f";
    constant KEY_LeftArrow                    : std_logic_vector(7 downto 0) := x"50";
    constant KEY_DownArrow                    : std_logic_vector(7 downto 0) := x"51";
    constant KEY_UpArrow                      : std_logic_vector(7 downto 0) := x"52";
    constant KEY_NumLock                      : std_logic_vector(7 downto 0) := x"53";
    constant KEY_KP_Slash                     : std_logic_vector(7 downto 0) := x"54";
    constant KEY_KP_Asterisk                  : std_logic_vector(7 downto 0) := x"55";
    constant KEY_KP_Minus                     : std_logic_vector(7 downto 0) := x"56";
    constant KEY_KP_Plus                      : std_logic_vector(7 downto 0) := x"57";
    constant KEY_KP_Enter                     : std_logic_vector(7 downto 0) := x"58";
    constant KEY_KP_1_End                     : std_logic_vector(7 downto 0) := x"59";
    constant KEY_KP_2_DownArrow               : std_logic_vector(7 downto 0) := x"5a";
    constant KEY_KP_3_PgDn                    : std_logic_vector(7 downto 0) := x"5b";
    constant KEY_KP_4_LeftArrow               : std_logic_vector(7 downto 0) := x"5c";
    constant KEY_KP_5                         : std_logic_vector(7 downto 0) := x"5d";
    constant KEY_KP_6_RightArrow              : std_logic_vector(7 downto 0) := x"5e";
    constant KEY_KP_7_Home                    : std_logic_vector(7 downto 0) := x"5f";
    constant KEY_KP_8_UpArrow                 : std_logic_vector(7 downto 0) := x"60";
    constant KEY_KP_9_PgUp                    : std_logic_vector(7 downto 0) := x"61";
    constant KEY_KP_0_Ins                     : std_logic_vector(7 downto 0) := x"62";
    constant KEY_KP_Period_Delete             : std_logic_vector(7 downto 0) := x"63";
    constant KEY_Backslash_Pipe_UK            : std_logic_vector(7 downto 0) := x"64";
    constant KEY_Menu                         : std_logic_vector(7 downto 0) := x"65";
    constant KEY_LCtrl                        : std_logic_vector(7 downto 0) := x"e0";
    constant KEY_LShift                       : std_logic_vector(7 downto 0) := x"e1";
    constant KEY_LAlt                         : std_logic_vector(7 downto 0) := x"e2";
    constant KEY_LWin                         : std_logic_vector(7 downto 0) := x"e3";
    constant KEY_RCtrl                        : std_logic_vector(7 downto 0) := x"e4";
    constant KEY_RShift                       : std_logic_vector(7 downto 0) := x"e5";
    constant KEY_RAlt                         : std_logic_vector(7 downto 0) := x"e7";
    constant KEY_RWin                         : std_logic_vector(7 downto 0) := x"e6";

end package usb_hid_codes_pkg;
