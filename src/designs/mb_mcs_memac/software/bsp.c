// bsp.c

#include "xparameters.h"
#include "xiomodule.h"

XIOModule io;

int bsp_init() {
    XIOModule_Initialize(&io, XPAR_IOMODULE_0_DEVICE_ID);
    return 0;
}
