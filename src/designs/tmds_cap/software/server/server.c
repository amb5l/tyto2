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
#include "sdram.h"
#include "cap.h"
#include "global.h"
#include "csr.h" // debug only
#include "dma.h" // debug only

#include "lwip/tcp.h"
#include "lwip/dhcp.h"
#include "lwip/timeouts.h"
void lwip_init();

#define MAX_UDP_PAYLOAD 1472
#define UDP_PORT_BASE   65400
#define UDP_PORT_RX     (UDP_PORT_BASE+0)
#define UDP_PORT_TX     (UDP_PORT_BASE+1)
#define UDP_PORT_BCAST  (UDP_PORT_BASE+2)

#define BYTES_PER_PIXEL 4
#define MAX_UDP_PIXELS (MAX_UDP_PAYLOAD/BYTES_PER_PIXEL) // 1472 bytes = 368 pixels

const char s_rx_prefix[]  = "tmds_cap";
const char s_rx_cmd_req[] = "req";
const char s_rx_cmd_cap[] = "cap";
const char s_tx_advert[]  = "tmds_cap advert";
const char s_tx_ack[]     = "tmds_cap ack";

ip_addr_t broadcast, client;
struct udp_pcb *udp_pcb_rx, *udp_pcb_tx, *udp_pcb_bcast;
struct pbuf *pkt;
err_t err;

void print_ip(char *msg, ip_addr_t *ip)
{
    print(msg);
    printf("%d.%d.%d.%d\r\n", ip4_addr1(ip), ip4_addr2(ip), ip4_addr3(ip), ip4_addr4(ip));
    fflush(stdout);
}

// broadcast advertisement
void advertise()
{
	u16_t s_tx_advert_len = strlen(s_tx_advert);

    pkt->payload = (void *)s_tx_advert;
    pkt->len = s_tx_advert_len;
    pkt->tot_len = s_tx_advert_len;
    err = ERR_TIMEOUT;
    while (err != ERR_OK)
        err = udp_sendto(udp_pcb_bcast, pkt, &broadcast, UDP_PORT_BCAST);
}

// acknowledge connection request
void acknowledge()
{
	u16_t s_tx_ack_len = strlen(s_tx_ack);

	pkt->payload = (void *)s_tx_ack;
	pkt->len = s_tx_ack_len;
	pkt->tot_len = s_tx_ack_len;
	err = ERR_TIMEOUT;
	while (err != ERR_OK)
		err = udp_sendto(udp_pcb_tx, pkt, &client, UDP_PORT_TX);
}

// handle received UDP packets
void udp_rx(
    void* arg,
    struct udp_pcb* upcb,
    struct pbuf* p,
    const ip_addr_t* addr,
    u16_t port
)
{
    char *s;
    long n;

    s = strtok((char *)p->payload, " ");
    if (!strcmp(s_rx_prefix,s)) {
        s = strtok(NULL, " ");
        // handle client request
        if (!strcmp(s_rx_cmd_req, s)) {
            client.addr = addr->addr;
            acknowledge();
        }
        // handle other commands
        else if (!strcmp(s_rx_cmd_cap, s)) {
            s = strtok(NULL, " ");
            n = strtol(s, (char **)NULL, 10);
            printf("udp_rx: cap: n = %ld\r\n", n);
            cap_start((uint32_t)n);
        }
    }
    else {
        printf("udp_rx: bad prefix (%s)\r\n", s);
    }
    pbuf_free(p);
}

// transfer captured data
void transfer(uint32_t pixels)
{
    int i;

    for (i = 0; i < pixels; i += MAX_UDP_PIXELS) {
        if (pixels-i >= MAX_UDP_PIXELS) {
            pkt->tot_len = pkt->len = BYTES_PER_PIXEL*MAX_UDP_PIXELS;
        } else {
            pkt->tot_len = pkt->len = BYTES_PER_PIXEL*(pixels-i);
        }
        pkt->payload = (void *)&cap_buf[i];
        //printf("transfer: sending %d pixels from offset %d\r\n", pkt->len/BYTES_PER_PIXEL, i);
        err = ERR_TIMEOUT;
        while (err != ERR_OK)
            err = udp_sendto(udp_pcb_tx, pkt, &client, UDP_PORT_TX);
    }
    printf("transfer: done\r\n");
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

// initialise everything
void server_init()
{
    hal_init();
    cap_init();
    Eth0.ip_addr.addr = Eth0.netmask.addr = Eth0.gw.addr = 0;
    lwip_init();
    hal_netif_add(&Eth0, &Eth0.ip_addr, &Eth0.netmask, &Eth0.gw);
    netif_set_default(&Eth0);
    hal_enable_interrupts();
    netif_set_up(&Eth0);

    // UDP setup
    udp_pcb_rx = udp_new();
    udp_bind(udp_pcb_rx, IP_ADDR_ANY, UDP_PORT_RX ) ;
    udp_connect(udp_pcb_rx, IP_ADDR_ANY, UDP_PORT_RX);
    udp_recv(udp_pcb_rx, udp_rx, NULL ) ;
    udp_pcb_tx = udp_new();
    udp_bind(udp_pcb_tx, IP_ADDR_ANY, UDP_PORT_TX ) ;
    udp_connect(udp_pcb_tx, IP_ADDR_ANY, UDP_PORT_TX);
    udp_pcb_bcast = udp_new();
    ip_set_option(udp_pcb_bcast, SOF_BROADCAST);
    udp_bind(udp_pcb_bcast, IP_ADDR_ANY, UDP_PORT_BCAST ) ;
    udp_connect(udp_pcb_bcast, IP_ADDR_ANY, UDP_PORT_BCAST);
    pkt = pbuf_alloc(PBUF_TRANSPORT, MAX_UDP_PAYLOAD, PBUF_RAM);

    client.addr = 0;
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
    broadcast = Eth0.ip_addr;
    broadcast.addr |= ~Eth0.netmask.addr;
    print_ip("Broadcast    : ", (ip_addr_t *)&broadcast.addr);
    printf("\r\n");
}

// foreground loop
void server_run()
{
    uint32_t pixels;

    countdown = 0;
    while (1) {

        hal_netif_rx(&Eth0);
        sys_check_timeouts();

        // advertise once per second
        if (countdown <= 0) {
        	countdown = COUNTDOWN_SEC;
        	advertise();
        }

        // transfer pixels as required
        pixels = cap_rdy();
        if (pixels) { // capture data is ready to transfer
            transfer(pixels);
        }
    }
}
