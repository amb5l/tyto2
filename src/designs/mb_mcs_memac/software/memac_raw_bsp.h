#ifndef _memac_raw_bsp_h_
#define _memac_raw_bsp_h_

#include "bsp.h"
#include "memac_raw.h"

#define MEMAC_SIZE_TX_BUF     TX_BUF_SIZE
#define MEMAC_SIZE_RX_BUF     RX_BUF_SIZE

#define MEMAC_BASE            0xC0000000
#define MEMAC_BASE_TX_BUF     (MEMAC_BASE + 0x00000)
#define MEMAC_BASE_TX_BUF_ERR (MEMAC_BASE + 0x10000)
#define MEMAC_BASE_TX_PDQ     (MEMAC_BASE + 0x20000)
#define MEMAC_BASE_RX_BUF     (MEMAC_BASE + 0x40000)
#define MEMAC_BASE_RX_BUF_ERR (MEMAC_BASE + 0x50000)
#define MEMAC_BASE_RX_PDQ     (MEMAC_BASE + 0x60000)
#define MEMAC_BASE_MDIO       (MEMAC_BASE + 0x80000)

#define MEMAC_GPOB_PHY_RST_N    0
#define MEMAC_GPOB_TX_RST_N     1
#define MEMAC_GPOB_RX_RST_N     2
#define MEMAC_GPOB_PHY_MDIO_PRE 3
#define MEMAC_GPOB_TX_SPD0      4
#define MEMAC_GPOB_TX_SPD1      5
#define MEMAC_GPOB_RX_SPD0      6
#define MEMAC_GPOB_RX_SPD1      7
#define MEMAC_GPOB_RX_IPG_MIN0  8
#define MEMAC_GPOB_RX_IPG_MIN1  9
#define MEMAC_GPOB_RX_IPG_MIN2  10
#define MEMAC_GPOB_RX_IPG_MIN3  11
#define MEMAC_GPOB_RX_PRE_LEN0  12
#define MEMAC_GPOB_RX_PRE_LEN1  13
#define MEMAC_GPOB_RX_PRE_LEN2  14
#define MEMAC_GPOB_RX_PRE_LEN3  15
#define MEMAC_GPOB_RX_PRE_INC   16
#define MEMAC_GPOB_RX_FCS_INC   17

#define MEMAC_GPOM_TX_SPD       (0b11 << MEMAC_GPOB_TX_SPD0)
#define MEMAC_GPOM_RX_SPD       (0b11 << MEMAC_GPOB_RX_SPD0)
#define MEMAC_GPOM_RX_IPG_MIN   (0b1111 << MEMAC_GPOB_RX_IPG_MIN0)
#define MEMAC_GPOM_RX_PRE_LEN   (0b1111 << MEMAC_GPOB_RX_PRE_LEN0)
#define MEMAC_GPOM_RX_PRE_INC   (1 << MEMAC_GPOB_RX_PRE_INC)
#define MEMAC_GPOM_RX_FCS_INC   (1 << MEMAC_GPOB_RX_FCS_INC)

#define MEMAC_GPIB_TX_PRQ_RDY   0
#define MEMAC_GPIB_TX_PFQ_RDY   1
#define MEMAC_GPIB_RX_PRQ_RDY   2
#define MEMAC_GPIB_RX_PFQ_RDY   3
#define MEMAC_GPIB_RX_SPD0      5
#define MEMAC_GPIB_RX_SPD1      6

#define MEMAC_SPD_RSVD 0b11
#define MEMAC_SPD_1000 0b10
#define MEMAC_SPD_100  0b01
#define MEMAC_SPD_10   0b00

void memac_raw_phy_reset(uint8_t r);
void memac_raw_phy_mdio_poke(uint8_t pa, uint8_t ra, uint16_t d);
uint16_t memac_raw_phy_mdio_peek(uint8_t pa, uint8_t ra);
uint16_t memac_raw_get_speed(void);
retcode_t memac_raw_set_speed(uint16_t s) ;
void memac_raw_reset(uint8_t r);
#define memac_raw_tx_prq_rdy() (gpi(1) & (1 << MEMAC_GPIB_TX_PRQ_RDY) ? true : false)
#define memac_raw_tx_pfq_rdy() (gpi(1) & (1 << MEMAC_GPIB_TX_PFQ_RDY) ? true : false)
#define memac_raw_rx_prq_rdy() (gpi(1) & (1 << MEMAC_GPIB_RX_PRQ_RDY) ? true : false)
#define memac_raw_rx_pfq_rdy() (gpi(1) & (1 << MEMAC_GPIB_RX_PFQ_RDY) ? true : false)
retcode_t memac_raw_tx_send(TxPktDesc_t *p);
void memac_raw_rx_ctrl(uint8_t ipgMin, uint8_t preLen, uint8_t preInc, uint8_t fcsInc);
retcode_t memac_raw_rx_get(RxPktDesc_t *pPD);
retcode_t memac_raw_tx_send(TxPktDesc_t *pPD);
retcode_t memac_raw_tx_free(TxPktDesc_t *pPD);
retcode_t memac_raw_rx_free(RxPktDesc_t *pPD);
retcode_t memac_raw_bsp_init(void);

#endif
