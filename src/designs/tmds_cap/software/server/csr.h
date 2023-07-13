// csr.h

#ifndef _CSR_H_
#define _CSR_H_

#include <stdint.h>

#include "xparameters.h"
#include "tmds_cap_csr_ra.h"

#define CSR_BASEADDR XPAR_MAXI32_BASEADDR

#define CSR_CAPCTRL_EN   1<<0
#define CSR_CAPCTRL_TEST 1<<1
#define CSR_CAPCTRL_RST  1<<31

#define CSR_CAPSTAT_RUN  1<<0
#define CSR_CAPSTAT_STOP 1<<1

#define CSR_POKE(a,d) *(volatile uint32_t *)(CSR_BASEADDR+a)=d
#define CSR_PEEK(a)   *(volatile uint32_t *)(CSR_BASEADDR+a)

#endif
