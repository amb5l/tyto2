

#include <string.h>

#include "bsp.h"
#include "memac_raw.h"
#include QUOTE(PHY.h)
#include "printf.h"

#define CTRL_C 3

int main() {

    bsp_init();

#ifdef BUILD_CONFIG_RLS
    printf(QUOTE(APP_NAME) " app 28\r\n");
#endif
    memac_raw_init();

printf("Initialised...\r\n");
#ifndef BUILD_CONFIG_DBG
    do {
        printf("Waiting for PHY auto negotiation...\r\n");
        bsp_interval(500 * BSP_INTERVAL_1mS);
    } while (phy_anc());
    printf("link speed : %d\r\n", memac_raw_get_speed());
#endif

    while (1) {
        memac_raw_poll();
        //printf("Rx: %d\r\n", memacCountRx);
        //printf("Rx u: %d\r\n", memacCountRxUnhandled);
        //printf("ARP Rx: %d\r\n", memacRawCountArpReqRx);
        //printf("ARP Tx: %d\r\n", memacRawCountArpRepTx);
        //printf("ICMP Rx: %d\r\n", memacRawCountIcmpRx);
        //printf("ICMP echo reply Tx: %d\r\n", memacRawCountIcmpEchoRepTx);
        //printf("\r\n");
    }

    while(1) {
#ifdef BUILD_CONFIG_DBG
        putchar(CTRL_C); // simulator sees this and stops running
#endif
    }

}
