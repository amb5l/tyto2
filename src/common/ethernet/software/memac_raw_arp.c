#include "memac_raw.h"

#define ARP_LEN            28
#define ARP_HTYPE_ETHERNET 0x0001
#define ARP_PTYPE_IPv4     0x0800
#define ARP_HLEN           0x06
#define ARP_PLEN           0x04
#define ARP_OPER_REQUEST   0x0001
#define ARP_OPER_REPLY     0x0002

uint32_t memacRawCountArpReqRx     = 0;
//uint32_t memacRawCountArpReqRxGood = 0;
//uint32_t memacRawCountArpReqRxDrop = 0;
//uint32_t memacRawCountArpReqRxBad  = 0;
uint32_t memacRawCountArpRepTx     = 0;

TxPktDesc_t ArpReplyTxPktDesc;
TxPktDescState_t ArpReplyTxPktDescState;

// TODO: allow for more than one outstanding ARP request
// TODO: handle inbound replies
retcode_t memac_raw_arp_rx(RxPktDesc_t *pPD) {
    if (memac_raw_rx_peek16 (pPD, 12) != FRAME_ETHERTYPE_ARP)
        return RET_RX_OTHER; // not ARP so try another protocol
    memacRawCountArpReqRx++;
    if (memac_raw_rx_peek16 (pPD, FRAME_HDR_LEN+0) == ARP_HTYPE_ETHERNET)
    if (memac_raw_rx_peek16 (pPD, FRAME_HDR_LEN+2) == ARP_PTYPE_IPv4    )
    if (memac_raw_rx_peek8  (pPD, FRAME_HDR_LEN+4) == ARP_HLEN          )
    if (memac_raw_rx_peek8  (pPD, FRAME_HDR_LEN+5) == ARP_PLEN          )
    if (memac_raw_rx_peek16 (pPD, FRAME_HDR_LEN+6) == ARP_OPER_REQUEST  )
    {
        IpAddr_t spa = memac_raw_rx_peek32(pPD, FRAME_HDR_LEN+14);
        IpAddr_t tpa = memac_raw_rx_peek32(pPD, FRAME_HDR_LEN+24);
        if (tpa != myIpAddr) { // check TPA
            return RET_RX_IGNORE; // we are not the target of this request
        }
        if (ArpReplyTxPktDescState != TX_FREE)
            return RET_RX_DROP; // reply packet is not available
        // build reply packet
        memac_raw_tx_rxcpy  (&ArpReplyTxPktDesc, 0, 6, pPD, 6); // destination MAC address
        memac_raw_tx_poke16 (&ArpReplyTxPktDesc, FRAME_HDR_LEN+ 0,    ARP_HTYPE_ETHERNET    ); // HTYPE = ethernet
        memac_raw_tx_poke16 (&ArpReplyTxPktDesc, FRAME_HDR_LEN+ 2,    ARP_PTYPE_IPv4        ); // PTYPE = IPv4
        memac_raw_tx_poke8  (&ArpReplyTxPktDesc, FRAME_HDR_LEN+ 4,    ARP_HLEN              ); // HLEN = 6
        memac_raw_tx_poke8  (&ArpReplyTxPktDesc, FRAME_HDR_LEN+ 5,    ARP_PLEN              ); // PLEN = 4
        memac_raw_tx_poke16 (&ArpReplyTxPktDesc, FRAME_HDR_LEN+ 6,    ARP_OPER_REPLY        ); // OPER = reply
        memac_raw_tx_memcpy (&ArpReplyTxPktDesc, FRAME_HDR_LEN+ 8, 6, (uint8_t *)myMacAddr  ); // SHA = my MAC address
        memac_raw_tx_poke32 (&ArpReplyTxPktDesc, FRAME_HDR_LEN+14,    myIpAddr              ); // SPA = my IP address
        memac_raw_tx_rxcpy  (&ArpReplyTxPktDesc, FRAME_HDR_LEN+18, 6, pPD, FRAME_HDR_LEN+ 8 ); // THA = SHA
        memac_raw_tx_poke32 (&ArpReplyTxPktDesc, FRAME_HDR_LEN+24,    spa                   ); // TPA = SPA
        ArpReplyTxPktDescState = TX_PEND;
        return RET_SUCCESS;
    }
    return RET_RX_BAD;
}

retcode_t memac_raw_arp_tx_free(TxPktDesc_t *p) {
    if (
        (p->len == ArpReplyTxPktDesc.len) &&
        (p->idx == ArpReplyTxPktDesc.idx) &&
        (ArpReplyTxPktDescState == TX_RSVD)
    ) {
        ArpReplyTxPktDescState = TX_FREE;
        return RET_SUCCESS;
    }
    else
        return RET_TX_OTHER;
}

void memac_raw_arp_tx_send(void) {
    if ((ArpReplyTxPktDescState == TX_PEND) && (memac_raw_tx_prq_rdy()))  {
        memac_raw_tx_send(&ArpReplyTxPktDesc);
       memacRawCountArpRepTx++;
        ArpReplyTxPktDescState = TX_RSVD;
    }
}

// on entry:
retcode_t memac_raw_arp_init(void) {
	ArpReplyTxPktDescState = TX_FREE;
    ArpReplyTxPktDesc.len = FRAME_HDR_LEN+ARP_LEN;
    if (!memac_raw_tx_alloc(&ArpReplyTxPktDesc)) {
        memac_raw_tx_init(&ArpReplyTxPktDesc, BroadcastMacAddr, FRAME_ETHERTYPE_ARP);
        return RET_SUCCESS;
    }
    else
        return RET_FAIL;
}
