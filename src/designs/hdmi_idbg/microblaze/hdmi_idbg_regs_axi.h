/*******************************************************************************
** hdmi_idbg_regs_axi.h                                                       **
** Status register definitions for hdmi_rx_selectio IP.                       **
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

#ifndef _hdmi_idbg_REGS_AXI_H_
#define _hdmi_idbg_REGS_AXI_H_

#include "xparameters.h"

#define REGS_BASE 0x70000000

#define RA_COUNT_FREQ		(REGS_BASE+0x00)
#define RA_LOCK				(REGS_BASE+0x04)
#define RA_ALIGN 			(REGS_BASE+0x08)
#define RA_TAP_MASK_0		(REGS_BASE+0x10)
#define RA_TAP_MASK_1		(REGS_BASE+0x14)
#define RA_TAP_MASK_2		(REGS_BASE+0x18)
#define RA_TAP_0			(REGS_BASE+0x20)
#define RA_TAP_4			(REGS_BASE+0x24)
#define RA_TAP_8			(REGS_BASE+0x28)
#define RA_BITSLIP_0		(REGS_BASE+0x30)
#define RA_BITSLIP_1		(REGS_BASE+0x34)
#define RA_BITSLIP_2		(REGS_BASE+0x38)
#define RA_COUNT_ACYCLE_0	(REGS_BASE+0x40)
#define RA_COUNT_ACYCLE_1	(REGS_BASE+0x44)
#define RA_COUNT_ACYCLE_2	(REGS_BASE+0x48)
#define RA_COUNT_TAP_OK_0	(REGS_BASE+0x50)
#define RA_COUNT_TAP_OK_1	(REGS_BASE+0x54)
#define RA_COUNT_TAP_OK_2	(REGS_BASE+0x58)
#define RA_COUNT_AGAIN_S_0	(REGS_BASE+0x60)
#define RA_COUNT_AGAIN_S_1	(REGS_BASE+0x64)
#define RA_COUNT_AGAIN_S_2	(REGS_BASE+0x68)
#define RA_COUNT_AGAIN_P	(REGS_BASE+0x6C)
#define RA_COUNT_ALOSS_S_0	(REGS_BASE+0x70)
#define RA_COUNT_ALOSS_S_1	(REGS_BASE+0x74)
#define RA_COUNT_ALOSS_S_2	(REGS_BASE+0x78)
#define RA_COUNT_ALOSS_P	(REGS_BASE+0x7C)

#endif
