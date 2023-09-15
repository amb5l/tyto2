// cap.c

#include <stdint.h>
#include <stdio.h>

#include "sleep.h"

#include "csr.h"
#include "dma.h"
#include "sdram.h"

#include "cap.h"

#define CAP_DMA_MAX_BYTES (32*1024*1024)
#define CAP_BUF_ALIGN_PIXELS 4
#define CAP_BUF_ALIGN_BYTES (4*CAP_BUF_ALIGN_PIXELS)
volatile uint32_t cap_buf_unaligned[CAP_BUF_PIXELS+CAP_BUF_ALIGN_PIXELS];

uint32_t cap_bytes_transferred;
uint32_t cap_bytes_remaining;

// hack to disable test pattern generation
#define CSR_CAPCTRL_TEST 0

void cap_init() {
    cap_buf = (uint32_t *)((CAP_BUF_ALIGN_BYTES+(uint32_t)cap_buf_unaligned) & -CAP_BUF_ALIGN_BYTES);
	printf("sizeof(cap_buf_unaligned) = %ld\r\n", sizeof(cap_buf_unaligned));
	printf("cap_buf_unaligned = 0x%08X\r\n", cap_buf_unaligned);
	printf("cap_buf = 0x%08X\r\n", cap_buf);
    CSR_POKE(RA_CAPCTRL, CSR_CAPCTRL_RST);
    usleep(1);
    CSR_POKE(RA_CAPCTRL, CSR_CAPCTRL_TEST);
    dma_reset();
    dma_init();
}

void cap_start(uint32_t pixels) {
	cap_bytes_transferred = 0;
	cap_bytes_remaining = 4*pixels;
	sdram_fill((uint32_t)cap_buf, 4*pixels, 0xAAAAAAAA, 0 ); // invalid TMDS characters
	if (4*pixels > CAP_DMA_MAX_BYTES)
		dma_start((uint32_t)cap_buf, CAP_DMA_MAX_BYTES);
	else
		dma_start((uint32_t)cap_buf, 4*pixels);
    CSR_POKE(RA_CAPSIZE, pixels);
    CSR_POKE(RA_CAPCTRL, CSR_CAPCTRL_EN | CSR_CAPCTRL_TEST);
}

uint32_t cap_rdy() {
	if (dma_idle()){
		cap_bytes_transferred += dma_count();
		cap_bytes_remaining -= dma_count();
		if (cap_bytes_remaining) {
			if (cap_bytes_remaining > CAP_DMA_MAX_BYTES)
				dma_start(cap_bytes_transferred+(uint32_t)cap_buf, CAP_DMA_MAX_BYTES);
			else
				dma_start(cap_bytes_transferred+(uint32_t)cap_buf, cap_bytes_remaining);
			return 0;
		} else {
	        CSR_POKE(RA_CAPCTRL, CSR_CAPCTRL_TEST);
	        return CSR_PEEK(RA_CAPSIZE);
		}
	}
}

void cap_reg_dump()
{
    uint32_t r;

    printf("\r\n");
    r = CSR_PEEK( RA_SIGNATURE );
    printf("  SIGNATURE : %08lX ('%c%c%c%c')\r\n",
        r,
        ((unsigned char *)&r)[0],
        ((unsigned char *)&r)[1],
        ((unsigned char *)&r)[2],
        ((unsigned char *)&r)[3]
    );

    r = CSR_PEEK( RA_FREQ      ); printf("  FREQ      : %08lX (%.2f MHz)\r\n", r, r/100.0);
    r = CSR_PEEK( RA_ASTAT     ); printf("  ASTAT     : %08lX\r\n", r);
                                  printf("              SKEW2 = %lu, SKEW1 = %lu\r\n", (r>>10)&3, (r>>8)&3);
                                  printf("              ALIGNP = %lu, ALIGNS2 = %lu, ALIGNS1 = %lu, ALIGNS0 = %lu\r\n", (r>>7)&1, (r>>6)&1, (r>>5)&1, (r>>4)&1);
                                  printf("              BAND = %lu, LOCK = %lu\r\n", (r>>1)&3, r&1);
    r = CSR_PEEK( RA_ATAPMASK0 ); printf("  ATAPMASK0 : %08lX\r\n", r);
    r = CSR_PEEK( RA_ATAPMASK1 ); printf("  ATAPMASK1 : %08lX\r\n", r);
    r = CSR_PEEK( RA_ATAPMASK2 ); printf("  ATAPMASK2 : %08lX\r\n", r);
    r = CSR_PEEK( RA_ATAP      ); printf("  ATAP      : %08lX (%lu,%lu,%lu)\r\n", r, (r>>16)&31, (r>>8)&31, r&31);
    r = CSR_PEEK( RA_ABITSLIP  ); printf("  ABITSLIP  : %08lX (%lu,%lu,%lu)\r\n", r, (r>>8)&15, (r>>4)&15, r&15);
    r = CSR_PEEK( RA_ACYCLE0   ); printf("  ACYCLE0   : %08lX\r\n", r);
    r = CSR_PEEK( RA_ACYCLE1   ); printf("  ACYCLE1   : %08lX\r\n", r);
    r = CSR_PEEK( RA_ACYCLE2   ); printf("  ACYCLE2   : %08lX\r\n", r);
    r = CSR_PEEK( RA_ATAPOK0   ); printf("  ATAPOK0   : %08lX\r\n", r);
    r = CSR_PEEK( RA_ATAPOK1   ); printf("  ATAPOK1   : %08lX\r\n", r);
    r = CSR_PEEK( RA_ATAPOK2   ); printf("  ATAPOK2   : %08lX\r\n", r);
    r = CSR_PEEK( RA_AGAIN0    ); printf("  AGAIN0    : %08lX\r\n", r);
    r = CSR_PEEK( RA_AGAIN1    ); printf("  AGAIN1    : %08lX\r\n", r);
    r = CSR_PEEK( RA_AGAIN2    ); printf("  AGAIN2    : %08lX\r\n", r);
    r = CSR_PEEK( RA_AGAINP    ); printf("  AGAINP    : %08lX\r\n", r);
    r = CSR_PEEK( RA_ALOSS0    ); printf("  ALOSS0    : %08lX\r\n", r);
    r = CSR_PEEK( RA_ALOSS1    ); printf("  ALOSS1    : %08lX\r\n", r);
    r = CSR_PEEK( RA_ALOSS2    ); printf("  ALOSS2    : %08lX\r\n", r);
    r = CSR_PEEK( RA_ALOSSP    ); printf("  ALOSSP    : %08lX\r\n", r);
    r = CSR_PEEK( RA_CAPCTRL   ); printf("  CAPCTRL   : %08lX\r\n", r);
    r = CSR_PEEK( RA_CAPSIZE   ); printf("  CAPSIZE   : %08lX\r\n", r);
    r = CSR_PEEK( RA_CAPSTAT   ); printf("  CAPSTAT   : %08lX\r\n", r);
    r = CSR_PEEK( RA_CAPCOUNT  ); printf("  CAPCOUNT  : %08lX\r\n", r);
    r = CSR_PEEK( RA_SCRATCH   ); printf("  SCRATCH   : %08lX\r\n", r);
    printf("\r\n");
}
