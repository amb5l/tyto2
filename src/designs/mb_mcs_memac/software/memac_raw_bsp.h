#ifndef _memac_raw_bsp_h_
#define _memac_raw_bsp_h_

#include <stdint.h>

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

#define MEMAC_GPO_PHY_RST_N    0
#define MEMAC_GPO_TX_RST_N     1
#define MEMAC_GPO_RX_RST_N     2
#define MEMAC_GPO_PHY_MDIO_PRE 3
#define MEMAC_GPO_TX_SPD0      4
#define MEMAC_GPO_TX_SPD1      5
#define MEMAC_GPO_RX_SPD0      6
#define MEMAC_GPO_RX_SPD1      7

#define MEMAC_GPI_TX_PRQ_RDY   0
#define MEMAC_GPI_RX_SPD0      5
#define MEMAC_GPI_RX_SPD1      6

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
uint8_t memac_raw_bsp_init(void);

#endif
