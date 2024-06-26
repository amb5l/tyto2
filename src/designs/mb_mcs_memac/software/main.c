

#include <string.h>

#include "bsp.h"
#include "memac_raw.h"
#include QUOTE(PHY.h)
#include "printf.h"

#define CTRL_C 3

int main() {

    bsp_init();
#ifdef BUILD_CONFIG_RLS
    printf(QUOTE(APP_NAME) " app 25\r\n");
#endif
    memac_raw_init();

#ifndef BUILD_CONFIG_DBG
    printf("PHY ID: %08X\r\n", phyID);
    while (phy_anc())
        ;
    printf("  RX speed : %d\r\n", memac_raw_get_speed());
    printf("      link : %d\r\n", phy_link());
    printf("     speed : %d\r\n", phy_speed());
    printf("    duplex : %d\r\n", phy_duplex());
#endif

    // handle inbound ping (and associated ARP) requests
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
