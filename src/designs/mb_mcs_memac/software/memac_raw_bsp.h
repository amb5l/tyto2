#ifndef _memac_raw_bsp_h_
#define _memac_raw_bsp_h_

#include <stdint.h>

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

void phy_mdio_poke(uint8_t pa, uint8_t ra, uint16_t d);
uint16_t phy_mdio_peek(uint8_t pa, uint8_t ra);
uint8_t memac_raw_get_speed(void);
void memac_raw_set_speed(uint8_t spd);
void memac_raw_reset(uint8_t rst);
uint8_t memac_raw_tx_rdy(void);
uint8_t memac_raw_tx_send(uint8_t *pBuf, uint16_t len);
void memac_raw_rx_ctrl(
    uint8_t ipg_min,
    uint8_t pre_len,
    uint8_t pre_inc,
    uint8_t fcs_inc
);
uint8_t memac_raw_rx_rdy(void);
uint8_t memac_raw_rx_get(RxPktRsrvDesc_t *p);
uint8_t memac_raw_bsp_init(void);

#endif
