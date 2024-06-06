//test

#include <stdio.h>

#include "xparameters.h"
#include "xiomodule.h"

#define Q(x) #x
#define QUOTE(x) Q(x)

int main() {

	XIOModule io;

    XIOModule_Initialize(&io, XPAR_IOMODULE_0_DEVICE_ID);
    
    printf(QUOTE(APP_NAME) " application\r\n");
    
    XIOModule_DiscreteWrite(&io,1,0x55);

    while(1)
        ;

    return 0;
}
