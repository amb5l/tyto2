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

	bsp_init();

	cb_set_border(CB_LIGHT_BLUE);

	cb_set_col(CB_YELLOW, CB_BLACK);
	printf("MEGAtest application : board rev %d commit %08X\n\n", bsp_board_rev(), bsp_commit());

	cb_set_col(CB_GREEN, CB_BLACK);

	r = ht_init();
	printf("ht_init: ");
	ht_err(1);

	printf("simple 128kbyte fill then test...");
	r = ht_run(1,0,0,0,0x20000,0x00010000,0x00020002,0,0,0,0,0,0,0,4);
	r = ht_run(0,1,0,0,0x20000,0x00010000,0x00020002,0,0,0,0,0,0,0,4);
	printf("read 1: "); ht_err(r);
	r = ht_run(0,1,0,0,0x20000,0x00010000,0x00020002,0,0,0,0,0,0,0,4);
	printf("read 2: "); ht_err(r);

	while (errors == 0) {

		printf("temperature x 10 = %d\n", xadc_temp10());

		printf("fill and test, sequential address, all 1s... ");
		r = ht_run(1,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,0);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, sequential address, all 0s... ");
		r = ht_run(1,1,0,0,0x800000,0,0,0,0,0,0,0,0,0,0);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,0,0,0,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, sequential address, incrementing data... ");
		r = ht_run(1,1,0,0x550000,0x2200,0x00010000,0x00020002,0,0,0,0,0,0,0,0);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0x550000,0x2200,0x00010000,0x00020002,0,0,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, sequential address, incrementing data (inverted)... ");
		r = ht_run(1,1,0,0,0x800000,0x00010000,0x00020002,0,0,1,0,0,0,0,0);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0x00010000,0x00020002,0,0,1,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill then test, sequential address, incrementing data, random burst (1..256)...");
		r = ht_run(1,0,0,0,0x10000,0x00010000,0x00020002,0,0,0,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x10000,0x00010000,0x00020002,0,0,0,0,0,0,1,8);
		printf("read 1: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x10000,0x00010000,0x00020002,0,0,0,0,0,0,0,8);
		printf("read 2: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill then test, sequential address, incrementing data (inverted), random burst (1..256)...");
		r = ht_run(1,0,0,0,0x10000,0x00010000,0x00020002,0,0,1,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x10000,0x00010000,0x00020002,0,0,1,0,0,0,1,8);
		printf("read 1: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x10000,0x00010000,0x00020002,0,0,1,0,0,0,0,8);
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

		printf("fill then test, sequential address, incrementing data, random burst (1..256)...");
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

		printf("fill and test, sequential address, incrementing data...");
		r = ht_run(1,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, sequential address, incrementing data (inverted)...");
		r = ht_run(1,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("fill and test, random address, random data... ");
		r = ht_run(1,1,0,0,0x800000,0,0,1,1,0,0,0,0,0,0);
		printf("concurrent read: "); ht_err(r);
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,0,1,1,0,0,0,0,0,0);
		printf("follow on read: "); ht_err(r);
		errors += r;
		printf("\n");

		printf("\n");
		cb_set_col(CB_WHITE, CB_RED);
		tests++;
		printf(" tests: %d   errors: %d ", tests, errors);
		cb_set_col(CB_GREEN, CB_BLACK);
		printf("\n");

	}

	while (1)
		;

}
