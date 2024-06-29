#include "bsp.h"
#include "printf.h"

#define Q(x) #x
#define QUOTE(x) Q(x)

#define CTRL_C 3

int main() {

    bsp_init();

    printf(QUOTE(APP_NAME) " application\r\n");

    while(1) {
#ifdef BUILD_CONFIG_DBG
        putchar(CTRL_C); // simulator sees this and stops running
#endif
    }

}
