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

#define BYTES_PER_PIXEL 4

#define UDP_MAX_PAYLOAD 1472
#define UDP_PORT        65400

#define TCP_MAX_PAYLOAD 1460
#define TCP_PORT        65401

const char s_disco[]      = "tmds_cap disco";
const char s_cmd_prefix[] = "tmds_cap";
const char s_cmd_get[]    = "get";

ip_addr_t broadcast;
struct udp_pcb *udp_pcb_bcast;
struct pbuf *udp_pbuf;

struct tcp_pcb *tcp_pcb_listen;
struct tcp_pcb *tcp_pcb_tx;

void print_ip(char *msg, ip_addr_t *ip)
{
    print(msg);
    printf("%d.%d.%d.%d\r\n", ip4_addr1(ip), ip4_addr2(ip), ip4_addr3(ip), ip4_addr4(ip));
    fflush(stdout);
}

// broadcast advertisement (UDP)
void advertise(const char *s)
{
    u16_t l = strlen(s);

    udp_pbuf->payload = (void *)s;
    udp_pbuf->len = l;
    udp_pbuf->tot_len = l;
    while (udp_sendto(udp_pcb_bcast, udp_pbuf, &broadcast, UDP_PORT) != ERR_OK);
}

void server_tcp_close(struct tcp_pcb *pcb)
{
  tcp_arg(pcb, NULL);
  tcp_sent(pcb, NULL);
  tcp_recv(pcb, NULL);
  tcp_err(pcb, NULL);
  tcp_poll(pcb, NULL, 0);
  tcp_close(pcb);
}

err_t server_tcp_recv(void *arg, struct tcp_pcb *pcb, struct pbuf *p, err_t err)
{
    char *s;
    long n;

    if (p) {
        s = strtok((char *)p->payload, " ");
        if (!strcmp(s_cmd_prefix,s)) {
            s = strtok(NULL, " ");
            if (!strcmp(s_cmd_get, s)) {
                s = strtok(NULL, " ");
                n = strtol(s, (char **)NULL, 10);
                printf("client requested %ld pixels\r\n", n);
                tcp_pcb_tx = pcb;
                cap_start((uint32_t)n);
            } else {
                printf("received unknown command from client (%s)\r\n", s);
            }
        } else {
            printf("received bad prefix from client (%s)\r\n", s);
        }
        tcp_recved(pcb, p->tot_len);
        pbuf_free(p);
    }
    else {
        // no pbuf?
        printf("TCP connection closed\r\n");
        server_tcp_close(pcb);
    }
    return ERR_OK;
}

err_t server_tcp_sent(void *arg, struct tcp_pcb *pcb, u16_t len)
{
	// do nothing
	return ERR_OK;
}

void server_tcp_error(void *arg, err_t err)
{
    printf("TCP error\r\n");
}



err_t server_tcp_poll(void *arg, struct tcp_pcb *pcb)
{
    // do nothing
	return ERR_OK;
}

err_t server_tcp_accept(void *arg, struct tcp_pcb *pcb, err_t err)
{
	printf("TCP connection accepted\r\n");
    tcp_arg(pcb, NULL);
    tcp_sent(pcb, server_tcp_sent);
    tcp_recv(pcb, server_tcp_recv);
    tcp_err(pcb, server_tcp_error);
    tcp_poll(pcb, server_tcp_poll, 0);
    return ERR_OK;
}

uint32_t pixels_remaining = 0;
uint32_t pixels_sent = 0;

// transfer captured data
void transfer()
{
    int n;

    n = tcp_sndbuf(tcp_pcb_tx)/BYTES_PER_PIXEL; // get send buffer space in pixels
    if (n) {
        if (n > pixels_remaining)
            n = pixels_remaining;
        if (tcp_write(tcp_pcb_tx,(void *)&cap_buf[pixels_sent],n * BYTES_PER_PIXEL,0) == ERR_OK) {
            pixels_sent += n; pixels_remaining -= n;
        }
    }
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
    udp_pcb_bcast = udp_new();
    ip_set_option(udp_pcb_bcast, SOF_BROADCAST);
    udp_bind(udp_pcb_bcast, IP_ADDR_ANY, UDP_PORT ) ;
    udp_connect(udp_pcb_bcast, IP_ADDR_ANY, UDP_PORT);
    udp_pbuf = pbuf_alloc(PBUF_TRANSPORT, UDP_MAX_PAYLOAD, PBUF_RAM);

    // TCP setup
    tcp_pcb_listen = tcp_new();
    tcp_bind(tcp_pcb_listen, IP_ADDR_ANY, TCP_PORT);
    tcp_pcb_listen = tcp_listen(tcp_pcb_listen);
    tcp_accept(tcp_pcb_listen, server_tcp_accept);
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
    countdown = 0;
    while (1) {

        hal_netif_rx(&Eth0);
        sys_check_timeouts();

        // advertise once per second to enable discovery
        if (countdown <= 0) {
            countdown = COUNTDOWN_SEC;
            advertise(s_disco);
            printf("pixels_sent = %d, pixels_remaining = %d\r\n", pixels_sent, pixels_remaining);
        }

        // transfer pixels as required
        if (pixels_remaining) {
            transfer();
        }
        else {
        	pixels_sent = 0;
            pixels_remaining = cap_rdy();
        }
    }
}
