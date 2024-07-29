#include <stdlib.h>
#include <stdint.h>

#include "axi_gpio.h"
#include "cb.h"
#include "printf.h"

void bsp_cb_border(uint8_t c) {
	uint32_t r;

	r = axi_gpio_get_gpi(0);
	r = (r & ~0xF0) | (c << 4);
	axi_gpio_set_gpo(0, r);
}

void bsp_init(uint8_t mode)
{
	uint32_t r;
	uint8_t x, y;

	r = axi_gpio_get_gpi(0);
	r = (r & ~1) | (mode & 1);
	axi_gpio_set_gpo(0, r);
	cb_width = 80;
	cb_height = mode ? 32 : 25;
	cb_x = 0;
	cb_y = 0;
	cb_attr = 0x0F;
	for (x = 0; x < cb_width; x++)
		for (y = 0; y < cb_height; y++)
			POKE_CHAR_ATTR(x,y,0,cb_attr);
    init_printf(NULL,cb_putc);
}
