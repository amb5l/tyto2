#ifndef _bsp_h_
#define _bsp_h_

#include <stdint.h>

#include "xiomodule.h"

#include "peekpoke.h"

#define gpi(n) XIOModule_DiscreteRead(&io,n)
#define gpo(n,d) XIOModule_DiscreteWrite(&io,n,d)
#define gpobit(n,b,d) XIOModule_DiscreteWrite(&io,n,((io.GpoValue[n-1] & ~(1 << (b))) | ((d) << (b))))
#define gpormw(n,m,d) XIOModule_DiscreteWrite(&io,n,((io.GpoValue[n-1] & ~(m)) | (d)))

#define led(d) gpo(4,d)

extern XIOModule io;

int putchar(int c);
int bsp_init();

#endif
