#include "bsp.h"
#include "printf.h"
#include "memac_mcs.h"

#define Q(x) #x
#define QUOTE(x) Q(x)

#define CTRL_C 3

int main() {

    bsp_init();
    led(7);
#ifndef BUILD_CONFIG_DBG
    printf(QUOTE(APP_NAME) " application\r\n");
#endif
    phy_init();
    printf("PHY ID: %06X %02X %X\r\n", phy_id.oui, phy_id.model, phy_id.rev);

    while(1) {
        putchar(CTRL_C);
    }
}
