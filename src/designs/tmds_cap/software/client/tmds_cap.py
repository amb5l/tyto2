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

# standard modules
import sys,argparse,struct,socket,array,time

# local modules
import tmds_spec
import hdmi_spec

print("-------------------------------------------------------------------------------")
print("tmds_cap client application")
print("-------------------------------------------------------------------------------")
print()

PIXELS = (3*1920*1080)+2200 # enough for 2 full frames of 1080p, or 4 fields of 1080i

parser = argparse.ArgumentParser(
    prog='tmds_cap.py',
    description='TMDS data capture and analysis for HDMI and DVI sources',
    epilog='See https://github.com/amb5l/tyto2'
    )
group = parser.add_mutually_exclusive_group(required=False)
group.add_argument('-n',type=int,default=PIXELS,help='capture N pixels from hardware (default: %(default)s)')
group.add_argument('-i',metavar='filename',default=None,help='read TMDS data from specified input file (default: %(default)s)')
parser.add_argument('-o',metavar='filename',default=None,help='write TMDS data to specified output file (default: %(default)s)')
args = parser.parse_args()
n = args.n
infile = args.i
outfile = args.o

################################################################################
# get TMDS data from infile or hardware

BYTES_PER_PIXEL = 4

if infile:
    # read TMDS data from file
    print("reading TMDS data from %s..." % infile)
    tmds_packed = array.array('L')
    n = 0
    with open(infile, 'rb') as f:
        tmds_bytes = f.read()
    n = int(len(tmds_bytes)/BYTES_PER_PIXEL)
    print("%d pixels read" % n)
else:
    # read TMDS data from hardware
    s_myip = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s_myip.connect(("8.8.8.8", 80))
    MY_IP = s_myip.getsockname()[0]
    s_myip.close()
    print("my IP address is", MY_IP)
    UDP_PORT = 65400
    UDP_MAX_PAYLOAD = 1472
    TCP_PORT = 65401
    TCP_MAX_PAYLOAD = 1460
    print("listening for server advertisements (UDP broadcasts) on port %d..." % UDP_PORT)
    s_bcast = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s_bcast.bind(('', UDP_PORT))
    while True:
        data, addr = s_bcast.recvfrom(UDP_MAX_PAYLOAD) # buffer size is 1024 bytes
        if addr[1] != UDP_PORT:
            print("unexpected source port (%s)" % addr[1])
        if data == b'tmds_cap disco':
            server_ip = addr[0]
            break
        else:
            print("unexpected data (%s)" % data)
    s_bcast.close()
    s_tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # TCP socket
    print("connecting to server at", server_ip)
    s_tcp.connect((server_ip,TCP_PORT))
    print("CONNECTION ESTABLISHED")
    print("requesting %d pixels..." % n)
    t0 = time.perf_counter()
    s_tcp.sendall(b'tmds_cap get '+bytes(str(n),'utf-8'))
    breq = n*BYTES_PER_PIXEL
    tmds_bytes = bytearray()
    while len(tmds_bytes) < breq:
        data = s_tcp.recv(breq-len(data))
        if data:
            tmds_bytes.extend(data)
    print("done (total time = %.2f seconds)" % (time.perf_counter()-t0))
    s_tcp.close()

# convert raw bytes to packed TMDS
tmds_packed = array.array('L', n*[0])
for i in range(n):
    tmds_packed[i] = int.from_bytes(tmds_bytes[4*i:4+(4*i)],'little')
if outfile:
    # write TMDS data to file
    print("writing TMDS data to %s..." % outfile)
    with open(outfile, 'wb') as f:
        for d in tmds_packed:
            f.write(struct.pack('<L',d))
    f.close()

# separate channels from packed TMDS data
tmds = []
for ch in range(3):
    tmds.append(array.array('h',n*[-1]))
    for i in range(n):
        tmds[ch][i] = (tmds_packed[i] >> (10*ch)) & 0x3FF
del tmds_packed

################################################################################
# analysis: constants and variables

# flag values for period type
PERIOD_UNKNOWN          = 0
PERIOD_CTRL             = 1
PERIOD_VIDEO_PRE        = 2
PERIOD_VIDEO_GB         = 4
PERIOD_VIDEO            = 8
PERIOD_DATA_PRE         = 16
PERIOD_DATA_GB_LEADING  = 32 # used during prelim decode for *any* data guardband
PERIOD_DATA_GB_TRAILING = 64
PERIOD_DATA             = 128

tmds_ch_p = [] # period flags per channel
tmds_c = []*3 # 2 bit C value per channel, -1 = invalid
for ch in range(3):
    tmds_ch_p.append(array.array('B', n*[PERIOD_UNKNOWN]))
    tmds_c.append(array.array('b', n*[-1]))
tmds_p = array.array('B', n*[PERIOD_UNKNOWN]) # overall period flags
tmds_sync = array.array('b', n*[-1]) # bit 0 = h sync, bit 1 = v sync

################################################################################
# measurements to be made

m_protocol      = 'DVI'

m_start         = -1 # offset of first control pixel (start of valid data)

# horizontal timing (durations are in pixels)
m_h_sync_pol    = -1 # h sync polarity (1 = high, 0 = low)
m_h_front_porch = -1 # duration of h front porch (active to sync)
m_h_sync        = -1 # duration of h sync
m_h_back_porch  = -1 # duration of h back porch (sync to active)
m_h_active      = -1 # duration of h active
m_h_blank       = -1 # m_h_blank = m_h_front_porch+m_h_sync+m_h_back_porch
m_h_total       = -1 # m_h_total = m_h_blank+m_h_active

# vertical timing (durations are in lines)
m_v_sync_i      = -1 # offset of first vsync (for first field if interlaced)
m_v_interlace   = -1 # 1 = interlace, 0 = progressive
m_v_sync_pol    = -1 # v sync polarity (1 = high, 0 = low)
m_v_front_porch = -1 # duration of v front porch (active to sync) (first field)
m_v_sync        = -1 # duration of v sync
m_v_back_porch  = -1 # duration of v back porch (sync to active) (first field)
m_v_active      = -1 # duration of v active
m_v_blank       = -1 # m_v_blank = m_v_front_porch+m_v_sync+m_v_back_porch
m_v_total       = -1 # m_v_total = m_v_blank+m_h_active

# note: in the case of interlace,
#  m_v_front_porch and m_v_back_porch are relative to upper field v sync
# i.e. they are integers.
# For the lower field the numbers are 1/2 a line greater.

################################################################################
# analysis

stop = False

print("analysis pass 1 - preliminary period detection per channel")
for i in range(n):
    for ch in range(3):
        p = PERIOD_UNKNOWN
        if tmds[ch][i] in tmds_spec.ctrl:
            p |= PERIOD_CTRL
            tmds_c[ch][i] = tmds_spec.ctrl.index(tmds[ch][i])
            if ch > 0:
                if tmds_c[ch][i] > 0:
                    m_protocol = 'HDMI'
        if tmds[ch][i] == tmds_spec.video_gb[ch]:
            p |= PERIOD_VIDEO_GB
        if tmds_spec.video[tmds[ch][i]] != -1:
            p |= PERIOD_VIDEO
        if ch == 0:
            if tmds[ch][i] in tmds_spec.terc4:
                p |= PERIOD_DATA
        else:
            if tmds[ch][i] == tmds_spec.data_gb:
                p |= PERIOD_DATA_GB_LEADING | PERIOD_DATA_GB_TRAILING
            if tmds[ch][i] in tmds_spec.terc4:
                p |= PERIOD_DATA
        if p == 0:
            print("error: illegal TMDS character (offset %d, channel %d)" % (i,ch)); stop = True; break
        tmds_ch_p[ch][i] = p

if not stop:
    print("analysis pass 2 - resolve control periods")
    p_count = 0
    for i in range(n):
        cp = [tmds_ch_p[0][i],tmds_ch_p[1][i],tmds_ch_p[2][i]] # channel periods
        # control periods should begin and end together across all channels
        if (cp[0] | cp[1] | cp[2]) & PERIOD_CTRL: # control period for at least one channel
            if cp[0] & cp[1] & cp[2] & PERIOD_CTRL: # control period across all
                tmds_p[i] = PERIOD_CTRL
                if m_start == -1 and tmds_c[1][i] == 0 and tmds_c[2][i] == 0:
                    m_start = i
            else:
                print("error: control period channel misalignment (offset %d)" % i); stop = True; break
        else:
            if p_count > 0 and p_count < hdmi_spec.CTRL_PERIOD_LEN_MIN:
                print("error: control period too short (offset %d)" % i); stop = True; break
            p_count = 0

if not stop:
    print("analysis pass 3 - detect preambles")
    for i in range(m_start,n):
        cc = [tmds_c[0][i],tmds_c[1][i],tmds_c[2][i]] # channel C values
        p = tmds_p[i]
        if p & PERIOD_CTRL:
            if cc[1] == 0 and cc[2] == 0: # normal control period
                pass
            elif cc[1] == 1 and cc[2] == 0: # video preamble
                p |= PERIOD_VIDEO_PRE
            elif cc[1] == 1 and cc[2] == 1: # data preamble
                p |= PERIOD_DATA_PRE
            else:
                print("error: illegal control period CTL value (offset %d, CTL[3:0] = %s)", \
                    i,format(cc[2],'#04b')[2:],format(cc[1],'#04b')[2:]); stop = True; break
            tmds_p[i] = p

if not stop:
    print("analysis pass 4 - check preambles and detect data islands")
    p_count = 0
    p_type = ''
    for i in range(n):
        cp = [tmds_ch_p[0][i],tmds_ch_p[1][i],tmds_ch_p[2][i]] # channel periods
        p = tmds_p[i]
        if p_type == 'video_pre':
            if p & PERIOD_VIDEO_PRE:
                p_count += 1
            else:
                if p_count != hdmi_spec.PRE_LEN:
                    print("error: bad video preamble length (offset %d, length %d)" % (i,p_count)); stop = True; break
                elif cp[0] & cp[1] & cp[2] & PERIOD_VIDEO_GB:
                    p |= PERIOD_VIDEO_GB
                    p_type = 'video_gb'
                    p_count = 1
                else:
                    print("error: expected video guardband after preamble (offset %d)" % i); stop = True; break
        elif p_type == 'video_gb':
            if cp[0] & cp[1] & cp[2] & PERIOD_VIDEO_GB:
                p |= PERIOD_VIDEO_GB
                p_count += 1
            else:
                if p_count != hdmi_spec.GB_LEN:
                    print("error: bad video guardband length (offset %d, length %d)" % (i,p_count)); stop = True; break
                p_type = ''
                p_count = 0
        elif p_type == 'data_pre':
            if p & PERIOD_DATA_PRE:
                p_count += 1
            else:
                if p_count != hdmi_spec.PRE_LEN:
                    print("error: bad data preamble length (offset %d, length %d)" % (i,p_count)); stop = True; break
                elif (cp[0] & PERIOD_DATA) and (cp[1] & cp[2] & PERIOD_DATA_GB_LEADING):
                    p |= PERIOD_DATA_GB_LEADING
                    p_type = 'data_gb_leading'
                    p_count = 1
                else:
                    print("error: expected data guardband after preamble (offset %d)" % i); stop = True; break
        elif p_type == 'data_gb_leading':
            if (cp[0] & PERIOD_DATA) and (cp[1] & cp[2] & PERIOD_DATA_GB_LEADING):
                p |= PERIOD_DATA_GB_LEADING
                p_count += 1
            else:
                if p_count != hdmi_spec.GB_LEN:
                    print("error: bad leading data guardband length (offset %d, length %d)" % (i,p_count)); stop = True; break
                elif cp[0] & cp[1] & cp[2] & PERIOD_DATA:
                    p |= PERIOD_DATA
                    p_type = 'data'
                    p_count = 1
                else:
                    printf("error: expected TERC4 after leading data guardband (offset %d)" % i); stop = True; break
        elif p_type == 'data':
            if cp[0] & cp[1] & cp[2] & PERIOD_DATA:
                p |= PERIOD_DATA
                p_count += 1
            else:
                if p_count % hdmi_spec.PACKET_LEN != 0:
                    print("error: non-integer multiple of data packets (offset %d, data length %d)" % (i,p_count)); stop = True; break
                elif (p_count // hdmi_spec.PACKET_LEN) > hdmi_spec.PACKET_MAX:
                    print("error: too many consecutive data packets (offset %d)" % i); stop = True; break
                elif (cp[0] & PERIOD_DATA) and (cp[1] & cp[2] & PERIOD_DATA_GB_TRAILING):
                    p |= PERIOD_DATA_GB_TRAILING
                    p_type = 'data_gb_trailing'
                    p_count = 1
                else:
                    print("error: expected trailing data guardband after data (offset %d)" % i); stop = True; break
        elif p_type == 'data_gb_trailing':
            if (cp[0] & PERIOD_DATA) and (cp[1] & cp[2] & PERIOD_DATA_GB_LEADING):
                p |= PERIOD_DATA_GB_TRAILING
                p_count += 1
            else:
                if p_count != hdmi_spec.GB_LEN:
                    print("error: bad trailing data guardband length (offset %d, length %d)" % (i,p_count)); stop = True; break
                elif not p & PERIOD_CTRL:
                    print("error: expected control period after data island (offset %d" % i); stop = True; break
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
    for i in range(n):
        cp = [tmds_ch_p[0][i],tmds_ch_p[1][i],tmds_ch_p[2][i]] # channel periods
        p = tmds_p[i]
        if not p:
            if cp[0] & cp[1] & cp[2] & PERIOD_VIDEO:
                p |= PERIOD_VIDEO
            else:
                # this should be impossible
                print("error: non-video characters found in video period (offset %d, length %d)" % (i,p_count)); stop = True; break
        tmds_p[i] = p

# assumption - sync states persist after control and data periods
if not stop:
    print("analysis pass 6 - resolve syncs")
    sync = -1
    for i in range(n):
        p = tmds_p[i]
        if p & PERIOD_CTRL:
            sync = tmds_c[0][i]
        elif p & (PERIOD_DATA | PERIOD_DATA_GB_LEADING | PERIOD_DATA_GB_TRAILING):
            sync = tmds_spec.terc4.index(tmds[0][i]) & 3
        tmds_sync[i] = sync

if not stop:
    print("analysis pass 7 - horizontal video timing")
    # records
    r_h_event       = [None]*5  # record of h event types
    r_h_act         = [None]*3  # record of h active event levels
    r_h_act_i       = [None]*3  # record of h active event indices
    r_h_sync        = [None]*3  # record of h sync event levels
    r_h_sync_i      = [None]*3  # record of h sync event indices
    # short term variables
    h_act           = None      # h active level, this pixel
    h_act_1         = None      # h active level, previous pixel
    h_sync          = None      # h sync level, this pixel
    h_sync_1        = None      # h sync level, previous pixel
    h_event_bad     = None      # h event sequence is bad
    h_event_new     = None      # h event, this pixel (if applicable)
    h_total_i       = None      # index of previous event for h_total calculation
    # extract timing
    for i in range(m_start,n):
        h_act_1 = h_act; h_act = 1 if tmds_p[i] & PERIOD_VIDEO else 0
        h_sync_1 = h_sync; h_sync = tmds_sync[i] & 1
        h_event_bad = False
        h_event_new = None
        h_total_i   = None
        if h_act_1 != None and h_act != h_act_1:
            if h_sync != h_sync_1:
                print("at %d: coinciding events on h_act and h_sync" % i); err_i = i; stop=True; break
            else:
                if h_act == 1 and h_act_1 == 0:
                    h_event_new = "h_act_rising"
                elif h_act == 0 and h_act_1 == 1:
                    h_event_new = "h_act_falling"
                else:
                    print("at %d: impossible levels (h_act = %d,  h_act_1 = %d)" % (i,h_act,h_act_1)); err_i = i; stop=True; break
        elif h_sync_1 != None and h_sync != h_sync_1:
            if h_sync == 1 and h_sync_1 == 0:
                h_event_new = "h_sync_rising"
            elif h_sync == 0 and h_sync_1 == 1:
                h_event_new = "h_sync_falling"
            else:
                print("at %d: impossible levels (h_sync = %d,  h_sync_1 = %d)" % (h_sync,h_sync_1)); err_i = i; stop=True; break
        if h_event_new:
            r_h_event = [h_event_new]+r_h_event[:-1]
            h_total_i = None
            if r_h_event[0][:5] == "h_act":
                r_h_act = [h_act]+r_h_act[:-1]
                r_h_act_i = [i]+r_h_act_i[:-1]
                if not (r_h_event[0] == "h_act_rising" and r_h_event[3] != "h_act_falling"):
                    h_total_i = r_h_act_i[2]
            elif r_h_event[0][:6] == "h_sync":
                r_h_sync[2] = r_h_sync[1]; r_h_sync[1] = r_h_sync[0]; r_h_sync[0] = h_sync
                r_h_sync_i = [i]+r_h_sync_i[:-1]
                h_total_i = r_h_sync_i[2]
            if r_h_event[1] != None:
                if r_h_event[0] == "h_act_rising":
                    if r_h_event[1][:6] == "h_sync":
                        # check/measure h_sync_pol
                        if m_h_sync_pol != -1:
                            if m_h_sync_pol != 1-r_h_sync[0]:
                                s = "h_sync_rising" if r_h_sync[0] == 1 else "h_sync_falling"
                                print("%s at %d: preceding %s is unexpected" % (r_h_event[0],i,s)); err_i = i; stop=True; break
                        else:
                            m_h_sync_pol = 1-r_h_sync[0]
                        # check/measure h_back_porch
                        if m_h_back_porch != -1:
                            if m_h_back_porch != r_h_act_i[0]-r_h_sync_i[0]:
                                print("%s at %d: expected h_back_porch = %g found %g" % (r_h_event[0],i,m_h_back_porch,r_h_act_i[0]-r_h_sync_i[0])); err_i = i; stop=True; break
                        else:
                            if r_h_sync_i[0] != None:
                                m_h_back_porch = r_h_act_i[0]-r_h_sync_i[0]
                        # check/measure h_blank
                        if r_h_event[2][:6] == "h_sync" and r_h_event[3] == "h_act_falling":
                            if m_h_blank != -1:
                                if m_h_blank != r_h_act_i[0]-r_h_act_i[1]:
                                    print("%s at %d: expected h_blank = %g found %g" % (r_h_event[0],i,m_h_blank,r_h_act_i[0]-r_h_act_i[1])); err_i = i; stop=True; break
                            else:
                                if r_h_act_i[1] != None:
                                    m_h_blank = r_h_act_i[0]-r_h_act_i[1]
                    else:
                        h_event_bad = True
                elif r_h_event[0] == "h_act_falling":
                    if r_h_event[1] == "h_act_rising":
                        # check/measure h_active
                        if m_h_active != -1:
                            if m_h_active != r_h_act_i[0]-r_h_act_i[1]:
                                print("%s at %d: expected h_active = %g found %g" % (r_h_event[0],i,m_h_active,r_h_act_i[0]-r_h_act_i[1])); err_i = i; stop=True; break
                        else:
                            m_h_active = r_h_act_i[0]-r_h_act_i[1]
                    else:
                        h_event_bad = True
                elif r_h_event[0][:6] == "h_sync":
                    if r_h_event[1] == "h_act_falling":
                        # check/measure h_sync_pol
                        if m_h_sync_pol != -1:
                            if m_h_sync_pol != h_sync:
                                s = "low" if r_h_sync[0] == 0 else "high"
                                print("%s at %d: unexpected active %s h sync" % (r_h_event[0],i,s)); err_i = i; stop=True; break
                        else:
                            m_h_sync_pol = h_sync
                        # check_measure h_front_porch
                        if m_h_front_porch != -1:
                            if m_h_front_porch != r_h_sync_i[0]-r_h_act_i[0]:
                                print("%s at %d: expected h_front_porch = %g found %g" % (r_h_event[0],i,m_h_front_porch,r_h_sync_i[0]-r_h_act_i[0])); err_i = i; stop=True; break
                        else:
                            m_h_front_porch = r_h_sync_i[0]-r_h_act_i[0]
                    elif r_h_event[1][:6] == "h_sync" and r_h_event[2] != None:
                        if r_h_event[2][:6] == "h_sync":
                            if r_h_sync_i[0]-r_h_sync_i[1] > r_h_sync_i[1]-r_h_sync_i[2]: # leading
                                x_h_sync_pol = h_sync
                                x_h_sync = r_h_sync_i[1]-r_h_sync_i[2]
                            else: # trailing
                                x_h_sync_pol = 1-h_sync
                                x_h_sync = r_h_sync_i[0]-r_h_sync_i[1]
                            # check/measure h_sync_pol
                            if m_h_sync_pol != -1:
                                if m_h_sync_pol != x_h_sync_pol:
                                    s = "low" if r_h_sync[0] == 0 else "high"
                                    print("%s at %d: unexpected active %s h sync" % (r_h_event[0],i,s)); err_i = i; stop=True; break
                            else:
                                m_h_sync_pol = x_h_sync_pol
                            # check_measure h_sync
                            if m_h_sync != -1:
                                if m_h_sync != x_h_sync:
                                    print("%s at %d: expected h_sync = %g found %g" % (r_h_event[0],i,m_h_sync,x_h_sync)); err_i = i; stop=True; break
                            else:
                                m_h_sync = x_h_sync
                else:
                    print("%s at %d: unexpected event" % (r_h_event[0],i)); err_i = i; stop=True; break
                if h_event_bad:
                    print("at %d: unexpected event sequence (%s followed by %s)" % (r_h_event[1],r_h_event[0])); err_i = i; stop=True; break
                else:
                    # check/measure h_total
                    if not ( \
                        (r_h_event[0] == "h_act_rising" and r_h_event[3] != "h_act_falling") or
                        (r_h_event[0] == "h_act_falling" and r_h_event[4] != "h_act_falling") \
                    ):
                        if m_h_total != -1:
                            if m_h_total != i-h_total_i:
                                print("%s at %d: expected h_total = %g found %g" % (r_h_event[0],i,m_h_total,i-h_total_i)); err_i = i; stop=True; break
                        else:
                            if h_total_i != None:
                                m_h_total = i-h_total_i
    if m_h_blank != m_h_front_porch+m_h_sync+m_h_back_porch:
        print("ERROR: h_blank != h_front_porch + h_sync + h_back_porch")
    if m_h_total != m_h_active+m_h_blank:
        print("ERROR: h_total != h_active + h_blank")

if not stop:
    print("analysis pass 8 - vertical video timing")
    # records
    r_h_sync_leading  = [None]*3  # record of h sync leading edge indices
    r_v_sync_leading  = [None]*3  # record of v sync leading edge indices
    r_v_sync_trailing = [None]*3  # record of v sync trailing edge indices
    r_v_act           = [None]*3  # record of v active events (level,index)
    # short term variables
    h_act             = None
    h_act_1           = None
    h_sync            = None
    h_sync_1          = None
    h_sync_i          = None
    v_sync            = None
    v_sync_1          = None
    v_act             = None
    v_act_1           = None
    field             = None
    # get m_v_sync_pol
    for i in range(m_start,n):
        h_act = 1 if tmds_p[i] & PERIOD_VIDEO else 0
        v_sync = (tmds_sync[i] & 2) >> 1
        if h_act == 1 and m_v_sync_pol == -1:
            m_v_sync_pol = 1-v_sync
            break
    # get m_v_sync_i, m_v_interlace
    m_v_interlace = 0
    for i in range(m_start,n):
        h_sync_1 = h_sync; h_sync = tmds_sync[i] & 1
        v_sync_1 = v_sync; v_sync = (tmds_sync[i] & 2) >> 1
        if v_sync == m_v_sync_pol and v_sync_1 == 1-m_v_sync_pol: # leading edge of v sync
            if h_sync == m_h_sync_pol and h_sync_1 == 1-m_h_sync_pol: # coincident leading edge of h sync
                if m_v_sync_i == -1:
                    m_v_sync_i = i
            else: # non coincident h sync
                m_v_interlace = 1
        if m_v_sync_i != -1 and m_v_interlace == 1:
            break
    # get/check m_v_total
    for i in range(m_start,n):
        h_act_1 = h_act; h_act = 1 if tmds_p[i] & PERIOD_VIDEO else 0
        h_sync_1 = h_sync; h_sync = tmds_sync[i] & 1
        v_sync_1 = v_sync; v_sync = (tmds_sync[i] & 2) >> 1
        if h_act == 1 and h_act_1 == 0: # leading edge of h active
            v_act = 1
        if h_sync == m_h_sync_pol and h_sync_1 == 1-m_h_sync_pol: # leading edge of h sync
            if h_sync_i != None:
                # process v_act for preceding line
                if v_act_1 != None and v_act != v_act_1:
                    r_v_act = [[h_sync_i,1]]+r_v_act[:-1]
                    if v_act == 1 and v_act_1 == 0: # leading edge of v active
                        if r_v_act[0] != None and r_v_sync_trailing[0] != None and field != None:
                            # check/measure v_back_porch
                            x = ((r_v_act[0][0]-r_v_sync_trailing[0])/m_h_total)+(field/2)
                            if m_v_back_porch != -1:
                                if m_v_back_porch != x:
                                    print("at %d: expected v_back_porch = %g found %g" % (i,m_v_back_porch,x)); err_i = i; stop=True; break
                            else:
                                m_v_back_porch = x
                                if m_v_back_porch != int(m_v_back_porch):
                                    print("at %d: expected integer v_back_porch, found %g" % (i,m_v_back_porch)); err_i = i; stop=True; break
                        if r_v_act[1] != None:
                            # check/measure v_blank
                            x = (r_v_act[0][0]-r_v_act[1][0])/m_h_total
                            if m_v_blank != -1:
                                if m_v_blank != x:
                                    print("at %d: expected v_blank = %g found %g" % (i,m_v_blank,x)); err_i = i; stop=True; break
                            else:
                                m_v_blank = x
                                if m_v_blank != int(m_v_blank):
                                    print("at %d: expected integer v_blank, found %g" % (i,m_v_blank)); err_i = i; stop=True; break
                    elif v_act == 0 and v_act_1 == 1: # trailing edge of v active
                        if r_v_act[1] != None:
                            # check/measure v_active
                            x = (r_v_act[0][0]-r_v_act[1][0])/m_h_total
                            if m_v_active != -1:
                                if m_v_active != x:
                                    print("at %d: expected v_active = %g found %g" % (i,m_v_active,x)); err_i = i; stop=True; break
                            else:
                                m_v_active = x
                                if m_v_active != int(m_v_active):
                                    print("at %d: expected integer v_active, found %g" % (i,m_v_active)); err_i = i; stop=True; break
                v_act_1 = v_act; v_act = 0
            h_sync_i = i
        if v_sync == m_v_sync_pol and v_sync_1 == 1-m_v_sync_pol: # leading edge of v sync
            field = 1 if h_sync_i != i else 0
            r_v_sync_leading = [i]+r_v_sync_leading[:-1]
            r_v_sync_leading_prev = r_v_sync_leading[1] if m_v_interlace == 0 else r_v_sync_leading[2]
            if m_v_interlace == 0: # progressive
                r_v_sync_leading_prev = r_v_sync_leading[1]
                h_sync_i_x = i
            elif field == 0: # first field of interlace
                r_v_sync_leading_prev = r_v_sync_leading[2]
                h_sync_i_x = i
            elif field == 1: # second field of interlace
                r_v_sync_leading_prev = r_v_sync_leading[2]
                h_sync_i_x = i-m_h_total/2
            # check position of v sync edge w.r.t h sync leading edge
            if h_sync_i != h_sync_i_x:
                print("at %d: bad v sync position w.r.t. h sync - found offset %d, expected %g" % (i,i-h_sync_i,i-h_sync_i_x)); err_i = i; stop=True; break
            # check/measure m_v_total
            if r_v_sync_leading_prev != None:
                if m_v_total != -1:
                    if m_v_total != (i-r_v_sync_leading_prev)/m_h_total:
                        print("at %d: expected v_total = %g found %g" % (i,m_v_total,(i-r_v_sync_leading_prev)/m_h_total)); err_i = i; stop=True; break
                else:
                    m_v_total = (i-r_v_sync_leading_prev)/m_h_total
                    if m_v_total != int(m_v_total):
                        print("at %d: expected integer v_total, found %g" % (i,m_v_total)); err_i = i; stop=True; break
            if r_v_act[0] != None and field != None:
                # check/measure m_v_front_porch
                x = ((i-r_v_act[0][0])/m_h_total)+(field/2)
                if m_v_front_porch != -1:
                    if m_v_front_porch != x:
                        print("at %d: expected v_front_porch = %g found %g" % (i,m_v_front_porch,x)); err_i = i; stop=True; break
                else:
                    m_v_front_porch = x
                    if m_v_front_porch != int(m_v_front_porch):
                        print("at %d: expected integer v_front_porch, found %g" % (i,m_v_front_porch)); err_i = i; stop=True; break
        elif v_sync == 1-m_v_sync_pol and v_sync_1 == m_v_sync_pol: # trailing edge of v sync
            r_v_sync_trailing = [i]+r_v_sync_trailing[:-1]
            r_v_sync_trailing_prev = r_v_sync_trailing[1] if m_v_interlace == 0 else r_v_sync_trailing[2]
            if m_v_interlace == 0: # progressive
                r_v_sync_trailing_prev = r_v_sync_trailing[1]
                h_sync_i_x = i
            elif field == 0: # first field of interlace
                r_v_sync_trailing_prev = r_v_sync_trailing[2]
                h_sync_i_x = i
            elif field == 1: # second field of interlace
                r_v_sync_trailing_prev = r_v_sync_trailing[2]
                h_sync_i_x = i-m_h_total/2
            # check position of v sync edge w.r.t h sync leading edge
            if h_sync_i != h_sync_i_x:
                print("at %d: bad v sync position w.r.t. h sync - found offset %d, expected %g" % (i,i-h_sync_i,i-h_sync_i_x)); err_i = i; stop=True; break
            # check/measure m_v_total
            if r_v_sync_trailing_prev != None:
                if m_v_total != -1:
                    if m_v_total != (i-r_v_sync_trailing_prev)/m_h_total:
                        print("at %d: expected v_total = %g found %g" % (i,m_v_total,(i-r_v_sync_trailing_prev)/m_h_total)); err_i = i; stop=True; break
                else:
                    m_v_total = (i-r_v_sync_trailing_prev)/m_h_total
                    if m_v_total != int(m_v_total):
                        print("at %d: expected integer v_total, found %g" % (i,m_v_total)); err_i = i; stop=True; break
            if r_v_sync_leading[0] != None:
                # check/measure m_v_sync
                x = (i-r_v_sync_leading[0])/m_h_total
                if m_v_sync != -1:
                    if m_v_sync != x:
                        print("at %d: expected v_sync = %g found %g" % (i,m_v_sync,x)); err_i = i; stop=True; break
                else:
                    m_v_sync = x
                    if m_v_sync != int(m_v_sync):
                        print("at %d: expected integer v_sync, found %g" % (i,m_v_sync)); err_i = i; stop=True; break
    m_v_front_porch = int(m_v_front_porch)
    m_v_sync = int(m_v_sync)
    m_v_back_porch = int(m_v_back_porch)
    m_v_active = int(m_v_active)
    m_v_blank = int(m_v_blank)
    m_v_total = int(m_v_total)
    if m_v_blank != m_v_front_porch+m_v_sync+m_v_back_porch:
        print("ERROR: v_blank != v_front_porch + v_sync + v_back_porch")
    if m_v_total != m_v_active+m_v_blank:
        print("ERROR: v_total != v_active + v_blank")

################################################################################
# report

print()
print("REPORT")
print("pixels analysed: %d" % n)
print("first valid pixel: %d" % m_start)
print("protocol is", m_protocol)
print()
print("horizontal timings:")
print("   sync polarity : %s" % ("high" if m_h_sync_pol == 1 else "low" if m_h_sync_pol == 0 else "???"))
print("     front porch : %d" % m_h_front_porch)
print("      sync width : %d" % m_h_sync)
print("      back porch : %d" % m_h_back_porch)
print("          active : %d" % m_h_active)
print("           blank : %d" % m_h_blank)
print("           total : %d" % m_h_total)
print()
print("vertical timings:")
print("            scan : %s" % ("interlace" if m_v_interlace == 1 else "progressive" if m_v_interlace == 0 else "???"))
print("   sync polarity : %s" % ("high" if m_v_sync_pol == 1 else "low" if m_v_sync_pol == 0 else "???"))
print("     front porch : %d" % m_v_front_porch)
print("      sync width : %d" % m_v_sync)
print("      back porch : %d" % m_v_back_porch)
print("          active : %d" % m_v_active)
print("           blank : %d" % m_v_blank)
print("           total : %d" % m_v_total)

# TODO:
# check consistency of field periods for interlace
# more HDMI rules e.g. check for extended control periods
# decode data and verify
# compare video timing with CTA spec

################################################################################
# error dump

if stop:
    print()
    print("         | ...ch 2... | ...ch 1... | ...ch 0... |  CTL   | H V |")
    for i in range(err_i-3000,err_i+3000): # TODO prevent starting index < 0
        print(f'{i:008d}',end=" | ")
        print(f'{tmds[2][i]:010b}',end=" | ")
        print(f'{tmds[1][i]:010b}',end=" | ")
        print(f'{tmds[0][i]:010b}',end=" | ")
        p = tmds_p[i]
        if p & PERIOD_CTRL:
            print(format(tmds_c[2][i],'#04b')[2:],end="")
            print(format(tmds_c[1][i],'#04b')[2:],end="")
            print(format(tmds_c[0][i],'#04b')[2:],end=" | ")
        else:
            print("......",end=" | ")
        print(tmds_sync[i] & 1,end=" ")
        print((tmds_sync[i] >> 1) & 1,end=" | ")
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
