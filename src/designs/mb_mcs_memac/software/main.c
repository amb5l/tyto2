#include "printf.h"
#include "bsp.h"
#include "memac_mcs.h"

#define Q(x) #x
#define QUOTE(x) Q(x)

int main() {

    printf(QUOTE(APP_NAME) " application\r\n");
    bsp_init();
    phy_init();
    printf("PHY ID: %06X %02X %X\r\n", phy_id.oui, phy_id.model, phy_id.rev);
    while(1)
        ;

}
