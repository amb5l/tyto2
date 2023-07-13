// global.c

#include <stdint.h>

#include "lwip/netif.h"

volatile uint32_t *cap_buf;
volatile int countdown;
struct netif Eth0;
