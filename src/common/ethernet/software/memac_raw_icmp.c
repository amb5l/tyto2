// TODO: support outbound requests

#include "memac_raw.h"

uint32_t memacRawCountIcmpRx            = 0;
//uint32_t memacRawCountIcmpEchoReqRx     = 0;
//uint32_t memacRawCountIcmpEchoReqRxGood = 0;
//uint32_t memacRawCountIcmpEchoReqRxDrop = 0;
uint32_t memacRawCountIcmpEchoRepTx     = 0;

TxPktDesc_t IcmpReplyTxPktDesc;
TxPktDescState_t IcmpReplyTxPktDescState;

retcode_t memac_raw_icmp_rx(RxPktDesc_t *pPD) {
    if (memac_raw_rx_peek8(pPD, FRAME_HDR_LEN+9) != IP_PROTOCOL_ICMP)
        return RET_RX_OTHER; // not ICMP so try another protocol
    memacRawCountIcmpRx++;

    uint8_t ipHdrLen = 4 * (memac_raw_rx_peek8(pPD, FRAME_HDR_LEN+0) & 0b1111);
    uint16_t type_code = memac_raw_rx_peek16(pPD, FRAME_HDR_LEN+ipHdrLen+0);
    if (type_code != 0x0800 && type_code != 0x0000)
        return RET_RX_IGNORE; // not an echo request or reply

    IpAddr_t dstIpAddr = (IpAddr_t)memac_raw_rx_peek32(pPD, FRAME_HDR_LEN+16);
    if (dstIpAddr != myIpAddr)
        return RET_RX_IGNORE; // we are not the target of this ping

    uint16_t ipTotalLen = memac_raw_rx_peek16(pPD, FRAME_HDR_LEN+2);
    uint16_t icmpLen = ipTotalLen - ipHdrLen;
    uint32_t checkSum32 = 0;
    for (uint16_t i = 0; i < icmpLen; i+=2) {
        if (i == icmpLen-1) {
            checkSum32 += memac_raw_rx_peek8(pPD, FRAME_HDR_LEN+ipHdrLen+i);
            break;
        }
        else
            checkSum32 += i != 2 ? memac_raw_rx_peek16(pPD, FRAME_HDR_LEN+ipHdrLen+i) : 0;
    }
    uint16_t checkSum = (~((checkSum32 & 0xFFFF) + (checkSum32 >> 16)));
    if (memac_raw_rx_peek16(pPD, FRAME_HDR_LEN+ipHdrLen+2) != checkSum)
        return RET_RX_BAD; // checksum is bad

    if (IcmpReplyTxPktDescState != TX_FREE)
        return RET_RX_DROP; // reply packet is not available

    // build reply packet
    MacAddr_t srcMacAddr;
    memac_raw_rx_memcpy(pPD, 6, 6, srcMacAddr);
    IpAddr_t srcIpAddr = (IpAddr_t)memac_raw_rx_peek32(pPD, FRAME_HDR_LEN+12);
    memac_raw_ip_tx_init(
        &IcmpReplyTxPktDesc, // buffer to write to
        srcMacAddr,          // destination MAC address = source
        srcIpAddr,           // destination IP address = source
        IP_PROTOCOL_ICMP,    // IP protocol
        icmpLen              // length of payload
    );
    memac_raw_tx_poke16(&IcmpReplyTxPktDesc, FRAME_HDR_LEN+ 4, memac_raw_rx_peek16(pPD, FRAME_HDR_LEN+4)); // copy identification
    memac_raw_ip_tx_cks(&IcmpReplyTxPktDesc);
    memac_raw_tx_rxcpy( // copy echo request to reply
        &IcmpReplyTxPktDesc,
        FRAME_HDR_LEN+IP_HDR_LEN,
        icmpLen,
        pPD,
        FRAME_HDR_LEN+ipHdrLen
    );
    memac_raw_tx_poke8( // set type to echo reply
        &IcmpReplyTxPktDesc,
        FRAME_HDR_LEN+IP_HDR_LEN+0,
        0
    );
    memac_raw_tx_poke16(&IcmpReplyTxPktDesc, FRAME_HDR_LEN+IP_HDR_LEN+2, checkSum + 0x0800); // adjust ICMP checksum for reply type
    IcmpReplyTxPktDesc.len = FRAME_HDR_LEN+IP_HDR_LEN+icmpLen;
    IcmpReplyTxPktDescState = TX_PEND;
    return RET_SUCCESS;
}

retcode_t memac_raw_icmp_tx_free(TxPktDesc_t *pPD) {
    if (
        (pPD->len == IcmpReplyTxPktDesc.len) &&
        (pPD->idx == IcmpReplyTxPktDesc.idx) &&
        (IcmpReplyTxPktDescState == TX_RSVD)
    ) {
        IcmpReplyTxPktDescState = TX_FREE;
        return RET_SUCCESS;
    }
    else
        return RET_TX_OTHER;
}

void memac_raw_icmp_tx_send(void) {
    if ((IcmpReplyTxPktDescState == TX_PEND) && (memac_raw_tx_prq_rdy()))  {
        memac_raw_tx_send(&IcmpReplyTxPktDesc);
        memacRawCountIcmpEchoRepTx++;
        IcmpReplyTxPktDescState = TX_RSVD;
    }
}

retcode_t memac_raw_icmp_init(void) {
    IcmpReplyTxPktDescState = TX_FREE;
    IcmpReplyTxPktDesc.len = FRAME_HDR_LEN+IP_MTU;
    return memac_raw_tx_alloc(&IcmpReplyTxPktDesc);
}
