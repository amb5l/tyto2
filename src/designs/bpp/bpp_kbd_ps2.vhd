--------------------------------------------------------------------------------
-- bpp_kbd_ps2.vhd                                                            --
-- BPP PS/2 keyboard interface.                                               --
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
-- TODO: add LED support

library ieee;
use ieee.std_logic_1164.all;

package bpp_kbd_ps2_pkg is

    component bpp_kbd_ps2 is
        port (

                clk           : in  std_logic;
                clken         : in  std_logic;
                rst           : in  std_logic;

                ps2_clk_i     : in  std_logic;
                ps2_clk_o     : out std_logic;
                ps2_data_i    : in  std_logic;
                ps2_data_o    : out std_logic;

                opt_mode      : in  std_logic_vector(2 downto 0);
                opt_boot      : in  std_logic;
                opt_disc      : in  std_logic_vector(1 downto 0);
                opt_spare     : in  std_logic;
                opt_dfs_nfs   : in  std_logic;

                led_capslock  : in  std_logic;
                led_shiftlock : in  std_logic;
                led_motor     : in  std_logic;

                kbd_break     : out std_logic;
                kbd_load      : in  std_logic;
                kbd_row       : in  std_logic_vector(2 downto 0);
                kbd_col       : in  std_logic_vector(3 downto 0);
                kbd_press     : out std_logic;
                kbd_irq       : out std_logic

        );
    end component bpp_kbd_ps2;

end package bpp_kbd_ps2_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ps2_host_pkg.all;
use work.ps2_to_usbhid_pkg.all;
use work.bpp_kbd_bbc_pkg.all;
use work.usb_hid_codes_pkg.all;

entity bpp_kbd_ps2 is
    port (

            clk           : in  std_logic;                    -- clock
            clken         : in  std_logic;                    -- clock enable
            rst           : in  std_logic;                    -- reset

            ps2_clk_i     : in  std_logic;                    -- PS/2 serial clock in
            ps2_clk_o     : out std_logic;                    -- PS/2 serial clock out
            ps2_data_i    : in  std_logic;                    -- PS/2 serial data in
            ps2_data_o    : out std_logic;                    -- PS/2 serial data out

            opt_mode      : in  std_logic_vector(2 downto 0); -- startup options: video mode (0-7)
            opt_boot      : in  std_logic;                    -- startup options: 1 = boot on BREAK, 0 = boot on SHIFT BREAK
            opt_disc      : in  std_logic_vector(1 downto 0); -- startup options: disc timing
            opt_spare     : in  std_logic;                    -- startup options: spare
            opt_dfs_nfs   : in  std_logic;                    -- startup options: 1 = DFS, 0 = NFS

            led_capslock  : in  std_logic;                    -- } LED states
            led_shiftlock : in  std_logic;                    -- }
            led_motor     : in  std_logic;                    -- }

            kbd_break     : out std_logic;                    -- BBC micro keyboard: BREAK pressed
            kbd_load      : in  std_logic;                    -- BBC micro keyboard: load
            kbd_row       : in  std_logic_vector(2 downto 0); -- BBC micro keyboard: row (0-7)
            kbd_col       : in  std_logic_vector(3 downto 0); -- BBC micro keyboard: column (0-9)
            kbd_press     : out std_logic;                    -- BBC micro keyboard: key press
            kbd_irq       : out std_logic                     -- BBC micro keyboard: key press in column

    );
end entity bpp_kbd_ps2;

architecture synth of bpp_kbd_ps2 is

    signal d2h_stb  : std_logic;
    signal d2h_data : std_logic_vector(7 downto 0);

    signal h2d_req  : std_logic;
    signal h2d_ack  : std_logic;
    signal h2d_nack : std_logic;
    signal h2d_data : std_logic_vector(7 downto 0);

    signal hid_stb  : std_logic;
    signal hid_make : std_logic;
    signal hid_code : std_logic_vector(7 downto 0);

    signal khid     : std_logic_vector(0 to 127);   -- USB HID key states } 1 = made/closed
    signal kbbc     : std_logic_vector(0 to 79);    -- BBC key states     } 0 = broken/open

    signal c        : integer range 0 to 15;        -- current column
    signal r        : integer range 0 to 7;         -- current row

    --------------------------------------------------------------------------------
    -- functions to tidy mapping and contract HID key code range from 256 to 128 codes

    function i7(v:std_logic_vector(6 downto 0)) return integer is
    begin
        return to_integer(unsigned(v));
    end function i7;

    function i8to7(v:std_logic_vector(7 downto 0)) return integer is
        variable r: integer range 0 to 127;
    begin
        r := to_integer(unsigned(v(6 downto 0)));
        if v(7 downto 4) = x"E" then
            r := r+16;
        end if;
        return r;
    end function i8to7;

    --------------------------------------------------------------------------------

begin

    --------------------------------------------------------------------------------
    -- PS/2 IP cores

    PS2: component ps2_host
        generic map (
            fclk       => 32.0
        )
        port map (
            clk        => clk,
            rst        => rst,
            ps2_clk_i  => ps2_clk_i,
            ps2_clk_o  => ps2_clk_o,
            ps2_data_i => ps2_data_i,
            ps2_data_o => ps2_data_o,
            d2h_stb    => d2h_stb,
            d2h_data   => d2h_data,
            h2d_req    => h2d_req,
            h2d_ack    => h2d_ack,
            h2d_nack   => h2d_nack,
            h2d_data   => h2d_data
        );

    HID: component ps2_to_usbhid
        generic map (
            nonUS    => true
        )
        port map (
            clk      => clk,
            rst      => rst,
            ps2_stb  => d2h_stb,
            ps2_data => d2h_data,
            hid_stb  => hid_stb,
            hid_make => hid_make,
            hid_code => hid_code
        );

    -- host to device not used
    h2d_req <= '0';
    h2d_data <= (others => '0');

    --------------------------------------------------------------------------------
    -- maintain HID key states by tracking make/break on each code

    MAKE_BREAK: process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                khid <= (others => '0');
            else
                if hid_stb = '1' then
                    if hid_code /= KEY_Pause_Break then
                        khid(i8to7(hid_code)) <= hid_make;
                    end if;
                end if;
            end if;
        end if;
    end process MAKE_BREAK;

    --------------------------------------------------------------------------------
    -- map BBC key states from HID key states

    kbbc(i7( BBC_F0                           )) <= khid(i8to7( KEY_F10                          ))                                       ;
    kbbc(i7( BBC_F1                           )) <= khid(i8to7( KEY_F1                           ))                                       ;
    kbbc(i7( BBC_F2                           )) <= khid(i8to7( KEY_F2                           ))                                       ;
    kbbc(i7( BBC_F3                           )) <= khid(i8to7( KEY_F3                           ))                                       ;
    kbbc(i7( BBC_F4                           )) <= khid(i8to7( KEY_F4                           ))                                       ;
    kbbc(i7( BBC_F5                           )) <= khid(i8to7( KEY_F5                           ))                                       ;
    kbbc(i7( BBC_F6                           )) <= khid(i8to7( KEY_F6                           ))                                       ;
    kbbc(i7( BBC_F7                           )) <= khid(i8to7( KEY_F7                           ))                                       ;
    kbbc(i7( BBC_F8                           )) <= khid(i8to7( KEY_F8                           ))                                       ;
    kbbc(i7( BBC_F9                           )) <= khid(i8to7( KEY_F9                           ))                                       ;

    kbbc(i7( BBC_Escape                       )) <= khid(i8to7( KEY_Escape                       ))                                       ;
    kbbc(i7( BBC_1_ExclamationMark            )) <= khid(i8to7( KEY_1_ExclamationMark            ))                                       ;
    kbbc(i7( BBC_2_DoubleQuote                )) <= khid(i8to7( KEY_2_DoubleQuote_UK             ))                                       ;
    kbbc(i7( BBC_3_Hash                       )) <= khid(i8to7( KEY_3_Pound_UK                   ))                                       ;
    kbbc(i7( BBC_4_Dollar                     )) <= khid(i8to7( KEY_4_Dollar                     ))                                       ;
    kbbc(i7( BBC_5_Percent                    )) <= khid(i8to7( KEY_5_Percent                    ))                                       ;
    kbbc(i7( BBC_6_Ampersand                  )) <= khid(i8to7( KEY_6_Caret                      ))                                       ;
    kbbc(i7( BBC_7_Apostrophe                 )) <= khid(i8to7( KEY_7_Ampersand                  ))                                       ;
    kbbc(i7( BBC_8_LRoundBracket              )) <= khid(i8to7( KEY_8_Asterisk                   ))                                       ;
    kbbc(i7( BBC_9_RRoundBracket              )) <= khid(i8to7( KEY_9_LRoundBracket              ))                                       ;
    kbbc(i7( BBC_0                            )) <= khid(i8to7( KEY_0_RRoundBracket              ))                                       ;
    kbbc(i7( BBC_Minus_Equal                  )) <= khid(i8to7( KEY_Minus_Underscore             ))                                       ;
    kbbc(i7( BBC_Caret_Tilde                  )) <= khid(i8to7( KEY_Equal_Plus                   ))                                       ;
    kbbc(i7( BBC_BackSlash_BrokenBar          )) <= khid(i8to7( KEY_Backslash_Pipe_UK            ))                                       ;
    kbbc(i7( BBC_LeftArrow                    )) <= khid(i8to7( KEY_LeftArrow                    )) or khid(i8to7( KEY_KP_4_LeftArrow  )) ;
    kbbc(i7( BBC_RightArrow                   )) <= khid(i8to7( KEY_RightArrow                   )) or khid(i8to7( KEY_KP_6_RightArrow )) ;

    kbbc(i7( BBC_Tab                          )) <= khid(i8to7( KEY_Tab                          ))                                       ;
    kbbc(i7( BBC_Q                            )) <= khid(i8to7( KEY_Q                            ))                                       ;
    kbbc(i7( BBC_W                            )) <= khid(i8to7( KEY_W                            ))                                       ;
    kbbc(i7( BBC_E                            )) <= khid(i8to7( KEY_E                            ))                                       ;
    kbbc(i7( BBC_R                            )) <= khid(i8to7( KEY_R                            ))                                       ;
    kbbc(i7( BBC_T                            )) <= khid(i8to7( KEY_T                            ))                                       ;
    kbbc(i7( BBC_Y                            )) <= khid(i8to7( KEY_Y                            ))                                       ;
    kbbc(i7( BBC_U                            )) <= khid(i8to7( KEY_U                            ))                                       ;
    kbbc(i7( BBC_I                            )) <= khid(i8to7( KEY_I                            ))                                       ;
    kbbc(i7( BBC_O                            )) <= khid(i8to7( KEY_O                            ))                                       ;
    kbbc(i7( BBC_P                            )) <= khid(i8to7( KEY_P                            ))                                       ;
    kbbc(i7( BBC_At                           )) <= khid(i8to7( KEY_Grave_Negate_BrokenBar       ))                                       ;
    kbbc(i7( BBC_LSquareBracket_LCurlyBracket )) <= khid(i8to7( KEY_LSquareBracket_LCurlyBracket ))                                       ;
    kbbc(i7( BBC_Underscore_Pound             )) <= khid(i8to7( KEY_Hash_Tilde_UK                ))                                       ;
    kbbc(i7( BBC_UpArrow                      )) <= khid(i8to7( KEY_UpArrow                      )) or khid(i8to7( KEY_KP_8_UpArrow    )) ;
    kbbc(i7( BBC_DownArrow                    )) <= khid(i8to7( KEY_DownArrow                    )) or khid(i8to7( KEY_KP_2_DownArrow  )) ;

    kbbc(i7( BBC_CapsLock                     )) <= khid(i8to7( KEY_CapsLock                     ))                                       ;
    kbbc(i7( BBC_Ctrl                         )) <= khid(i8to7( KEY_LCtrl                        )) or khid(i8to7( KEY_RCtrl           )) ;
    kbbc(i7( BBC_A                            )) <= khid(i8to7( KEY_A                            ))                                       ;
    kbbc(i7( BBC_S                            )) <= khid(i8to7( KEY_S                            ))                                       ;
    kbbc(i7( BBC_D                            )) <= khid(i8to7( KEY_D                            ))                                       ;
    kbbc(i7( BBC_F                            )) <= khid(i8to7( KEY_F                            ))                                       ;
    kbbc(i7( BBC_G                            )) <= khid(i8to7( KEY_G                            ))                                       ;
    kbbc(i7( BBC_H                            )) <= khid(i8to7( KEY_H                            ))                                       ;
    kbbc(i7( BBC_J                            )) <= khid(i8to7( KEY_J                            ))                                       ;
    kbbc(i7( BBC_K                            )) <= khid(i8to7( KEY_K                            ))                                       ;
    kbbc(i7( BBC_L                            )) <= khid(i8to7( KEY_L                            ))                                       ;
    kbbc(i7( BBC_SemiColon_Plus               )) <= khid(i8to7( KEY_SemiColon_Colon              ))                                       ;
    kbbc(i7( BBC_Colon_Asterisk               )) <= khid(i8to7( KEY_Apostrophe_At_UK             ))                                       ;
    kbbc(i7( BBC_RSquareBracket_RCurlyBracket )) <= khid(i8to7( KEY_RSquareBracket_RCurlyBracket ))                                       ;
    kbbc(i7( BBC_Return                       )) <= khid(i8to7( KEY_Enter                        ))                                       ;

    kbbc(i7( BBC_ShiftLock                    )) <= khid(i8to7( KEY_LWin                         ))                                       ;
    kbbc(i7( BBC_Shift                        )) <= khid(i8to7( KEY_LShift                       )) or khid(i8to7( KEY_RShift          )) ;
    kbbc(i7( BBC_Z                            )) <= khid(i8to7( KEY_Z                            ))                                       ;
    kbbc(i7( BBC_X                            )) <= khid(i8to7( KEY_X                            ))                                       ;
    kbbc(i7( BBC_C                            )) <= khid(i8to7( KEY_C                            ))                                       ;
    kbbc(i7( BBC_V                            )) <= khid(i8to7( KEY_V                            ))                                       ;
    kbbc(i7( BBC_B                            )) <= khid(i8to7( KEY_B                            ))                                       ;
    kbbc(i7( BBC_N                            )) <= khid(i8to7( KEY_N                            ))                                       ;
    kbbc(i7( BBC_M                            )) <= khid(i8to7( KEY_M                            ))                                       ;
    kbbc(i7( BBC_Comma_LessThan               )) <= khid(i8to7( KEY_Comma_LessThan               ))                                       ;
    kbbc(i7( BBC_Period_GreaterThan           )) <= khid(i8to7( KEY_Period_GreaterThan           ))                                       ;
    kbbc(i7( BBC_Slash_QuestionMark           )) <= khid(i8to7( KEY_Slash_QuestionMark           ))                                       ;
    kbbc(i7( BBC_Delete                       )) <= khid(i8to7( KEY_Delete                       )) or khid(i8to7( KEY_Backspace       )) ;
    kbbc(i7( BBC_Copy                         )) <= khid(i8to7( KEY_End                          ))                                       ;

    kbbc(i7( BBC_Space                        )) <= khid(i8to7( KEY_Space                        ))                                       ;

    kbbc(i7( BBC_Opt_1                        )) <= opt_dfs_nfs                                                                           ;
    kbbc(i7( BBC_Opt_2                        )) <= opt_spare                                                                             ;
    kbbc(i7( BBC_Opt_3                        )) <= opt_disc(1)                                                                           ;
    kbbc(i7( BBC_Opt_4                        )) <= opt_disc(0)                                                                           ;
    kbbc(i7( BBC_Opt_5                        )) <= opt_boot                                                                              ;
    kbbc(i7( BBC_Opt_6                        )) <= opt_mode(2)                                                                           ;
    kbbc(i7( BBC_Opt_7                        )) <= opt_mode(1)                                                                           ;
    kbbc(i7( BBC_Opt_8                        )) <= opt_mode(0)                                                                           ;

    --------------------------------------------------------------------------------
    -- key readout

    DO_74LS163: process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                c <= 0;
            elsif clken = '1' then
                if kbd_load = '1' then
                    c <= to_integer(unsigned(kbd_col));
                else
                    c <= (c+1) mod 16;
                end if;
            end if;
        end if;
    end process DO_74LS163;

    r <= to_integer(unsigned(kbd_row));

    kbd_break <= khid(i8to7( KEY_F12 ));
    kbd_press <= kbbc((8*c)+r);
    kbd_irq <= '1' when kbbc(7+(8*c) downto 1+(8*c)) /= x"00" else '0';

    --------------------------------------------------------------------------------

end architecture synth;
