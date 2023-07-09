// dma.c

#include <stdio.h>
#include <stdint.h>

#include "xparameters.h"

#define DMA_BASEADDR XPAR_AXI_DMA_BASEADDR

#define S2MM_DMACR        0x30 // control register
#define S2MM_DMASR        0x34 // status register
#define S2MM_DMADA        0x48 // destination address bits 31..0
#define S2MM_DMADA_MSB    0x4C // destination address bits 63..32
#define S2MM_LENGTH       0x58 // length (bytes)
#define S2MM_DMACR_RS     1<<0
#define S2MM_DMACR_RESET  1<<2
#define S2MM_DMASR_HALTED 1<<0
#define S2MM_DMASR_IDLE   1<<1

#define PEEK(a)   *(volatile uint32_t *)(DMA_BASEADDR+a)
#define POKE(a,d) *(volatile uint32_t *)(DMA_BASEADDR+a)=d

void dma_reset() {
    POKE(S2MM_DMACR, S2MM_DMACR_RESET);
    while(PEEK(S2MM_DMACR) & S2MM_DMACR_RESET);
}

void dma_init() {
	POKE( S2MM_DMACR     , 0 );
    POKE( S2MM_DMADA_MSB , 0 );
    printf(" dma_init: S2MM_DMACR = %08X\r\n", (unsigned int)PEEK(S2MM_DMACR));
    printf(" dma_init: S2MM_DMADA_MSB = %08X\r\n", (unsigned int)PEEK(S2MM_DMADA_MSB));
    printf(" dma_init: S2MM_DMASR = %08X\r\n", (unsigned int)PEEK(S2MM_DMASR));
}

void dma_start(uint32_t addr, uint32_t bytes) {
    POKE( S2MM_DMACR  , S2MM_DMACR_RS );
    POKE( S2MM_DMADA  , addr          );
    POKE( S2MM_LENGTH , bytes         );
    //printf(" dma_start: S2MM_DMADA = %08X\r\n", PEEK(S2MM_DMADA));
    //printf(" dma_start: S2MM_LENGTH = %08X\r\n", PEEK(S2MM_LENGTH));
    //printf(" dma_start: S2MM_DMACR = %08X\r\n", PEEK(S2MM_DMACR));
}

void dma_stop() {
    POKE(S2MM_DMACR,0);
}

int dma_halted() {
    return PEEK(S2MM_DMASR) & S2MM_DMASR_HALTED;
}

int dma_idle() {
	printf("dma_idle: S2MM_DMASR = %08X\r\n", (unsigned int)PEEK(S2MM_DMASR));
	printf("dma_idle: S2MM_LENGTH = %08X\r\n", (unsigned int)PEEK(S2MM_LENGTH));
    return PEEK(S2MM_DMASR) & S2MM_DMASR_IDLE;
}

