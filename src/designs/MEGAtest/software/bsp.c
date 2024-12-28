// bsp.c

#include "xparameters.h"
#include "bsp.h"
#include "cb.h"
#include "printf.h"
#if IS_BD(mb_mcs)
#include "xiomodule.h"
#endif
#if IS_BD(mbv_maxi_j)
#include "xuartlite_l.h"

uint8_t jtag_uart_en    = 0;
uint8_t jtag_uart_en_tx = 0;

#endif

#if IS_BD(mb_mcs)

XIOModule io;

void bsp_interval(uint32_t t) {
    XIOModule_SetResetValue(&io, 0, t);
	XIOModule_Timer_Start(&io, 0);
	while (XIOModule_GetValue(&io, 0) != -1)
		;
}

#endif

void bsp_cb_border(uint8_t c) {
	gpormw(1, 0xF << 4, (c & 0xF) << 4);
}

void bsp_putc(void *p, char c)
{
    cb_putc(0, c);
#if IS_BD(mbv_maxi_j)
    if (jtag_uart_en && jtag_uart_en_tx) {
	    XUartLite_SendByte(STDOUT_BASEADDRESS, c);
    }
#endif
}

#if IS_BD(mbv_maxi_j)
char bsp_getc(void *p) {
    return XUartLite_RecvByte(STDIN_BASEADDRESS);
}
#endif

uint8_t bsp_getc_rdy(void) {
    return !XUartLite_IsReceiveEmpty(STDIN_BASEADDRESS);
}

int bsp_init() {
#if IS_BD(mb_mcs)
    XIOModule_Initialize(&io, XPAR_IOMODULE_0_DEVICE_ID);
	XIOModule_Timer_SetOptions(&io, 0, 0);
#endif
#if 0
    gpormw(1, 0xF, 1);                 // set video mode (720x480p60)
    gpormw(1, 0x3 << 8, 0 << 8);       // text params: no pixel repetition
    gpormw(1, 0xFF << 16, 80 << 16);   // text params: width  = 80
    gpormw(1, 0xFF << 24, 25 << 24);   // text params: height = 25
    gpormw(2, 0xFFFF <<  0, 40 <<  0); // text params: offset X = 40
    gpormw(2, 0xFFFF << 16, 40 << 16); // text params: offset Y = 40
    cb_init(80,25);
#else
    gpormw(1, 0xF, 3);                 // set video mode (1280x720p60)
    gpormw(1, 0x3 << 8, 0 << 8);       // text params: no pixel repetition
    gpormw(1, 0xFF << 16, 154 << 16);  // text params: width  = 154
    gpormw(1, 0xFF << 24, 42 << 24);   // text params: height = 42
    gpormw(2, 0xFFFF <<  0, 24 <<  0); // text params: offset X = 24
    gpormw(2, 0xFFFF << 16, 24 << 16); // text params: offset Y = 24
    cb_init(154,42);
#endif
    init_printf(0, bsp_putc);
    return 0;
}
