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
#include "peekpoke.h"
#include "tmds_cap_regs_axi.h"

int main()
{
    printf("tmds_cap_digilent_nexys_video\n");
    while(1) {
		printf("\n");
		printf("     COUNT_FREQ : %08X\n", peek32(RA_COUNT_FREQ		));
		printf("           LOCK : %08X\n", peek32(RA_LOCK			));
		printf("          ALIGN : %08X\n", peek32(RA_ALIGN 			));
		printf("     TAP_MASK_0 : %08X\n", peek32(RA_TAP_MASK_0		));
		printf("     TAP_MASK_1 : %08X\n", peek32(RA_TAP_MASK_1		));
		printf("     TAP_MASK_2 : %08X\n", peek32(RA_TAP_MASK_2		));
		printf("          TAP_0 : %08X\n", peek32(RA_TAP_0			));
		printf("          TAP_1 : %08X\n", peek32(RA_TAP_4			));
		printf("          TAP_2 : %08X\n", peek32(RA_TAP_8			));
		printf("      BITSLIP_0 : %08X\n", peek32(RA_BITSLIP_0		));
		printf("      BITSLIP_1 : %08X\n", peek32(RA_BITSLIP_1		));
		printf("      BITSLIP_2 : %08X\n", peek32(RA_BITSLIP_2		));
		printf("COUNT_ATTEMPT_0 : %08X\n", peek32(RA_COUNT_ATTEMPT_0));
		printf("COUNT_ATTEMPT_1 : %08X\n", peek32(RA_COUNT_ATTEMPT_1));
		printf("COUNT_ATTEMPT_2 : %08X\n", peek32(RA_COUNT_ATTEMPT_2));
		printf("  COUNT_ALIGN_0 : %08X\n", peek32(RA_COUNT_ALIGN_0	));
		printf("  COUNT_ALIGN_1 : %08X\n", peek32(RA_COUNT_ALIGN_1	));
		printf("  COUNT_ALIGN_2 : %08X\n", peek32(RA_COUNT_ALIGN_2	));
		printf(" COUNT_RETAIN_0 : %08X\n", peek32(RA_COUNT_RETAIN_0	));
		printf(" COUNT_RETAIN_1 : %08X\n", peek32(RA_COUNT_RETAIN_1	));
		printf(" COUNT_RETAIN_2 : %08X\n", peek32(RA_COUNT_RETAIN_2	));
		printf("COUNT_UNALIGN_0 : %08X\n", peek32(RA_COUNT_UNALIGN_0));
		printf("COUNT_UNALIGN_1 : %08X\n", peek32(RA_COUNT_UNALIGN_1));
		printf("COUNT_UNALIGN_2 : %08X\n", peek32(RA_COUNT_UNALIGN_2));
    }
}
