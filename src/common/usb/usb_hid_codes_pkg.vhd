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

  constant key_a                            : std_logic_vector(7 downto 0) := x"04";
  constant key_b                            : std_logic_vector(7 downto 0) := x"05";
  constant key_c                            : std_logic_vector(7 downto 0) := x"06";
  constant key_d                            : std_logic_vector(7 downto 0) := x"07";
  constant key_e                            : std_logic_vector(7 downto 0) := x"08";
  constant key_f                            : std_logic_vector(7 downto 0) := x"09";
  constant key_g                            : std_logic_vector(7 downto 0) := x"0A";
  constant key_h                            : std_logic_vector(7 downto 0) := x"0B";
  constant key_i                            : std_logic_vector(7 downto 0) := x"0C";
  constant key_j                            : std_logic_vector(7 downto 0) := x"0D";
  constant key_k                            : std_logic_vector(7 downto 0) := x"0E";
  constant key_l                            : std_logic_vector(7 downto 0) := x"0F";
  constant key_m                            : std_logic_vector(7 downto 0) := x"10";
  constant key_n                            : std_logic_vector(7 downto 0) := x"11";
  constant key_o                            : std_logic_vector(7 downto 0) := x"12";
  constant key_p                            : std_logic_vector(7 downto 0) := x"13";
  constant key_q                            : std_logic_vector(7 downto 0) := x"14";
  constant key_r                            : std_logic_vector(7 downto 0) := x"15";
  constant key_s                            : std_logic_vector(7 downto 0) := x"16";
  constant key_t                            : std_logic_vector(7 downto 0) := x"17";
  constant key_u                            : std_logic_vector(7 downto 0) := x"18";
  constant key_v                            : std_logic_vector(7 downto 0) := x"19";
  constant key_w                            : std_logic_vector(7 downto 0) := x"1A";
  constant key_x                            : std_logic_vector(7 downto 0) := x"1B";
  constant key_y                            : std_logic_vector(7 downto 0) := x"1C";
  constant key_z                            : std_logic_vector(7 downto 0) := x"1D";
  constant key_1_exclamationmark            : std_logic_vector(7 downto 0) := x"1E";
  constant key_2_at_us                      : std_logic_vector(7 downto 0) := x"1F";
  constant key_2_doublequote_uk             : std_logic_vector(7 downto 0) := x"1F";
  constant key_3_hash_us                    : std_logic_vector(7 downto 0) := x"20";
  constant key_3_pound_uk                   : std_logic_vector(7 downto 0) := x"20";
  constant key_4_dollar                     : std_logic_vector(7 downto 0) := x"21";
  constant key_5_percent                    : std_logic_vector(7 downto 0) := x"22";
  constant key_6_caret                      : std_logic_vector(7 downto 0) := x"23";
  constant key_7_ampersand                  : std_logic_vector(7 downto 0) := x"24";
  constant key_8_asterisk                   : std_logic_vector(7 downto 0) := x"25";
  constant key_9_lroundbracket              : std_logic_vector(7 downto 0) := x"26";
  constant key_0_rroundbracket              : std_logic_vector(7 downto 0) := x"27";
  constant key_enter                        : std_logic_vector(7 downto 0) := x"28";
  constant key_escape                       : std_logic_vector(7 downto 0) := x"29";
  constant key_backspace                    : std_logic_vector(7 downto 0) := x"2A";
  constant key_tab                          : std_logic_vector(7 downto 0) := x"2B";
  constant key_space                        : std_logic_vector(7 downto 0) := x"2C";
  constant key_minus_underscore             : std_logic_vector(7 downto 0) := x"2D";
  constant key_equal_plus                   : std_logic_vector(7 downto 0) := x"2E";
  constant key_lsquarebracket_lcurlybracket : std_logic_vector(7 downto 0) := x"2F";
  constant key_rsquarebracket_rcurlybracket : std_logic_vector(7 downto 0) := x"30";
  constant key_backslash_pipe_us            : std_logic_vector(7 downto 0) := x"31";
  constant key_hash_tilde_uk                : std_logic_vector(7 downto 0) := x"32";
  constant key_semicolon_colon              : std_logic_vector(7 downto 0) := x"33";
  constant key_apostrophe_doublequote_us    : std_logic_vector(7 downto 0) := x"34";
  constant key_apostrophe_at_uk             : std_logic_vector(7 downto 0) := x"34";
  constant key_grave_negate_brokenbar       : std_logic_vector(7 downto 0) := x"35";
  constant key_comma_lessthan               : std_logic_vector(7 downto 0) := x"36";
  constant key_period_greaterthan           : std_logic_vector(7 downto 0) := x"37";
  constant key_slash_questionmark           : std_logic_vector(7 downto 0) := x"38";
  constant key_capslock                     : std_logic_vector(7 downto 0) := x"39";
  constant key_f1                           : std_logic_vector(7 downto 0) := x"3A";
  constant key_f2                           : std_logic_vector(7 downto 0) := x"3B";
  constant key_f3                           : std_logic_vector(7 downto 0) := x"3C";
  constant key_f4                           : std_logic_vector(7 downto 0) := x"3D";
  constant key_f5                           : std_logic_vector(7 downto 0) := x"3E";
  constant key_f6                           : std_logic_vector(7 downto 0) := x"3F";
  constant key_f7                           : std_logic_vector(7 downto 0) := x"40";
  constant key_f8                           : std_logic_vector(7 downto 0) := x"41";
  constant key_f9                           : std_logic_vector(7 downto 0) := x"42";
  constant key_f10                          : std_logic_vector(7 downto 0) := x"43";
  constant key_f11                          : std_logic_vector(7 downto 0) := x"44";
  constant key_f12                          : std_logic_vector(7 downto 0) := x"45";
  constant key_prtscr_sysrq                 : std_logic_vector(7 downto 0) := x"46";
  constant key_scrolllock                   : std_logic_vector(7 downto 0) := x"47";
  constant key_pause_break                  : std_logic_vector(7 downto 0) := x"48";
  constant key_insert                       : std_logic_vector(7 downto 0) := x"49";
  constant key_home                         : std_logic_vector(7 downto 0) := x"4A";
  constant key_pgup                         : std_logic_vector(7 downto 0) := x"4B";
  constant key_delete                       : std_logic_vector(7 downto 0) := x"4C";
  constant key_end                          : std_logic_vector(7 downto 0) := x"4D";
  constant key_pgdn                         : std_logic_vector(7 downto 0) := x"4E";
  constant key_rightarrow                   : std_logic_vector(7 downto 0) := x"4F";
  constant key_leftarrow                    : std_logic_vector(7 downto 0) := x"50";
  constant key_downarrow                    : std_logic_vector(7 downto 0) := x"51";
  constant key_uparrow                      : std_logic_vector(7 downto 0) := x"52";
  constant key_numlock                      : std_logic_vector(7 downto 0) := x"53";
  constant key_kp_slash                     : std_logic_vector(7 downto 0) := x"54";
  constant key_kp_asterisk                  : std_logic_vector(7 downto 0) := x"55";
  constant key_kp_minus                     : std_logic_vector(7 downto 0) := x"56";
  constant key_kp_plus                      : std_logic_vector(7 downto 0) := x"57";
  constant key_kp_enter                     : std_logic_vector(7 downto 0) := x"58";
  constant key_kp_1_end                     : std_logic_vector(7 downto 0) := x"59";
  constant key_kp_2_downarrow               : std_logic_vector(7 downto 0) := x"5A";
  constant key_kp_3_pgdn                    : std_logic_vector(7 downto 0) := x"5B";
  constant key_kp_4_leftarrow               : std_logic_vector(7 downto 0) := x"5C";
  constant key_kp_5                         : std_logic_vector(7 downto 0) := x"5D";
  constant key_kp_6_rightarrow              : std_logic_vector(7 downto 0) := x"5E";
  constant key_kp_7_home                    : std_logic_vector(7 downto 0) := x"5F";
  constant key_kp_8_uparrow                 : std_logic_vector(7 downto 0) := x"60";
  constant key_kp_9_pgup                    : std_logic_vector(7 downto 0) := x"61";
  constant key_kp_0_ins                     : std_logic_vector(7 downto 0) := x"62";
  constant key_kp_period_delete             : std_logic_vector(7 downto 0) := x"63";
  constant key_backslash_pipe_uk            : std_logic_vector(7 downto 0) := x"64";
  constant key_menu                         : std_logic_vector(7 downto 0) := x"65";
  constant key_lctrl                        : std_logic_vector(7 downto 0) := x"E0";
  constant key_lshift                       : std_logic_vector(7 downto 0) := x"E1";
  constant key_lalt                         : std_logic_vector(7 downto 0) := x"E2";
  constant key_lwin                         : std_logic_vector(7 downto 0) := x"E3";
  constant key_rctrl                        : std_logic_vector(7 downto 0) := x"E4";
  constant key_rshift                       : std_logic_vector(7 downto 0) := x"E5";
  constant key_rwin                         : std_logic_vector(7 downto 0) := x"E6";
  constant key_ralt                         : std_logic_vector(7 downto 0) := x"E7";

end package usb_hid_codes_pkg;
