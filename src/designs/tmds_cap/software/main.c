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
#include "xil_printf.h"
#include "sleep.h"
#include "tmds_cap_csr.h"

int main()
{
    while(1) {
    	usleep(1000000);
        print("tmds_cap\r\n");
    }
}

/*
 * 		print("\n");
        print("  SIGNATURE    : %08X\n", TMDS_CAP_CSR_PEEK( RA_SIGNATURE ));
        print("  FREQ         : %08X\n", TMDS_CAP_CSR_PEEK( RA_FREQ      ));
        print("  ASTAT        : %08X\n", TMDS_CAP_CSR_PEEK( RA_ASTAT     ));
        print("  ATAPMASK0    : %08X\n", TMDS_CAP_CSR_PEEK( RA_ATAPMASK0 ));
        print("  ATAPMASK1    : %08X\n", TMDS_CAP_CSR_PEEK( RA_ATAPMASK1 ));
        print("  ATAPMASK2    : %08X\n", TMDS_CAP_CSR_PEEK( RA_ATAPMASK2 ));
        print("  ATAP         : %08X\n", TMDS_CAP_CSR_PEEK( RA_ATAP      ));
        print("  ABITSLIP     : %08X\n", TMDS_CAP_CSR_PEEK( RA_ABITSLIP  ));
        print("  ACYCLE0      : %08X\n", TMDS_CAP_CSR_PEEK( RA_ACYCLE0   ));
        print("  ACYCLE1      : %08X\n", TMDS_CAP_CSR_PEEK( RA_ACYCLE1   ));
        print("  ACYCLE2      : %08X\n", TMDS_CAP_CSR_PEEK( RA_ACYCLE2   ));
        print("  ATAPOK0      : %08X\n", TMDS_CAP_CSR_PEEK( RA_ATAPOK0   ));
        print("  ATAPOK1      : %08X\n", TMDS_CAP_CSR_PEEK( RA_ATAPOK1   ));
        print("  ATAPOK2      : %08X\n", TMDS_CAP_CSR_PEEK( RA_ATAPOK2   ));
        print("  AGAIN0       : %08X\n", TMDS_CAP_CSR_PEEK( RA_AGAIN0    ));
        print("  AGAIN1       : %08X\n", TMDS_CAP_CSR_PEEK( RA_AGAIN1    ));
        print("  AGAIN2       : %08X\n", TMDS_CAP_CSR_PEEK( RA_AGAIN2    ));
        print("  AGAINP       : %08X\n", TMDS_CAP_CSR_PEEK( RA_AGAINP    ));
        print("  ALOSS0       : %08X\n", TMDS_CAP_CSR_PEEK( RA_ALOSS0    ));
        print("  ALOSS1       : %08X\n", TMDS_CAP_CSR_PEEK( RA_ALOSS1    ));
        print("  ALOSS2       : %08X\n", TMDS_CAP_CSR_PEEK( RA_ALOSS2    ));
        print("  ALOSSP       : %08X\n", TMDS_CAP_CSR_PEEK( RA_ALOSSP    ));
        print("  CAPCTRL      : %08X\n", TMDS_CAP_CSR_PEEK( RA_CAPCTRL   ));
        print("  CAPSIZE      : %08X\n", TMDS_CAP_CSR_PEEK( RA_CAPSIZE   ));
        print("  CAPSTAT      : %08X\n", TMDS_CAP_CSR_PEEK( RA_CAPSTAT   ));
        print("  CAPCOUNT     : %08X\n", TMDS_CAP_CSR_PEEK( RA_CAPCOUNT  ));
        print("  SCRATCH      : %08X\n", TMDS_CAP_CSR_PEEK( RA_SCRATCH   ));
 */
