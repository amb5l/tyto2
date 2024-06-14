// memac_mcs.h

#include <stdint.h>
#include "sleep.h"

#include "bsp.h"
#include "memac_mcs.h"
#include "memac_mcs_p.h"
#include "mdio.h"

phy_id_t phy_id;

void phy_reset(void) {
    XIOModule_DiscreteClear(&io,1,1<<MEMAC_GPO_PHY_RST_N);
#ifndef BUILD_CONFIG_DBG
    usleep(50000);
#endif
    XIOModule_DiscreteSet(&io,1,1<<MEMAC_GPO_PHY_RST_N);
#ifndef BUILD_CONFIG_DBG
    usleep(50000);
#endif
}

void phy_mdio_pre(uint8_t x) {
	if (x) {
		XIOModule_DiscreteSet(&io,1,1<<MEMAC_GPO_PHY_MDIO_PRE);
	}
	else {
		XIOModule_DiscreteClear(&io,1,1<<MEMAC_GPO_PHY_MDIO_PRE);
	}
}

void phy_init(void) {
    uint16_t id1, id2;

    phy_reset();
    phy_mdio_pre(1);
    id1 = phy_mdio_peek(MDIO_RA_PHYID1);
    id2 = phy_mdio_peek(MDIO_RA_PHYID2);
    phy_id.oui = (id1 << 6) | (id2 >> 10);
    phy_id.model = (id2 >> 4) & 0x3F;
    phy_id.rev = id2 & 0xF;
}
