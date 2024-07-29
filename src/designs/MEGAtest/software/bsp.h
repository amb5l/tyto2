#ifndef _bsp_h_
#define _bsp_h_

#include <stdint.h>

#include "xiomodule.h"

#include "peekpoke.h"

// TODO get this from an external symbol
#define BSP_INTERVAL_1S  100000000
#define BSP_INTERVAL_1mS 100000
#define BSP_INTERVAL_1uS 100

#define gpi(n) XIOModule_DiscreteRead(&io,n)
#define gpo(n,d) XIOModule_DiscreteWrite(&io,n,d)
#define gpobit(n,b,d) XIOModule_DiscreteWrite(&io,n,((io.GpoValue[n-1] & ~(1 << (b))) | ((d) << (b))))
#define gpormw(n,m,d) XIOModule_DiscreteWrite(&io,n,((io.GpoValue[n-1] & ~(m)) | (d)))

#include "xparameters.h"
#define CB_BUF	XPAR_BRAM_S_AXI_BASEADDR

extern XIOModule io;

void bsp_interval(uint32_t t);
int bsp_init();

#endif
