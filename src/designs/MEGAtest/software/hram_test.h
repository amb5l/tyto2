#ifndef _hram_test_h_
#define _hram_test_h_

#include "bsp.h"

#define RA_CTRL (HT_BASE+0x00)
#define RA_STAT (HT_BASE+0x04)
#define RA_BASE (HT_BASE+0x08)
#define RA_SIZE (HT_BASE+0x0C)
#define RA_DATA (HT_BASE+0x10)
#define RA_INCR (HT_BASE+0x14)
#define RA_ERRL (HT_BASE+0x18)
#define RA_ERRH (HT_BASE+0x1C)

extern u8 ht_clksel; // clock select: 00 = 100MHz, 01 = 105MHz, 10 = 110MHz, 11 = 120MHz
extern u8 ht_tlat;   // HyperRAM latency, 0-7, typically 4 cycles
extern u8 ht_trwr;   // HyperRAM read-write recovery, 0-7, typically 4 cycles
extern u8 ht_trac;   // read access through FIFO, 0-3, typically 2
extern u8 ht_fix_w2; // ISSI single write bug fix enable
extern u8 ht_abw;    // address boundary for writes (e.g. 9 for 9 bit column address)

#define ht_lol() (peek8(RA_STAT+3) & 1) // loss of lock

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
    u8  d32    ,
    u8  cb_m   ,
    u8  cb_i   ,
    u8  cb_pol ,
    u8  brnd   ,
    u8  bmag
);
void ht_err(const char *s);
u8 ht_init(void);
void ht_info(void);

#endif
