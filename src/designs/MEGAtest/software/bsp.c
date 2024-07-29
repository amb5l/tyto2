// bsp.c

#include "xparameters.h"
#include "xiomodule.h"
#include "xil_printf.h"
#include "peekpoke.h"
#include "printf.h"
#include "bsp.h"

XIOModule io;

#define IO_BASE XPAR_CPU_IOMODULE_0_IO_BASEADDR

int putchar(int c) {
	while (!(gpi(1) & 1))
		;
	poke8(IO_BASE, (uint8_t)(c & 0xFF));
	return 0;
}

void outchar(void *p, char c) {
	while (!(gpi(1) & 1))
		;
	poke8(IO_BASE, (uint8_t)(c & 0xFF));
}

void bsp_interval(uint32_t t) {
    XIOModule_SetResetValue(&io, 0, t);
	XIOModule_Timer_Start(&io, 0);
	while (XIOModule_GetValue(&io, 0) != -1)
		;
}

int bsp_init() {
    XIOModule_Initialize(&io, XPAR_IOMODULE_0_DEVICE_ID);
	XIOModule_Timer_SetOptions(&io, 0, 0);
    init_printf(NULL,outchar);
    return 0;
}
