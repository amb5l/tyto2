#ifndef _memac_raw_udp_h_
#define _memac_raw_udp_h_

#include "memac_raw.h"

uint16_t memac_raw_udp_tx_init(
	TxPktDesc_t *p,
	MacAddr_t   *pDstMac,
	IpAddr_t     DstIp,
	uint16_t     srcPort,
	uint16_t     dstPort,
	uint16_t     len
);
void memac_raw_udp_tx_cks(TxPktDesc_t *p, uint16_t len);

#endif
