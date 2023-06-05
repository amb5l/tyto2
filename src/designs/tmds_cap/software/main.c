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
#include "sleep.h"
#include "tmds_cap_csr.h"

int main()
{
    unsigned int led;
    
    led = 0;
    while(1) {
    	usleep(1000000);
        printf("tmds_cap\r\n");
 		printf("\r\n");
        printf("  SIGNATURE    : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_SIGNATURE ));
        printf("  FREQ         : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_FREQ      ));
        printf("  ASTAT        : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ASTAT     ));
        printf("  ATAPMASK0    : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ATAPMASK0 ));
        printf("  ATAPMASK1    : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ATAPMASK1 ));
        printf("  ATAPMASK2    : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ATAPMASK2 ));
        printf("  ATAP         : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ATAP      ));
        printf("  ABITSLIP     : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ABITSLIP  ));
        printf("  ACYCLE0      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ACYCLE0   ));
        printf("  ACYCLE1      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ACYCLE1   ));
        printf("  ACYCLE2      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ACYCLE2   ));
        printf("  ATAPOK0      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ATAPOK0   ));
        printf("  ATAPOK1      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ATAPOK1   ));
        printf("  ATAPOK2      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ATAPOK2   ));
        printf("  AGAIN0       : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_AGAIN0    ));
        printf("  AGAIN1       : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_AGAIN1    ));
        printf("  AGAIN2       : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_AGAIN2    ));
        printf("  AGAINP       : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_AGAINP    ));
        printf("  ALOSS0       : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ALOSS0    ));
        printf("  ALOSS1       : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ALOSS1    ));
        printf("  ALOSS2       : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ALOSS2    ));
        printf("  ALOSSP       : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_ALOSSP    ));
        printf("  CAPCTRL      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_CAPCTRL   ));
        printf("  CAPSIZE      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_CAPSIZE   ));
        printf("  CAPSTAT      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_CAPSTAT   ));
        printf("  CAPCOUNT     : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_CAPCOUNT  ));
        printf("  SCRATCH      : %08X\r\n", TMDS_CAP_CSR_PEEK( RA_SCRATCH   ));
        TMDS_CAP_CSR_POKE( RA_LED, led );
        led = (led+1) & 0xF;
    }
}

