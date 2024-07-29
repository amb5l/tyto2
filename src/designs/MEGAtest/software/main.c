#include <string.h>

#include "bsp.h"
#include "cb.h"

#define Q(x) #x
#define QUOTE(x) Q(x)

#define CTRL_C 3

int main() {

	int i;
	uint8_t attr;
	unsigned int u;
	char s[256];

	bsp_init();
	cb_set_border(CB_LIGHT_BLUE);
	cb_set_col(CB_YELLOW, CB_BLUE);
	printf("MicroBlaze demo application for mb_cb design...\n");

	strcpy(s, "HELLO! ");
	attr = 0x34;
	u = (cb_width*(cb_height-1))/strlen(s);
	for (i = 0; i < u; i++) {
		cb_set_attr(attr++);
		printf("%s", s);
	}

	while(1)
		;

}
