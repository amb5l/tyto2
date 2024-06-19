#include "bsp.h"
#include "memac_raw.h"
#include "memac_raw_bsp.h"
#include "memac_raw_mdio.h"

#define ETHERTYPE_IPv4    0x0800
#define ETHERTYPE_ARP     0x0806
#define IP_PROTOCOL_UDP   0x11
#define IP_PROTOCOL_ICMP  0x01

PhyID_t   PhyID;
MacAddr_t MyMacAddr = {0xEE,0xEE,0xEE,0xEE,0xEE,0xEE};
IpAddr_t  MyIpAddr = {192,168,1,155};

void phy_id(void) {
	uint16_t id1, id2;
    id1 = phy_mdio_peek(1, MDIO_RA_PHYID1);
    id2 = phy_mdio_peek(1, MDIO_RA_PHYID2);
    PhyID.oui = (id1 << 6) | (id2 >> 10);
    PhyID.model = (id2 >> 4) & 0x3F;
    PhyID.rev = id2 & 0xF;
}

uint16_t memac_raw_tx_init(
    uint8_t   *pBuf,     // buffer to write to
    MacAddr_t *pDstMac,  // destination MAC address
    uint16_t   etherType, // Ethernet type
    uint16_t   len       // length of payload
) {
    memcpy(&pBuf[0], pDstMac,   6);
    memcpy(&pBuf[6], MyMacAddr, 6);
    poke16be(&pBuf[12], etherType);
    return 14;
}

uint16_t memac_raw_ip_tx_init(
    uint8_t   *pBuf,     // buffer to write to
    MacAddr_t *pDstMac,  // destination MAC address
    IpAddr_t  *pSrcIp,   // source IP address
    IpAddr_t  *pDstIp,   // destination IP address
    uint8_t    protocol, // IP protocol
    uint16_t   len       // length of payload
) {
    uint16_t i;
    i = memac_raw_tx_init(pBuf, pDstMac, ETHERTYPE_IPv4, len+20);
    poke8    ( &pBuf[i+ 0],      0x45 ); // version, IHL
    poke8    ( &pBuf[i+ 1],         0 ); // DSCP, ECN
    poke16be ( &pBuf[i+ 2],    len+20 ); // total length (includes header)
    poke16be ( &pBuf[i+ 4],         0 ); // identification
    poke16be ( &pBuf[i+ 6],         0 ); // flags, fragment offset
    poke8    ( &pBuf[i+ 8],        64 ); // TTL
    poke8    ( &pBuf[i+ 9],  protocol ); // protocol
    poke16be ( &pBuf[i+10],         0 ); // checksum
    memcpy   ( &pBuf[i+12], pSrcIp, 4 ); // source IP
    memcpy   ( &pBuf[i+16], pDstIp, 4 ); // destination IP
    // calculate IP checksum
    uint32_t cks = 0;
    for (uint16_t j = 0; j < 20; j += 2) {
        cks += peek16be(&pBuf[i+j]);
    }
    cks = ~((cks & 0xFFFF) + (cks >> 16));
    poke16be(&pBuf[i+10], cks);
    return i+20;
}

uint16_t memac_raw_udp_tx_init(
    uint8_t   *pBuf,
    MacAddr_t *pDstMac,
    IpAddr_t  *pSrcIp,
    IpAddr_t  *pDstIp,
    uint16_t   srcPort,
    uint16_t   dstPort,
    uint16_t   len
) {
    uint16_t i;
    i = memac_raw_ip_tx_init(pBuf, pDstMac, pSrcIp, pDstIp, IP_PROTOCOL_UDP, len+8);
    poke16be ( &pBuf[i+0], srcPort ); // source port
    poke16be ( &pBuf[i+2], dstPort ); // destination port
    poke16be ( &pBuf[i+4],     len ); // length
    poke16   ( &pBuf[i+6],       0 ); // checksum
    return i+8;
}

void memac_raw_udp_tx_cks(uint8_t *pBuf, uint16_t len) {
    // calculate UDP checksum, starting at offset 32
    uint32_t cks = 0;
    for (uint16_t i = 0; i < len+8; i += 2) {
        if (i == len+8-1) {
            cks += pBuf[34+i];
            break;
        }
        else
            cks += peek16be(&pBuf[34+i]);
    }
    // add pseudo header
    cks += peek16be ( &pBuf[14+12  ] ); // source IP
    cks += peek16be ( &pBuf[14+16  ] ); // destination IP
    cks += peek8    ( &pBuf[14+ 9  ] ); // protocol
    cks += peek16be ( &pBuf[14+20+6] ); // UDP length
    // fold 32-bit sum to 16 bits, then take 1's complement
    cks = ~((cks & 0xFFFF) + (cks >> 16));
    // if result is zero, send FFFF
    if (cks == 0) cks = 0xFFFF;
    // write to UDP header
    poke16be(&pBuf[14+20+6], cks);
}

void memac_raw_udp_tx_send(uint8_t *buf, uint16_t len) {
    memac_raw_tx_send(buf, len+14+20+8);
}

void memac_raw_init(void) {
    memac_raw_bsp_init();
}
