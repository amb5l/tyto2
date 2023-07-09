import socket

s_myip = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s_myip.connect(("8.8.8.8", 80))
UDP_IP = s_myip.getsockname()[0]
s_myip.close()
print("my IP address is", UDP_IP)

UDP_PORT_BASE = 65400
UDP_PORT_TX = UDP_PORT_BASE+0
UDP_PORT_RX = UDP_PORT_BASE+1
UDP_PORT_BCAST = UDP_PORT_BASE+2
UDP_MAX_PAYLOAD = 1024

MSG_ADVERT = b'tmds_cap server advertisement';
MSG_REQ = b'tmds_cap client req';
MSG_ACK = b'tmds_cap server ack';

print("listening for server advertisements on port %d..." % UDP_PORT_BCAST)
s_bcast = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s_bcast.bind((UDP_IP, UDP_PORT_BCAST))
while True:
    data, addr = s_bcast.recvfrom(UDP_MAX_PAYLOAD) # buffer size is 1024 bytes
    print("from %s:%s received message: %s" % (addr[0],addr[1],data.decode('ascii')))
    if addr[1] != UDP_PORT_BCAST:
        print("unexpected source port (%s)" % addr[1])
    if data == MSG_ADVERT:
        server_ip = addr[0]
        break
s_bcast.close()

print("server IP address:", server_ip)

s_tx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s_tx.bind((UDP_IP, UDP_PORT_TX))
s_rx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s_rx.bind((UDP_IP, UDP_PORT_RX))

print("requesting client connection on port %d..." % UDP_PORT_TX)
s_tx.sendto(MSG_REQ, (server_ip, UDP_PORT_TX))

print("waiting for server acknowledgement on port %d..." % UDP_PORT_RX)
while True:
    data, addr = s_rx.recvfrom(UDP_MAX_PAYLOAD) # buffer size is 1024 bytes
    print("from %s:%s received message: %s" % (addr[0],addr[1],data.decode('ascii')))
    if addr[0] != server_ip:
        print("unexpected source address (%s)" % addr[0])
    if addr[1] != UDP_PORT_RX:
        print("unexpected source port (%s)" % addr[1])
    if data == MSG_ACK:
        break

print("CONNECTION ESTABLISHED")
