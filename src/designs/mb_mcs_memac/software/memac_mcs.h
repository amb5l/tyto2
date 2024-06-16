#ifndef _memac_mcs_h_
#define _memac_mcs_h_

#include "memac_mcs_p.h"

typedef struct {
    uint32_t oui;
    uint8_t  model;
    uint8_t  rev;
} phy_id_t;

extern phy_id_t phy_id;

#define phy_mdio_poke(ra,d) poke16(MEMEC_BASE_MDIO | (ra << 2), data)
#define phy_mdio_peek(ra) peek16(MEMEC_BASE_MDIO | (ra << 2))

void phy_reset(void);
void phy_init(void);

#endif
