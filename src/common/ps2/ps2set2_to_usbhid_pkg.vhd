--------------------------------------------------------------------------------
-- ps2set_to_usbhid_pkg.vhd                                                   --
-- PS/2 set 2 support for ps2_to_usbhid.vhd.                                  --
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

library work;
use work.tyto_types_pkg.all;
use work.usb_hid_codes_pkg.all;

package ps2set_to_usbhid_pkg is

    function ps2set_to_usbhid(constant nonUS : boolean := true) return slv_8_0_t;

end package ps2set_to_usbhid_pkg;

package body ps2set_to_usbhid_pkg is

    constant N     : std_logic_vector(0 downto 0) := "0";             -- not last
    constant L     : std_logic_vector(0 downto 0) := "1";             -- last
    constant C     : std_logic_vector(0 downto 0) := "0";             -- code
    constant P     : std_logic_vector(0 downto 0) := "1";             -- prefix
    constant EMPTY : std_logic_vector(8 downto 0) := C & x"00";       -- empty break

    function ps2set_to_usbhid(constant nonUS : boolean := true) return slv_8_0_t is
        constant tbl: slv_8_0_t := (
--          USB HID keycode                      PS/2 MAKE         PS/2 BREAK
            N&KEY_Backslash_Pipe,                C&x"5D",          P&x"F0",C&x"5D", -- KEY_hash_tilde for non-US keyboards
            N&KEY_Europe2,                       C&x"61",          P&x"E0",C&x"61", -- Backslash_Pipe (non-US)
            N&KEY_A,                             C&x"1C",          P&x"F0",C&x"1C",
            N&KEY_B,                             C&x"32",          P&x"F0",C&x"32",
            N&KEY_C,                             C&x"21",          P&x"F0",C&x"21",
            N&KEY_D,                             C&x"23",          P&x"F0",C&x"23",
            N&KEY_E,                             C&x"24",          P&x"F0",C&x"24",
            N&KEY_F,                             C&x"2B",          P&x"F0",C&x"2B",
            N&KEY_G,                             C&x"34",          P&x"F0",C&x"34",
            N&KEY_H,                             C&x"33",          P&x"F0",C&x"33",
            N&KEY_I,                             C&x"43",          P&x"F0",C&x"43",
            N&KEY_J,                             C&x"3B",          P&x"F0",C&x"3B",
            N&KEY_K,                             C&x"42",          P&x"F0",C&x"42",
            N&KEY_L,                             C&x"4B",          P&x"F0",C&x"4B",
            N&KEY_M,                             C&x"3A",          P&x"F0",C&x"3A",
            N&KEY_N,                             C&x"31",          P&x"F0",C&x"31",
            N&KEY_O,                             C&x"44",          P&x"F0",C&x"44",
            N&KEY_P,                             C&x"4D",          P&x"F0",C&x"4D",
            N&KEY_Q,                             C&x"15",          P&x"F0",C&x"15",
            N&KEY_R,                             C&x"2D",          P&x"F0",C&x"2D",
            N&KEY_S,                             C&x"1B",          P&x"F0",C&x"1B",
            N&KEY_T,                             C&x"2C",          P&x"F0",C&x"2C",
            N&KEY_U,                             C&x"3C",          P&x"F0",C&x"3C",
            N&KEY_V,                             C&x"2A",          P&x"F0",C&x"2A",
            N&KEY_W,                             C&x"1D",          P&x"F0",C&x"1D",
            N&KEY_X,                             C&x"22",          P&x"F0",C&x"22",
            N&KEY_Y,                             C&x"35",          P&x"F0",C&x"35",
            N&KEY_Z,                             C&x"1A",          P&x"F0",C&x"1A",
            N&KEY_1_ExclamationMark,             C&x"16",          P&x"F0",C&x"16",
            N&KEY_2_DoubleQuote,                 C&x"1E",          P&x"F0",C&x"1E",
            N&KEY_3_Pound,                       C&x"26",          P&x"F0",C&x"26",
            N&KEY_4_Dollar,                      C&x"25",          P&x"F0",C&x"25",
            N&KEY_5_Percent,                     C&x"2E",          P&x"F0",C&x"2E",
            N&KEY_6_Caret,                       C&x"36",          P&x"F0",C&x"36",
            N&KEY_7_Ampersand,                   C&x"3D",          P&x"F0",C&x"3D",
            N&KEY_8_Asterisk,                    C&x"3E",          P&x"F0",C&x"3E",
            N&KEY_9_LRoundBracket,               C&x"46",          P&x"F0",C&x"46",
            N&KEY_0_RRoundBracket,               C&x"45",          P&x"F0",C&x"45",
            N&KEY_Enter,                         C&x"5A",          P&x"F0",C&x"5A",
            N&KEY_Escape,                        C&x"76",          P&x"F0",C&x"76",
            N&KEY_Backspace,                     C&x"66",          P&x"F0",C&x"66",
            N&KEY_SemiColon_Colon,               C&x"4C",          P&x"F0",C&x"4C",
            N&KEY_Tab,                           C&x"0D",          P&x"F0",C&x"0D",
            N&KEY_Space,                         C&x"29",          P&x"F0",C&x"29",
            N&KEY_Minus_Underscore,              C&x"4E",          P&x"F0",C&x"4E",
            N&KEY_Equal_Plus,                    C&x"55",          P&x"F0",C&x"55",
            N&KEY_LSquareBracket_LCurlyBracket,  C&x"54",          P&x"F0",C&x"54",
            N&KEY_RSquareBracket_RCurlyBracket,  C&x"5B",          P&x"F0",C&x"5B",
            N&KEY_Apostrophe_At,                 C&x"52",          P&x"F0",C&x"52",
            N&KEY_Grave_Negate_BrokenBar,        C&x"0E",          P&x"F0",C&x"0E",
            N&KEY_Comma_LessThan,                C&x"41",          P&x"F0",C&x"41",
            N&KEY_Period_GreaterThan,            C&x"49",          P&x"F0",C&x"49",
            N&KEY_Slash_QuestionMark,            C&x"4A",          P&x"F0",C&x"4A",
            N&KEY_CapsLock,                      C&x"58",          P&x"F0",C&x"58",
            N&KEY_F1,                            C&x"05",          P&x"F0",C&x"05",
            N&KEY_F2,                            C&x"06",          P&x"F0",C&x"06",
            N&KEY_F3,                            C&x"04",          P&x"F0",C&x"04",
            N&KEY_F4,                            C&x"0C",          P&x"F0",C&x"0C",
            N&KEY_F5,                            C&x"03",          P&x"F0",C&x"03",
            N&KEY_F6,                            C&x"0B",          P&x"F0",C&x"0B",
            N&KEY_F7,                            C&x"83",          P&x"F0",C&x"83",
            N&KEY_F8,                            C&x"0A",          P&x"F0",C&x"0A",
            N&KEY_F9,                            C&x"01",          P&x"F0",C&x"01",
            N&KEY_F10,                           C&x"09",          P&x"F0",C&x"09",
            N&KEY_F11,                           C&x"78",          P&x"F0",C&x"78",
            N&KEY_F12,                           C&x"07",          P&x"F0",C&x"07",
            N&KEY_PrtScr_SysRq,                  P&x"E0",C&x"7C",  P&x"E0",P&x"F0",C&x"7C",
            N&KEY_ScrollLock,                    C&x"7E",          P&x"F0",C&x"7E",
            N&KEY_Insert,                        P&x"E0",C&x"70",  P&x"E0",P&x"F0",C&x"70",
            N&KEY_Home,                          P&x"E0",C&x"6C",  P&x"E0",P&x"F0",C&x"6C",
            N&KEY_PgUp,                          P&x"E0",C&x"7D",  P&x"E0",P&x"F0",C&x"7D",
            N&KEY_Delete,                        P&x"E0",C&x"71",  P&x"E0",P&x"F0",C&x"71",
            N&KEY_End,                           P&x"E0",C&x"69",  P&x"E0",P&x"F0",C&x"69",
            N&KEY_PgDn,                          P&x"E0",C&x"7A",  P&x"E0",P&x"F0",C&x"7A",
            N&KEY_RightArrow,                    P&x"E0",C&x"74",  P&x"E0",P&x"F0",C&x"74",
            N&KEY_LeftArrow,                     P&x"E0",C&x"6B",  P&x"E0",P&x"F0",C&x"6B",
            N&KEY_DownArrow,                     P&x"E0",C&x"72",  P&x"E0",P&x"F0",C&x"72",
            N&KEY_UpArrow,                       P&x"E0",C&x"75",  P&x"E0",P&x"F0",C&x"75",
            N&KEY_NumLock,                       C&x"77",          P&x"F0",C&x"77",
            N&KEY_KP_Slash,                      P&x"E0",C&x"4A",  P&x"E0",P&x"F0",C&x"4A",
            N&KEY_KP_Asterisk,                   C&x"7C",          P&x"F0",C&x"7C",
            N&KEY_KP_Minus,                      C&x"7B",          P&x"F0",C&x"7B",
            N&KEY_KP_Plus,                       C&x"79",          P&x"F0",C&x"79",
            N&KEY_KP_Enter,                      P&x"E0",C&x"5A",  P&x"E0",P&x"F0",C&x"5A",
            N&KEY_KP_1_End,                      C&x"69",          P&x"F0",C&x"69",
            N&KEY_KP_2_DownArrow,                C&x"72",          P&x"F0",C&x"72",
            N&KEY_KP_3_PgDn,                     C&x"7A",          P&x"F0",C&x"7A",
            N&KEY_KP_4_LeftArrow,                C&x"6B",          P&x"F0",C&x"6B",
            N&KEY_KP_5,                          C&x"73",          P&x"F0",C&x"73",
            N&KEY_KP_6_RightArrow,               C&x"74",          P&x"F0",C&x"74",
            N&KEY_KP_7_Home,                     C&x"6C",          P&x"F0",C&x"6C",
            N&KEY_KP_8_UpArrow,                  C&x"75",          P&x"F0",C&x"75",
            N&KEY_KP_9_PgUp,                     C&x"7D",          P&x"F0",C&x"7D",
            N&KEY_KP_0_Ins,                      C&x"70",          P&x"F0",C&x"70",
            N&KEY_KP_Period_Delete,              C&x"71",          P&x"F0",C&x"71",
            N&KEY_Menu,                          P&x"E0",C&x"2F",  P&x"E0",P&x"F0",C&x"2F",
            N&KEY_LCtrl,                         C&x"14",          P&x"F0",C&x"14",
            N&KEY_LShift,                        C&x"12",          P&x"F0",C&x"12",
            N&KEY_LAlt,                          C&x"11",          P&x"F0",C&x"11",
            N&KEY_LWin,                          P&x"E0",C&x"1F",  P&x"E0",P&x"F0",C&x"1F",
            N&KEY_RCtrl,                         P&x"E0",C&x"14",  P&x"E0",P&x"F0",C&x"14",
            N&KEY_RShift,                        C&x"59",          P&x"F0",C&x"59",
            N&KEY_RWin,                          P&x"E0",C&x"27",  P&x"E0",P&x"F0",C&x"27",
            N&KEY_RAlt,                          P&x"E0",C&x"11",  P&x"E0",P&x"F0",C&x"11",
            N&KEY_Pause_Break,                   P&x"E1",P&x"14",P&x"77",P&x"E1",P&x"F0",P&x"14",P&x"F0",C&x"77", EMPTY,
            L&KEY_Pause_Break,                   P&x"E0",P&x"7E",P&x"E0",P&x"F0",C&x"7E", EMPTY
        );
        variable r : slv_8_0_t(tbl'range) := tbl;
    begin
        -- PS/2 code 5D (first table entry) varies
        if nonUS then
            r(0) := N & KEY_Europe1; -- Hash_Tilde
        end if;
        return r;
    end function ps2set_to_usbhid;

end package body ps2set_to_usbhid_pkg;
