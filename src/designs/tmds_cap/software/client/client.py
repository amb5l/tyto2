import socket, array
import tmds_decode

################################################################################
# network stuff

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

MSG_ADVERT = b'tmds_cap advert';
MSG_REQ = b'tmds_cap req';
MSG_ACK = b'tmds_cap ack';
MSG_CMD_CAP = b'tmds_cap cap';

print("listening for server advertisements on port %d..." % UDP_PORT_BCAST)
s_bcast = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s_bcast.bind((UDP_IP, UDP_PORT_BCAST))
while True:
    data, addr = s_bcast.recvfrom(UDP_MAX_PAYLOAD) # buffer size is 1024 bytes
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
    if addr[0] != server_ip:
        print("unexpected source address (%s)" % addr[0])
    if addr[1] != UDP_PORT_RX:
        print("unexpected source port (%s)" % addr[1])
    if data == MSG_ACK:
        break

print("CONNECTION ESTABLISHED")

# TODO
# establish mechanism to get capture statistics (pixel clock etc)

################################################################################
# get TMDS data

preq = 64 # pixels requested
BUF_LEN=preq

s_tx.sendto(b'tmds_cap cap '+bytes(str(preq),'utf-8'), (server_ip, UDP_PORT_TX))

# receive packed TMDS data
tmds_packed = array.array('L', BUF_LEN*[0])
pcnt = 0
while pcnt < preq:
    data, addr = s_rx.recvfrom(UDP_MAX_PAYLOAD)
    for i in range(len(data)//4):
        tmds_packed[pcnt] = int.from_bytes(data[4*i:4+(4*i)],'little')
        pcnt += 1

# separate channels from packed TMDS data
tmds = []
for ch in range(3):
    tmds.append(array.array('h', BUF_LEN*[-1]))
    for i in range(pcnt):
        tmds[ch][i] = (tmds_packed[i] >> (10*ch)) & 0x3FF;
del tmds_packed

################################################################################
# DVI/HDMI protocol analysis

# flag values for period type
PERIOD_UNKNOWN = 0
PERIOD_CTRL = 1
PERIOD_VIDEO_PRE = 2
PERIOD_VIDEO_GB = 4
PERIOD_VIDEO = 8
PERIOD_DATA_PRE = 16
PERIOD_DATA_GB_LEADING = 32 # used during prelim decode for *any* data guardband
PERIOD_DATA_GB_TRAILING = 64
PERIOD_DATA = 128

tmds_ch_p = [] # period flags per channel
tmds_c = []*3 # 2 bit C value per channel, -1 = invalid
for ch in range(3):
    tmds_ch_p.append(array.array('B', BUF_LEN*[PERIOD_UNKNOWN]))
    tmds_c.append(array.array('b', BUF_LEN*[-1]))
tmds_p = array.array('B', BUF_LEN*[PERIOD_UNKNOWN]) # overall period flags

hdmi = False
stop = False

print("analysis pass 1 - preliminary period detection per channel")
for i in range(pcnt):
    for ch in range(3):
        p = PERIOD_UNKNOWN
        if tmds[ch][i] in tmds_decode.ctrl:
            p = p | PERIOD_CTRL
            tmds_c[ch][i] = tmds_decode.ctrl.index(tmds[ch][i])
            if ch > 0:
                if tmds_c[ch][i] > 0:
                    hdmi = True
        if tmds[ch][i] == tmds_decode.video_gb[ch]:
            p = p | PERIOD_VIDEO_GB
        if tmds_decode.video[tmds[ch][i]] != -1:
            p = p | PERIOD_VIDEO
        if ch == 0:
            if tmds[ch][i] in tmds_decode.terc4_0:
                p = p | PERIOD_DATA_GB_LEADING | PERIOD_DATA_GB_TRAILING | PERIOD_DATA
        else:
            if tmds[ch][i] == tmds_decode.data_gb_1_2:
                p = p | PERIOD_DATA_GB_LEADING | PERIOD_DATA_GB_TRAILING
            if tmds[ch][i] in tmds_decode.terc4_1_2:
                p = p | PERIOD_DATA
        if p == 0:
            print("error: illegal TMDS character (offset %d, channel %d)" % (i,ch));
            stop = True
            # TODO: consider continuing analysis after this error?
        tmds_ch_p[ch][i] = p

print("Protocol is", "HDMI not DVI" if hdmi else "DVI not HDMI")

if not stop:
    print("analysis pass 2 - resolve control periods")
    for i in range(pcnt):
        cp = [tmds_ch_p[0][i],tmds_ch_p[1][i],tmds_ch_p[2][i]] # channel periods
        # control periods should begin and end in sync across all channels
        if (cp[0] | cp[1] | cp[2]) & PERIOD_CTRL: # control period for at least one channel
            if cp[0] & cp[1] & cp[2] & PERIOD_CTRL: # control period across all
                tmds_p[i] = PERIOD_CTRL
            else:
                print("error: control period channel misalignment (offset %d)" % i)
                stop = True
                # TODO: consider continuing analysis after this error?

if not stop:
    print("analysis pass 3 - detect preambles")
    for i in range(pcnt):
        cc = [tmds_c[0][i],tmds_c[1][i],tmds_c[2][i]] # channel C values
        p = tmds_p[i]
        if p & PERIOD_CTRL:
            if cc[1] == 0 and cc[2] == 0: # normal control period
                pass
            elif cc[1] == 1 and cc[2] == 0: # video preamble
                p = p | PERIOD_VIDEO_PRE
            elif cc[1] == 1 and cc[2] == 1: # data preamble
                p = p | PERIOD_DATA_PRE
            else:
                print("error: illegal control period (offset %d, CTL[3:0] = %s)", \
                    i,format(cc[2],'#04b')[2:],format(cc[1],'#04b')[2:])
                stop = True
                # TODO: consider continuing analysis after this error?
            tmds_p[i] = p
    
if not stop:
    print("analysis pass 4 - check preambles and resolve leading guardbands")
    p_count = 0
    p_type = ''
    for i in range(pcnt):        
        cp = [tmds_ch_p[0][i],tmds_ch_p[1][i],tmds_ch_p[2][i]] # channel periods
        p = tmds_p[i]
        if p_type == 'video_pre':
            if p & PERIOD_VIDEO_PRE:
                p_count += 1
            else:
                if p_count != HDMI_SPEC_PRE_LENGTH:
                    print("error: bad video preamble length (offset %d, length %d)" % (i,p_count))
                    stop = True
                    # TODO: consider continuing analysis after this error?
                elif cp[0] & cp[1] & cp[2] & PERIOD_VIDEO_GB:
                    p |= PERIOD_VIDEO_GB
                    p_type = 'video_gb'
                    p_count = 1                    
                else:
                    print("error: expected video guardband after preamble (offset %d)" % i)
                    stop = True
                    # TODO: consider continuing analysis after this error?                    
                    p_type = ''
                    p_count = 0
        elif p_type == 'video_gb':
            if cp[0] & cp[1] & cp[2] & PERIOD_VIDEO_GB:
                p |= PERIOD_VIDEO_GB
                p_count += 1
            else:
                if p_count != HDMI_SPEC_GB_LENGTH:
                    print("error: bad video guardband length (offset %d, length %d)" % (i,p_count))
                    stop = True
                    # TODO: consider continuing analysis after this error?
                p_type = ''
                p_count = 0                
        elif p_type == 'data_pre':
            if p & PERIOD_DATA_PRE:
                p_count += 1
            else:
                if p_count != HDMI_SPEC_PRE_LENGTH:
                    print("error: bad data preamble length (offset %d, length %d)" % (i,p_count))
                    stop = True
                    # TODO: consider continuing analysis after this error?
                elif cp[0] & cp[1] & cp[2] & PERIOD_DATA_GB_LEADING:
                    p |= PERIOD_DATA_GB_LEADING
                    p_type = 'data_gb_leading'
                    p_count = 1
                else:
                    print("error: expected data guardband after preamble (offset %d)" % i)
                    stop = True
                    # TODO: consider continuing analysis after this error?                    
                    p_type = ''
                    p_count = 0
        elif p_type == 'data_gb_leading':
            if cp[0] & cp[1] & cp[2] & PERIOD_DATA_GB_LEADING:
                p |= PERIOD_DATA_GB_LEADING
                p_count += 1
            else:
                if p_count != HDMI_SPEC_GB_LENGTH:
                    print("error: bad data guardband length (offset %d, length %d)" % (i,p_count))
                    stop = True
                    # TODO: consider continuing analysis after this error?
                p_type = ''
                p_count = 0                   
        else: # not currently processing a preamble or guardband
            if p & PERIOD_VIDEO_PRE:
                p_type = 'video_pre'
                p_count = 1
            elif p & PERIOD_DATA_PRE:
                p_type = 'data_pre'
                p_count = 1
        tmds_p[i] = p

# TODO:
# consistentcy of...
#   sync polarity, width, interval
#   H & V active, blanking and total periods
#   field/frame periods


# check for extended control periods

PERIOD_UNKNOWN = 0
PERIOD_CTRL = 1
PERIOD_VIDEO_PRE = 2
PERIOD_VIDEO_GB = 4
PERIOD_VIDEO = 8
PERIOD_DATA_PRE = 16
PERIOD_DATA_GB_LEADING = 32 # used during prelim decode for *any* data guardband
PERIOD_DATA_GB_TRAILING = 64
PERIOD_DATA = 128

print("| ...ch 2... | ...ch 1... | ...ch 0... | CTL  V H |")
for i in range(pcnt):
    print("|",end=" ")
    print(f'{tmds[2][i]:010b}',end=" | ")
    print(f'{tmds[1][i]:010b}',end=" | ")
    print(f'{tmds[0][i]:010b}',end=" | ")
    p = tmds_p[i]
    if p & PERIOD_CTRL:
        print(format(tmds_c[2][i],'#04b')[2:],end="")
        print(format(tmds_c[1][i],'#04b')[2:],end=" ")
        print(format(tmds_c[0][i],'#04b')[2],end=" ")
        print(format(tmds_c[0][i],'#04b')[3],end=" | ")
    else:
        print(".... . .",end=" | ")
    if p & PERIOD_VIDEO_PRE:
        print("v_pre",end=" | ")
    else:
        print("     ",end=" | ")
    if p & PERIOD_VIDEO_GB:
        print("v_gb",end=" | ")
    else:
        print("    ",end=" | ")
    if p & PERIOD_VIDEO:
        print("video",end=" | ")
    else:
        print("     ",end=" | ")
    if p & PERIOD_DATA_PRE:
        print("d_pre",end=" | ")
    else:
        print("     ",end=" | ")
    if p & PERIOD_DATA_GB_LEADING:
        print("d_gbl",end=" | ")
    else:
        print("     ",end=" | ")
    if p & PERIOD_DATA_GB_TRAILING:
        print("d_gbt",end=" | ")
    else:
        print("     ",end=" | ")
    if p & PERIOD_DATA:
        print("data",end=" | ")
    else:
        print("    ",end=" | ")
    print()
