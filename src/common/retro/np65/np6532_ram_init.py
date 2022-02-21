################################################################################
## np6532_ram_init.py                                                         ##
## Builds RAM initialisation VHDL package from specified binary files.        ##
################################################################################
## (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        ##
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

import sys, math

# constants
banks = 4 # np6532 has 4 byte bank RAM structure
name = 'ram_init'

if len(sys.argv) < 2:
    print('usage: np6532_ram_init.py <ram size> [<address> <bin_file>] <init_address> <init_bin_file>',file=sys.stderr)
    print('example:',file=sys.stderr)
    print('  np6532_ram_init.py 128 0 test.bin FC00 init.bin > np6532_ram_init_128k_pkg.vhd',file=sys.stderr)
    sys.exit(1)

ram_size = int(sys.argv[1], 0)
if ram_size != 64 and ram_size != 128 and ram_size != 256:
    print('unsupported RAM size ('+ram_size+')',file=sys.stderr)
    print('supported RAM sizes: 64, 128 or 256',file=sys.stderr)
    sys.exit(1)
bank_size = int(ram_size/banks)

i = 2
contents = []
while i < len(sys.argv)-1:
    addr = int(sys.argv[i], 16)
    vector_init = addr
    if addr < 0 or addr >= (1024*ram_size):
        print('bad address (%s)' % sys.argv[i],file=sys.stderr)
        sys.exit(1)
    i += 1
    if i >= len(sys.argv):
        print('missing filename after address '+sys.argv[i-1],file=sys.stderr)
        sys.exit(1)
    filename = sys.argv[i]
    i += 1
    contents.append([addr,filename])

if vector_init >= 2**16:
    print('init vector outside bottom 64k',file=sys.stderr)
    sys.exit(1)

data = [0x00] * (ram_size * 1024)

# load binary file(s)
for addr, filename in contents:
    i = 0
    with open(filename, 'rb') as f:
        byte = f.read(1)
        while byte != b'':
            data[addr+i] = ord(byte)
            i += 1
            byte = f.read(1)
    f.close()

# write VHDL
print('--------------------------------------------------------------------------------')
print('-- RAM size: '+str(ram_size)+'k')
print('-- initial contents:')
for base_address, filename in contents:
    print('--   %s @ %05X' % (filename, base_address))
print('--------------------------------------------------------------------------------')
print('')
print('library ieee;')
print('use ieee.std_logic_1164.all;')
print('')
print('library work;')
print('use work.tyto_types_pkg.all;')
print('')
print('package np6532_ram_init_pkg is')
print('')
print('  subtype ram_bank_t is slv_7_0(0 to '+str((bank_size*1024)-1)+');')
print('  type ram_t is array(0 to '+str(banks-1)+') of ram_bank_t;')
print('')
print('  constant '+name+' : ram_t :=')
print('    ( -- %d banks...' % banks)
for bank in range(banks):
    print('      ( -- %d bytes per bank...' % (bank_size*1024))
    for row in range(ram_size*16):
        row_bytes = [data[(row*64)+(i*4)+bank] for i in range(16)]
        print('        '+','.join(['X"%02X"' % d for d in row_bytes]),end='')
        if row < (ram_size*16)-1:
            print(',',end='')
        print('')
    print('      )',end='');
    if bank < banks-1:
        print(',',end='')
    print('')
print('    );')
print('');
print('end package np6532_ram_init_pkg;');
