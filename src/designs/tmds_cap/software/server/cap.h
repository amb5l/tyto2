// cap.h

#ifndef _CAP_H_
#define _CAP_H_

#include <stdint.h>

#define CAP_BUF_PIXELS (250*1000*1000) // 250 Mpixels requires 1 GiByte
#define CAP_BUF_BYTES (4*CAP_BUF_PIXELS)

extern volatile uint32_t *cap_buf;
void cap_init();
void cap_start(uint32_t pixels);
uint32_t cap_rdy();
void cap_reg_dump();

#endif
