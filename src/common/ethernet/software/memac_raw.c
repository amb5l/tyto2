#include "bsp.h"
#include "memac_raw.h"
#include "memac_raw_mdio.h"
#include QUOTE(PHY.h)

uint32_t  phyID;
MacAddr_t myMacAddr = {0xEE,0xEE,0xEE,0xEE,0xEE,0xEE};
MacAddr_t BroadcastMacAddr = {0xFF,0xFF,0xFF,0xFF,0xFF,0xFF};
uint16_t  txFree;

uint32_t memacCountTxUnhandled = 0; // PFQ entry not handled
uint32_t memacCountRx          = 0; // RX packet count
uint32_t memacCountRxUnhandled = 0; // PRQ entry not handled

void phy_id(void) {
    phyID = (phy_mdio_peek(1, MDIO_RA_phyID1) << 16) | phy_mdio_peek(1, MDIO_RA_phyID2);
}

retcode_t phy_anc(void) {
    return phy_mdio_peek(1, MDIO_RA_BMSR) & (1 << MDIO_RB_BMSR_ANC) ? 0 : 1;
}

void memac_raw_tx_poke8(TxPktDesc_t *pPD, uint16_t i, uint8_t d) {
    poke8(MEMAC_BASE_TX_BUF | ((pPD->idx+i) % MEMAC_SIZE_TX_BUF), d);
};

void memac_raw_tx_poke16(TxPktDesc_t *pPD, uint16_t i, uint16_t d) {
    memac_raw_tx_poke8( pPD, i,   d >> 8   );
    memac_raw_tx_poke8( pPD, i+1, d & 0xFF );
};

void memac_raw_tx_poke32(TxPktDesc_t *pPD, uint16_t i, uint32_t d) {
    memac_raw_tx_poke8( pPD, i+0, (d >> 24) & 0xFF );
    memac_raw_tx_poke8( pPD, i+1, (d >> 16) & 0xFF );
    memac_raw_tx_poke8( pPD, i+2, (d >>  8) & 0xFF );
    memac_raw_tx_poke8( pPD, i+3, (d >>  0) & 0xFF );
};

uint8_t memac_raw_tx_peek8(TxPktDesc_t *pPD, uint16_t i) {
    return peek8(MEMAC_BASE_TX_BUF | ((pPD->idx+i) % MEMAC_SIZE_TX_BUF));
};

uint16_t memac_raw_tx_peek16(TxPktDesc_t *pPD, uint16_t i) {
    return (memac_raw_tx_peek8(pPD,i+0) << 8)
         | (memac_raw_tx_peek8(pPD,i+1)     );
};

uint32_t memac_raw_tx_peek32(TxPktDesc_t *pPD, uint16_t i) {
    return (memac_raw_tx_peek8(pPD,i+0) << 24)
         | (memac_raw_tx_peek8(pPD,i+1) << 16)
         | (memac_raw_tx_peek8(pPD,i+2) <<  8)
         | (memac_raw_tx_peek8(pPD,i+3)      );
};

uint8_t memac_raw_rx_peek8(RxPktDesc_t *pPD, uint16_t i) {
    return peek8(MEMAC_BASE_RX_BUF | ((pPD->idx+i) % MEMAC_SIZE_RX_BUF));
};

uint16_t memac_raw_rx_peek16(RxPktDesc_t *pPD, uint16_t i) {
    return (memac_raw_rx_peek8(pPD,i+0) << 8)
         | (memac_raw_rx_peek8(pPD,i+1)     );
};

uint32_t memac_raw_rx_peek32(RxPktDesc_t *pPD, uint16_t i) {
    return (memac_raw_rx_peek8(pPD,i+0) << 24)
         | (memac_raw_rx_peek8(pPD,i+1) << 16)
         | (memac_raw_rx_peek8(pPD,i+2) <<  8)
         | (memac_raw_rx_peek8(pPD,i+3)      );
};

void memac_raw_tx_memcpy(TxPktDesc_t *pPD, uint16_t idx, uint16_t len, uint8_t *pSrc) {
    for (uint16_t i = 0; i < len; i++) {
        memac_raw_tx_poke8(pPD, idx+i, pSrc[i]);
    }
}

void memac_raw_tx_rxcpy(TxPktDesc_t *t, uint16_t ti, uint16_t len, RxPktDesc_t *r, uint16_t ri) {
    for (uint16_t i = 0; i < len; i++) {
        memac_raw_tx_poke8(t, ti+i, memac_raw_rx_peek8(r, ri+i));
    }
}

void memac_raw_rx_memcpy(RxPktDesc_t *pPD, uint16_t idx, uint16_t len, uint8_t *pDst) {
    for (uint16_t i = 0; i < len; i++) {
        pDst[i] = memac_raw_rx_peek8(pPD, idx+i);
    }
}

uint16_t memac_raw_tx_init(
    TxPktDesc_t *pPD,        // packet descriptor
    MacAddr_t    pDstMac,  // destination MAC address
    uint16_t     etherType // Ethernet type
) {
    memac_raw_tx_memcpy(pPD,  0, 6, pDstMac  );
    memac_raw_tx_memcpy(pPD,  6, 6, myMacAddr);
    memac_raw_tx_poke16(pPD, 12,    etherType);
    return 14; // index of payload
}

void memac_raw_poll(void) {

    RxPktDesc_t RxRsvdPktDesc;
    TxPktDesc_t TxFreePktDesc;

    // TX PFQ

    if (!memac_raw_tx_free(&TxFreePktDesc)) {
#ifdef MEMAC_RAW_ENABLE_ARP
        if (memac_raw_arp_tx_free(&TxFreePktDesc) < 0)
#endif
#ifdef MEMAC_RAW_ENABLE_IP
        if (memac_raw_ip_tx_free(&TxFreePktDesc) < 0)
#endif
        memacCountTxUnhandled++;
    }

    // RX PRQ & PFQ

    if (!memac_raw_rx_get(&RxRsvdPktDesc)) {
        memacCountRx++;
#ifdef MEMAC_RAW_ENABLE_ARP
        if (memac_raw_arp_rx(&RxRsvdPktDesc) < 0)
#endif
#ifdef MEMAC_RAW_ENABLE_IP
        if (memac_raw_ip_rx(&RxRsvdPktDesc) < 0)
#endif
        memacCountRxUnhandled++;
        memac_raw_rx_free(&RxRsvdPktDesc);
    }

    // TX PRQ

#ifdef MEMAC_RAW_ENABLE_ARP
        memac_raw_arp_tx_send();
#endif
#ifdef MEMAC_RAW_ENABLE_ICMP
        memac_raw_icmp_tx_send();
#endif

}

retcode_t memac_raw_tx_alloc(TxPktDesc_t *pPD) {
    if (txFree > pPD->len) {
        pPD->idx = MEMAC_BASE_TX_BUF + MEMAC_SIZE_TX_BUF - txFree;
        txFree -= pPD->len;
        return RET_SUCCESS;
    }
    else
        return RET_FAIL;
}

retcode_t memac_raw_init(void) {
    memac_raw_bsp_init();
    memac_raw_rx_ctrl(0b1000, 0b1000, 0, 0);
    memac_raw_set_speed(1000);
    memac_raw_reset(0);
    phy_reset(0);
    phy_id();
    txFree = MEMAC_SIZE_TX_BUF;
    if (true)
#ifdef MEMAC_RAW_ENABLE_IP
    if (!memac_raw_ip_init())
#endif
#ifdef MEMAC_RAW_ENABLE_ARP
    if (!memac_raw_arp_init())
#endif
#ifdef MEMAC_RAW_ENABLE_ICMP
    if (!memac_raw_icmp_init())
#endif
    return RET_SUCCESS;
    return RET_FAIL;
}
