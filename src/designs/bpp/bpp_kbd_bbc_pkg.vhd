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

  constant bbc_shift                        : std_logic_vector(6 downto 0) := "0000000";
  constant bbc_q                            : std_logic_vector(6 downto 0) := "0000001";
  constant bbc_f0                           : std_logic_vector(6 downto 0) := "0000010";
  constant bbc_1_exclamationmark            : std_logic_vector(6 downto 0) := "0000011";
  constant bbc_capslock                     : std_logic_vector(6 downto 0) := "0000100";
  constant bbc_shiftlock                    : std_logic_vector(6 downto 0) := "0000101";
  constant bbc_tab                          : std_logic_vector(6 downto 0) := "0000110";
  constant bbc_escape                       : std_logic_vector(6 downto 0) := "0000111";
  constant bbc_ctrl                         : std_logic_vector(6 downto 0) := "0001000";
  constant bbc_3_hash                       : std_logic_vector(6 downto 0) := "0001001";
  constant bbc_w                            : std_logic_vector(6 downto 0) := "0001010";
  constant bbc_2_doublequote                : std_logic_vector(6 downto 0) := "0001011";
  constant bbc_a                            : std_logic_vector(6 downto 0) := "0001100";
  constant bbc_s                            : std_logic_vector(6 downto 0) := "0001101";
  constant bbc_z                            : std_logic_vector(6 downto 0) := "0001110";
  constant bbc_f1                           : std_logic_vector(6 downto 0) := "0001111";
  constant bbc_opt_8                        : std_logic_vector(6 downto 0) := "0010000";
  constant bbc_4_dollar                     : std_logic_vector(6 downto 0) := "0010001";
  constant bbc_e                            : std_logic_vector(6 downto 0) := "0010010";
  constant bbc_d                            : std_logic_vector(6 downto 0) := "0010011";
  constant bbc_x                            : std_logic_vector(6 downto 0) := "0010100";
  constant bbc_c                            : std_logic_vector(6 downto 0) := "0010101";
  constant bbc_space                        : std_logic_vector(6 downto 0) := "0010110";
  constant bbc_f2                           : std_logic_vector(6 downto 0) := "0010111";
  constant bbc_opt_7                        : std_logic_vector(6 downto 0) := "0011000";
  constant bbc_5_percent                    : std_logic_vector(6 downto 0) := "0011001";
  constant bbc_t                            : std_logic_vector(6 downto 0) := "0011010";
  constant bbc_r                            : std_logic_vector(6 downto 0) := "0011011";
  constant bbc_f                            : std_logic_vector(6 downto 0) := "0011100";
  constant bbc_g                            : std_logic_vector(6 downto 0) := "0011101";
  constant bbc_v                            : std_logic_vector(6 downto 0) := "0011110";
  constant bbc_f3                           : std_logic_vector(6 downto 0) := "0011111";
  constant bbc_opt_6                        : std_logic_vector(6 downto 0) := "0100000";
  constant bbc_f4                           : std_logic_vector(6 downto 0) := "0100001";
  constant bbc_7_apostrophe                 : std_logic_vector(6 downto 0) := "0100010";
  constant bbc_6_ampersand                  : std_logic_vector(6 downto 0) := "0100011";
  constant bbc_y                            : std_logic_vector(6 downto 0) := "0100100";
  constant bbc_h                            : std_logic_vector(6 downto 0) := "0100101";
  constant bbc_b                            : std_logic_vector(6 downto 0) := "0100110";
  constant bbc_f5                           : std_logic_vector(6 downto 0) := "0100111";
  constant bbc_opt_5                        : std_logic_vector(6 downto 0) := "0101000";
  constant bbc_8_lroundbracket              : std_logic_vector(6 downto 0) := "0101001";
  constant bbc_i                            : std_logic_vector(6 downto 0) := "0101010";
  constant bbc_u                            : std_logic_vector(6 downto 0) := "0101011";
  constant bbc_j                            : std_logic_vector(6 downto 0) := "0101100";
  constant bbc_n                            : std_logic_vector(6 downto 0) := "0101101";
  constant bbc_m                            : std_logic_vector(6 downto 0) := "0101110";
  constant bbc_f6                           : std_logic_vector(6 downto 0) := "0101111";
  constant bbc_opt_4                        : std_logic_vector(6 downto 0) := "0110000";
  constant bbc_f7                           : std_logic_vector(6 downto 0) := "0110001";
  constant bbc_9_rroundbracket              : std_logic_vector(6 downto 0) := "0110010";
  constant bbc_o                            : std_logic_vector(6 downto 0) := "0110011";
  constant bbc_k                            : std_logic_vector(6 downto 0) := "0110100";
  constant bbc_l                            : std_logic_vector(6 downto 0) := "0110101";
  constant bbc_comma_lessthan               : std_logic_vector(6 downto 0) := "0110110";
  constant bbc_f8                           : std_logic_vector(6 downto 0) := "0110111";
  constant bbc_opt_3                        : std_logic_vector(6 downto 0) := "0111000";
  constant bbc_minus_equal                  : std_logic_vector(6 downto 0) := "0111001";
  constant bbc_0                            : std_logic_vector(6 downto 0) := "0111010";
  constant bbc_p                            : std_logic_vector(6 downto 0) := "0111011";
  constant bbc_at                           : std_logic_vector(6 downto 0) := "0111100";
  constant bbc_semicolon_plus               : std_logic_vector(6 downto 0) := "0111101";
  constant bbc_period_greaterthan           : std_logic_vector(6 downto 0) := "0111110";
  constant bbc_f9                           : std_logic_vector(6 downto 0) := "0111111";
  constant bbc_opt_2                        : std_logic_vector(6 downto 0) := "1000000";
  constant bbc_caret_tilde                  : std_logic_vector(6 downto 0) := "1000001";
  constant bbc_underscore_pound             : std_logic_vector(6 downto 0) := "1000010";
  constant bbc_lsquarebracket_lcurlybracket : std_logic_vector(6 downto 0) := "1000011";
  constant bbc_colon_asterisk               : std_logic_vector(6 downto 0) := "1000100";
  constant bbc_rsquarebracket_rcurlybracket : std_logic_vector(6 downto 0) := "1000101";
  constant bbc_slash_questionmark           : std_logic_vector(6 downto 0) := "1000110";
  constant bbc_backslash_brokenbar          : std_logic_vector(6 downto 0) := "1000111";
  constant bbc_opt_1                        : std_logic_vector(6 downto 0) := "1001000";
  constant bbc_leftarrow                    : std_logic_vector(6 downto 0) := "1001001";
  constant bbc_downarrow                    : std_logic_vector(6 downto 0) := "1001010";
  constant bbc_uparrow                      : std_logic_vector(6 downto 0) := "1001011";
  constant bbc_return                       : std_logic_vector(6 downto 0) := "1001100";
  constant bbc_delete                       : std_logic_vector(6 downto 0) := "1001101";
  constant bbc_copy                         : std_logic_vector(6 downto 0) := "1001110";
  constant bbc_rightarrow                   : std_logic_vector(6 downto 0) := "1001111";

end package bpp_kbd_bbc_pkg;
