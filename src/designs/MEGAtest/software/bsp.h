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
#define CB_BUF    XPAR_CPU_IOMODULE_0_IO_BASEADDR
#define XADC_BASE (XPAR_CPU_IOMODULE_0_IO_BASEADDR | (1 << 28))
#define HT_BASE   (XPAR_CPU_IOMODULE_0_IO_BASEADDR | (1 << 29))

extern XIOModule io;

void bsp_interval(uint32_t t);
void bsp_cb_border(uint8_t c);
int bsp_init();

#endif
