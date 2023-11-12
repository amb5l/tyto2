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
# TODO:
# get pixel clock frequency from h/w
# analysis progress bar
# output video to BMP
# output audio to WAV

# standard modules
import sys,os,argparse,struct,socket,array,time
from datetime import datetime

# local package
import spec

start_time = datetime.now()

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

group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-n',type=int,default=PIXELS,help='capture N pixels from hardware (default: %(default)s)')
group.add_argument('-i',metavar='filename',default=None,help='read raw TMDS data from specified file (default: %(default)s)')
group.add_argument('-r',metavar='filename',default=None,help='read decoded TMDS data from specified file (default: %(default)s)')
parser.add_argument('-o',metavar='filename',default=None,required=False,help='write raw TMDS data to specified file (default: %(default)s)')
parser.add_argument('-w',metavar='filename',default=None,help='write decoded TMDS data to specified file (default: %(default)s)')

args = parser.parse_args()
if args.o and not args.n:
   parser.error("Writing raw TMDS data is only supported when capturing from hardware (-n)")
if args.w and args.r:
   parser.error("Writing decoded TMDS data is not supported when reading decoded TMDS data")
n = args.n
infile_raw = args.i
outfile_raw = args.o
infile_dec = args.r
outfile_dec = args.w

################################################################################
# get TMDS data from infile_raw or hardware

BYTES_PER_PIXEL = 4

if infile_raw:
    # read raw TMDS data from file
    print("reading raw TMDS data from %s..." % infile_raw,end=" ")
    f = open(infile_raw, 'rb')
    nb = os.path.getsize(infile_raw)
    if nb % 4 != 0:
        print("size of %s is not a multiple of %d" % (infile_raw,BYTES_PER_PIXEL))
        sys.exit(1)
    tmds_bytes = memoryview(bytearray(nb))
    nr = f.readinto(tmds_bytes)
    f.close()
    if nb != nr:
        print("failed to read %s correctly (expected %d, read %d)" % (infile_raw,nb,nr))
        sys.exit(1)
    n = nb//BYTES_PER_PIXEL
    print("%d pixels read" % n)
elif not infile_dec:
    # read raw TMDS data from hardware
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
    tmds_bytes = memoryview(bytearray(n*BYTES_PER_PIXEL))
    i = 0
    while i < n*BYTES_PER_PIXEL:
        nr = s_tcp.recv_into(tmds_bytes[i:])
        if nr == 0:
            print("failed to read from hardware after %d bytes" % i)
            sys.exit(1)
    print("done (total time = %.2f seconds)" % (time.perf_counter()-t0))
    s_tcp.close()

if not infile_dec:

    # convert raw bytes to 32 bit TMDS triplets (3 x 10 bits)
    tmds_packed = tmds_bytes.cast('L')

    # write TMDS data to file if required
    if outfile_raw:
        print("writing raw TMDS data to %s..." % outfile_raw)
        with open(outfile_raw, 'wb') as f:
            for d in tmds_packed:
                f.write(struct.pack('<L',d))
        f.close()

    # separate channels from packed TMDS data
    print("separating TMDS channels")
    tmds = []
    for ch in range(3):
        tmds.append(array.array('h',n*[-1]))
    for i in range(n):
        l = tmds_packed[i]
        tmds[0][i] = l & 0x3FF
        l >>= 10
        tmds[1][i] = l & 0x3FF
        l >>= 10
        tmds[2][i] = l & 0x3FF

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
# utility functions

def int2vec(x,n):
    return [(x >> i) & 1 for i in range(n)]

def vec2int(v):
    r = 0
    for i in range(len(v)):
        r |= v[i] << i
    return r

def xor_vec(v):
    r = 0
    for bit in v:
        r ^= bit
    return r

def xor_byte(b):
    r = 0
    for i in range(8):
        r = r ^ (b >> i)
    return r & 1

def or_list(l):
    r = 0
    for e in l:
        r |= e
    return r

def bch_ecc(bytes):
    q = int2vec(0,8);
    n = q[:]
    for byte in bytes:
        d = int2vec(byte,8)
        # see hdmi_bch_ecc.py
        n[0] = xor_vec([d[0],d[1],d[2],d[4],d[5],d[7],q[0],q[1],q[2],q[4],q[5],q[7]])
        n[1] = xor_vec([d[3],d[4],d[6],d[7],q[3],q[4],q[6],q[7]])
        n[2] = xor_vec([d[1],d[2],q[1],q[2]])
        n[3] = xor_vec([d[0],d[2],d[3],q[0],q[2],q[3]])
        n[4] = xor_vec([d[0],d[1],d[3],d[4],q[0],q[1],q[3],q[4]])
        n[5] = xor_vec([d[1],d[2],d[4],d[5],q[1],q[2],q[4],q[5]])
        n[6] = xor_vec([d[0],d[2],d[3],d[5],d[6],q[0],q[2],q[3],q[5],q[6]])
        n[7] = xor_vec([d[0],d[1],d[3],d[4],d[6],d[7],q[0],q[1],q[3],q[4],q[6],q[7]])
        q = n[:]
    return vec2int(q)

def print_hex_list(bytes,end="\r\n"):
    for byte in bytes[:-1]:
        print("%02X" % byte,end=" ")
    print("%02X" % bytes[-1],end=end)

def type_key(s):
    return list(spec.hdmi.PACKET_TYPES.keys())[list(spec.hdmi.PACKET_TYPES.values()).index(s)]

def bit_field(v,msb,lsb):
    return (v >> lsb) & ((2**((msb-lsb)+1))-1)

################################################################################
# data packet related

# data island packet class
# TODO: remove unused functions
class packet():
    def __init__(self):
        self.i = 0 # index (pixel position)
        self.raw = memoryview(bytearray(36))
        self.bch_blocks = [self.raw[0:8],self.raw[8:16],self.raw[16:24],self.raw[24:32],self.raw[32:36]]
        self.hb,self.sb = self.bch_blocks[4],self.bch_blocks[:4]
        self.hb_body,self.sb_body = self.hb[:3],[self.sb[0][:7],self.sb[1][:7],self.sb[2][:7],self.sb[3][:7]]
        self.hb_ecc,self.sb_ecc = self.hb[3:],[self.sb[0][7:],self.sb[1][7:],self.sb[2][7:],self.sb[3][7:]]
        self.notes = []
    def get_raw(self):
        return self.raw.tolist()
    def get_hb(self):
        return self.hb.tolist()
    def get_sb(self):
        return [i.tolist() for i in self.sb]
    def get_pb(self):
        return [i for s in self.get_sb_body() for i in s]
    def get_hb_body(self):
        return self.hb_body.tolist()
    def get_sb_body(self):
        return [i.tolist() for i in self.sb_body]
    def get_hb_ecc(self):
        return self.hb_ecc.tolist()[0]
    def get_sb_ecc(self):
        return [i.tolist()[0] for i in self.sb_ecc]
    def set_raw(self,bytes):
        self.raw[:] = memoryview(bytearray(bytes))
    def set_hb(self,bytes):
        self.hb[:] = memoryview(bytearray(bytes))
    def set_sb(self,i,bytes):
        self.sb[i][:] = memoryview(bytearray(bytes))

# IEC 60958 channel status block
class iec60958_csb():
    def __init__(self):      self.raw = memoryview(bytearray(24))
    def set_raw(self,bytes): self.raw[:] = memoryview(bytearray(bytes))
    def get_raw(self):       return self.raw.tolist()
    def get_raw_a(self):     return bit_field(self.raw[0],0,0)
    def get_raw_b(self):     return bit_field(self.raw[0],1,1)
    def get_raw_c(self):     return bit_field(self.raw[0],2,2)
    def get_raw_d(self):     return bit_field(self.raw[0],5,3)
    def get_raw_mode(self):  return bit_field(self.raw[0],7,6)
    def get_raw_cat(self):   return self.raw[1]
    def get_raw_src(self):   return bit_field(self.raw[2],3,0)
    def get_raw_chan(self):  return bit_field(self.raw[2],7,4)
    def get_raw_fs(self):    return bit_field(self.raw[3],3,0)
    def get_raw_acc(self):   return bit_field(self.raw[3],5,4)
    def get_raw_wmax(self):  return bit_field(self.raw[4],0,0)
    def get_raw_wlen(self):  return bit_field(self.raw[4],3,1)
    def get_raw_fso(self):   return bit_field(self.raw[4],7,4)

    def get_a(self): return "consumer" if self.get_raw_a() == 0 else "professional"
    def get_b(self): return "linear PCM" if self.get_raw_b() == 0 else "other"
    def get_c(self): return "copyright" if self.get_raw_c() == 0 else "no copyright"
    def get_d(self):
        match self.get_raw_d():
            case 0b000: return "2 audio channels without pre-emphasis"
            case 0b001: return "2 audio channels with 50us/15us pre-emphasis"
            case 0b010: return "reserved (for 2 audio channels with pre-emphasis)"
            case 0b011: return "reserved (for 2 audio channels with pre-emphasis)"
            case 0b100: return "reserved (0b100)"
            case 0b101: return "reserved (0b101)"
            case 0b110: return "reserved (0b110)"
            case 0b111: return "reserved (0b111)"
    def get_mode(self): return "mode 0" if self.get_raw_mode() == 0 else "unsupported mode"
    def get_cat(self):  return self.raw[1]
    def get_src(self):
        if self.get_raw_src() == 0:
            return "do not take into account"
        else:
            return "%d" % self.get_raw_src()
    def get_chan(self):
        if self.get_raw_chan() == 0:
            return "do not take into account"
        elif self.get_raw_chan() == 1:
            return "1 (stereo left)"
        elif self.get_raw_chan() == 2:
            return "2 (stereo right)"
        else:
            return "%d" % self.get_raw_chan()
    def get_fs(self):
        match self.get_raw_fs():
            case 0b0000: return "44.1 kHz"
            case 0b0001: return "reserved (0001)"
            case 0b0010: return "48 kHz"
            case 0b0011: return "32 kHz"
            case 0b0100: return "22.05 kHz"
            case 0b0101: return "reserved (0101)"
            case 0b0110: return "24 kHz"
            case 0b0111: return "reserved (0111)"
            case 0b1000: return "88.2 kHz"
            case 0b1001: return "reserved (1001)"
            case 0b1010: return "96 kHz"
            case 0b1011: return "reserved (1011)"
            case 0b1100: return "176.4 kHz"
            case 0b1101: return "reserved (1101)"
            case 0b1110: return "192 kHz"
            case 0b1111: return "reserved (1111)"
    def get_acc(self):
        match self.get_raw_acc():
            case 0b00: return "level II"
            case 0b01: return "level I"
            case 0b10: return "level III"
            case 0b11: return "frame rate not matched to sample frequency"
    def get_wmax(self): return "20 bits" if self.get_raw_wmax() == 0 else "24 bits"
    def get_wlen(self):
        match self.get_raw_wlen():
            case 0b000: return "word length not indicated"
            case 0b001: return "16 bits" if self.get_raw_wmax() == 0 else "20 bits"
            case 0b010: return "18 bits" if self.get_raw_wmax() == 0 else "22 bits"
            case 0b011: return "reserved (011)"
            case 0b100: return "19 bits" if self.get_raw_wmax() == 0 else "23 bits"
            case 0b101: return "20 bits" if self.get_raw_wmax() == 0 else "24 bits"
            case 0b110: return "17 bits" if self.get_raw_wmax() == 0 else "21 bits"
            case 0b111: return "reserved (111)"
    def get_fso(self):
        match self.get_raw_fso():
            case 0b1111: return "44.1 kHz"
            case 0b0111: return "88.2 kHz"
            case 0b1011: return "22.05 kHz"
            case 0b0011: return "176.4 kHz"
            case 0b1101: return "48 kHz"
            case 0b0101: return "96 kHz"
            case 0b1001: return "24 kHz"
            case 0b0001: return "192 kHz"
            case 0b1110: return "reserved (1110)"
            case 0b0110: return "8 kHz"
            case 0b1010: return "11.025 kHz"
            case 0b0010: return "12 kHz"
            case 0b1100: return "32 kHz"
            case 0b0100: return "reserved (0100)"
            case 0b1000: return "16 kHz"
            case 0b0000: return "not indicated"

packet_dict = {} # dictionary of packet lists, keyed by type code
iec60958_subframe = array.array('B', 4*[0])
iec60958_cs_raw = [] # raw channel status data (for 8 channels)
iec60958_cs_raw_tmp = [] # raw CSB work in progress (for 8 channels)
iec60958_cs = [] # processed channel status data
for i in range(8):
    iec60958_cs_raw.append([])
    iec60958_cs_raw_tmp.append(array.array('b'))
    iec60958_cs.append([])

################################################################################
# decode (tmds[] => tmds_p, tmds_c, tmds_sync)

stop = False

if not infile_dec:

    print("preliminary period detection per channel")
    for ch in range(3):
        for i in range(n):
            p = PERIOD_UNKNOWN
            if tmds[ch][i] in spec.tmds.ctrl:
                p |= PERIOD_CTRL
                tmds_c[ch][i] = spec.tmds.ctrl.index(tmds[ch][i])
                if ch > 0:
                    if tmds_c[ch][i] > 0:
                        m_protocol = 'HDMI'
            if tmds[ch][i] == spec.tmds.video_gb[ch]:
                p |= PERIOD_VIDEO_GB
            if spec.tmds.video[tmds[ch][i]] != -1:
                p |= PERIOD_VIDEO
            if ch == 0:
                if tmds[ch][i] in spec.tmds.terc4:
                    p |= PERIOD_DATA
            else:
                if tmds[ch][i] == spec.tmds.data_gb:
                    p |= PERIOD_DATA_GB_LEADING | PERIOD_DATA_GB_TRAILING
                if tmds[ch][i] in spec.tmds.terc4:
                    p |= PERIOD_DATA
            if p == 0:
                print("error: illegal TMDS character (offset %d, channel %d)" % (i,ch)); stop = True; break
            tmds_ch_p[ch][i] = p

    if not stop:
        print("resolve control periods")
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
                if p_count > 0 and p_count < spec.hdmi.CTRL_PERIOD_LEN_MIN:
                    print("error: control period too short (offset %d)" % i); stop = True; break
                p_count = 0

    if not stop:
        print("detect preambles")
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
        print("check preambles and detect data islands")
        p_count = 0
        p_type = ''
        for i in range(n):
            cp = [tmds_ch_p[0][i],tmds_ch_p[1][i],tmds_ch_p[2][i]] # channel periods
            p = tmds_p[i]
            if p_type == 'video_pre':
                if p & PERIOD_VIDEO_PRE:
                    p_count += 1
                else:
                    if p_count != spec.hdmi.PRE_LEN:
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
                    if p_count != spec.hdmi.GB_LEN:
                        print("error: bad video guardband length (offset %d, length %d)" % (i,p_count)); stop = True; break
                    p_type = ''
                    p_count = 0
            elif p_type == 'data_pre':
                if p & PERIOD_DATA_PRE:
                    p_count += 1
                else:
                    if p_count != spec.hdmi.PRE_LEN:
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
                    if p_count != spec.hdmi.GB_LEN:
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
                    if p_count % spec.hdmi.PACKET_LEN != 0:
                        print("error: non-integer multiple of data packets (offset %d, data length %d)" % (i,p_count)); stop = True; break
                    elif (p_count // spec.hdmi.PACKET_LEN) > spec.hdmi.PACKET_MAX:
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
                    if p_count != spec.hdmi.GB_LEN:
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
        print("detect video periods")
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
        print("resolve syncs")
        sync = -1
        for i in range(n):
            p = tmds_p[i]
            if p & PERIOD_CTRL:
                sync = tmds_c[0][i]
            elif p & (PERIOD_DATA | PERIOD_DATA_GB_LEADING | PERIOD_DATA_GB_TRAILING):
                sync = spec.tmds.terc4.index(tmds[0][i]) & 3
            tmds_sync[i] = sync

    # write decoded data to file
    if outfile_dec:
        print("writing decoded TMDS data to %s..." % outfile_dec,end=" ")
        f = open(outfile_dec, 'wb')
        f.write(struct.pack('I', n))
        f.write(struct.pack('I', m_start))
        f.write(struct.pack('I', 1 if m_protocol == 'HDMI' else 0))
        for i in range(3):
            tmds[i].tofile(f)
            tmds_ch_p[i].tofile(f)
            tmds_c[i].tofile(f)
        tmds_p.tofile(f)
        tmds_sync.tofile(f)
        print("%d pixels written" % n)

else: # read decoded data from file
    print("reading decoded TMDS data from %s..." % infile_dec,end=" ")
    f = open(infile_dec, 'rb')
    n = struct.unpack('I', f.read(4))[0]
    m_start = struct.unpack('I', f.read(4))[0]
    m_protocol = struct.unpack('I', f.read(4))[0]
    m_protocol = 'HDMI' if m_protocol == 1 else 'DVI'
    tmds = []
    tmds_ch_p = []
    tmds_c = []
    tmds_p = array.array('B')
    tmds_sync = array.array('b')
    for i in range(3):
        tmds.append(array.array('h'))
        tmds_ch_p.append(array.array('B'))
        tmds_c.append(array.array('b'))
        tmds[i].fromfile(f,n)
        tmds_ch_p[i].fromfile(f,n)
        tmds_c[i].fromfile(f,n)
    tmds_p.fromfile(f,n)
    tmds_sync.fromfile(f,n)
    print("%d pixels read" % n)

################################################################################
# analysis

err_i = 0

if not stop:
    print("detect horizontal video timing")
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
    print("detect vertical video timing")
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

if not stop and m_protocol == "HDMI":
    print("extract data island packets")
    i = m_start
    while i < n:
        p = tmds_p[i]
        if p & PERIOD_DATA:
            if n-i >= spec.hdmi.PACKET_LEN: # complete packet available
                d = packet()
                d.i = i
                for j in range(32):
                    # 4 bit data word per channel
                    a = int2vec(spec.tmds.terc4.index(tmds[0][i+j]),4)
                    b = int2vec(spec.tmds.terc4.index(tmds[1][i+j]),4)
                    c = int2vec(spec.tmds.terc4.index(tmds[2][i+j]),4)
                    # fill subpackets 0..3
                    byte = j >> 2 # 0..7
                    bit = (j & 3) << 1
                    for k in range(4):
                        d.sb[k][byte] |= (b[k] << bit)
                        d.sb[k][byte] |= (c[k] << (bit+1))
                    # fill header
                    byte = j >> 3 # 0..3
                    bit = j & 7
                    d.hb[byte] |= (a[2] << bit)
                # store packet
                if d.hb[0] in packet_dict:
                    packet_dict[d.hb[0]].append(d)
                else:
                    packet_dict[d.hb[0]] = [d]
                i += spec.hdmi.PACKET_LEN
            else: # no more complete packets
                i = n # so halt
        else:
            i += 1

if not stop and m_protocol == "HDMI":
    print("check data island packet ECC")
    for _,packet_list in packet_dict.items():
        for d in packet_list:
            if bch_ecc(d.get_hb_body()) != d.get_hb_ecc() \
            or bch_ecc(d.get_sb_body()[0]) != d.get_sb_ecc()[0] \
            or bch_ecc(d.get_sb_body()[1]) != d.get_sb_ecc()[1] \
            or bch_ecc(d.get_sb_body()[2]) != d.get_sb_ecc()[2] \
            or bch_ecc(d.get_sb_body()[3]) != d.get_sb_ecc()[3]:
                print("packet %d: bad ECC" % i)
                print_hex_list(d.get_raw())
                print(d.get_hb_body(),d.get_hb_ecc(),bch_ecc(d.get_hb_body()))
                print(d.get_sb_body()[0],d.get_sb_ecc()[0],bch_ecc(d.get_sb_body()[0]))
                print(d.get_sb_body()[1],d.get_sb_ecc()[0],bch_ecc(d.get_sb_body()[1]))
                print(d.get_sb_body()[2],d.get_sb_ecc()[0],bch_ecc(d.get_sb_body()[2]))
                print(d.get_sb_body()[3],d.get_sb_ecc()[0],bch_ecc(d.get_sb_body()[3]))
                stop = True
                break

if not stop and m_protocol == "HDMI":
    print("decoding and checking data island packets")
    for packet_type_code,packet_list in packet_dict.items():
        if stop:
            break;
        for d in packet_list:
            if stop:
                break;
            hb = d.get_hb(); sb = d.get_sb(); pb = d.get_pb()
            if packet_type_code != hb[0]:
                print("inconceivable!"); stop = True; break
            if packet_type_code in spec.hdmi.PACKET_TYPES:
                packet_type = spec.hdmi.PACKET_TYPES[packet_type_code]
            else:
                print("at %d: unknown packet type (0x%02X)" % (d.i,packet_type_code)); stop = True; break
            ################################################################################
            if packet_type == "Null":
                # RULE: all bytes must be zero
                if sum(d.raw) != 0:
                    print("at %d: non zero content in null packet" % d.i); stop = True; break
            ################################################################################
            elif packet_type == "Audio Clock Regeneration (N/CTS)":
                pass
            ################################################################################
            elif packet_type == "Audio Sample":
                # RULE: 3 MSBs of HB1 must be zero
                if hb[1] & 0xE0:
                    print("Audio Sample Packet at %d: InfoFrame HB1 MSBs set (0x02X)" % (d.i,hb[1])); stop = True; break
                # extract fields
                SP     = bit_field(hb[1],3,0)
                LAYOUT = bit_field(hb[1],4,4)
                SF     = bit_field(hb[2],3,0)
                B      = bit_field(hb[2],7,4)
                if LAYOUT == 0:
                    if SP != 0 and SP != 1 and SP != 3 and SP != 7 and SP != 15:
                        print("Audio Sample Packet at %d: bad sample present value (%s)" % (d.i,"{:04b}".format(SP))); stop = True; break
                if B != 0 and B != 1 and B != 2 and B != 4 and B != 8:
                    print("Audio Sample Packet at %d: bad B value (%s)" % (d.i,"{:04b}".format(B))); stop = True; break
                # process 4 subpackets, each containing a sample pair
                for spn in range(4):
                    if SP & (1<<spn): # if sample (pair) is present
                        # do both members of the sample pair
                        for spm in range(2):
                            ch = spm if LAYOUT == 0 else (spn*4)+spm
                            # build 28 bit subframe word
                            iec60958_subframe[0] = sb[spn][   spm*3 ]
                            iec60958_subframe[1] = sb[spn][1+(spm*3)]
                            iec60958_subframe[2] = sb[spn][2+(spm*3)]
                            iec60958_subframe[3] = (sb[spn][6] >> (spm*4)) & 0xF
                            # check parity
                            par = 0
                            for i in range(4):
                                par = par ^ xor_byte(iec60958_subframe[i])
                            if par != 0:
                                print("Audio Sample Packet at %d: bad parity in channel %d, subpacket %d" % (d.i,spm,spn)); stop = True; break
                            # build raw IEC 60958 channel status blocks
                            C = bit_field(iec60958_subframe[3],2,2)
                            if B & (1<<spn):
                                iec60958_cs_raw_tmp[ch] = array.array('b',[C])
                            elif len(iec60958_cs_raw_tmp[ch]):
                                iec60958_cs_raw_tmp[ch].append(C)
                                if len(iec60958_cs_raw_tmp[ch]) == 192:
                                    iec60958_cs_raw[ch].append(iec60958_cs_raw_tmp[ch])
                # TODO: extract user data messages

            ################################################################################
            elif packet_type == "General Control":
                pass
            ################################################################################
            elif packet_type == "ACP":
                pass
            ################################################################################
            elif packet_type == "ISRC1":
                pass
            ################################################################################
            elif packet_type == "ISRC2":
                pass
            ################################################################################
            elif packet_type == "One Bit Audio Sample":
                pass
            ################################################################################
            elif packet_type == "DST":
                pass
            ################################################################################
            elif packet_type == "HBR Audio Stream":
                pass
            ################################################################################
            elif packet_type == "Gamut Metadata":
                pass
            ################################################################################
            elif packet_type[:9] == "InfoFrame":
                infoframe_version = hb[1]
                infoframe_length = hb[2] & 0x1F
                # RULE: HB2 bits 7..5 must be zero
                if hb[2] & 0xE0:
                    print("at %d: InfoFrame HB2 MSBs set (0x02X)" % (d.i,hb[2])); stop = True; break
                # RULE: checksum must be good
                if sum(hb[:3]+pb[:1+infoframe_length]) & 0xFF != 0:
                    print("at %d: bad InfoFrame checksum" % d.i); stop = True; break
                ################################################################################
                if   packet_type == "InfoFrame: Vendor Specific":
                    pass
                    #TODO HDMI vendor specific
                ################################################################################
                elif packet_type == "InfoFrame: Auxiliary Video Information (AVI)":
                    # RULE: length = 13
                    if infoframe_length != 13:
                        print("at %d: bad length (0x%02X) for AVI InfoFrame" % (d.i,infoframe_length)); stop = True; break
                ################################################################################
                elif packet_type == "InfoFrame: Source Product Description":
                    # RULE: length = 25
                    if infoframe_length != 25:
                        print("at %d: bad length (0x%02X) for SPD InfoFrame" % (d.i,infoframe_length)); stop = True; break
                    # RULE: vendor name and product description use 7-bit ASCII code
                    if or_list(pb[1:25]) & 0x80:
                        print("at %d: non-ASCII character(s) in SPD InfoFrame" % i); stop = True; break
                    vendor_name = ''.join(map(chr,pb[1:9]))
                    product_description = ''.join(map(chr,pb[9:25]))
                    source_information_code = pb[25]
                    if source_information_code in spec.cta861.SPD_SOURCE_INFO:
                        source_information = spec.cta861.SPD_SOURCE_INFO[source_information_code]
                    else:
                        source_information = "reserved (0x%02X)" % source_information_code
                    d.notes.append("Vendor Name = %s, Product Description = %s, Source Information = %s" % (vendor_name,product_description,source_information))
                ################################################################################
                elif packet_type == "InfoFrame: Audio":
                    # RULE: length = 10
                    if infoframe_length != 10:
                        print("at %d: bad length (0x%02X) for Audio InfoFrame" % (d.i,infoframe_length)); stop = True; break
                    # extract fields
                    CC     = bit_field(pb[ 1],2,0)
                    F1     = bit_field(pb[ 1],3,3)
                    CT     = bit_field(pb[ 1],7,4)
                    SS     = bit_field(pb[ 2],1,0)
                    SF     = bit_field(pb[ 2],4,2)
                    F2     = bit_field(pb[ 2],7,5)
                    CXT    = bit_field(pb[ 3],4,0)
                    F3     = bit_field(pb[ 3],7,5)
                    CA     = bit_field(pb[ 4],7,0)
                    LFEPBL = bit_field(pb[ 5],1,0)
                    F5     = bit_field(pb[ 5],2,2)
                    LSV    = bit_field(pb[ 5],6,3)
                    DM_INH = bit_field(pb[ 5],7,7)
                    F6     = bit_field(pb[ 6],7,0)
                    F7     = bit_field(pb[ 7],7,0)
                    F8     = bit_field(pb[ 8],7,0)
                    F9     = bit_field(pb[ 9],7,0)
                    F10    = bit_field(pb[10],7,0)
                    # CC[2:0] = channel count minus one; 000 = refer to stream header
                    if CC == 0:
                        d.notes.append("channel count: refer to stream header" % CC)
                    else:
                        d.notes.append("channel count: %d" % (CC+1))
                    # F1 must equal 0
                    if F1 != 0:
                        d.notes.append("F1: 1 (ILLEGAL)")
                        stop = True
                    # CT[3:0] must equal 0000 (refer to stream header)
                    s = "coding type: " + spec.cta861.AUDIO_CT[CT]
                    if CT != 0:
                        s += " (ILLEGAL FOR HDMI)"
                        stop = True
                    d.notes.append(s)
                    # SS[1:0] must equal 00 (refer to stream header)
                    s = "sample size: " + spec.cta861.AUDIO_SS[SS]
                    if SS != 0:
                        s += " (ILLEGAL FOR HDMI)"
                        stop = True
                    d.notes.append(s)
                    # SF[2:0] = sample frequency
                    d.notes.append("sample frequency: %s" % spec.cta861.AUDIO_SF[SF])
                    # TODO: SF should be zero for L-PCM or IEC 61937
                    # F2 must equal 0
                    if F2 != 0:
                        d.notes.append("F2: 0b%s (ILLEGAL)" % format(F2,'03b'))
                        stop = True
                    # CXT must equal 0
                    s = "coding extension type: " + spec.cta861.AUDIO_CXT[CXT]
                    if CXT != 0:
                        s += " (ILLEGAL FOR HDMI)"
                        stop = True
                    d.notes.append(s)
                    # F3 must equal 0
                    if F3 != 0:
                        d.notes.append("F3: 0b%s (ILLEGAL)" % format(F3,'03b'))
                        stop = True
                    # TODO: CA not valid for IEC 61937
                    if CA < len(spec.cta861.AUDIO_CA):
                        s = "channel assignment: " + spec.cta861.AUDIO_CA[CA]
                    elif CA == 0xFE:
                        s = "delivery according to speaker mask"
                    elif CA == 0xFF:
                        s = "delivery by channel index"
                    else:
                        s = "reserved (ILLEGAL)"
                        stop = True
                    d.notes.append(s)
                    # LFEPBL
                    s = "LFE playback level: " + spec.cta861.AUDIO_LFEPBL[LFEPBL]
                    if LFEPBL == 3:
                        s += " (ILLEGAL)"
                        stop = True
                    d.notes.append(s)
                    # F5 must equal 0
                    if F5 != 0:
                        d.notes.append("F5: %d (ILLEGAL)" % F5)
                        stop = True
                    # LSV
                    d.notes.append("level shift value: %ddB" % LSV)
                    # DM_INH
                    d.notes.append("downmix: " + "permitted" if DM_INH == 0 else "prohibited")
                    # F6 must equal 0
                    if F6 != 0:
                        d.notes.append("F6: 0b%s (ILLEGAL)" % format(F6,'08b'))
                        stop = True
                    # F7 must equal 0
                    if F7 != 0:
                        d.notes.append("F7: 0b%s (ILLEGAL)" % format(F7,'08b'))
                        stop = True
                    # F8 must equal 0
                    if F8 != 0:
                        d.notes.append("F8: 0b%s (ILLEGAL)" % format(F8,'08b'))
                        stop = True
                    # F9 must equal 0
                    if F9 != 0:
                        d.notes.append("F9: 0b%s (ILLEGAL)" % format(F9,'08b'))
                        stop = True
                    # F10 must equal 0
                    if F10 != 0:
                        d.notes.append("F10: 0b%s (ILLEGAL)" % format(F10,'08b'))
                        stop = True
                    if stop:
                        print("AUDIO INFOFRAME: ERRORS ENCOUNTERED")
                ################################################################################
                elif packet_type == "InfoFrame: MPEG Source":
                    pass
                ################################################################################
                elif packet_type == "InfoFrame: NTSC VBI":
                    pass
                ################################################################################
                elif packet_type == "InfoFrame: Dynamic Range and Mastering":
                    pass
                ################################################################################
                else:
                    print("inconceivable!"); stop = True; break
            ################################################################################
            else:
                print("inconceivable!"); stop = True; break

    if not stop:
        print("processing raw IEC 60958 channel status blocks")
        for ch in range(len(iec60958_cs_raw)):
            for raw_block in iec60958_cs_raw[ch]:
                csb = iec60958_csb()
                csb.set_raw([vec2int(raw_block[i*8:8+(i*8)]) for i in range(24)])
                iec60958_cs[ch].append(csb)

    if not stop:
        ptype = type_key("InfoFrame: Auxiliary Video Information (AVI)")
        if ptype in packet_dict:
            packet_list = packet_dict[ptype]
            if len(packet_list) > 1:
                print("checking consistency of %d AVI InfoFrames... " % len(packet_list),end="")
                if not all(x.raw==packet_list[0].raw for x in packet_list):
                    print("differences found:")
                    for p in packet_list:
                        print("  %s" % p.notes[0])
                else:
                    print("OK")

    if not stop:
        type_key("InfoFrame: Audio")
        if ptype in packet_dict:
            packet_list = packet_dict[ptype]
            if len(packet_list) > 1:
                print("checking consistency of %d Audio InfoFrames... " % len(packet_list),end="")
                if not all(x.raw==packet_list[0].raw for x in packet_list):
                    print("differences found")
                else:
                    print("OK")

    if not stop:
        ptype = type_key("InfoFrame: Source Product Description")
        if ptype in packet_dict:
            packet_list = packet_dict[ptype]
            if len(packet_list) > 1:
                print("checking consistency of %d SPD InfoFrames... " % len(packet_list),end="")
                if not all(x.raw==packet_list[0].raw for x in packet_list):
                    print("differences found:")
                    for p in packet_list:
                        print("  %s" % p.notes[0])
                else:
                    print("OK")

    if not stop:
        print("checking consistency of IEC 60958 channel status blocks:")
        for ch in range(len(iec60958_cs)):
            print("  channel %d: %d CSBs ... " % (ch,len(iec60958_cs_raw[ch])),end=" ")
            if len(iec60958_cs[ch]) >= 2:
                if not all(x.get_raw()==iec60958_cs[ch][0].get_raw() for x in iec60958_cs[ch]):
                    print("differences found:")
                    for csb in iec60958_cs[ch]:
                        print("    "+" ".join(["%02X" % x for x in csb.get_raw()]))
                else:
                    print("OK")
            else:
                print("N/A")

    print("checking consistency of Audio Sample Packets with Audio InfoFrames (SP)")
    print("NOT YET DONE")

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
print()
print("data packet types and counts:")
for t,l in packet_dict.items():
    if t in spec.hdmi.PACKET_TYPES:
        desc = spec.hdmi.PACKET_TYPES[t]
    else:
        desc = t
    print("%50s : %d" % (desc,len(l)))

ptype = type_key("InfoFrame: Source Product Description")
if ptype in packet_dict:
    d = packet_dict[ptype][0]
    print()
    print("first Source Product Description decoded:")
    for n in d.notes:
        print(n)

ptype = type_key("InfoFrame: Audio")
if ptype in packet_dict:
    d = packet_dict[ptype][0]
    print()
    print("first Audio InfoFrame decoded:")
    for n in d.notes:
        print(n)
    print()

print("first CSB:")
csb = iec60958_cs[0][0]
print("                            a = %s" % csb.get_a())
print("                            b = %s" % csb.get_b())
print("                            c = %s" % csb.get_c())
print("                            d = %s" % csb.get_d())
print("                category code = %s" % csb.get_cat())
print("                source number = %s" % csb.get_src())
print("               channel number = %s" % csb.get_chan())
print("           sampling frequency = %s" % csb.get_fs())
print("               clock accuracy = %s" % csb.get_acc())
print("              word max length = %s" % csb.get_wmax())
print("                  word length = %s" % csb.get_wlen())
print("  original sampling frequency = %s" % csb.get_fso())


# TODO:
# check consistency of field periods for interlace
# more HDMI rules e.g. check for extended control periods
# compare video timing with CTA spec

################################################################################
# error dump

if stop and err_i:
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

elapsed = datetime.now()-start_time
print()
print("elapsed time =",elapsed)