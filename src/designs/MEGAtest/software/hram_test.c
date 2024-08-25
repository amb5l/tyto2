#include "hram_test.h"
#include "printf.h"

u8 ht_clksel = 0;

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
    u8  cb_m   ,
    u8  cb_i   ,
    u8  cb_pol ,
    u8  brnd   ,
    u8  bmag
) {
    while(peek8(RA_STAT+3)) // wait if unlocked
        ;
    poke32(RA_BASE,addr);
    poke32(RA_SIZE,size);
    poke32(RA_DATA,data);
    poke32(RA_INCR,incr);
    u32 x =
        ((bmag   & 15) << 12) |
        ((brnd   &  1) << 11) |
        ((cb_pol &  1) << 10) |
        ((cb_i   &  1) <<  9) |
        ((cb_m   &  1) <<  8) |
        ((drnd   &  1) <<  7) |
        ((arnd   &  1) <<  6) |
        ((reg    &  1) <<  5) |
        ((r      &  1) <<  4) |
        ((w      &  1) <<  3) |
        (1             <<  2) |
        (ht_clksel & 3);
    poke32(RA_CTRL,x); // run
    while(!(peek8(RA_STAT+1))) // wait until done
        ;
    poke32(RA_CTRL,0); // negate run
    while(peek8(RA_STAT+1)) // wait until done cleared
        ;
    return peek8(RA_STAT+2); // return error status
}

void ht_err(u8 r) {
    if (r)
        printf("\nread %04X expected %04X address %08X\n",
            peek16(RA_EDAT),
            peek16(RA_EDAT+2),
            peek32(RA_EADD)
        );
    else
        printf("OK  ");
}

u8 ht_init(void) {
	ht_run(1,0,1,0x1000,2,0x8FF7,0,0,0,0,0,0,0,0); // write CFGREG0 - set latency to 4, variable
	u8 r = ht_run(0,1,1,0x0000,2,0x0C83,0,0,0,0,0,0,0,0); // read IDREG0
	return r;
}