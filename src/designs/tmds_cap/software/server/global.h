// global.h

#ifndef _GLOBAL_H_
#define _GLOBAL_H_

#include <stdint.h>

#include "lwip/netif.h"

extern volatile uint32_t *cap_buf;
extern volatile int countdown;
extern struct netif Eth0;

#endif
