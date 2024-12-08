#include "xadc.h"

int16_t xadc_temp10(void) {
    while (xadc_bsy())
        ;
    u16 code = peek16(XADC_TEMP) >> 4;
    float temp = (((float)code * 503.975) / 4096.0) - 273.15;
    int16_t temp10 = (int16_t)(temp * 10.0);
    return temp10;
}
