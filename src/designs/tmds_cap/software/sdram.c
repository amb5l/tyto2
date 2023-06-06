// sdram.c

#include <stdio.h>

void sdram_fill(uint32_t baseaddr, uint32_t highaddr, uint32_t start, uint32_t incr) {
    uint32_t a, d;

    d = start;
    for (a = baseaddr; a <= highaddr; a += 4) {
        *(uint32_t *)a = d;
        d += incr;
    }
}

void sdram_test(uint32_t baseaddr, uint32_t highaddr, uint32_t start, uint32_t incr) {
    uint32_t a, d, r, e;

    e = 0;
    d = start;
    for (a = baseaddr; a <= highaddr; a += 4) {
        r = *(uint32_t *)a;
        if r != d {
            printf("sdram_test: at %08X read %08X expected %08X\r\n", a, r, d);
            e++;
        }
        d += incr;
    }
    if e
        printf("sdram_test: %u errors\r\n", e);
    else
        printf("sdram_test: no errors!\r\n", e);
}
