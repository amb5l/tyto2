// csr.h

#include "xparameters.h"
#include "tmds_cap_csr_ra.h"

#define CSR_BASEADDR XPAR_MAXI32_BASEADDR

#define CSR_POKE(a,d) *(unsigned int *)(CSR_BASEADDR+a)=d
#define CSR_PEEK(a)   *(unsigned int *)(CSR_BASEADDR+a)
