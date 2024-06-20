#define Q(x) #x
#define QUOTE(x) Q(x)

#include <string.h>

#include "sleep.h"

#include "bsp.h"
#include "memac_raw.h"
#include "memac_raw_bsp.h"
#include "memac_raw_mdio.h"
#include QUOTE(PHY.h)
#include "printf.h"

#define CTRL_C 3

char *test_message = "hello!";
MacAddr_t DstMacAddr = {0x00,0xE0,0x4C,0x78,0x14,0x5B};
IpAddr_t DstIpAddr = {192, 168, 1, 128};

RxPktRsrvDesc_t RxPRD;
RxPktFreeDesc_t RxPFD;

int main() {

    bsp_init();
    led(1);
#ifdef BUILD_CONFIG_RLS
    printf(QUOTE(APP_NAME) " app 1220\r\n");
#endif
    led(2);
    memac_raw_rx_ctrl(0b1000, 0b1000, 1, 1);
    memac_raw_init();
    memac_raw_set_speed(MEMAC_SPD_1000);
    memac_raw_reset(0);
    gpobit(1,MEMAC_GPOB_PHY_RST_N,1);
#ifdef BUILD_CONFIG_RLS
    usleep(45000);
#endif
    led(3);

    phy_id();
#ifndef BUILD_CONFIG_DBG
    printf("PHY ID: %08lX\r\n", PhyID);
    do {
        printf("waiting for auto-negotiation to complete...\r\n");
        usleep(500000);
    } while(!((phy_mdio_peek(1, MDIO_RA_BMSR) >> MDIO_RB_BMSR_ANC) & 1));
    printf("        RX speed : %d\r\n", memac_raw_get_speed());
    printf("            link : %d\r\n", phy_link());
    printf("           speed : %d\r\n", phy_speed());
    printf("          duplex : %d\r\n", phy_duplex());
#endif
    led(4);

    while(!memac_raw_rx_rdy())
        ;
    memac_raw_rx_get(&RxPRD);
    printf("len %d flags %04X\r\n", RxPRD.len, RxPRD.flags);
    for (uint16_t i = 0; i < RxPRD.len; i++) {
        printf("%02X ", peek8(MEMAC_BASE_RX_BUF + RxPRD.idx + i));
    }
    printf("\r\n");

    while(1) {
#ifdef BUILD_CONFIG_DBG
        putchar(CTRL_C); // simulator sees this and stops running
#endif
    }

    while(1) {
        printf("%d", phy_mdio_peek(1, MDIO_RA_BMSR) >> MDIO_RB_BMSR_LINK & 1);
        usleep(200000);
    }

    // this screws things up somehow? why?
    //phy_mdio_poke(1,30,44); // set ext page 44
    //printf(" reg 28 : %04X\r\n", phy_mdio_peek(1,28));
    //printf(" reg 26 : %04X\r\n", phy_mdio_peek(1,26));
    //phy_mdio_poke(1,31,0); // set page 0

    printf("waiting...\r\n");
    while(1) {
        // read all PHY registers
        for (int i = 0; i < 32; i++) {
            uint16_t data = phy_mdio_peek(1, i);
            printf("PHY %02X: %04X\r\n", i, data);
        }
        printf("        RX speed : %d\r\n", memac_raw_get_speed());
        printf("            link : %d\r\n", phy_link());
        printf("           speed : %d\r\n", phy_speed());
        printf("          duplex : %d\r\n", phy_duplex());
        usleep(1000000);
    }

    phy_reset();
    phy_id();
#ifndef BUILD_CONFIG_DBG
    printf("PHY ID: %08lX\r\n", PhyID);
#endif
    // read all PHY registers
    for (int i = 0; i < 32; i++) {
        uint16_t data = phy_mdio_peek(1, i);
        printf("PHY %02X: %04X\r\n", i, data);
    }

#if 1
        // this doesn't work! why? BMCR value is 0040 after, not 1140
        printf("PHY soft reset\r\n");
        // reset TODO make function for this
        phy_mdio_poke(1, MDIO_RA_BMCR,phy_mdio_peek(1, MDIO_RA_BMCR) | (1 << MDIO_RB_BMCR_RST));
        while (phy_mdio_peek(1, MDIO_RA_BMCR) & (1 << MDIO_RB_BMCR_RST))
            printf("waiting for reset to clear...\r\n");
        // read all PHY registers
        for (int i = 0; i < 32; i++) {
            uint16_t data = phy_mdio_peek(1, i);
            printf("PHY %02X: %04X\r\n", i, data);
        }
#endif

    // restart auto-negotiation
    phy_mdio_poke(1, MDIO_RA_BMCR,phy_mdio_peek(1, MDIO_RA_BMCR) | (1 << MDIO_RB_BMCR_RAN));
    while (1) {
        sleep(1);
        printf("auto-negotiation complete: %d\r\n", (phy_mdio_peek(1, MDIO_RA_BMSR) >> MDIO_RB_BMSR_ANC) & 1);
        printf("            link : %d\r\n", phy_link());
        printf(" spd/dx resolved : %d\r\n", (phy_mdio_peek(1, RTL8211_PHYSR) >> 11) & 1);
        printf("           speed : %d\r\n", phy_speed());
        printf("          duplex : %d\r\n", phy_duplex());
        printf("           rx ok : %d\r\n", (phy_mdio_peek(1, RTL8211_PHYSR) >> 1) & 1);
        printf("          jabber : %d\r\n", (phy_mdio_peek(1, RTL8211_PHYSR) >> 0) & 1);
        printf("       crossover : %d\r\n", (phy_mdio_peek(1, RTL8211_PHYSR) >> 6) & 1);
        printf("        RX speed : %d\r\n", memac_raw_get_speed());
    }

    // initialise UDP packet
    // TODO use ARP to get DstMacAddr
    uint16_t i = memac_raw_udp_tx_init(
        (uint8_t *)MEMAC_BASE_TX_BUF, // buffer
        &DstMacAddr,                  // destination MAC address = all 1s
        &MyIpAddr,                    // source IP address = all 0s
        &DstIpAddr,                   // destination IP address = all 1s
        68,                           // source port = 68
        67,                           // destination port = 67
        strlen(test_message)          // length of payload
    );
    led(3);

    // write payload
    memcpy((void *)(MEMAC_BASE_TX_BUF + i), test_message, strlen(test_message));
    led(4);

    // checksum
    memac_raw_udp_tx_cks((uint8_t *)MEMAC_BASE_TX_BUF, strlen(test_message));
    led(5);

    // send
    while(1)
        memac_raw_udp_tx_send((uint8_t *)MEMAC_BASE_TX_BUF, strlen(test_message));
    led(6);

    while(1) {
#ifdef BUILD_CONFIG_DBG
        putchar(CTRL_C); // simulator sees this and stops running
#endif
    }
}
