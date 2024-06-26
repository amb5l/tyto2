#include "sleep.h"

#include "memac_raw_bsp.h"
#include "rtl8211.h"

void phy_reset(uint8_t r) {
    memac_raw_phy_reset(r);
#ifndef BUILD_CONFIG_DBG
    bsp_interval(r ? 15 * BSP_INTERVAL_1mS : 45 * BSP_INTERVAL_1mS); // recommended: 10ms assertion, 30ms delay
#endif
}

void phy_mdio_poke(uint8_t pa, uint8_t ra, uint16_t d) {
    memac_raw_phy_mdio_poke(pa, ra, d);
}

uint16_t phy_mdio_peek(uint8_t pa, uint8_t ra) {
    return memac_raw_phy_mdio_peek(pa, ra);
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
