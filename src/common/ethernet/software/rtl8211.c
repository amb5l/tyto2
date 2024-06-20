#include <stdint.h>

#include "rtl8211.h"
#include "bsp.h"
#include "memac_raw_bsp.h"

void phy_reset(void) {
    gpobit(1,MEMAC_GPOB_PHY_RST_N,0);
#ifndef BUILD_CONFIG_DBG
    usleep(15000); // 10ms recommended
#endif
    gpobit(1,MEMAC_GPOB_PHY_RST_N,1);
#ifndef BUILD_CONFIG_DBG
    usleep(45000); // 30ms recommended
#endif
}

uint8_t phy_link(void) {
    return (phy_mdio_peek(1, RTL8211_PHYSR) >> 10) & 1;
}

uint8_t phy_speed(void) {
    return (phy_mdio_peek(1, RTL8211_PHYSR) >> 14) & 3;
}

uint8_t phy_duplex(void) {
    return (phy_mdio_peek(1, RTL8211_PHYSR) >> 13) & 1;
}

void phy_init(void) {
    // disable CLK125 (if not connected on this board)
    // disable green ethernet
}
