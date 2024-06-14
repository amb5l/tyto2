#include "printf.h"
#include "bsp.h"
#include "memac_mcs.h"

#define Q(x) #x
#define QUOTE(x) Q(x)

int main() {

    bsp_init();
    led(1);
    //printf(QUOTE(APP_NAME) " application\r\n");
    phy_init();
    printf("PHY ID: %06X %02X %X\r\n", phy_id.oui, phy_id.model, phy_id.rev);
    while(1)
        ;

}
