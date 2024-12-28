#include "hram_test.h"
#include "cb.h"
#include "printf.h"

uint16_t ht_cfgreg0; // configuration register 0
u16 ht_idreg0;  // ID register 0
u8 ht_clksel;   // clock select:
                // 000 = 100MHz, 001 = 105MHz, 010 = 110MHz, 011 = 120MHz,
                // 100 =  50MHz, 101 =  75MHz, 110 =  90MHz, 111 =  95MHz
u8 ht_tlat;     // HyperRAM latency, 0-7, typically 4 cycles
u8 ht_trwr;     // HyperRAM read-write recovery, 0-7, typically 4 cycles
u8 ht_trac;     // read access through FIFO, 0-3, typically 2
u8 ht_fix_w2;   // ISSI single write bug fix enable
u8 ht_abw;      // address boundary for writes (e.g. 9 for 9 bit column address)


// return value: 1 = errors detected, 0 = no errors detected
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
) {
    while(peek8(RA_STAT+3)) // wait if unlocked
        ;
    poke32(RA_BASE,addr);
    poke32(RA_SIZE,size);
    poke32(RA_DATA,data);
    poke32(RA_INCR,incr);
    u32 x =
        ((ht_clksel &  7) << 28) |
		((ht_abw    & 15) << 24) |
        ((ht_fix_w2 &  1) << 23) |
        ((ht_trac   &  1) << 22) |
        ((ht_trwr   &  7) << 19) |
        ((ht_tlat   &  7) << 16) |
        ((bmag      & 15) << 12) |
        ((brnd      &  1) << 11) |
        ((cb_pol    &  1) << 10) |
        ((cb_i      &  1) <<  9) |
        ((cb_m      &  1) <<  8) |
        ((d32       &  1) <<  7) |
        ((dinv      &  1) <<  6) |
        ((drnd      &  1) <<  5) |
        ((arnd      &  1) <<  4) |
        ((reg       &  1) <<  3) |
        ((r         &  1) <<  2) |
        ((w         &  1) <<  1);
    poke32(RA_CTRL,x | (1 << 31)); // reset assert
    poke32(RA_CTRL,x);             // reset negate
    poke32(RA_CTRL,x | 1);         // run assert
    while(!(peek8(RA_STAT+1)))     // wait until done
        ;
    poke32(RA_CTRL,x);             // run negate
    while(peek8(RA_STAT+1))        // wait until done cleared
        ;
    return ((peek8(RA_STAT+2) & 1) == 0); // return error status
}

void ht_err(const char *s) {
    if (!(peek8(RA_STAT+2) & 1)) {
        u8 attr = cb_get_attr();
        u8 c = 0;
        cb_set_col(CB_WHITE, CB_GREEN);
        printf("%s\n", s);
        cb_set_col(CB_WHITE, CB_RED);
        do {
            u32 ea = peek32(RA_ERRL);
            u32 ed = peek32(RA_ERRH);
            u16 er = ed & 0xFFFF;
            u16 ex = ed >> 16;
            printf("address %08X read %04X expected %04X\n", ea, er, ex);
        } while ((!(peek8(RA_STAT+2) & 1)) && (++c < 10));
        cb_set_attr(attr);
    } else {
        u8 attr = cb_get_attr();
        cb_set_col(CB_GREEN, CB_BLACK);
        jtag_uart_en_tx = 0;
        printf("%s - OK\n", s);
        jtag_uart_en_tx = 1;
        cb_set_attr(attr);
    }
}

u8 ht_init(void) {
    ht_cfgreg0 = 0xBFF7; // 46 ohms, variable latency = 4
    ht_idreg0  = 0x0C83; // IS66WVH8M8
    ht_clksel  = 0;      // 100 MHz
    ht_tlat    = 4;      // latency = 4 cycles
    ht_trwr    = 4;      // read-write recovery = 4 cycles
    ht_trac    = 2;      // read access through FIFO = 2 cycles
    ht_fix_w2  = 1;      // ISSI single write bug fix = enabled
    ht_abw     = 9;      // address boundary for writes = row boundary (9 bit column)
    poke32(RA_CTRL,(ht_clksel & 7) << 28);
    ht_lol(); // dummy read to allow time for LOL to assert
    while (ht_lol()); // wait for MMCM lock
	ht_run(1,0,1,0x1000,2,ht_cfgreg0,0,0,0,0,0,0,0,0,0,0); // write CFGREG0
	return ht_run(0,1,1,0x0000,2,ht_idreg0,0,0,0,0,0,0,0,0,0,0); // read and check IDREG0;
}

void ht_info(void) {
    u8 y;

    cb_i = 0;

	cb_set_col(CB_LIGHT_MAGENTA, CB_BLACK);
    printf("HyperRAM controller settings:\n");
    cb_set_col(CB_LIGHT_CYAN, CB_BLACK);
    printf("                              clock = ");
    switch(ht_clksel) {
        case 0: printf("100 MHz"); break;
        case 1: printf("105 MHz"); break;
        case 2: printf("110 MHz"); break;
        case 3: printf("120 MHz"); break;
        case 4: printf(" 50 MHz"); break;
        case 5: printf(" 75 MHz"); break;
        case 6: printf(" 90 MHz"); break;
        case 7: printf(" 95 MHz"); break;
    }
    printf("\n");
    printf("                            latency = %d cycles\n", ht_tlat);
    printf("                read-write recovery = %d cycles\n", ht_trwr);
    printf("           read access through FIFO = %d cycles\n", ht_trac);
    printf("               single write bug fix = %s\n", ht_fix_w2 ? "enabled" : "disabled");
    printf("  address boundary for write bursts = ");
    if (ht_abw == -1)
        printf("disabled");
    else
        printf("%d bits", ht_abw);
    printf("\n\n");

    y = cb_y;
    cb_y -= 8;
    cb_i = 48;
    printf("\r");

	cb_set_col(CB_LIGHT_MAGENTA, CB_BLACK);
    printf("HyperRAM device configuration:\n");
    cb_set_col(CB_LIGHT_CYAN, CB_BLACK);
    printf("  deep power down enable = %d\n", (ht_cfgreg0 >> 15) & 1);
    printf("          drive strength = ");
    switch((ht_cfgreg0 >> 12) & 7) {
        case 0: printf("34 ohms"); break;
        case 1: printf("115 ohms"); break;
        case 2: printf("67 ohms"); break;
        case 3: printf("46 ohms"); break;
        case 4: printf("34 ohms"); break;
        case 5: printf("27 ohms"); break;
        case 6: printf("22 ohms"); break;
        case 7: printf("19 ohms"); break;
    }
    printf("\n");
    printf("                reserved = %d%d%d%d\n",
        (ht_cfgreg0 >> 11) & 1,
        (ht_cfgreg0 >> 10) & 1,
        (ht_cfgreg0 >>  9) & 1,
        (ht_cfgreg0 >>  8) & 1
    );
    printf("         initial latency = ");
    switch((ht_cfgreg0 >> 4) & 15) {
        case 0b0000 : printf("5 cycles"); break;
        case 0b0001 : printf("6 cycles"); break;
        case 0b0010 : printf("7 cycles"); break;
        case 0b0011 : printf("8 cycles"); break;
        case 0b1110 : printf("3 cycles"); break;
        case 0b1111 : printf("4 cycles"); break;
        default     : printf("reserved");
    }
    printf("\n");
    printf("                 latency = %s\n", (ht_cfgreg0 >> 3) & 1 ? "fixed" : "variable");
    printf("            hybrid burst = %s\n", (ht_cfgreg0 >> 2) & 1 ? "disabled (legacy)" : "enabled");
    printf("            burst length = ");
    switch((ht_cfgreg0 >> 0) & 3) {
        case 0b00: printf("128 bytes"); break;
        case 0b01: printf("64 bytes"); break;
        case 0b10: printf("16 bytes"); break;
        case 0b11: printf("32 bytes"); break;
    }
    printf("\n");
	cb_set_col(CB_LIGHT_MAGENTA, CB_BLACK);

    cb_y -= 8;
    cb_i = 94;
    printf("\r");

	cb_set_col(CB_LIGHT_MAGENTA, CB_BLACK);
    printf("HyperRAM device ID:\n");
    cb_set_col(CB_LIGHT_CYAN, CB_BLACK);
    printf("      reserved bits 15..14 = %d%d\n",
        (ht_idreg0 >> 15) & 1,
        (ht_idreg0 >> 14) & 1
    );
    printf("           reserved bit 13 = %d\n", (ht_idreg0 >> 13) & 1);
    printf("     row address bit count = %d\n", 1+((ht_idreg0 >>  8) & 31));
    printf("  column address bit count = %d\n", 1+((ht_idreg0 >>  4) & 15));
    printf("              manufacturer = ");
    if ((ht_idreg0 & 15) == 0b0011)
        printf("ISSI (0011)");
    else
        printf("unknown (%d%d%d%d)",
            (ht_idreg0 >> 3) & 1,
            (ht_idreg0 >> 2) & 1,
            (ht_idreg0 >> 1) & 1,
            (ht_idreg0 >> 0) & 1
        );
    printf("\n");

    cb_y = y;
    cb_i = 0;
    printf("\r");
}
