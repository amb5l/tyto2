#ifndef _memac_raw_ip_h_
#define _memac_raw_ip_h_

#define IP_MTU           1500
#define IP_VER_IHL       0x45
#define IP_HDR_LEN       ((IP_VER_IHL & 0b1111)*4)
#define IP_PROTOCOL_UDP  0x11
#define IP_PROTOCOL_ICMP 0x01

typedef uint32_t IpAddr_t;

extern IpAddr_t myIpAddr;

#define memac_raw_ipaddr(a,b,c,d) ((a<<24)|(b<<16)|(c<<8)|d)
retcode_t memac_raw_ip_rx(RxPktDesc_t *p);
uint16_t memac_raw_ip_tx_init(
    TxPktDesc_t *p,        // packet descriptor
    MacAddr_t    pDstMac,  // destination MAC address
    IpAddr_t     DstIp,    // destination IP address
    uint8_t      protocol, // IP protocol
    uint16_t     len       // length of payload
);
void memac_raw_ip_tx_cks(TxPktDesc_t *p);
retcode_t memac_raw_ip_tx_free(TxPktDesc_t *p);
retcode_t memac_raw_ip_init(void);

#endif
