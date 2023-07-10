#include "server.h"

int main()
{
    server_banner();
    server_init();
    server_dhcp();
    server_conn();
    server_run();
}
