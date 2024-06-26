#include "memac_raw.h"

IpAddr_t myIpAddr;

retcode_t memac_raw_ip_rx(RxPktDesc_t *pPD) {

    if (memac_raw_rx_peek16 (pPD, 12) != FRAME_ETHERTYPE_IPv4)
        return RET_RX_OTHER;

    uint8_t x = memac_raw_rx_peek8(pPD, FRAME_HDR_LEN+0);
    if (x >> 4 != 4) // version = 4
        return RET_RX_BAD;

    uint8_t hdrLen = (x & 0b1111) * 4;
    uint32_t checkSum32 = 0;
    for (uint8_t i = 0; i < hdrLen; i+=2)
        checkSum32 += i != 10 ? memac_raw_rx_peek16(pPD, FRAME_HDR_LEN+i) : 0;
    uint16_t checkSum = (~((checkSum32 & 0xFFFF) + (checkSum32 >> 16)));
    if (checkSum != memac_raw_rx_peek16(pPD, FRAME_HDR_LEN+10))
        return RET_RX_BAD;
    printf("IP proto 0x%02X\r\n", memac_raw_rx_peek8(pPD, FRAME_HDR_LEN+9));

    if (true)
#ifdef MEMAC_RAW_ENABLE_ICMP
    if (memac_raw_icmp_rx(pPD) < 0)
#endif
#ifdef MEMAC_RAW_ENABLE_UDP
    if (memac_raw_udp_rx(pPD) < 0)
#endif
    return RET_FAIL;
    return RET_SUCCESS;
}

// initialise an IP packet
uint16_t memac_raw_ip_tx_init(
    TxPktDesc_t *pPD,      // packet descriptor
    MacAddr_t    pDstMac,  // destination MAC address
    IpAddr_t     DstIp,    // destination IP address
    uint8_t      protocol, // IP protocol
    uint16_t     len       // length of payload
) {
    uint16_t i = memac_raw_tx_init(pPD, pDstMac, FRAME_ETHERTYPE_IPv4);
    memac_raw_tx_poke8 (pPD, i+ 0,     IP_VER_IHL ); // version, IHL
    memac_raw_tx_poke8 (pPD, i+ 1,              0 ); // DSCP, ECN
    memac_raw_tx_poke16(pPD, i+ 2, len+IP_HDR_LEN ); // total length (includes header)
    memac_raw_tx_poke16(pPD, i+ 4,              0 ); // identification
    memac_raw_tx_poke16(pPD, i+ 6,              0 ); // flags, fragment offset
    memac_raw_tx_poke8 (pPD, i+ 8,             64 ); // TTL
    memac_raw_tx_poke8 (pPD, i+ 9,       protocol ); // protocol
    memac_raw_tx_poke16(pPD, i+10,              0 ); // checksum
    memac_raw_tx_poke32(pPD, i+12,       myIpAddr ); // source IP
    memac_raw_tx_poke32(pPD, i+16,          DstIp ); // destination IP
    return i+20;
}

void memac_raw_ip_tx_cks(TxPktDesc_t *pPD) {
    uint8_t hdrLen = 4 * (memac_raw_tx_peek8(pPD, FRAME_HDR_LEN+0) & 0b1111);
    uint32_t checkSum32 = 0;
    for (uint16_t i = 0; i < hdrLen; i += 2)
        checkSum32 += i != 10 ? memac_raw_tx_peek16(pPD, FRAME_HDR_LEN+i) : 0;
    uint16_t checkSum = ~((checkSum32 & 0xFFFF) + (checkSum32 >> 16));
    memac_raw_tx_poke16(pPD, FRAME_HDR_LEN+10, checkSum);
}

retcode_t memac_raw_ip_tx_free(TxPktDesc_t *pPD) {
    retcode_t r;
#ifdef MEMAC_RAW_ENABLE_ICMP
    r = memac_raw_icmp_tx_free(pPD);
    if (r >= 0)
        return r;
#endif
#ifdef MEMAC_RAW_ENABLE_UDP
    r = memac_raw_udp_tx_free(p);
    if (r >= 0)
        return r;
#endif
    return RET_TX_OTHER;
}

retcode_t memac_raw_ip_init(void) {
    myIpAddr = memac_raw_ipaddr(192,168,2,155);
    printf("myIpAddr = %d %d %d %d\r\n",
        (myIpAddr >> 24),
        (myIpAddr >> 16) & 0xFF,
        (myIpAddr >>  8) & 0xFF,
        (myIpAddr >>  0) & 0xFF
    );
    return RET_SUCCESS;
}
