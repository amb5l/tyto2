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
	u8 rb_mag = 1;
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

	while (1) {

		cb_set_col(CB_YELLOW, CB_BLACK);
		printf("MEGAtest application : board rev %d commit %08X\n", bsp_board_rev(), bsp_commit());
		cb_set_col(CB_WHITE, CB_RED);
		printf("\n tests: %d   errors: %d \n\n", tests, errors);
		tests++;
		ht_info();
		cb_set_col(CB_WHITE, CB_BLACK);
		t10 = xadc_temp10();
		printf("temperature = %d.%d\n\n", t10 / 10, t10 % 10);
		cb_set_col(CB_GREEN, CB_BLACK);

		printf("fill and test, sequential address, all 1s... ");
		r = ht_run(1,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,rb_mag);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, sequential address, all 0s... ");
		r = ht_run(1,1,0,0,0x800000,0,0,0,0,0,0,0,0,0,rb_mag);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,0,0,0,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, sequential address, incrementing 16-bit data... ");
		r = ht_run(1,1,0,0,0x800000,0x00010000,0x00020002,0,0,0,0,0,0,0,rb_mag);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0x00010000,0x00020002,0,0,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, sequential address, incrementing 16-bit data (inverted)... ");
		r = ht_run(1,1,0,0,0x800000,0x00010000,0x00020002,0,0,1,0,0,0,0,rb_mag);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0x00010000,0x00020002,0,0,1,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill then test, sequential address, incrementing 16-bit data, random burst (1..256)...");
		r = ht_run(1,0,0,0,0x800000,0x00010000,0x00020002,0,0,0,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0x00010000,0x00020002,0,0,0,0,0,0,1,8);
		printf("read 1: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0x00010000,0x00020002,0,0,0,0,0,0,0,8);
		printf("read 2: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill then test, sequential address, incrementing 16-bit data (inverted), random burst (1..256)...");
		r = ht_run(1,0,0,0,0x800000,0x00010000,0x00020002,0,0,1,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0x00010000,0x00020002,0,0,1,0,0,0,1,8);
		printf("read 1: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0x00010000,0x00020002,0,0,1,0,0,0,0,8);
		printf("read 2: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill then test, sequential address, random data, fixed burst (256)...");
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,0,0,0,0,0,8);
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,0,0,0,8);
		printf("read 1: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,0,0,0,8);
		printf("read 2: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill then test, sequential address, data = address, random burst (1..256)...");
		r = ht_run(1,0,0,0,0x800000,0,4,0,0,0,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,1,8);
		printf("read 1: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,1,8);
		printf("read 2: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill then test, sequential address, random data, random burst (1..256)...");
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,0,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,0,0,1,8);
		printf("read 1: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,0,0,1,8);
		printf("read 2: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill then test, sequential address, random data, random burst (1..256), checkerboard...");
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,0,0,0,0,1,8);
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,0,1,1,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,1,0,1,8);
		printf("read 1: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,1,0,1,8);
		printf("read 2: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill then test, random address, random data...");
		r = ht_run(1,0,0,0,0x800000,0,0,1,1,0,0,0,0,0,0);
		r = ht_run(0,1,0,0,0x800000,0,0,1,1,0,0,0,0,0,0);
		printf("read 1: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,0,1,1,0,0,0,0,0,0);
		printf("read 2: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, sequential address, data = address...");
		r = ht_run(1,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,rb_mag);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, sequential address, data = address (inverted)...");
		r = ht_run(1,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,rb_mag);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, random address, random data... (rb_mag = %d) ", rb_mag);
		r = ht_run(1,1,0,0,0x800000,0,0,1,1,0,0,0,0,0,rb_mag);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,0,1,1,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");
	}
}
