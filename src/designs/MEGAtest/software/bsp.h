#ifndef _bsp_h_
#define _bsp_h_

#include <stdint.h>
#include "xil_types.h"
#include "xparameters.h"

#define BD_mb_mcs     1
#define BD_mbv_maxi_j 2
#define XADD_BD(x)    BD_##x
#define ADD_BD(x)     XADD_BD(x)
#define IS_BD(x)     (ADD_BD(BD) == BD_##x)

#if IS_BD(mb_mcs)

#include "xiomodule.h"

#define CB_BUF    XPAR_CPU_IOMODULE_0_IO_BASEADDR
#define XADC_BASE (XPAR_CPU_IOMODULE_0_IO_BASEADDR | (1 << 28))
#define HT_BASE   (XPAR_CPU_IOMODULE_0_IO_BASEADDR | (1 << 29))

#define gpi(n)        XIOModule_DiscreteRead(&io,n)
#define gpo(n,d)      XIOModule_DiscreteWrite(&io,n,d)
#define gpobit(n,b,d) XIOModule_DiscreteWrite(&io,n,((io.GpoValue[n-1] & ~(1 << (b))) | ((d) << (b))))
#define gpormw(n,m,d) XIOModule_DiscreteWrite(&io,n,((io.GpoValue[n-1] & ~(m)) | (d)))

// TODO get this from an external symbol
#define BSP_INTERVAL_1S  100000000
#define BSP_INTERVAL_1mS 100000
#define BSP_INTERVAL_1uS 100

extern XIOModule io;

#endif

#if IS_BD(mbv_maxi_j)

#include "peekpoke.h"

#define CB_BUF    (XPAR_MAXI_BASEADDR | (0b100 << 28))
#define XADC_BASE (XPAR_MAXI_BASEADDR | (0b101 << 28))
#define HT_BASE   (XPAR_MAXI_BASEADDR | (0b110 << 28))
#define GPIO_BASE (XPAR_MAXI_BASEADDR | (0b111 << 28))

#define gpi(n)        peek32(GPIO_BASE+((n+3)<<2))
#define gpo_i(n)      peek32(GPIO_BASE+((n-1)<<2))
#define gpo(n,d)      poke32(GPIO_BASE+((n-1)<<2),d)
#define gpobit(n,b,d) gpo(n,(gpo_i(n) & ~(1 << (b))) | ((d) << (b)))
#define gpormw(n,m,d) gpo(n,(gpo_i(n) & ~(m)) | (d))

extern uint8_t jtag_uart_en;
extern uint8_t jtag_uart_en_tx;
uint8_t bsp_getc_rdy(void);
char bsp_getc(void *p);

#endif

void bsp_interval(uint32_t t);
void bsp_cb_border(uint8_t c);
#define bsp_board_rev() (gpi(4) & 0xF)
#define bsp_commit() gpi(3)
int bsp_init();

#endif
