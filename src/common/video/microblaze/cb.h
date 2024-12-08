/*******************************************************************************
** cb.h                                                                       **
** Simple character buffer driver.                                            **
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

#ifndef _CB_H_
#define _CB_H_

#include "bsp.h"
#include "peekpoke.h"
#include "printf.h"

#define CB_BLACK			0x0
#define CB_BLUE			    0x1
#define CB_GREEN			0x2
#define CB_CYAN			    0x3
#define CB_RED				0x4
#define CB_MAGENTA			0x5
#define CB_BROWN			0x6
#define CB_LIGHT_GRAY		0x7
#define CB_DARK_GRAY		0x8
#define CB_LIGHT_BLUE		0x9
#define CB_LIGHT_GREEN		0xA
#define CB_LIGHT_CYAN		0xB
#define CB_LIGHT_RED		0xC
#define CB_LIGHT_MAGENTA	0xD
#define CB_YELLOW			0xE
#define CB_WHITE			0xF

extern uint8_t cb_width;
extern uint8_t cb_height;
extern uint8_t cb_i;
extern uint8_t cb_x;
extern uint8_t cb_y;
extern uint8_t cb_attr;

#define POKE_CHAR(x,y,c) poke8(CB_BUF+((x+(y*cb_width))<<1),c)
#define PEEK_CHAR(x,y) peek8(CB_BUF+((x+(y*cb_width))<<1))
#define POKE_ATTR(x,y,a) poke8(CB_BUF+((x+(y*cb_width))<<1)+1,a)
#define PEEK_ATTR(x,y) peek8(CB_BUF+((x+(y*cb_width))<<1)+1)
#define POKE_COL_FG(x,y,col) POKE_ATTR(x,y,(PEEK_ATTR(x,y) & 0xF0)|(col & 0x0F))
#define POKE_COL_BG(x,y,col) POKE_ATTR(x,y,(PEEK_ATTR(x,y) & 0x0F)|((col & 0x0F)<<4))
#define POKE_CHAR_ATTR(x,y,c,a) poke16(CB_BUF+((x+(y*cb_width))<<1),(a << 8)|c)

void cb_init(uint8_t w, uint8_t h);
void cb_poke_char(uint8_t x, uint8_t y, uint8_t c);
void cb_poke_attr(uint8_t x, uint8_t y, uint8_t a);
void cb_poke_col_fg(uint8_t x, uint8_t y, uint8_t col);
void cb_poke_col_bg(uint8_t x, uint8_t y, uint8_t col);
void cb_poke_char_attr(uint8_t x, uint8_t y, uint8_t c, uint8_t a);
void cb_set_pos(uint8_t x, uint8_t y);
void cb_set_border(uint8_t col);
void cb_set_attr(uint8_t attr);
void cb_set_col(uint8_t fg, uint8_t bg);
void cb_set_col_fg(uint8_t col);
void cb_set_col_bg(uint8_t col);
void cb_scroll_up();
void cb_newline();
void cb_putc(void *p, char c);

#endif
