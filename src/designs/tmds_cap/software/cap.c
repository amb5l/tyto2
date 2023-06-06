// cap.c

/*

#include "csr.h"

#define S2MM_DMACR          0x30 // control register
#define S2MM_DMASR          0x34 // status register
#define S2MM_DMADA          0x48 // destination address bits 31..0
#define S2MM_DMADA_MSB      0x4C // destination address bits 63..32
#define S2MM_LENGTH         0x58 // length (bytes)

#define S2MM_DMACR_RS       1<<0
#define S2MM_DMACR_RESET    1<<2

#define S2MM_DMASR_HALTED   1<<0
#define S2MM_DMASR_IDLE     1<<1

void cap(uint32_t baseaddr, uint32_t pixels) {
    
    DMAC_POKE(S2MM_DMADA,  baseaddr);
    DMAC_POKE(S2MM_LENGTH, pixels<<2);
    DMAC_POKE(S2MM_DMACR,  S2MM_DMACR_RS); // run
    
    CSR_POKE(RA_CAPSIZE, pixels);
    CSR_POKE(RA_CAPCTRL, 0);      // unreset
    CSR_POKE(RA_CAPCTRL, 1);      // run
    
    // wait for stream to finish
    while()
        ;
    // wait for DMAC to finish
    
    
    
}

*/