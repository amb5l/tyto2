// hal.h

#ifndef _HAL_H_
#define _HAL_H_

#include "lwip/tcp.h"

#define SCUTIMER_INTERVAL_MSECS 100
#define SCUTIMER_LOAD_VAL       (XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ / (2*(1000/SCUTIMER_INTERVAL_MSECS)))
#define LINK_DET_INTERVAL_MSECS 1000
#define COUNTDOWN_SEC 			(1000/SCUTIMER_INTERVAL_MSECS)

extern volatile int countdown;

void hal_init(void);
void hal_enable_interrupts(void);
struct netif * hal_netif_add(struct netif *netif, ip_addr_t *ipaddr, ip_addr_t *netmask, ip_addr_t *gateway);
void hal_netif_rx(struct netif *netif);

#endif
