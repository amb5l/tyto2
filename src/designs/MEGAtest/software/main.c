#include <string.h>

#include "bsp.h"
#include "xadc.h"
#include "cb.h"
#include "hram_test.h"

#define Q(x) #x
#define QUOTE(x) Q(x)

#define CTRL_C 3

int main() {

	u32 tests = 0;
	u32 e = 0;
	u16 t10;

	bsp_init();
	jtag_uart_en = 0;

	cb_set_border(CB_LIGHT_BLUE);

	while (1) {

		jtag_uart_en_tx = 1;
		cb_set_col(CB_YELLOW, CB_BLACK);
		printf("MEGAtest application : board rev %d commit %08X\n\n", bsp_board_rev(), bsp_commit());
		ht_info();
		printf("\n");
		e = ht_init();
		ht_err("initialisation");
		if (e) {
			cb_set_col(CB_WHITE, CB_RED);
			printf("\n HALTED DUE TO BAD ID \n", tests);
			while(1);
		}
		tests = 0;
		e = 0;

		while (1) {

			tests++;
#ifndef BUILD_CFG_DBG
			t10 = xadc_temp10();
#else
			t10 = 0;
#endif
			cb_set_col(CB_YELLOW, CB_BLACK);
			printf("test %d    fail %d    temp %d.%d\n", tests, e, t10 / 10, t10 % 10);
			cb_set_col(CB_GREEN, CB_BLACK);

			e += ht_run(1,0,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,0,0);
			e += ht_run(0,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,0,0);
			ht_err("write then read: sequential address, data = all 1s, single cycles");

			e += ht_run(0,1,0,0,0x800000,0xFFFFFFFF,0,0,0,0,0,0,0,0,0,0);
			ht_err("2nd read: sequential address, data = all 1s, single cycles");

			e += ht_run(1,0,0,0,0x800000,0,0,0,0,0,0,0,0,0,0,0);
			e += ht_run(0,1,0,0,0x800000,0,0,0,0,0,0,0,0,0,0,0);
			ht_err("write then read: sequential address, data = all 0s, single cycles");

			e += ht_run(0,1,0,0,0x800000,0,0,0,0,0,0,0,0,0,0,0);
			ht_err("2nd read: sequential address, data = all 0s, single cycles");

			e += ht_run(1,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0,0);
			ht_err("interleaved write/read: sequential address, data = address");

			e += ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0,8);
			ht_err("2nd read: sequential address, data = address, burst 256");

			e += ht_run(1,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0,0);
			ht_err("interleaved write/read: sequential address, data = inverted address");

			e += ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0,8);
			ht_err("2nd read: sequential address, data = inverted address, burst 256");

			e += ht_run(1,0,0,0,0x800000,0,4,0,0,0,0,1,0,0,1,8);
			e += ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,1,1,1,8);
			ht_err("checkboard masked write (bytes 0,3,4,7");

			e += ht_run(1,0,0,0,0x800000,0,4,0,0,0,0,1,0,1,1,8);
			e += ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,1,8);
			ht_err("checkboard masked write (bytes 1,2,5,6");

			e += ht_run(1,0,0,0,0x800000,0,0,0,1,0,0,0,0,0,1,8);
			e += ht_run(0,1,0,0,0x800000,0,0,0,1,0,0,0,0,0,1,8);
			ht_err("write then read: sequential address, random data, random burst (1..256)");

			e += ht_run(0,1,0,0,0x800000,0,4,0,1,0,0,0,0,0,0,8);
			ht_err("2nd read: sequential address, random data, burst 256");

			e += ht_run(1,0,0,0,0x800000,0,0,0,1,1,0,0,0,0,1,8);
			e += ht_run(0,1,0,0,0x800000,0,0,0,1,1,0,0,0,0,1,8);
			ht_err("write then read: sequential address, inverted random data, random burst (1..256)");

			e += ht_run(0,1,0,0,0x800000,0,4,0,1,1,0,0,0,0,0,8);
			ht_err("2nd read: sequential address, inverted random data, burst 256");

			e += ht_run(1,0,0,0,0x800000,0,4,0,0,0,0,0,0,0,1,8);
			e += ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,1,8);
			ht_err("write then read: sequential address, data = address, random burst (1..256)");

			e += ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0,8);
			ht_err("2nd read: sequential address, data = address, burst 256");

			e += ht_run(1,0,0,0,0x800000,0,4,0,0,1,0,0,0,0,1,8);
			e += ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,1,8);
			ht_err("write then read: sequential address, data = inverted address, random burst (1..256)");

			e += ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0,8);
			ht_err("2nd read: sequential address, data = inverted address, burst 256");

			e += ht_run(1,1,0,0,0x800000,0,0,1,0,0,1,0,0,0,0,0);
			ht_err("interleaved write/read: random address, data = address");

			e += ht_run(0,1,0,0,0x800000,0,4,0,0,0,0,0,0,0,0,8);
			ht_err("2nd read: sequential address, data = address, burst = 256");

			e += ht_run(1,1,0,0,0x800000,0,0,1,0,1,1,0,0,0,0,0);
			ht_err("interleaved write/read: random address, data = inverted address");

			e += ht_run(0,1,0,0,0x800000,0,4,0,0,1,0,0,0,0,0,8);
			ht_err("2nd read: sequential address, data = inverted address, burst = 256");

#if IS_BD(mbv_maxi_j)
			if (!jtag_uart_en) {
				if (e) {
					cb_set_col(CB_WHITE, CB_RED);
					printf("\n HALTED DUE TO ERROR(S) AFTER %d TESTS\n", tests);
					while(1)
						;
				}
				if (bsp_getc_rdy()) {
					while (bsp_getc_rdy()) // drain receive buffer
						if (bsp_getc(0) == '!') {
							jtag_uart_en = 1;
							cb_set_col(CB_WHITE, CB_RED);
							printf("\n\nJTAG UART enabled\n\n");
							break;
						}
				}
				if (jtag_uart_en)
					break;
			}
#else
			if (e) {
				cb_set_col(CB_WHITE, CB_RED);
				printf("\n HALTED DUE TO ERROR(S) AFTER %d TESTS\n", tests);
				while(1)
					;
			}
#endif
		}
	}

}
