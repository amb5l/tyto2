#ifndef _memac_raw_arp_h
#define _memac_raw_arp_h

#include "memac_raw.h"

extern uint32_t memacRawCountArpReqRx;
extern uint32_t memacRawCountArpRepTx;

retcode_t memac_raw_arp_rx(RxPktDesc_t *pPD);
retcode_t memac_raw_arp_tx_free(TxPktDesc_t *pPD);
void memac_raw_arp_tx_send(void);
retcode_t memac_raw_arp_init(void);

#endif
