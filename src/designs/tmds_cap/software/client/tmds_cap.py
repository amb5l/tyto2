################################################################################
## tmds_cap.py                                                                ##
## Client application for the tmds_cap design.                                ##
################################################################################
## (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        ##
## This file is part of The Tyto Project. The Tyto Project is free software:  ##
## you can redistribute it and/or modify it under the terms of the GNU Lesser ##
## General Public License as published by the Free Software Foundation,       ##
## either version 3 of the License, or (at your option) any later version.    ##
## The Tyto Project is distributed in the hope that it will be useful, but    ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     ##
## License for more details. You should have received a copy of the GNU       ##
## Lesser General Public License along with The Tyto Project. If not, see     ##
## https://www.gnu.org/licenses/.                                             ##
################################################################################

import sys,socket,array,time
import tmds_spec
import hdmi_spec

print("-------------------------------------------------------------------------------")
print("tmds_cap client application")
print("-------------------------------------------------------------------------------")
print()

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
UDP_MAX_PAYLOAD = 1472

MSG_ADVERT = b'tmds_cap advert'
MSG_REQ = b'tmds_cap req'
MSG_ACK = b'tmds_cap ack'
MSG_CMD_CAP = b'tmds_cap cap'

print("listening for server advertisements on port %d..." % UDP_PORT_BCAST)
s_bcast = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s_bcast.bind(('', UDP_PORT_BCAST))
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

preq = 4*1024*1024 # more than enough for 2 frames of 1080p50
BUF_LEN=preq

print("requesting %d pixels..." % preq)
sys.stdout.flush()
s_tx.sendto(b'tmds_cap cap '+bytes(str(preq),'utf-8'), (server_ip, UDP_PORT_TX))

# receive packed TMDS data
t0 = time.perf_counter()
tmds_packed = array.array('L', BUF_LEN*[0])
pcnt = 0
while pcnt < preq:
    data, addr = s_rx.recvfrom(UDP_MAX_PAYLOAD)
    t1 = time.perf_counter()
    if t1-t0 >= 1.0:
        t0 = t1
        print("  %d" % pcnt)
    for i in range(len(data)//4):
        tmds_packed[pcnt] = int.from_bytes(data[4*i:4+(4*i)],'little')
        pcnt += 1
print("done")

# separate channels from packed TMDS data
tmds = []
for ch in range(3):
    tmds.append(array.array('h', BUF_LEN*[-1]))
    for i in range(pcnt):
        tmds[ch][i] = (tmds_packed[i] >> (10*ch)) & 0x3FF
del tmds_packed

print()
print("TMDS data received")
print()

################################################################################
# analysis: constants and variables

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
tmds_sync = array.array('b', BUF_LEN*[-1]) # bit 0 = h_sync, bit 1 = v_sync
tmds_valid = -1 # offset of first valid pixel

# measurements
m_protocol     = 'DVI'
m_interlaced   = None
m_h_sync_count = -1
m_h_sync_pol   = -1
m_h_sync_width = -1
m_v_sync_count = -1
m_v_sync_pol   = -1
m_v_sync_width = -1
m_v_total      = -1
m_v_active     = -1
m_v_blank      = -1
m_h_act_count  = -1
m_h_act_high   = -1
m_h_act_low    = -1

################################################################################
# detect period types (set tmds_p)

stop = False

print("analysis pass 1 - preliminary period detection per channel")
for i in range(pcnt):
    for ch in range(3):
        p = PERIOD_UNKNOWN
        if tmds[ch][i] in tmds_spec.ctrl:
            p = p | PERIOD_CTRL
            tmds_c[ch][i] = tmds_spec.ctrl.index(tmds[ch][i])
            if ch > 0:
                if tmds_c[ch][i] > 0:
                    m_protocol = 'HDMI'
        if tmds[ch][i] == tmds_spec.video_gb[ch]:
            p = p | PERIOD_VIDEO_GB
        if tmds_spec.video[tmds[ch][i]] != -1:
            p = p | PERIOD_VIDEO
        if ch == 0:
            if tmds[ch][i] in tmds_spec.terc4:
                p = p | PERIOD_DATA
        else:
            if tmds[ch][i] == tmds_spec.data_gb:
                p = p | PERIOD_DATA_GB_LEADING | PERIOD_DATA_GB_TRAILING
            if tmds[ch][i] in tmds_spec.terc4:
                p = p | PERIOD_DATA
        if p == 0:
            print("error: illegal TMDS character (offset %d, channel %d)" % (i,ch))
            stop = True
            # TODO: consider continuing analysis after this error?
        tmds_ch_p[ch][i] = p

if not stop:
    print("analysis pass 2 - resolve control periods")
    p_count = 0
    for i in range(pcnt):
        cp = [tmds_ch_p[0][i],tmds_ch_p[1][i],tmds_ch_p[2][i]] # channel periods
        # control periods should begin and end in sync across all channels
        if (cp[0] | cp[1] | cp[2]) & PERIOD_CTRL: # control period for at least one channel
            if cp[0] & cp[1] & cp[2] & PERIOD_CTRL: # control period across all
                tmds_p[i] = PERIOD_CTRL
            else:
                print("error: control period channel misalignment (offset %d)" % i)
                stop = True
                break
                # TODO: consider continuing analysis after this error?
        else:
            if p_count > 0 and p_count < hdmi_spec.CTRL_PERIOD_LEN_MIN:
                print("error: control period too short (offset %d)" % i)
                stop = True
                break
            p_count = 0

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
                print("error: illegal control period CTL value (offset %d, CTL[3:0] = %s)", \
                    i,format(cc[2],'#04b')[2:],format(cc[1],'#04b')[2:])
                stop = True
                break
                # TODO: consider continuing analysis after this error?
            tmds_p[i] = p

if not stop:
    print("analysis pass 4 - check preambles and detect data islands")
    p_count = 0
    p_type = ''
    for i in range(pcnt):
        cp = [tmds_ch_p[0][i],tmds_ch_p[1][i],tmds_ch_p[2][i]] # channel periods
        p = tmds_p[i]
        if p_type == 'video_pre':
            if p & PERIOD_VIDEO_PRE:
                p_count += 1
            else:
                if p_count != hdmi_spec.PRE_LEN:
                    print("error: bad video preamble length (offset %d, length %d)" % (i,p_count))
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
                elif cp[0] & cp[1] & cp[2] & PERIOD_VIDEO_GB:
                    p |= PERIOD_VIDEO_GB
                    p_type = 'video_gb'
                    p_count = 1
                else:
                    print("error: expected video guardband after preamble (offset %d)" % i)
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
        elif p_type == 'video_gb':
            if cp[0] & cp[1] & cp[2] & PERIOD_VIDEO_GB:
                p |= PERIOD_VIDEO_GB
                p_count += 1
            else:
                if p_count != hdmi_spec.GB_LEN:
                    print("error: bad video guardband length (offset %d, length %d)" % (i,p_count))
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
                p_type = ''
                p_count = 0
        elif p_type == 'data_pre':
            if p & PERIOD_DATA_PRE:
                p_count += 1
            else:
                if p_count != hdmi_spec.PRE_LEN:
                    print("error: bad data preamble length (offset %d, length %d)" % (i,p_count))
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
                elif (cp[0] & PERIOD_DATA) and (cp[1] & cp[2] & PERIOD_DATA_GB_LEADING):
                    p |= PERIOD_DATA_GB_LEADING
                    p_type = 'data_gb_leading'
                    p_count = 1
                else:
                    print("error: expected data guardband after preamble (offset %d)" % i)
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
        elif p_type == 'data_gb_leading':
            if (cp[0] & PERIOD_DATA) and (cp[1] & cp[2] & PERIOD_DATA_GB_LEADING):
                p |= PERIOD_DATA_GB_LEADING
                p_count += 1
            else:
                if p_count != hdmi_spec.GB_LEN:
                    print("error: bad leading data guardband length (offset %d, length %d)" % (i,p_count))
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
                elif cp[0] & cp[1] & cp[2] & PERIOD_DATA:
                    p |= PERIOD_DATA
                    p_type = 'data'
                    p_count = 1
                else:
                    printf("error: expected TERC4 after leading data guardband (offset %d)" % i)
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
        elif p_type == 'data':
            if cp[0] & cp[1] & cp[2] & PERIOD_DATA:
                p |= PERIOD_DATA
                p_count += 1
            else:
                if p_count % hdmi_spec.PACKET_LEN != 0:
                    print("error: non-integer multiple of data packets (offset %d, data length %d)" % (i,p_count))
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
                elif (p_count // hdmi_spec.PACKET_LEN) > hdmi_spec.PACKET_MAX:
                    print("error: too many consecutive data packets (offset %d)" % i)
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
                elif (cp[0] & PERIOD_DATA) and (cp[1] & cp[2] & PERIOD_DATA_GB_TRAILING):
                    p |= PERIOD_DATA_GB_TRAILING
                    p_type = 'data_gb_trailing'
                    p_count = 1
                else:
                    print("error: expected trailing data guardband after data (offset %d)" % i)
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
        elif p_type == 'data_gb_trailing':
            if (cp[0] & PERIOD_DATA) and (cp[1] & cp[2] & PERIOD_DATA_GB_LEADING):
                p |= PERIOD_DATA_GB_TRAILING
                p_count += 1
            else:
                if p_count != hdmi_spec.GB_LEN:
                    print("error: bad trailing data guardband length (offset %d, length %d)" % (i,p_count))
                    stop = True
                    break
                    # TODO: consider continuing analysis after this error?
                elif not p & PERIOD_CTRL:
                    print("error: expected control period after data island (offset %d" % i)
                    stop = True
                    break
                else:
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

if not stop:
    print("analysis pass 5 - detect video periods")
    p_count = 0
    for i in range(pcnt):
        cp = [tmds_ch_p[0][i],tmds_ch_p[1][i],tmds_ch_p[2][i]] # channel periods
        p = tmds_p[i]
        if not p:
            if cp[0] & cp[1] & cp[2] & PERIOD_VIDEO:
                p = p | PERIOD_VIDEO
            else:
                # this should be impossible
                print("error: non-video characters found in video period (offset %d, length %d)" % (i,p_count))
                stop = True
                break
                # TODO: consider continuing analysis after this error?
        tmds_p[i] = p

# assumption - sync states persist after control and data periods
if not stop:
    print("analysis pass 6 - resolve syncs")
    sync = -1
    for i in range(pcnt):
        p = tmds_p[i]
        if p & PERIOD_CTRL:
            sync = tmds_c[0][i]
        elif p & (PERIOD_DATA | PERIOD_DATA_GB_LEADING | PERIOD_DATA_GB_TRAILING):
            sync = tmds_spec.terc4.index(tmds[0][i]) & 3
        tmds_sync[i] = sync
        if sync >= 0 and tmds_valid < 0:
            tmds_valid = i

if not stop:
    print("analysis pass 7 - video timing measurements")
    h_sync_prev    = None # previous h_sync state
    h_sync_rising  = None # index of latest h_sync rising edge
    h_sync_falling = None # index of latest h_sync falling edge
    h_sync_high    = None # width of lastest h_sync high period
    h_sync_low     = None # width of lastest h_sync low period
    v_sync_prev    = None # previous v_sync state
    v_sync_rising  = None # index of latest v_sync rising edge
    v_sync_falling = None # index of latest v_sync falling edge
    v_sync_high    = None # width of lastest v_sync high period
    v_sync_low     = None # width of lastest v_sync low period
    h_act_prev     = None
    h_act_rising   = None
    h_act_falling  = None
    h_act_high     = None
    h_act_low      = None
    for i in range(pcnt):
        if tmds_sync[i] >= 0:
            h_sync = tmds_sync[i] & 1
            v_sync = (tmds_sync[i] >> 1) & 1
            if h_sync_prev != None and h_sync != h_sync_prev:
                if h_sync == 0:
                    m_h_sync_count += 1 # assume counting falling edges is OK
                    h_sync_falling = i
                    if h_sync_rising:
                        if h_sync_high:
                            if h_sync_high != h_sync_falling - h_sync_rising:
                                print("error: inconsistent h_sync high duration (offset %d, found %d, expected %d)" % (i, h_sync_falling - h_sync_rising, h_sync_high))
                                stop = True
                                break
                        else:
                            h_sync_high = h_sync_falling - h_sync_rising
                else:
                    h_sync_rising = i
                    if h_sync_falling:
                        if h_sync_low:
                            if h_sync_low != h_sync_rising - h_sync_falling:
                                print("error: inconsistent h_sync low duration (offset %d)" % i)
                                print("error: inconsistent h_sync low duration (offset %d, found %d, expected %d)" % (i, h_sync_rising - h_sync_falling, h_sync_low))
                                stop = True
                                break
                        else:
                            h_sync_low = h_sync_rising - h_sync_falling
            if v_sync_prev != None and v_sync != v_sync_prev:
                if v_sync == 0:
                    m_h_sync_count += 1 # assume counting falling edges is OK
                    v_sync_falling = i
                    if v_sync_rising:
                        if v_sync_high:
                            if v_sync_high != v_sync_falling - v_sync_rising:
                                print("error: inconsistent v_sync high duration (offset %d)" % i)
                                stop = True
                                break
                        else:
                            v_sync_high = v_sync_falling - v_sync_rising
                else:
                    v_sync_rising = i
                    if v_sync_falling:
                        if v_sync_low:
                            if v_sync_low != v_sync_rising - v_sync_falling:
                                print("error: inconsistent v_sync low duration (offset %d)" % i)
                                stop = True
                                break
                        else:
                            v_sync_low = v_sync_rising - v_sync_falling
            h_sync_prev = h_sync
            v_sync_prev = v_sync
            h_act = 1 if tmds_p[i] & PERIOD_VIDEO else 0
            if h_act_prev != None and h_act != h_act_prev:
                if h_act == 0:
                    m_h_act_count += 1
                    h_act_falling = i
                    if h_act_rising:
                        if h_act_high:
                            if h_act_high != h_act_falling - h_act_rising:
                                print("error: inconsistent h_act high duration (offset %d)" % i)
                                stop = True
                                break
                        else:
                            h_act_high = h_act_falling - h_act_rising
                else:
                    h_act_rising = i
                    if h_act_falling:
                        if h_act_low:
                            if h_act_low != h_act_rising - h_act_falling:
                                print("error: inconsistent h_act low duration (offset %d)" % i)
                                stop = True
                                break
                        else:
                            h_act_low = h_act_rising - h_act_falling
            h_act_prev = h_act
    if h_sync_low and h_sync_high:
        if h_sync_low >= h_sync_high:
            m_h_sync_pol   = 1
            m_h_sync_width = h_sync_high
        else:
            m_h_sync_pol   = 0
            m_h_sync_width = h_sync_low
    if v_sync_low and v_sync_high:
        if v_sync_low >= v_sync_high:
            m_v_sync_pol   = 1
            m_v_sync_width = v_sync_high
        else:
            m_v_sync_pol   = 0
            m_v_sync_width = v_sync_low
    m_h_act_high = h_act_high
    m_h_act_low  = h_act_low

################################################################################

print()
print("REPORT")
print("pixels analysed: %d" % pcnt)
print("first valid pixel: %d" % tmds_valid)
print("protocol is", m_protocol)
print()
#print("          h syncs seen : %d" % m_h_sync_count)
#print("          v syncs seen : %d" % m_v_sync_count)
#print(" h active periods seen : %d" % m_h_act_count)
#print("         h active high : %d" % m_h_act_high)
#print("          h active low : %d" % m_h_act_low)
#print()


print("horizontal timings:")
print("   sync polarity : %d" % m_h_sync_pol)
print("      sync width : %d" % m_h_sync_width)
print("   active pixels : %d" % m_h_act_high )
print("    blank pixels : %d" % m_h_act_low  )
print("    total pixels : %d" % (m_h_act_high+m_h_act_low)  )
print("vertical timings:")
print("   sync polarity : %d" % m_v_sync_pol)
print("      sync width : %d" % m_v_sync_width)
print("    total pixels : %d" % m_v_total  )
print("   active pixels : %d" % m_v_active )
print("    blank pixels : %d" % m_v_blank  )

# TODO:
# check consistency of...
#   H & V active, blanking and total periods
#   field/frame periods
# check for extended control periods
# decode data and verify

################################################################################
# debug - dump TMDS data and period information

if 0:
    print()
    print("         | ...ch 2... | ...ch 1... | ...ch 0... | H V |  CTL |")
    for i in range(pcnt):
        print(f'{i:008d}',end=" | ")
        print(f'{tmds[2][i]:010b}',end=" | ")
        print(f'{tmds[1][i]:010b}',end=" | ")
        print(f'{tmds[0][i]:010b}',end=" | ")
        p = tmds_p[i]
        print(tmds_sync[i] & 1,end=" ")
        print((tmds_sync[i] >> 1) & 1,end=" | ")
        if p & PERIOD_CTRL:
            print(format(tmds_c[2][i],'#04b')[2:],end="")
            print(format(tmds_c[1][i],'#04b')[2:],end=" | ")
        else:
            print("....",end=" | ")
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
