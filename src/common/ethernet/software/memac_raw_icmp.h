#ifndef _memac_raw_icmp_h
#define _memac_raw_icmp_h

#include "memac_raw.h"

extern uint32_t memacRawCountIcmpRx;
extern uint32_t memacRawCountIcmpEchoRepTx;

retcode_t memac_raw_icmp_rx(RxPktDesc_t *pPD);
retcode_t memac_raw_icmp_tx_free(TxPktDesc_t *pPD);
void memac_raw_icmp_tx_send(void);
retcode_t memac_raw_icmp_init(void);

#endif
