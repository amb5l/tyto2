// bsp.c

#include "xparameters.h"
#include "xiomodule.h"
#include "xil_printf.h"
#include "printf.h"

XIOModule io;

int putchar(int c) {
	outbyte(c & 0xFF);
	return 0;
}

void outchar(void *p, char c) {
	outbyte(c);
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
