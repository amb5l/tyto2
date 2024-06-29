#ifndef _rtl8211_h_
#define _rtl8211_h_

#define PHY_OUI 0x001C0C

#define RTL8211_PHYSR 0x11

void phy_reset(uint8_t r);
void phy_mdio_poke(uint8_t pa, uint8_t ra, uint16_t d);
uint16_t phy_mdio_peek(uint8_t pa, uint8_t ra);
uint8_t phy_link(void);
uint8_t phy_speed(void);
uint8_t phy_duplex(void);

#endif
