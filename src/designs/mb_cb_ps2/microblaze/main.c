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
#define GPI_H2D_DLSB 16

uint16_t kbd_get(void) {

    uint32_t r;
    while(1) { // wait for req
        r = axi_gpio_get_gpi(0);
        if (r & (1 << GPI_HID_REQ))
            break;
    }
    axi_gpio_set_gpo_bit(0,GPO_HID_ACK,1); // assert ack
    while(axi_gpio_get_gpi_bit(0,GPI_HID_REQ)); // wait for !req
    return (r >> GPI_HID_DLSB) & 0x1FF;
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
            printf("MAKE\n");
        else
            printf("break\n");
    }
}
