// cap.c

#include <stdint.h>

#include "csr.h"
#include "dma.h"
#include "sdram.h"

void cap_init() {
	CSR_POKE(RA_CAPCTRL, CSR_CAPCTRL_RST);
	usleep(1);
	CSR_POKE(RA_CAPCTRL, CSR_CAPCTRL_TEST);
	dma_reset();
	dma_init();
}

void cap_wait(uint32_t addr, uint32_t pixels) {
	uint32_t r;

    dma_start(addr, 4*pixels);
    CSR_POKE(RA_CAPSIZE, pixels);
    CSR_POKE(RA_CAPCTRL, CSR_CAPCTRL_EN | CSR_CAPCTRL_TEST);
    while(1) {
    	r = CSR_PEEK(RA_CAPSTAT);
    	if (r & CSR_CAPSTAT_STOP)
    		break;
    	usleep(1000000);
    }
    CSR_POKE(RA_CAPCTRL, CSR_CAPCTRL_TEST);
    while(!dma_idle()) {
    	printf("mem0 = %08X\r\n", *(uint32_t *)SDRAM_BASEADDR);
    	usleep(1000000);
    }
}
