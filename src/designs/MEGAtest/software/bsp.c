// bsp.c

#include "xparameters.h"
#include "xiomodule.h"
#include "xil_printf.h"
#include "peekpoke.h"
#include "printf.h"
#include "bsp.h"
#include "cb.h"

XIOModule io;

void bsp_interval(uint32_t t) {
    XIOModule_SetResetValue(&io, 0, t);
	XIOModule_Timer_Start(&io, 0);
	while (XIOModule_GetValue(&io, 0) != -1)
		;
}

void bsp_cb_border(uint8_t c) {
	gpormw(1, 0xF << 4, (c & 0xF) << 4);
}

int bsp_init() {
    XIOModule_Initialize(&io, XPAR_IOMODULE_0_DEVICE_ID);
	XIOModule_Timer_SetOptions(&io, 0, 0);
    gpormw(1, 0xF, 3);                  // set video mode (1280x720p60)
    gpormw(1, 0x3 << 8, 0 << 8);        // text params: no pixel repetition
    gpormw(1, 0xFF << 16, 132 << 16);   // text params: width
    gpormw(1, 0xFF << 24, 40 << 24);    // text params: height
    gpormw(2, 0xFFFF <<  0, 112 <<  0); // text params: offset X
    gpormw(2, 0xFFFF << 16,  40 << 16); // text params: offset Y
    cb_init(132,40);
    init_printf(NULL,cb_putc);
    return 0;
}
