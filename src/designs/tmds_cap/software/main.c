/*******************************************************************************
** main.c                                                                     **
** MicroBlaze demo application for tmds_cap design.                           **
********************************************************************************
** (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        **
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

#include <stdio.h>
#include <stdint.h>
#include "sleep.h"

#include "xil_cache.h"

#include "csr.h"
#include "sdram.h"
#include "cap.h"

#define PIXELS 2048

int main()
{
    uint32_t r;
    uint8_t led;
    uint32_t btn_init;

    Xil_DCacheDisable();

    printf("tmds_cap\r\n");

    cap_init();

    btn_init = CSR_PEEK(RA_GPI) & 1;
    printf("btn_init = %d\r\n", btn_init);
    btn_init = CSR_PEEK(RA_GPI) & 1;
    printf("btn_init = %d\r\n", btn_init);
    // wait for button 0
    CSR_POKE( RA_GPO, 0 );
    while(1) {
    	r = CSR_PEEK(RA_GPI) & 1;
    	printf("r = %d", r);
    	if (btn_init == r)
    		printf("button not yet pressed, r = %d\r\n", r);
    	else {
    		printf("button pressed! r = %d\r\n", r);
    		break;
    	}
    	usleep(1000000);
    	fflush(stdout);
    }
    led = 15;
    CSR_POKE( RA_GPO, led );

    while(1) {
    	usleep(1000000);
 		printf("\r\n");
 		printf("SDRAM fill (base = %08X)\r\n", SDRAM_BASEADDR);
        sdram_fill(SDRAM_BASEADDR, PIXELS, 0xFFFFFFFF, 0xFFFFFFFF);
 		printf("SDRAM test\r\n");
        sdram_test(SDRAM_BASEADDR, PIXELS, 0xFFFFFFFF, 0xFFFFFFFF);
        *(uint32_t *)SDRAM_BASEADDR = 0xDEADBEEF;
 		printf("capture\r\n");
        cap_wait(SDRAM_BASEADDR, PIXELS);
 		printf("SDRAM test\r\n");
        sdram_test(SDRAM_BASEADDR, PIXELS, 0xFFFFFFFF, 0xFFFFFFFF);
/*
 		printf("SDRAM fill (base = %08X)\r\n", SDRAM_BASEADDR);
        sdram_fill(0x10000000, 0x11000000, 0x31415926, 0x27182817);
 		printf("SDRAM test\r\n");
        sdram_test(0x10000000, 0x11000000, 0x31415926, 0x27182817);
 		printf("\r\n");
        r = CSR_PEEK( RA_SIGNATURE ); printf("  SIGNATURE    : %08X\r\n", r);
        r = CSR_PEEK( RA_FREQ      ); printf("  FREQ         : %08X (%.2f MHz)\r\n", r, r/100.0);
        r = CSR_PEEK( RA_ASTAT     ); printf("  ASTAT        : %08X\r\n", r);
                                      printf("                 SKEW2 = %d, SKEW1 = %d\r\n", (r>>10)&3, (r>>8)&3);
                                      printf("                 ALIGNP = %d, ALIGNS2 = %d, ALIGNS1 = %d, ALIGNS0 = %d\r\n", (r>>7)&1, (r>>6)&1, (r>>5)&1, (r>>4)&1);
                                      printf("                 BAND = %d, LOCK = %d\r\n", (r>>1)&3, r&1);
        r = CSR_PEEK( RA_ATAPMASK0 ); printf("  ATAPMASK0    : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPMASK1 ); printf("  ATAPMASK1    : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPMASK2 ); printf("  ATAPMASK2    : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAP      ); printf("  ATAP         : %08X (%d,%d,%d)\r\n", r, (r>>16)&31, (r>>8)&31, r&31);
        r = CSR_PEEK( RA_ABITSLIP  ); printf("  ABITSLIP     : %08X (%d,%d,%d)\r\n", r, (r>>8)&15, (r>>4)&15, r&15);
        r = CSR_PEEK( RA_ACYCLE0   ); printf("  ACYCLE0      : %08X\r\n", r);
        r = CSR_PEEK( RA_ACYCLE1   ); printf("  ACYCLE1      : %08X\r\n", r);
        r = CSR_PEEK( RA_ACYCLE2   ); printf("  ACYCLE2      : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPOK0   ); printf("  ATAPOK0      : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPOK1   ); printf("  ATAPOK1      : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPOK2   ); printf("  ATAPOK2      : %08X\r\n", r);
        r = CSR_PEEK( RA_AGAIN0    ); printf("  AGAIN0       : %08X\r\n", r);
        r = CSR_PEEK( RA_AGAIN1    ); printf("  AGAIN1       : %08X\r\n", r);
        r = CSR_PEEK( RA_AGAIN2    ); printf("  AGAIN2       : %08X\r\n", r);
        r = CSR_PEEK( RA_AGAINP    ); printf("  AGAINP       : %08X\r\n", r);
        r = CSR_PEEK( RA_ALOSS0    ); printf("  ALOSS0       : %08X\r\n", r);
        r = CSR_PEEK( RA_ALOSS1    ); printf("  ALOSS1       : %08X\r\n", r);
        r = CSR_PEEK( RA_ALOSS2    ); printf("  ALOSS2       : %08X\r\n", r);
        r = CSR_PEEK( RA_ALOSSP    ); printf("  ALOSSP       : %08X\r\n", r);
        r = CSR_PEEK( RA_CAPCTRL   ); printf("  CAPCTRL      : %08X\r\n", r);
        r = CSR_PEEK( RA_CAPSIZE   ); printf("  CAPSIZE      : %08X\r\n", r);
        r = CSR_PEEK( RA_CAPSTAT   ); printf("  CAPSTAT      : %08X\r\n", r);
        r = CSR_PEEK( RA_CAPCOUNT  ); printf("  CAPCOUNT     : %08X\r\n", r);
        r = CSR_PEEK( RA_SCRATCH   ); printf("  SCRATCH      : %08X\r\n", r);
*/
        CSR_POKE( RA_GPO, led );
        led = (led-1) & 0xF;
    }
}

