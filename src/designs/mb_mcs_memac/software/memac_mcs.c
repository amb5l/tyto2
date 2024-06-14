// memac_mcs.h

#include <stdint.h>

#include "bsp.h"
#include "memac_mcs.h"
#include "memac_mcs_p.h"
#include "mdio.h"

phy_id_t phy_id;

void phy_init(void) {
    uint16_t id1, id2;
    id1 = phy_mdio_peek(MDIO_RA_PHYID1);
    id2 = phy_mdio_peek(MDIO_RA_PHYID2);
    phy_id.oui = (id1 << 6) | (id2 >> 10);
    phy_id.model = (id2 >> 4) & 0x3F;
    phy_id.rev = id2 & 0xF;
}
