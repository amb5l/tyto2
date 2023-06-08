// cap.c

#include "csr.h"
#include "dma.h"
#include "sdram.h"

void capture(uint32_t addr, uint32_t pixels) {
    dma_start(addr, 4*pixels);
    CSR_POKE(RA_CAPSIZE, pixels);
    CSR_POKE(RA_CAPCTRL, CSR_CAPCTRL_RUN | CSR_CAPCTRL_TEST);
    while(!dma_idle());
}
