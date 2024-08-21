#ifndef _xadc_h_
#define _xadc_h_

#include "bsp.h"

#define XADC_TEMP    (XADC_BASE+(0x00<<2))
#define XADC_CFGREG0 (XADC_BASE+(0x40<<2))
#define XADC_CFGREG1 (XADC_BASE+(0x41<<2))
#define XADC_CFGREG2 (XADC_BASE+(0x42<<2))

#define xadc_bsy() (gpi(1) & 1)
int16_t xadc_temp10(void);

#endif
