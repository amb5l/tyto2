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
    0x81: "InfoFrame: Vendor Specific",
    0x82: "InfoFrame: Auxiliary Video Information (AVI)",
    0x83: "InfoFrame: Source Product Description",
    0x84: "InfoFrame: Audio",
    0x85: "InfoFrame: MPEG Source",
    0x86: "InfoFrame: NTSC VBI",
    0x87: "InfoFrame: Dynamic Range and Mastering"
}
