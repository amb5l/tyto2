// tmds_cap_csr.h

#include "tmds_cap_csr_ra.h"
#include "xparameters.h"
#define TMDS_CAP_CSR_BASE XPAR_TMDS_MAXI32_BASEADDR

#define TMDS_CAP_CSR_POKE(a,d) *(unsigned int *)(TMDS_CAP_CSR_BASE+a)=d
#define TMDS_CAP_CSR_PEEK(a)   *(unsigned int *)(TMDS_CAP_CSR_BASE+a)
