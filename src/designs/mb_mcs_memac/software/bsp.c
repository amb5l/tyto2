// bsp.c

#include <stdio.h>

#include "xparameters.h"
#include "xiomodule.h"
#include "printf.h"

XIOModule io;

void my_putc(void *p, char c) {
	putchar((int)c);
}

int bsp_init() {
    XIOModule_Initialize(&io, XPAR_IOMODULE_0_DEVICE_ID);
    init_printf(NULL,my_putc);
    return 0;
}
