// hal.c

#include "hal.h"

#include "xparameters.h"
#include "xtime_l.h"
#include "xil_cache.h"
#include "xscutimer.h"
#include "xscugic.h"

#include "netif/xadapter.h"

#include "lwip/dhcp.h"
#include "lwip/timeouts.h"

#include "global.h"

#define ISR_COUNT_LINK_DET    (LINK_DET_INTERVAL_MSECS/SCUTIMER_INTERVAL_MSECS)
#define ISR_COUNT_DHCP_FINE   (SCUTIMER_INTERVAL_MSECS/DHCP_FINE_TIMER_MSECS)
#define ISR_COUNT_DHCP_COARSE (SCUTIMER_INTERVAL_MSECS/DHCP_COARSE_TIMER_MSECS)

static XScuTimer XScuTimer0;
unsigned char mac_addr[] = { 0x00, 0x0a, 0x35, 0x00, 0x01, 0x02 };

void isr_timer(XScuTimer *pXScuTimer)
{
    static int counter_link_det = 0;
    static int counter_dhcp_fine = 0;
    static int counter_dhcp_coarse = 0;

    counter_link_det++;
    if (counter_link_det == ISR_COUNT_LINK_DET) {
        counter_link_det = 0;
        eth_link_detect(&Eth0);
    }
    counter_dhcp_fine++;
    if (counter_dhcp_fine == ISR_COUNT_DHCP_FINE) {
        counter_dhcp_fine = 0;
        dhcp_fine_tmr();
    }
    counter_dhcp_coarse++;
    if (counter_dhcp_coarse == ISR_COUNT_DHCP_COARSE) {
        counter_dhcp_coarse = 0;
        dhcp_coarse_tmr();
    }
    countdown--;
    XScuTimer_ClearInterruptStatus(pXScuTimer);
}

void hal_init(void)
{
    //Xil_DCacheDisable();

    // setup timer
    XScuTimer_Config *pXScuTimer_Config;
    pXScuTimer_Config = XScuTimer_LookupConfig(XPAR_SCUTIMER_DEVICE_ID);
    XScuTimer_CfgInitialize(
        &XScuTimer0,
        pXScuTimer_Config,
        pXScuTimer_Config->BaseAddr
    );
    XScuTimer_EnableAutoReload(&XScuTimer0);
    XScuTimer_LoadTimer(&XScuTimer0, SCUTIMER_LOAD_VAL);

    // setup interrupts
    Xil_ExceptionInit();
    XScuGic_DeviceInitialize(XPAR_SCUGIC_SINGLE_DEVICE_ID);
    Xil_ExceptionRegisterHandler(
        XIL_EXCEPTION_ID_IRQ_INT,
        (Xil_ExceptionHandler)XScuGic_DeviceInterruptHandler,
        (void *)XPAR_SCUGIC_SINGLE_DEVICE_ID
    );
    XScuGic_RegisterHandler(
        XPAR_SCUGIC_0_CPU_BASEADDR,
        XPAR_SCUTIMER_INTR,
        (Xil_ExceptionHandler)isr_timer,
        (void *)&XScuTimer0
    );
    XScuGic_EnableIntr(XPAR_SCUGIC_0_DIST_BASEADDR, XPAR_SCUTIMER_INTR);
}

void hal_enable_interrupts(void)
{
    Xil_ExceptionEnableMask(XIL_EXCEPTION_IRQ);
    XScuTimer_EnableInterrupt(&XScuTimer0);
    XScuTimer_Start(&XScuTimer0);
}

struct netif * hal_netif_add(
    struct netif *netif,
    ip_addr_t *ipaddr,
    ip_addr_t *netmask,
    ip_addr_t *gateway
)
{
    return xemac_add(
        netif,
        ipaddr,
        netmask,
        gateway,
        mac_addr,
        XPAR_XEMACPS_0_BASEADDR
    );
}

void hal_netif_rx(struct netif *netif)
{
    xemacif_input(netif);
}

u32_t sys_now(void)
{
    XTime tick;
    u64 time;
    XTime_GetTime(&tick);
    time = tick/(COUNTS_PER_SECOND / 1000);
    return time;
}
