// bsp.c

#include "xparameters.h"
#include "xiomodule.h"
#include "xil_printf.h"
#include "printf.h"

XIOModule io;

void putchar(char c) {
	outbyte(c);
}

void outchar(void *p, char c) {
	outbyte(c);
}

int bsp_init() {
    XIOModule_Initialize(&io, XPAR_IOMODULE_0_DEVICE_ID);
    init_printf(NULL,outchar);
    return 0;
}
