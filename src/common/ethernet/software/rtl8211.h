#define PHY_OUI 0x001C0C

#define RTL8211_PHYSR 0x11

void phy_reset(void);
uint8_t phy_link(void);
uint8_t phy_speed(void);
uint8_t phy_duplex(void);
