#ifndef _memac_raw_h_
#define _memac_raw_h_

#include <stdint.h>
#include <stdbool.h>

#define Q(x) #x
#define QUOTE(x) Q(x)

// EtherType field of Ethernet frame
#define FRAME_HDR_LEN            14
#define FRAME_ETHERTYPE_IPv4     0x0800
#define FRAME_ETHERTYPE_ARP      0x0806

// return codes
#define RET_SUCCESS     0
#define RET_FAIL        1
#define RET_TX_OTHER   -1 // not me
#define RET_TX_BUSY     1 // not ready, try again later
#define RET_RX_OTHER   -1 // not my protocol / not for me; don't drop it
#define RET_RX_IGNORE   1 // ignore it (drop it)
#define RET_RX_DROP     2 // drop it because of resource limits
#define RET_RX_BAD      3 // drop it because it's bad

typedef int8_t  retcode_t;
typedef uint8_t MacAddr_t[6];

typedef struct {
    uint16_t    len;
    uint16_t    idx;
    uint16_t    flags;
} RxPktDesc_t;

typedef struct {
    uint16_t    len;
    uint16_t    idx;
} TxPktDesc_t;

typedef enum {
    TX_FREE, // freed/unused
    TX_PEND, // pending = ready to submit to PRQ
    TX_RSVD  // reserved = sent to PRQ
} TxPktDescState_t;

extern uint32_t  phyID;
extern MacAddr_t myMacAddr;
extern MacAddr_t BroadcastMacAddr;

extern uint32_t memacCountTxUnhandled;
extern uint32_t memacCountRx;
extern uint32_t memacCountRxUnhandled;

void phy_id(void);
retcode_t phy_anc(void);
void memac_raw_tx_poke8(TxPktDesc_t *pPD, uint16_t i, uint8_t d);
void memac_raw_tx_poke16(TxPktDesc_t *pPD, uint16_t i, uint16_t d);
void memac_raw_tx_poke32(TxPktDesc_t *pPD, uint16_t i, uint32_t d);
uint8_t memac_raw_tx_peek8(TxPktDesc_t *pPD, uint16_t i);
uint16_t memac_raw_tx_peek16(TxPktDesc_t *pPD, uint16_t i);
uint32_t memac_raw_tx_peek32(TxPktDesc_t *pPD, uint16_t i);
uint8_t memac_raw_rx_peek8(RxPktDesc_t *pPD, uint16_t i);
uint16_t memac_raw_rx_peek16(RxPktDesc_t *pPD, uint16_t i);
uint32_t memac_raw_rx_peek32(RxPktDesc_t *pPD, uint16_t i);
void memac_raw_tx_memcpy(TxPktDesc_t *pPD, uint16_t idx, uint16_t len, uint8_t *pSrc);
void memac_raw_tx_rxcpy(TxPktDesc_t *t, uint16_t ti, uint16_t len, RxPktDesc_t *r, uint16_t ri);
void memac_raw_rx_memcpy(RxPktDesc_t *pPD, uint16_t idx, uint16_t len, uint8_t *pDst);
uint16_t memac_raw_tx_init(TxPktDesc_t *pPD, MacAddr_t pDstMac, uint16_t etherType);
void memac_raw_poll(void);
retcode_t memac_raw_tx_alloc(TxPktDesc_t *pPD);
retcode_t memac_raw_init(void);

#include "memac_raw_bsp.h"
#ifdef MEMAC_RAW_ENABLE_IP
#include "memac_raw_ip.h"
#endif
#ifdef MEMAC_RAW_ENABLE_ARP
#include "memac_raw_arp.h"
#endif
#ifdef MEMAC_RAW_ENABLE_ICMP
#include "memac_raw_icmp.h"
#endif

#endif
