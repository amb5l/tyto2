INFOFRAME_TYPES = {
    1: "Vendor Specific",
    2: "Auxiliary Video Information (AVI)",
    3: "Source Product Description",
    4: "Audio",
    5: "MPEG Source",
    6: "NTSC VBI",
    7: "Dynamic Range and Mastering"
}
SPD_SOURCE_INFO = {
    0x00: "unknown",
    0x01: "Digital STB",
    0x02: "DVD player",
    0x03: "D-VHS",
    0x04: "HDD Videorecorder",
    0x05: "DVC",
    0x06: "DSC",
    0x07: "Video CD",
    0x08: "Game",
    0x09: "PC general",
    0x0A: "Blu-Ray Disc (BD)",
    0x0B: "Super Audio CD",
    0x0C: "HD DVD",
    0x0D: "PMP"
}
AUDIO_CT = [
    "refer to stream header",
    "L-PCM",
    "AC-3",
    "MPEG-1",
    "MP3",
    "MPEG2",
    "AAC LC",
    "DTS",
    "ATRAC",
    "One Bit Audio",
    "Enhanced AC-3",
    "DTS-HD",
    "MAT",
    "DST",
    "WMA Pro",
    "refer to CXT"
]
AUDIO_SS = [
    "refer to stream header",
    "16 bit",
    "20 bit",
    "24 bit"
]
AUDIO_SF = [
    "refer to stream header",
    "32kHz",
    "44.1kHz (CD)",
    "48kHz",
    "88.3kHz",
    "96kHz",
    "176.4kHz",
    "192kHz"
]
AUDIO_CXT = [
    "refer to CT",
    "not in use",
    "not in use",
    "not in use",
    "MPEG-4 HE AAC",
    "MPEG-4 HE AAC v2",
    "MPEG-4 AAC LC",
    "DRA",
    "",
    "reserved",
    "",
    "",
    "",
    "",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved",
    "reserved"
]
AUDIO_CA = [
    "1=FL,2=FR",                                     # 0x00
    "1=FL,2=FR,3=LFE1",                              # 0x01
    "1=FL,2=FR,4=FC",                                # 0x02
    "1=FL,2=FR,3=LFE1,4=FC",                         # 0x03
    "1=FL,2=FR,5=BC",                                # 0x04
    "1=FL,2=FR,3=LFE1,5=BC",                         # 0x05
    "1=FL,2=FR,4=FC,5=BC",                           # 0x06
    "1=FL,2=FR,3=LFE1,4=FC,5=BC",                    # 0x07
    "1=FL,2=FR,5=LS,6=RS",                           # 0x08
    "1=FL,2=FR,3=LFE1,5=LS,6=RS",                    # 0x09
    "1=FL,2=FR,4=FC,5=LS,6=RS",                      # 0x0A
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS",               # 0x0B
    "1=FL,2=FR,5=LS,6=RS,7=BC",                      # 0x0C
    "1=FL,2=FR,3=LFE1,5=LS,6=RS,7=BC",               # 0x0D
    "1=FL,2=FR,4=FC,5=LS,6=RS,7=BC",                 # 0x0E
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,7=BC",          # 0x0F
    "1=FL,2=FR,5=LS,6=RS,7=RLC,8=RRC",               # 0x10
    "1=FL,2=FR,3=LFE1,5=LS,6=RS,7=RLC,8=RRC",        # 0x11
    "1=FL,2=FR,4=FC,5=LS,6=RS,7=RLC,8=RRC",          # 0x12
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,7=RLC,8=RRC",   # 0x13
    "1=FL,2=FR,7=FLC,8=FRC",                         # 0x14
    "1=FL,2=FR,3=LFE1,7=FLC,8=FRC",                  # 0x15
    "1=FL,2=FR,4=FC,7=FLC,8=FRC",                    # 0x16
    "1=FL,2=FR,3=LFE1,4=FC,7=FLC,8=FRC",             # 0x17
    "1=FL,2=FR,5=BC,7=FLC,8=FRC",                    # 0x18
    "1=FL,2=FR,3=LFE1,5=BC,7=FLC,8=FRC",             # 0x19
    "1=FL,2=FR,4=FC,5=BC,7=FLC,8=FRC",               # 0x1A
    "1=FL,2=FR,3=LFE1,4=FC,5=BC,7=FLC,8=FRC",        # 0x1B
    "1=FL,2=FR,5=LS,6=RS,7=FLC,8=FRC",               # 0x1C
    "1=FL,2=FR,3=LFE1,5=LS,6=RS,7=FLC,8=FRC",        # 0x1D
    "1=FL,2=FR,4=FC,5=LS,6=RS,7=FLC,8=FRC",          # 0x1E
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,7=FLC,8=FRC",   # 0x1F
    "1=FL,2=FR,4=FC,5=LS,6=RS,7=TpFC",               # 0x20
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,7=TpFC",        # 0x21
    "1=FL,2=FR,4=FC,5=LS,6=RS,8=TpC",                # 0x22
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,8=TpC",         # 0x23
    "1=FL,2=FR,5=LS,6=RS,7=TpFL,8=TpFR",             # 0x24
    "1=FL,2=FR,3=LFE1,5=LS,6=RS,7=TpFL,8=TpFR",      # 0x25
    "1=FL,2=FR,5=LS,6=RS,7=FLW,8=FRW",               # 0x26
    "1=FL,2=FR,3=LFE1,5=LS,6=RS,7=FLW,8=FRW",        # 0x27
    "1=FL,2=FR,4=FC,5=LS,6=RS,7=BC,8=TpC",           # 0x28
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,7=BC,8=TpC",    # 0x29
    "1=FL,2=FR,4=FC,5=LS,6=RS,7=BC,8=TpFC",          # 0x2A
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,7=BC,8=TpFC",   # 0x2B
    "1=FL,2=FR,4=FC,5=LS,6=RS,7=TpFC,8=TpC",         # 0x2C
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,7=TpFC,8=TpC",  # 0x2D
    "1=FL,2=FR,4=FC,5=LS,6=RS,7=TpFL,8=TpFR",        # 0x2E
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,7=TpFL,8=TpFR", # 0x2F
    "1=FL,2=FR,4=FC,5=LS,6=RS,7=FLW,8=FRW",          # 0x30
    "1=FL,2=FR,3=LFE1,4=FC,5=LS,6=RS,7=FLW,8=FRW"    # 0x31
]
AUDIO_LFEPBL = [
    "unknown or refer to other information",
    "0dB playback",
    "+10dB playback",
    "reserved"
]