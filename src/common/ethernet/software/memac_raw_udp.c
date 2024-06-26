#include "memac_raw.h"

uint16_t memac_raw_udp_tx_init(
    TxPktDesc_t *p,
    MacAddr_t    pDstMac,
    IpAddr_t     DstIp,
    uint16_t     srcPort,
    uint16_t     dstPort,
    uint16_t     len
) {
    uint16_t i = memac_raw_ip_tx_init(p, pDstMac, DstIp, IP_PROTOCOL_UDP, len+8);
    memac_raw_tx_poke16(p, i+0, srcPort ); // source port
    memac_raw_tx_poke16(p, i+2, dstPort ); // destination port
    memac_raw_tx_poke16(p, i+4,   8+len ); // length (includes header)
    memac_raw_tx_poke16(p, i+6,       0 ); // checksum
    return i+8;
}

void memac_raw_udp_tx_cks(TxPktDesc_t *p, uint16_t len) {
    // calculate UDP checksum, starting at offset 32
    uint8_t ip_hdr_len = 4 * (memac_raw_tx_peek8(p, FRAME_HDR_LEN+0) & 0b1111);
    uint32_t cks = 0;
    for (uint16_t i = 0; i < len+8; i += 2) {
        if (i == len+8-1) {
            cks += memac_raw_tx_peek8(p, FRAME_HDR_LEN+ip_hdr_len+i);
            break;
        }
        else
            cks += i != 6 ? memac_raw_tx_peek16(p, FRAME_HDR_LEN+ip_hdr_len+i) : 0;
    }
    // add pseudo header
    cks += memac_raw_tx_peek16(p, FRAME_HDR_LEN+12); // source IP
    cks += memac_raw_tx_peek16(p, FRAME_HDR_LEN+16); // destination IP
    cks += memac_raw_tx_peek8 (p, FRAME_HDR_LEN+ 9); // protocol
    cks += memac_raw_tx_peek16(p, FRAME_HDR_LEN+ip_hdr_len+6); // UDP length
    // fold 32-bit sum to 16 bits, then take 1's complement
    cks = ~((cks & 0xFFFF) + (cks >> 16));
    // if result is zero, send FFFF
    if (cks == 0) cks = 0xFFFF;
    // write to UDP header
    memac_raw_tx_poke16(p, FRAME_HDR_LEN+ip_hdr_len+6, cks);
}
