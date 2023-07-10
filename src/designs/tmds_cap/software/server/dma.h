// dma.h

#ifndef _DMA_H_
#define _DMA_H_

void dma_reset();
void dma_init();
void dma_start(uint32_t addr, uint32_t bytes);
void dma_stop();
int dma_halted(); 
int dma_idle();
uint32_t dma_status();

#endif
