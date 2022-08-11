/*******************************************************************************
** main.c                                                                     **
** MicroBlaze demo application for mb_cb design.                              **
********************************************************************************
** (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        **
** This file is part of The Tyto Project. The Tyto Project is free software:  **
** you can redistribute it and/or modify it under the terms of the GNU Lesser **
** General Public License as published by the Free Software Foundation,       **
** either version 3 of the License, or (at your option) any later version.    **
** The Tyto Project is distributed in the hope that it will be useful, but    **
** WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY **
** or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     **
** License for more details. You should have received a copy of the GNU       **
** Lesser General Public License along with The Tyto Project. If not, see     **
** https://www.gnu.org/licenses/.                                             **
*******************************************************************************/

#include <stdint.h>
#include <string.h>

#include "axi_gpio.h"
#include "cb.h"

#define MODE 0 // 0 = 80x25 (NTSC), 1 = 80x32 (PAL)

#define GPI_HID_REQ  8
#define GPI_H2D_ACK  9
#define GPI_H2D_NACK 10
#define GPI_HID_DLSB 16

#define GPO_HID_ACK  8
#define GPO_H2D_REQ  9
#define GPO_H2D_DLSB 16

// USB HID key codes
#define KEY_A                            0x04
#define KEY_B                            0x05
#define KEY_C                            0x06
#define KEY_D                            0x07
#define KEY_E                            0x08
#define KEY_F                            0x09
#define KEY_G                            0x0A
#define KEY_H                            0x0B
#define KEY_I                            0x0C
#define KEY_J                            0x0D
#define KEY_K                            0x0E
#define KEY_L                            0x0F
#define KEY_M                            0x10
#define KEY_N                            0x11
#define KEY_O                            0x12
#define KEY_P                            0x13
#define KEY_Q                            0x14
#define KEY_R                            0x15
#define KEY_S                            0x16
#define KEY_T                            0x17
#define KEY_U                            0x18
#define KEY_V                            0x19
#define KEY_W                            0x1A
#define KEY_X                            0x1B
#define KEY_Y                            0x1C
#define KEY_Z                            0x1D
#define KEY_1_ExclamationMark            0x1E
#define KEY_2_At_US                      0x1F
#define KEY_2_DoubleQuote_UK             0x1F
#define KEY_3_Hash_US                    0x20
#define KEY_3_Pound_UK                   0x20
#define KEY_4_Dollar                     0x21
#define KEY_5_Percent                    0x22
#define KEY_6_Caret                      0x23
#define KEY_7_Ampersand                  0x24
#define KEY_8_Asterisk                   0x25
#define KEY_9_LRoundBracket              0x26
#define KEY_0_RRoundBracket              0x27
#define KEY_Enter                        0x28
#define KEY_Escape                       0x29
#define KEY_Backspace                    0x2A
#define KEY_Tab                          0x2B
#define KEY_Space                        0x2C
#define KEY_Minus_Underscore             0x2D
#define KEY_Equal_Plus                   0x2E
#define KEY_LSquareBracket_LCurlyBracket 0x2F
#define KEY_RSquareBracket_RCurlyBracket 0x30
#define KEY_Backslash_Pipe_US            0x31
#define KEY_Hash_Tilde_UK                0x32
#define KEY_SemiColon_Colon              0x33
#define KEY_Apostrophe_DoubleQuote_US    0x34
#define KEY_Apostrophe_At_UK             0x34
#define KEY_Grave_Negate_BrokenBar       0x35
#define KEY_Comma_LessThan               0x36
#define KEY_Period_GreaterThan           0x37
#define KEY_Slash_QuestionMark           0x38
#define KEY_CapsLock                     0x39
#define KEY_F1                           0x3A
#define KEY_F2                           0x3B
#define KEY_F3                           0x3C
#define KEY_F4                           0x3D
#define KEY_F5                           0x3E
#define KEY_F6                           0x3F
#define KEY_F7                           0x40
#define KEY_F8                           0x41
#define KEY_F9                           0x42
#define KEY_F10                          0x43
#define KEY_F11                          0x44
#define KEY_F12                          0x45
#define KEY_PrtScr_SysRq                 0x46
#define KEY_ScrollLock                   0x47
#define KEY_Pause_Break                  0x48
#define KEY_Insert                       0x49
#define KEY_Home                         0x4A
#define KEY_PgUp                         0x4B
#define KEY_Delete                       0x4C
#define KEY_End                          0x4D
#define KEY_PgDn                         0x4E
#define KEY_RightArrow                   0x4F
#define KEY_LeftArrow                    0x50
#define KEY_DownArrow                    0x51
#define KEY_UpArrow                      0x52
#define KEY_NumLock                      0x53
#define KEY_KP_Slash                     0x54
#define KEY_KP_Asterisk                  0x55
#define KEY_KP_Minus                     0x56
#define KEY_KP_Plus                      0x57
#define KEY_KP_Enter                     0x58
#define KEY_KP_1_End                     0x59
#define KEY_KP_2_DownArrow               0x5A
#define KEY_KP_3_PgDn                    0x5B
#define KEY_KP_4_LeftArrow               0x5C
#define KEY_KP_5                         0x5D
#define KEY_KP_6_RightArrow              0x5E
#define KEY_KP_7_Home                    0x5F
#define KEY_KP_8_UpArrow                 0x60
#define KEY_KP_9_PgUp                    0x61
#define KEY_KP_0_Ins                     0x62
#define KEY_KP_Period_Delete             0x63
#define KEY_Backslash_Pipe_UK            0x64
#define KEY_Menu                         0x65
#define KEY_LCtrl                        0xE0
#define KEY_LShift                       0xE1
#define KEY_LAlt                         0xE2
#define KEY_LWin                         0xE3
#define KEY_RCtrl                        0xE4
#define KEY_RShift                       0xE5
#define KEY_RWin                         0xE6
#define KEY_RAlt                         0xE7

uint16_t kbd_get(void) {

    uint16_t k;
	uint32_t r;

    while(1) { // wait for req
        r = axi_gpio_get_gpi(0);
        if (r & (1 << GPI_HID_REQ))
            break;
    }
    axi_gpio_set_gpo_bit(0,GPO_HID_ACK,1); // assert ack
    k = (r >> GPI_HID_DLSB) & 0x1FF;
    r = axi_gpio_get_gpo(0);
    r = (r & 0x0000FFFF) | (k << GPO_H2D_DLSB);
	axi_gpio_set_gpo(0, r);
	while(axi_gpio_get_gpi_bit(0,GPI_HID_REQ)); // wait for !req
    axi_gpio_set_gpo_bit(0,GPO_HID_ACK,0); // negate ack
    return k;
}

int main()
{
	uint16_t k;

	cb_init(MODE);
	cb_set_border(CB_LIGHT_BLUE);
	cb_set_col(CB_YELLOW, CB_BLUE);
	printf("mb_cb_ps2 application running : press a key...\n");
	axi_gpio_set_gpo_bit(0,31,1);
	while(1) {
        k = kbd_get();
        printf("0x%02X  ", k & 0xFF);
        if (k & 0x100)
            printf("     MAKE:");
        else
            printf("    break:");
        switch(k & 0xFF) {
            case KEY_A                            : printf("A\n"); break;
            case KEY_B                            : printf("B\n"); break;
            case KEY_C                            : printf("C\n"); break;
            case KEY_D                            : printf("D\n"); break;
            case KEY_E                            : printf("E\n"); break;
            case KEY_F                            : printf("F\n"); break;
            case KEY_G                            : printf("G\n"); break;
            case KEY_H                            : printf("H\n"); break;
            case KEY_I                            : printf("I\n"); break;
            case KEY_J                            : printf("J\n"); break;
            case KEY_K                            : printf("K\n"); break;
            case KEY_L                            : printf("L\n"); break;
            case KEY_M                            : printf("M\n"); break;
            case KEY_N                            : printf("N\n"); break;
            case KEY_O                            : printf("O\n"); break;
            case KEY_P                            : printf("P\n"); break;
            case KEY_Q                            : printf("Q\n"); break;
            case KEY_R                            : printf("R\n"); break;
            case KEY_S                            : printf("S\n"); break;
            case KEY_T                            : printf("T\n"); break;
            case KEY_U                            : printf("U\n"); break;
            case KEY_V                            : printf("V\n"); break;
            case KEY_W                            : printf("W\n"); break;
            case KEY_X                            : printf("X\n"); break;
            case KEY_Y                            : printf("Y\n"); break;
            case KEY_Z                            : printf("Z\n"); break;
            case KEY_1_ExclamationMark            : printf("1_ExclamationMark\n"); break;
            case KEY_2_At_US                      : printf("2_At (US) or 2_DoubleQuote (UK)\n"); break;
            case KEY_3_Hash_US                    : printf("3_Hash (US) or 3_Pound (UK)\n"); break;
            case KEY_4_Dollar                     : printf("4_Dollar\n"); break;
            case KEY_5_Percent                    : printf("5_Percent\n"); break;
            case KEY_6_Caret                      : printf("6_Caret\n"); break;
            case KEY_7_Ampersand                  : printf("7_Ampersand\n"); break;
            case KEY_8_Asterisk                   : printf("8_Asterisk\n"); break;
            case KEY_9_LRoundBracket              : printf("9_LRoundBracket\n"); break;
            case KEY_0_RRoundBracket              : printf("0_RRoundBracket\n"); break;
            case KEY_Enter                        : printf("Enter\n"); break;
            case KEY_Escape                       : printf("Escape\n"); break;
            case KEY_Backspace                    : printf("Backspace\n"); break;
            case KEY_SemiColon_Colon              : printf("SemiColon_Colon\n"); break;
            case KEY_Tab                          : printf("Tab\n"); break;
            case KEY_Space                        : printf("Space\n"); break;
            case KEY_Minus_Underscore             : printf("Minus_Underscore\n"); break;
            case KEY_Equal_Plus                   : printf("Equal_Plus\n"); break;
            case KEY_LSquareBracket_LCurlyBracket : printf("LSquareBracket_LCurlyBracket\n"); break;
            case KEY_RSquareBracket_RCurlyBracket : printf("RSquareBracket_RCurlyBracket\n"); break;
            case KEY_Backslash_Pipe_US            : printf("Backslash_Pipe (US)\n"); break;
            case KEY_Hash_Tilde_UK                : printf("Hash_Tilde (UK)\n"); break;
            case KEY_Apostrophe_DoubleQuote_US    : printf("Apostrophe_DoubleQuote (US) or Apostrophe_At (UK)\n"); break;
            case KEY_Grave_Negate_BrokenBar       : printf("Grave_Negate_BrokenBar\n"); break;
            case KEY_Comma_LessThan               : printf("Comma_LessThan\n"); break;
            case KEY_Period_GreaterThan           : printf("Period_GreaterThan\n"); break;
            case KEY_Slash_QuestionMark           : printf("Slash_QuestionMark\n"); break;
            case KEY_CapsLock                     : printf("CapsLock\n"); break;
            case KEY_F1                           : printf("F1\n"); break;
            case KEY_F2                           : printf("F2\n"); break;
            case KEY_F3                           : printf("F3\n"); break;
            case KEY_F4                           : printf("F4\n"); break;
            case KEY_F5                           : printf("F5\n"); break;
            case KEY_F6                           : printf("F6\n"); break;
            case KEY_F7                           : printf("F7\n"); break;
            case KEY_F8                           : printf("F8\n"); break;
            case KEY_F9                           : printf("F9\n"); break;
            case KEY_F10                          : printf("F10\n"); break;
            case KEY_F11                          : printf("F11\n"); break;
            case KEY_F12                          : printf("F12\n"); break;
            case KEY_PrtScr_SysRq                 : printf("PrtScr_SysRq\n"); break;
            case KEY_ScrollLock                   : printf("ScrollLock\n"); break;
            case KEY_Pause_Break                  : printf("Pause_Break\n"); break;
            case KEY_Insert                       : printf("Insert\n"); break;
            case KEY_Home                         : printf("Home\n"); break;
            case KEY_PgUp                         : printf("PgUp\n"); break;
            case KEY_Delete                       : printf("Delete\n"); break;
            case KEY_End                          : printf("End\n"); break;
            case KEY_PgDn                         : printf("PgDn\n"); break;
            case KEY_RightArrow                   : printf("RightArrow\n"); break;
            case KEY_LeftArrow                    : printf("LeftArrow\n"); break;
            case KEY_DownArrow                    : printf("DownArrow\n"); break;
            case KEY_UpArrow                      : printf("UpArrow\n"); break;
            case KEY_NumLock                      : printf("NumLock\n"); break;
            case KEY_KP_Slash                     : printf("KP_Slash\n"); break;
            case KEY_KP_Asterisk                  : printf("KP_Asterisk\n"); break;
            case KEY_KP_Minus                     : printf("KP_Minus\n"); break;
            case KEY_KP_Plus                      : printf("KP_Plus\n"); break;
            case KEY_KP_Enter                     : printf("KP_Enter\n"); break;
            case KEY_KP_1_End                     : printf("KP_1_End\n"); break;
            case KEY_KP_2_DownArrow               : printf("KP_2_DownArrow\n"); break;
            case KEY_KP_3_PgDn                    : printf("KP_3_PgDn\n"); break;
            case KEY_KP_4_LeftArrow               : printf("KP_4_LeftArrow\n"); break;
            case KEY_KP_5                         : printf("KP_5\n"); break;
            case KEY_KP_6_RightArrow              : printf("KP_6_RightArrow\n"); break;
            case KEY_KP_7_Home                    : printf("KP_7_Home\n"); break;
            case KEY_KP_8_UpArrow                 : printf("KP_8_UpArrow\n"); break;
            case KEY_KP_9_PgUp                    : printf("KP_9_PgUp\n"); break;
            case KEY_KP_0_Ins                     : printf("KP_0_Ins\n"); break;
            case KEY_KP_Period_Delete             : printf("KP_Period_Delete\n"); break;
            case KEY_Backslash_Pipe_UK            : printf("Backslash_Pipe (UK)\n"); break;
            case KEY_Menu                         : printf("Menu\n"); break;
            case KEY_LCtrl                        : printf("LCtrl\n"); break;
            case KEY_LShift                       : printf("LShift\n"); break;
            case KEY_LAlt                         : printf("LAlt\n"); break;
            case KEY_LWin                         : printf("LWin\n"); break;
            case KEY_RCtrl                        : printf("RCtrl\n"); break;
            case KEY_RShift                       : printf("RShift\n"); break;
            case KEY_RWin                         : printf("RWin\n"); break;
            case KEY_RAlt                         : printf("RAlt\n"); break;
        }
    }
}
