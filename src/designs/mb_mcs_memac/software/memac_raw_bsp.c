#ifndef _rawip_bsp_h_
#define _rawip_bsp_h_

#include "bsp.h"
#include "memac_raw.h"

void memac_raw_phy_reset(uint8_t r) {
    gpobit(1, MEMAC_GPOB_PHY_RST_N, r ? 0 : 1);
}

void memac_raw_phy_mdio_poke(uint8_t pa, uint8_t ra, uint16_t d) {
    poke16(MEMAC_BASE_MDIO | (pa << 7) | (ra << 2), d);
}

uint16_t memac_raw_phy_mdio_peek(uint8_t pa, uint8_t ra) {
    return peek16(MEMAC_BASE_MDIO | (pa << 7) | (ra << 2));
}

uint16_t memac_raw_get_speed(void) {
    switch ((gpi(1) >> MEMAC_GPIB_RX_SPD0) & 0b11) {
        case MEMAC_SPD_1000: return 1000;
        case MEMAC_SPD_100:  return 100;
        case MEMAC_SPD_10:   return 10;
        default:             return 0;
    }
}

retcode_t memac_raw_set_speed(uint16_t s) {
    uint8_t spd;
    switch(s) {
        case 1000: spd = MEMAC_SPD_1000; break;
        case 100:  spd = MEMAC_SPD_100;  break;
        case 10:   spd = MEMAC_SPD_10;   break;
        default:   return RET_FAIL;
    }
    gpormw(1,
        MEMAC_GPOM_RX_SPD | MEMAC_GPOM_TX_SPD,
        (spd << MEMAC_GPOB_RX_SPD0) | (spd << MEMAC_GPOB_TX_SPD0)
    );
    return RET_SUCCESS;
}

void memac_raw_reset(uint8_t r) {
    uint8_t n = r ? 0 : 1;
    gpormw(1,
        (1 << MEMAC_GPOB_RX_RST_N) | (1 << MEMAC_GPOB_TX_RST_N),
        (n << MEMAC_GPOB_RX_RST_N) | (n << MEMAC_GPOB_TX_RST_N)
    );
}

void memac_raw_rx_ctrl(uint8_t ipgMin, uint8_t preLen, uint8_t preInc, uint8_t fcsInc) {
    gpormw(1,
        MEMAC_GPOM_RX_IPG_MIN |
        MEMAC_GPOM_RX_PRE_LEN |
        MEMAC_GPOM_RX_PRE_INC |
        MEMAC_GPOM_RX_FCS_INC,
        (((ipgMin) & 0b1111) << MEMAC_GPOB_RX_IPG_MIN0) |
        (((preLen) & 0b1111) << MEMAC_GPOB_RX_PRE_LEN0) |
        (((preInc) & 1) << MEMAC_GPOB_RX_PRE_INC) |
        (((fcsInc) & 1) << MEMAC_GPOB_RX_FCS_INC)
    );
}

retcode_t memac_raw_rx_get(RxPktDesc_t *pPD) {
    if (memac_raw_rx_prq_rdy()) {
        pPD->flags = peek16(MEMAC_BASE_RX_PDQ + 4);
        uint32_t r = peek32(MEMAC_BASE_RX_PDQ);
        pPD->len = r & 0xFFFF;
        pPD->idx = r >> 16;
        return RET_SUCCESS;
    }
    else
        return RET_FAIL;
}

retcode_t memac_raw_tx_send(TxPktDesc_t *pPD) {
    if (!memac_raw_tx_prq_rdy()) return RET_FAIL;
    poke32(MEMAC_BASE_TX_PDQ, pPD->idx << 16 | pPD->len);
    return RET_SUCCESS;
}

retcode_t memac_raw_tx_free(TxPktDesc_t *pPD) {
    if (!memac_raw_tx_pfq_rdy()) return RET_FAIL;
    uint32_t x = peek32(MEMAC_BASE_TX_PDQ);
    pPD->len = x & 0xFFFF;
    pPD->idx = x >> 16;
    return RET_SUCCESS;
}

retcode_t memac_raw_rx_free(RxPktDesc_t *pPD) {
    if (!memac_raw_rx_pfq_rdy()) return RET_FAIL;
    poke32(MEMAC_BASE_RX_PDQ, pPD->len);
    return RET_SUCCESS;
}

retcode_t memac_raw_bsp_init(void) {
    // enable MDIO preamble
	gpobit(1, MEMAC_GPOB_PHY_MDIO_PRE, 1);
    // TX options: preamble length = 8, auto preamble, auto FCS
    poke32(MEMAC_BASE_TX_PDQ+4, 0b111000);
    return 0;
}

#endif



