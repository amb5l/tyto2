/*******************************************************************************
** server.c                                                                   **
** tmds_cap server - wrappers for main functionality.                         **
********************************************************************************
** (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        **
** This file is part of The Tyto Project. The Tyto Project is free software:  **
** you can redistribute it and/or modify it under the terms of the GNU Lesser **
** General Public License as published by the Free Software Foundation,       **
** either version 3 of the License, or (at your option) any later version.    **
** The Tyto Project is distributed in the hope that it will be useful, but    **
** WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY **
** or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     **
** License for more details. You should have received a copy of the GNU       **
** Lesser General Public License along with The Tyto Project. If not, see     **
** https://www.gnu.org/licenses/.                                             **
*******************************************************************************/

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "sleep.h"

#include "hal.h"
#include "csr.h"
#include "sdram.h"
#include "cap.h"

#include "lwip/tcp.h"
#include "lwip/dhcp.h"
#include "lwip/timeouts.h"
void lwip_init();

#define MAX_UDP_PAYLOAD 1024
#define UDP_PORT_BASE   65400
#define UDP_PORT_RX     (UDP_PORT_BASE+0)
#define UDP_PORT_TX     (UDP_PORT_BASE+1)
#define UDP_PORT_BCAST  (UDP_PORT_BASE+2)

char *msg_advert = "tmds_cap server advertisement";
char *msg_req = "tmds_cap client req";
char *msg_ack = "tmds_cap server ack";

#define PIXELS 2048

struct netif Eth0;
ip_addr_t client;
volatile int countdown;

void print_ip(char *msg, ip_addr_t *ip)
{
	print(msg);
	printf("%d.%d.%d.%d\r\n", ip4_addr1(ip), ip4_addr2(ip), ip4_addr3(ip), ip4_addr4(ip));
	fflush(stdout);
}

void udp_rx(
	void* arg,            
    struct udp_pcb* upcb, 
	struct pbuf* p,       
	const ip_addr_t* addr,
	u16_t port			  
)
{
	if (!strcmp(msg_req, p->payload)) {
		client.addr = addr->addr;
	}
	pbuf_free(p);
}

// banner message
void server_banner()
{
	printf("\r\n");
	printf("-------------------------------------------------------------------------------\r\n");
	printf("tmds_cap\r\n");
	printf("-------------------------------------------------------------------------------\r\n");
	printf("\r\n");
}

// initialise everything required to bring the ethernet interface up
void server_init()
{
    hal_init();   
    Eth0.ip_addr.addr = Eth0.netmask.addr = Eth0.gw.addr = 0;
	lwip_init();
    hal_netif_add(&Eth0, &Eth0.ip_addr, &Eth0.netmask, &Eth0.gw);
	netif_set_default(&Eth0);
    hal_enable_interrupts();
	netif_set_up(&Eth0);
}

// establish IP address
void server_dhcp()
{
	printf("\r\nDHCP: starting... ");
	fflush(stdout);
	dhcp_start(&Eth0);
	countdown = COUNTDOWN_SEC * 30; // 30 seconds
	while((Eth0.ip_addr.addr == 0) && (countdown > 0)) {
		hal_netif_rx(&Eth0);
		sys_check_timeouts();
	}
	if (countdown <= 0) {
		if ((Eth0.ip_addr.addr) == 0) {
			printf("timeout - configuring defaults\r\n");
			IP4_ADDR(&Eth0.ip_addr, 192, 168,   1, 123);
			IP4_ADDR(&Eth0.netmask, 255, 255, 255,   0);
			IP4_ADDR(&Eth0.gw,      192, 168,   1,   1);
		}
	}
	else {
		printf("done\r\n");
	}

    // display IPv4 setup
	print_ip("IPv4 address : ", (ip_addr_t *)&Eth0.ip_addr.addr);
	print_ip("Subnet Mask  : ", (ip_addr_t *)&Eth0.netmask.addr);
	print_ip("Gateway      : ", (ip_addr_t *)&Eth0.gw.addr);
	ip_addr_t broadcast = Eth0.ip_addr;
	broadcast.addr |= ~Eth0.netmask.addr;
	print_ip("Broadcast    : ", (ip_addr_t *)&broadcast.addr);
	printf("\r\n");
}

// advertise and wait for client connection
void server_conn()
{
	struct udp_pcb *udp_pcb_rx, *udp_pcb_tx, *udp_pcb_bcast;
    struct pbuf *p = pbuf_alloc(PBUF_TRANSPORT, MAX_UDP_PAYLOAD, PBUF_RAM);
    err_t err;

    u16_t msg_advert_len = strlen(msg_advert);
    u16_t msg_ack_len = strlen(msg_ack);

	// UDP RX setup
	udp_pcb_rx = udp_new();
    udp_bind(udp_pcb_rx, IP_ADDR_ANY, UDP_PORT_RX ) ;
    udp_connect(udp_pcb_rx, IP_ADDR_ANY, UDP_PORT_RX);
    udp_recv(udp_pcb_rx, udp_rx, NULL ) ;

	// UDP TX setup
	udp_pcb_tx = udp_new();
    udp_bind(udp_pcb_tx, IP_ADDR_ANY, UDP_PORT_TX ) ;
    udp_connect(udp_pcb_tx, IP_ADDR_ANY, UDP_PORT_TX);
    udp_recv(udp_pcb_tx, udp_rx, NULL ) ;

    // UDP broadcast setup
    udp_pcb_bcast = udp_new();
    ip_set_option(udp_pcb_bcast, SOF_BROADCAST);
    udp_bind(udp_pcb_bcast, IP_ADDR_ANY, UDP_PORT_BCAST ) ;
    udp_connect(udp_pcb_bcast, IP_ADDR_ANY, UDP_PORT_BCAST);

    // broadcast advertisements until client requests connection
    printf("advertising... ");
    fflush(stdout);
    client.addr = 0;
    p->payload = msg_advert;
    p->len = msg_advert_len;
    p->tot_len = msg_advert_len;
    while (client.addr == 0) {
    	err = ERR_TIMEOUT;
    	while (err != ERR_OK)
    		err = udp_sendto(udp_pcb_bcast, p, &broadcast, UDP_PORT_BCAST);
    	countdown = COUNTDOWN_SEC;
    	while (countdown > 0 && client.addr == 0) {
    		hal_netif_rx(&Eth0);
    		sys_check_timeouts();
    	}
    }
    printf("client request received... ");
    fflush(stdout);

    // acknowledge connection request
    p->payload = msg_ack;
    p->len = msg_ack_len;
    p->tot_len = msg_ack_len;
	err = ERR_TIMEOUT;
	while (err != ERR_OK)
		err = udp_sendto(udp_pcb_tx, p, &client, UDP_PORT_TX);
    printf("client request acknowledged!\r\n");
}

// foreground loop
void server_run()
{
	while (1) {
		hal_netif_rx(&Eth0);
		sys_check_timeouts();
	}
}

#if 0
    cap_init();

    btn_init = CSR_PEEK(RA_GPI) & 1;
    printf("btn_init = %d\r\n", btn_init);
    btn_init = CSR_PEEK(RA_GPI) & 1;
    printf("btn_init = %d\r\n", btn_init);
    // wait for button 0
    CSR_POKE( RA_GPO, 0 );
    while(1) {
    	r = CSR_PEEK(RA_GPI) & 1;
    	printf("r = %d", r);
    	if (btn_init == r)
    		printf("button not yet pressed, r = %d\r\n", r);
    	else {
    		printf("button pressed! r = %d\r\n", r);
    		break;
    	}
    	usleep(1000000);
    	fflush(stdout);
    }
    led = 15;
    CSR_POKE( RA_GPO, led );

    while(1) {
    	usleep(1000000);
 		printf("\r\n");
 		printf("SDRAM fill (base = %08X)\r\n", SDRAM_BASEADDR);
        sdram_fill(SDRAM_BASEADDR, PIXELS, 0xFFFFFFFF, 0xFFFFFFFF);
 		printf("SDRAM test\r\n");
        sdram_test(SDRAM_BASEADDR, PIXELS, 0xFFFFFFFF, 0xFFFFFFFF);
        *(uint32_t *)SDRAM_BASEADDR = 0xDEADBEEF;
 		printf("capture\r\n");
        cap_wait(SDRAM_BASEADDR, PIXELS);
 		printf("SDRAM test\r\n");
        sdram_test(SDRAM_BASEADDR, PIXELS, 0xFFFFFFFF, 0xFFFFFFFF);
/*

    	uint32_t r;
    	uint8_t led;
    	uint32_t btn_init;

 		printf("SDRAM fill (base = %08X)\r\n", SDRAM_BASEADDR);
        sdram_fill(0x10000000, 0x11000000, 0x31415926, 0x27182817);
 		printf("SDRAM test\r\n");
        sdram_test(0x10000000, 0x11000000, 0x31415926, 0x27182817);
 		printf("\r\n");
        r = CSR_PEEK( RA_SIGNATURE ); printf("  SIGNATURE    : %08X\r\n", r);
        r = CSR_PEEK( RA_FREQ      ); printf("  FREQ         : %08X (%.2f MHz)\r\n", r, r/100.0);
        r = CSR_PEEK( RA_ASTAT     ); printf("  ASTAT        : %08X\r\n", r);
                                      printf("                 SKEW2 = %d, SKEW1 = %d\r\n", (r>>10)&3, (r>>8)&3);
                                      printf("                 ALIGNP = %d, ALIGNS2 = %d, ALIGNS1 = %d, ALIGNS0 = %d\r\n", (r>>7)&1, (r>>6)&1, (r>>5)&1, (r>>4)&1);
                                      printf("                 BAND = %d, LOCK = %d\r\n", (r>>1)&3, r&1);
        r = CSR_PEEK( RA_ATAPMASK0 ); printf("  ATAPMASK0    : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPMASK1 ); printf("  ATAPMASK1    : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPMASK2 ); printf("  ATAPMASK2    : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAP      ); printf("  ATAP         : %08X (%d,%d,%d)\r\n", r, (r>>16)&31, (r>>8)&31, r&31);
        r = CSR_PEEK( RA_ABITSLIP  ); printf("  ABITSLIP     : %08X (%d,%d,%d)\r\n", r, (r>>8)&15, (r>>4)&15, r&15);
        r = CSR_PEEK( RA_ACYCLE0   ); printf("  ACYCLE0      : %08X\r\n", r);
        r = CSR_PEEK( RA_ACYCLE1   ); printf("  ACYCLE1      : %08X\r\n", r);
        r = CSR_PEEK( RA_ACYCLE2   ); printf("  ACYCLE2      : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPOK0   ); printf("  ATAPOK0      : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPOK1   ); printf("  ATAPOK1      : %08X\r\n", r);
        r = CSR_PEEK( RA_ATAPOK2   ); printf("  ATAPOK2      : %08X\r\n", r);
        r = CSR_PEEK( RA_AGAIN0    ); printf("  AGAIN0       : %08X\r\n", r);
        r = CSR_PEEK( RA_AGAIN1    ); printf("  AGAIN1       : %08X\r\n", r);
        r = CSR_PEEK( RA_AGAIN2    ); printf("  AGAIN2       : %08X\r\n", r);
        r = CSR_PEEK( RA_AGAINP    ); printf("  AGAINP       : %08X\r\n", r);
        r = CSR_PEEK( RA_ALOSS0    ); printf("  ALOSS0       : %08X\r\n", r);
        r = CSR_PEEK( RA_ALOSS1    ); printf("  ALOSS1       : %08X\r\n", r);
        r = CSR_PEEK( RA_ALOSS2    ); printf("  ALOSS2       : %08X\r\n", r);
        r = CSR_PEEK( RA_ALOSSP    ); printf("  ALOSSP       : %08X\r\n", r);
        r = CSR_PEEK( RA_CAPCTRL   ); printf("  CAPCTRL      : %08X\r\n", r);
        r = CSR_PEEK( RA_CAPSIZE   ); printf("  CAPSIZE      : %08X\r\n", r);
        r = CSR_PEEK( RA_CAPSTAT   ); printf("  CAPSTAT      : %08X\r\n", r);
        r = CSR_PEEK( RA_CAPCOUNT  ); printf("  CAPCOUNT     : %08X\r\n", r);
        r = CSR_PEEK( RA_SCRATCH   ); printf("  SCRATCH      : %08X\r\n", r);
*/
        CSR_POKE( RA_GPO, led );
        led = (led-1) & 0xF;
    }
}

#endif