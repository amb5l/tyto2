#ifndef _memac_mcs_p_h_
#define _memac_mcs_p_h_

#define MEMAC_BASE            0xC0000000

#define MEMEC_BASE_TX_BUF     (MEMAC_BASE + 0x00000)
#define MEMEC_BASE_TX_BUF_ERR (MEMAC_BASE + 0x10000)
#define MEMEC_BASE_TX_PDQ     (MEMAC_BASE + 0x20000)
#define MEMEC_BASE_RX_BUF     (MEMAC_BASE + 0x40000)
#define MEMEC_BASE_RX_BUF_ERR (MEMAC_BASE + 0x50000)
#define MEMEC_BASE_RX_PDQ     (MEMAC_BASE + 0x60000)
#define MEMEC_BASE_MDIO       (MEMAC_BASE + 0x80000)

#define MEMAC_GPIO_MD_RDY   4

#endif
