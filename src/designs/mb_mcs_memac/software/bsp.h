#ifndef _bsp_h_
#define _bsp_h_

#include <stdint.h>

#include "xiomodule.h"

#define poke8(a,d)  {*(uint8_t *)a=d}
#define poke16(a,d) {*(uint16_t *)a=d}
#define poke32(a,d) {*(uint32_t *)a=d}
#define peek8(a)    (*(uint8_t *)a)
#define peek16(a)   (*(uint16_t *)a)
#define peek32(a)   (*(uint32_t *)a)

extern XIOModule io;

int bsp_init();

#endif
