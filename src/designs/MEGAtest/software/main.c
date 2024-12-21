#include <string.h>

#include "bsp.h"
#include "xadc.h"
#include "cb.h"
#include "hram_test.h"

#define Q(x) #x
#define QUOTE(x) Q(x)

#define CTRL_C 3

int main() {

	u8 r;
	u32 tests = 0;
	u32 errors = 0;
	u16 t10;

	bsp_init();
	cb_set_border(CB_LIGHT_BLUE);

	cb_set_col(CB_YELLOW, CB_BLACK);
	printf("MEGAtest application : board rev %d commit %08X\n\n", bsp_board_rev(), bsp_commit());
	cb_set_col(CB_GREEN, CB_BLACK);
	r = ht_init();
	printf("ht_init: ");
	ht_err(r);
	printf("\n\n");
	if (r) {
		cb_set_col(CB_WHITE, CB_RED);
		printf("\n HALTED DUE TO BAD ID \n", tests);
		while(1)
			;
	}

	while (errors == 0) {

		tests++;
		t10 = xadc_temp10();
		cb_set_col(CB_YELLOW, CB_BLACK);
		printf("MEGAtest application : board rev %d  commit %08X  temperature %d.%d  test %d\n\n",
			bsp_board_rev(), bsp_commit(), t10 / 10, t10 % 10, tests
		);
		ht_info();
		printf("\n");
		cb_set_col(CB_GREEN, CB_BLACK);

		printf("write then read: sequential address, data = all 1s, single cycles................................................... ");
		r = ht_run(1,0,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,0,0);
		r = ht_run(0,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,0,0);
		errors += ht_err(r);

		printf("read: sequential address, data = all 1s, single cycles.............................................................. ");
		r = ht_run(0,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,0,0);
		errors += ht_err(r);

		printf("write then read: sequential address, data = all 0s, single cycles................................................... ");
		r = ht_run(1,0,0,0,0x800000,0,0,0,0,0,0,0,0,0,0,0);
		r = ht_run(0,1,0,0,0x800000,0,0,0,0,0,0,0,0,0,0,0);
		errors += ht_err(r);

		printf("read: sequential address, data = all 0s, single cycles.............................................................. ");
		r = ht_run(0,1,0,0,0x800000,0,0,0,0,0,0,0,0,0,0,0);
		errors += ht_err(r);

		printf("interleaved write/read: sequential address, data = address.......................................................... ");
		r = ht_run(1,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0,0);
		errors += ht_err(r);

		printf("read: sequential address, data = address, burst 256................................................................. ");
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0,8);
		errors += ht_err(r);

		printf("interleaved write/read: sequential address, data = inverted address................................................. ");
		r = ht_run(1,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0,0);
		errors += ht_err(r);

		printf("read: sequential address, data = inverted address, burst 256........................................................ ");
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0,8);
		errors += ht_err(r);

		printf("checkboard masked write (bytes 0,3,4,7...) then verify: sequential address, data = address, random burst (1..256)... ");
		r = ht_run(1,0,0,0,0x800000,0,4,0,0,0,0,1,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,1,1,1,8);
		errors += ht_err(r);

		printf("checkboard masked write (bytes 1,2,5,6...) then verify: sequential address, data = address, random burst (1..256)... ");
		r = ht_run(1,0,0,0,0x800000,0,4,0,0,0,0,1,0,1,1,8);
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,1,8);
		errors += ht_err(r);

		printf("write then read: sequential address, random data, random burst (1..256)............................................. ");
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,0,0,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,0,0,0,1,8);
		errors += ht_err(r);

		printf("read: sequential address, random data, burst 256.................................................................... ");
		r = ht_run(0,1,0,0,0x800000,0,4,0,1,0,0,0,0,0,0,8);
		errors += ht_err(r);

		printf("write then read: sequential address, inverted random data, random burst (1..256).................................... ");
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,1,0,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,1,0,0,0,0,1,8);
		errors += ht_err(r);

		printf("read: sequential address, inverted random data, burst 256........................................................... ");
		r = ht_run(0,1,0,0,0x800000,0,4,0,1,1,0,0,0,0,0,8);
		errors += ht_err(r);

		printf("write then read: sequential address, data = address, random burst (1..256).......................................... ");
		r = ht_run(1,0,0,0,0x800000,0,4,0,0,0,0,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,1,8);
		errors += ht_err(r);

		printf("read: sequential address, data = address, burst 256................................................................. ");
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0,8);
		errors += ht_err(r);

		printf("write then read: sequential address, data = inverted address, random burst (1..256)................................. ");
		r = ht_run(1,0,0,0,0x800000,0,4,0,0,1,0,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,1,8);
		errors += ht_err(r);

		printf("read: sequential address, data = inverted address, burst 256........................................................ ");
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0,8);
		errors += ht_err(r);

		printf("interleaved write/read: random address, data = address, read burst = 8.............................................. ");
		r = ht_run(1,1,0,0,0x800000,0,0,1,0,0,1,0,0,0,0,3);
		errors += ht_err(r);

		printf("read: sequential address, data = address, burst = 256............................................................... ");
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0,8);
		errors += ht_err(r);

		printf("interleaved write/read: random address, data = inverted address, read burst = 8..................................... ");
		r = ht_run(1,1,0,0,0x800000,0,0,1,0,1,1,0,0,0,0,3);
		errors += ht_err(r);

		printf("read: sequential address, data = inverted address, burst = 256...................................................... ");
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0,8);
		errors += ht_err(r);

		printf("\n");
	}

	cb_set_col(CB_WHITE, CB_RED);
	printf(" HALTED DUE TO ERROR AFTER %d TESTS ", tests);
	while(1)
		;
}
