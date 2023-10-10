GB_LEN = 2
PRE_LEN = 8
CTRL_PERIOD_LEN_MIN = 12
EXT_CTRL_PERIOD_LEN_MIN = 32
PACKET_LEN = 32 # correct length of data packet
PACKET_MAX = 18 # max consecutive data packet count
PACKET_TYPES = { \
    0x00: "Null",
    0x01: "Audio Clock Regeneration (N/CTS)",
    0x02: "Audio Sample",
    0x03: "General Control",
    0x04: "ACP",
    0x05: "ISRC1",
    0x06: "ISRC2",
    0x07: "One Bit Audio Sample",
    0x08: "DST",
    0x09: "HBR Audio Stream",
    0x0A: "Gamut Metadata",
    0x80: "InfoFrame",
    0x81: "Vendor Specific InfoFrame",
    0x82: "AVI InfoFrame",
    0x83: "Source Product Descriptor InfoFrame",
    0x84: "Audio InfoFrame",
    0x85: "MPEG Source InfoFrame"
}