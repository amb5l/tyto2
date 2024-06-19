#ifndef _rawip_bsp_h_
#define _rawip_bsp_h_

#include "bsp.h"
#include "memac_raw_bsp.h"

void phy_mdio_poke(uint8_t pa, uint8_t ra, uint16_t d) {
    poke16(MEMAC_BASE_MDIO | (pa << 7) | (ra << 2), d);
}

uint16_t phy_mdio_peek(uint8_t pa, uint8_t ra) {
    return peek16(MEMAC_BASE_MDIO | (pa << 7) | (ra << 2));
}

uint8_t memac_raw_get_speed(void) {
    return (gpi(1) >> MEMAC_GPI_RX_SPD0) & 0b11;
}


void memac_raw_set_speed(uint8_t spd) {
    gpormw(1,
        (0b11 << MEMAC_GPO_RX_SPD0) | (0b11 << MEMAC_GPO_TX_SPD0),
        (spd << MEMAC_GPO_RX_SPD0) | (spd << MEMAC_GPO_TX_SPD0)
    );
}

void memac_raw_reset(uint8_t rst) {
    uint8_t n = rst ? 0 : 1;
    gpormw(1,
        (1 << MEMAC_GPO_RX_RST_N) | (1 << MEMAC_GPO_TX_RST_N),
        (n << MEMAC_GPO_RX_RST_N) | (n << MEMAC_GPO_TX_RST_N)
    );
}

uint8_t memac_raw_tx_rdy(void) {
    return gpi(1) & (1 << MEMAC_GPI_TX_PRQ_RDY) ? 1 : 0;
}

uint8_t memac_raw_tx_send(uint8_t *pBuf, uint16_t len) {
    if (!memac_raw_tx_rdy()) return 1;
    poke32(MEMAC_BASE_TX_PDQ, (((uint32_t)pBuf & (MEMAC_SIZE_TX_BUF-1)) << 16) | len);
    // write buffer
    memcpy((void *)MEMAC_BASE_TX_BUF, pBuf, len);
    // write length
    poke32(MEMAC_BASE_TX_PDQ, len);
    return 0;
}


uint8_t memac_raw_bsp_init(void) {
    // enable MDIO preamble
	XIOModule_DiscreteSet(&io,1,1<<MEMAC_GPO_PHY_MDIO_PRE);
    // TX options: preamble length = 8, auto preamble, auto FCS
    poke32(MEMAC_BASE_TX_PDQ+4, 0b111000);
    return 0;
}

#endif
