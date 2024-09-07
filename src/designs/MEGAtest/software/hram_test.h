#ifndef _hram_test_h_
#define _hram_test_h_

#include "bsp.h"

#define RA_CTRL (HT_BASE+0x00)
#define RA_STAT (HT_BASE+0x04)
#define RA_BASE (HT_BASE+0x08)
#define RA_SIZE (HT_BASE+0x0C)
#define RA_DATA (HT_BASE+0x10)
#define RA_INCR (HT_BASE+0x14)
#define RA_EADD (HT_BASE+0x18)
#define RA_EDAT (HT_BASE+0x1C)
#define RA_EDR0 (HT_BASE+0x20)
#define RA_EDR1 (HT_BASE+0x24)
#define RA_EDR2 (HT_BASE+0x28)
#define RA_EDR3 (HT_BASE+0x2C)

extern u8 ht_clksel;

u8 ht_run(
    u8  w      ,
    u8  r      ,
    u8  reg    ,
    u32 addr   ,
    u32 size   ,
    u32 data   ,
    u32 incr   ,
    u8  arnd   ,
    u8  drnd   ,
    u8  dinv   ,
    u8  cb_m   ,
    u8  cb_i   ,
    u8  cb_pol ,
    u8  brnd   ,
    u8  bmag
);
void ht_err(u8 r);
u8 ht_init(void);

#endif
