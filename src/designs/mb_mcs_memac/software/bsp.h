#ifndef _bsp_h_
#define _bsp_h_

#include <stdint.h>

#include "xiomodule.h"

#define poke8(a,d)  {*(volatile uint8_t *)(a)=d}
#define poke16(a,d) {*(volatile uint16_t *)(a)=d}
#define poke32(a,d) {*(volatile uint32_t *)(a)=d}
#define peek8(a)    (*(volatile uint8_t *)(a))
#define peek16(a)   (*(volatile uint16_t *)(a))
#define peek32(a)   (*(volatile uint32_t *)(a))

#define led(d) {XIOModule_DiscreteWrite(&io,4,d);}

extern XIOModule io;

int bsp_init();
void putchar(char c);

#endif
