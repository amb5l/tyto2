/*******************************************************************************
** cb.c                                                                       **
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

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "xil_types.h"
#include "xil_mem.h"

#include "bsp.h"
#include "cb.h"

uint8_t cb_width = 0;
uint8_t cb_height = 0;
uint8_t cb_x = 0;
uint8_t cb_y = 0;
uint8_t cb_attr = 0x0F;

void cb_init(uint8_t w, uint8_t h)
{
    cb_width  = w;
    cb_height = h;
#ifdef BUILD_CFG_DBG
	for (uint8_t x = 0; x < cb_width; x++)
		for (uint8_t y = 0; y < cb_height; y++) {
			POKE_CHAR_ATTR(x,y,0,cb_attr);
            POKE_CHAR(x,y,0);
        }
#endif
}

void cb_poke_char(uint8_t x, uint8_t y, uint8_t c)
{
	POKE_CHAR(x,y,c);
}

void cb_poke_attr(uint8_t x, uint8_t y, uint8_t a)
{
	POKE_ATTR(x,y,a);
}

void cb_poke_col_fg(uint8_t x, uint8_t y, uint8_t col)
{
	POKE_COL_FG(x,y,col);
}

void cb_poke_col_bg(uint8_t x, uint8_t y, uint8_t col)
{
	POKE_COL_BG(x,y,col);
}

void cb_poke_char_attr(uint8_t x, uint8_t y, uint8_t c, uint8_t a)
{
	POKE_CHAR_ATTR(x,y,c,a);
}

void cb_set_pos(uint8_t x, uint8_t y)
{
	cb_x = x;
	cb_y = y;
}

void cb_set_border(uint8_t col)
{
	bsp_cb_border(col);
}

void cb_set_attr(uint8_t attr)
{
	cb_attr = attr;
}

void cb_set_col(uint8_t fg, uint8_t bg)
{
	cb_attr = ((bg & 0x0F) << 4) | (fg & 0x0F);
}

void cb_set_col_fg(uint8_t col)
{
	cb_attr = (cb_attr & 0xF0) | (col & 0x0F);
}

void cb_set_col_bg(uint8_t col)
{
	cb_attr = (cb_attr & 0x0F) | ((col & 0x0F) << 4);
}

void cb_scroll_up()
{
	Xil_MemCpy((void *)CB_BUF, (void *)(CB_BUF+(cb_width<<1)), (cb_width<<1)*(cb_height-1));
	memset((void *)CB_BUF+((cb_width<<1)*(cb_height-1)), 0, (size_t)(cb_width<<1));
}

void cb_newline()
{
	cb_x = 0;
	if (++cb_y == cb_height) {
		cb_y--;
		cb_scroll_up();
	}
}

void cb_putc(void *p, char c)
{
	if (c >= 32) { // display characters 32..255
		POKE_CHAR_ATTR(cb_x++, cb_y, c, cb_attr);
		if (cb_x == cb_width) {
			cb_newline();
		}
	}
	else { // control characters 0..31
		switch(c) {
			case 10 :	// newline
				cb_newline();
				break;
			case 13 :	// CR
				cb_x = 0;
				break;
		}
	}
}
