// sdram.h

#ifndef _SDRAM_H_
#define _SDRAM_H_

#include "xparameters.h"

#ifdef __arm__
#define SDRAM_BASEADDR  XPAR_PS7_DDR_0_S_AXI_BASEADDR
#define SDRAM_HIGHADDR  XPAR_PS7_DDR_0_S_AXI_HIGHADDR
#endif

void sdram_fill(uint32_t addr, uint32_t len, uint32_t start, uint32_t incr);
void sdram_test(uint32_t addr, uint32_t len, uint32_t start, uint32_t incr);

#endif
