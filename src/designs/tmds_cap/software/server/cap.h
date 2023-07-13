// cap.h

#ifndef _CAP_H_
#define _CAP_H_

#include <stdint.h>

#define CAP_BUF_PIXELS (16*1024*1024)
#define CAP_BUF_BYTES (4*CAP_BUF_PIXELS)

extern volatile uint32_t *cap_buf;
void cap_init();
void cap_start(uint32_t pixels);
uint32_t cap_rdy();
void cap_reg_dump();

#endif
