#include "xadc.h"

int16_t xadc_temp10(void) {
    while (xadc_bsy())
        ;
    u16 code = peek16(XADC_TEMP);
    float temp = ((code * 503.975) / 4096) - 273.15;
    int16_t temp10 = (int16_t)(temp * 10.0);
    return temp10;
}
