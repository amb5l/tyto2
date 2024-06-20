#ifndef _memac_raw_h_
#define _memac_raw_h_

typedef uint8_t MacAddr_t[6];
typedef uint8_t IpAddr_t[4];

typedef struct {
    uint16_t len;
    uint16_t idx;
    uint16_t flags;
} RxPktRsrvDesc_t;

typedef struct {
    uint16_t len;
} RxPktFreeDesc_t;

extern uint32_t  PhyID;
extern MacAddr_t MyMacAddr;
extern IpAddr_t  MyIpAddr;

#define poke16be(a,d) {poke8(a,(d)>>8);poke8(a+1,(d)&0xFF);}
#define peek16be(a)   ((uint16_t)peek8(a)<<8|peek8(a+1))

void phy_id(void);

uint16_t memac_raw_ip_tx_init(
    uint8_t   *pBuf,     // buffer
    MacAddr_t *pDstMac,  // destination MAC address
    IpAddr_t  *pSrcIp,   // source IP address
    IpAddr_t  *pDstIp,   // destination IP address
    uint8_t    protocol, // IP protocol
    uint16_t   len       // length of payload
);

uint16_t memac_raw_udp_tx_init(
    uint8_t   *buf,     // buffer
    MacAddr_t *dstMac,  // destination MAC address
    IpAddr_t  *srcIp,   // source IP address
    IpAddr_t  *dstIp,   // destination IP address
    uint16_t   srcPort, // source port
    uint16_t   dstPort, // destination port
    uint16_t   len      // length of payload
);

void memac_raw_udp_tx_cks(uint8_t *buf, uint16_t len);

void memac_raw_udp_tx_send(uint8_t *buf, uint16_t len);

void memac_raw_init(void);

#endif
