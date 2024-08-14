#include <string.h>

#include "bsp.h"
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
	printf("MEGAtest application 9\n\n");

	cb_set_col(CB_GREEN, CB_BLACK);

	if (ht_init()) {
		printf("ht_init: ");
		ht_err();
		while(1)
			;
	}

#if 0
	printf("simple 128kbyte fill then test...");
	r = ht_run(1,0,0,0,0x20000,0x00010000,0x00020002,0,0,0,0,0,0,4);
	// inject deliberate error
	// r = ht_run(1,0,0,0x10000,2,0x0000ABCD,0,0,0,0,0,0,0,0);
	r = ht_run(0,1,0,0,0x20000,0x00010000,0x00020002,0,0,0,0,0,0,4);
	if (r) ht_err(); else printf("OK\n");
#endif

	//while (1) {
	for (u8 x = 0; x < 4; x++) {

#if 0
		printf("fill and test, seq address, all 1s... ");
		r = ht_run(1,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0);
		if (r) ht_err(); else printf("OK\n");
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0);
		if (r) {printf("reread: "); ht_err();} else printf("OK\n");
		errors += r;

		printf("fill and test, seq address, all 0s... ");
		r = ht_run(1,1,0,0,0x800000,0,0,0,0,0,0,0,0,0);
		if (r) ht_err(); else printf("OK\n");
		errors += r;
		r = ht_run(0,1,0,0,0x800000,0,0,0,0,0,0,0,0,0);
		if (r) {printf("reread: "); ht_err();} else printf("OK\n");
		errors += r;
#endif

		printf("fill and test, seq address, seq data, normal... ");
		r = ht_run(1,1,0,0x550000,0x2200,0x00010000,0x00020002,0,0,0,0,0,0,0);
		if (r) ht_err(); else printf("OK\n");
		errors += r;
		r = ht_run(0,1,0,0x550000,0x2200,0x00010000,0x00020002,0,0,0,0,0,0,0);
		if (r) {printf("reread: "); ht_err();} else printf("OK\n");
		errors += r;

		printf("fill and test, seq address, seq data, inverse... ");
		//r = ht_run(1,1,0,0,0x800000,0xFFFEFFFF,0xFFFEFFFE,0,0,0,0,0,0,0);
		r = ht_run(1,1,0,0x550000,0x2200,0xFFFEFFFF,0xFFFEFFFE,0,0,0,0,0,0,0);
		if (r) ht_err(); else printf("OK\n");
		errors += r;
		//r = ht_run(0,1,0,0,0x800000,0xFFFEFFFF,0xFFFEFFFE,0,0,0,0,0,0,0);
		r = ht_run(0,1,0,0x550000,0x2200,0xFFFEFFFF,0xFFFEFFFE,0,0,0,0,0,0,0);
		if (r) {printf("reread: "); ht_err();} else printf("OK\n");
		errors += r;

#if 0
		printf("full fill then test:\n");

		printf(" sequential address, incrementing data, random burst (2)...");
		r = ht_run(1,0,0,0,0x10000,0x00010000,0x00020002,0,0,0,0,0,1,0);
		r = ht_run(0,1,0,0,0x10000,0x00010000,0x00020002,0,0,0,0,0,1,0);
		if (r) {printf("read 1: "); ht_err();} else printf("OK\n");
		errors += r;
		r = ht_run(0,1,0,0,0x10000,0x00010000,0x00020002,0,0,0,0,0,0,1);
		if (r) {printf("read 2: "); ht_err();} else printf("OK\n");
		errors += r;

		printf(" sequential address, inverse incrementing data, random burst (2)...");
		r = ht_run(1,0,0,0,0x10000,0xFFFEFFFF,0xFFFEFFFE,0,0,0,0,0,1,0);
		r = ht_run(0,1,0,0,0x10000,0xFFFEFFFF,0xFFFEFFFE,0,0,0,0,0,1,0);
		if (r) {printf("read 1: "); ht_err();} else printf("OK\n");
		errors += r;
		r = ht_run(0,1,0,0,0x10000,0xFFFEFFFF,0xFFFEFFFE,0,0,0,0,0,0,1);
		if (r) {printf("read 2: "); ht_err();} else printf("OK\n");
		errors += r;
#endif

#if 0
		printf(" sequential address, random data, fixed burst (256)...");
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,0,0,0,0,8);
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,0,0,8);
		if (r) ht_err(); else printf("OK\n");
		errors += r;

		printf(" sequential address, incrementing data, random burst (1..256)...");
		r = ht_run(1,0,0,0,0x800000,0,4,0,0,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,1,8);
		if (r) ht_err(); else printf("OK\n");
		errors += r;

		printf(" sequential address, random data, random burst (1..256)...");
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,0,0,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,0,1,8);
		if (r) ht_err(); else printf("OK\n");
		errors += r;

		printf(" sequential address, random data, random burst (1..256), checkerboard...");
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,0,0,0,1,8);
		r = ht_run(1,0,0,0,0x800000,0,0,0,1,1,1,0,1,8);
		r = ht_run(0,1,0,0,0x800000,0,0,0,1,0,1,0,1,8);
		if (r) ht_err(); else printf("OK\n");
		errors += r;

		printf(" random address, random data...");
		r = ht_run(1,0,0,0,0x800000,0,0,1,1,0,0,0,0,0);
		r = ht_run(0,1,0,0,0x800000,0,0,1,1,0,0,0,0,0);
		if (r) ht_err(); else printf("OK\n");
		errors += r;

#endif

#if 0

		printf("full fill and test (interleaved write/read):\n");

		printf(" sequential address, incrementing data...");
		r = ht_run(1,1,0,0,0x800000,0,4,0,0,0,0,0,0,0);
		if (r) ht_err(); else printf("OK\n");
		errors += r;

		printf(" random address, random data... ");
		r = ht_run(1,1,0,0,0x800000,0,0,1,1,0,0,0,0,0);
		if (r) ht_err(); else printf("OK\n");
		errors += r;

#endif

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
