################################################################################
## tmds_cap_csr_ra.py                                                         ##
## Generates VHDL package and C header file from CSV.                         ##
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

import sys, csv, pathlib, math

print()
print('Usage:')
print('  tmds_cap_csr_ra.py addr_width [<csv_file> [<vhd_file> [<h_file>]]]')
print()
print('  addr_width: bit width (decimal) of slave address e.g. 8 for 256 bytes')
print('    csv_file: input CSV file (defaults to ./tmds_cap_csr_ra.csv)')
print('    vhd_file: output .vhd file (VHDL package) (default: ./tmds_cap_csr_ra.vhd)')
print('      h_file: output .h file (C header) (default: ./software/tmds_cap_csr_ra.h)')
print()

script = sys.argv[0]

if len(sys.argv) >= 2:
    addr_width = int(sys.argv[1])
else:
    print('addr_width not specified')
    sys.exit(1)

csv_file = './tmds_cap_csr_ra.csv'
if len(sys.argv) >= 3:
    csv_file = sys.argv[2]

vhd_file = './tmds_cap_csr_ra_pkg.vhd'
if len(sys.argv) >= 4:
    vhd_file = sys.argv[3]

h_file = './software/tmds_cap_csr_ra.h'
if len(sys.argv) >= 5:
    h_file = sys.argv[4]

print('  addr_width = %d' % addr_width)
print('    csv_file = %s' % csv_file)
print('    vhd_file = %s' % vhd_file)
print('      h_file = %s' % h_file)

rows = []
name_max_len = 0
with open(csv_file, 'r') as f:
    reader = csv.reader(f)
    for name, offset, comment in reader:
        name = name.strip()
        if len(name) > name_max_len:
            name_max_len = len(name)
        offset = int(offset.strip(),16)
        comment = comment.strip()    
        rows.append((name,offset,comment))

addr_digits = str(math.ceil(addr_width/4.0))

fv = open(vhd_file, 'w')
fv.write('--------------------------------------------------------------------------------\n')
fv.write('-- %s\n' % pathlib.PurePath(vhd_file).name)
fv.write('-- (generated from %s by %s)\n' % (pathlib.PurePath(csv_file).name,pathlib.PurePath(script).name))
fv.write('--------------------------------------------------------------------------------\n')
fv.write('\n')
fv.write('library ieee;\n')
fv.write('use ieee.std_logic_1164.all;\n')
fv.write('\n')
fv.write('package '+pathlib.PurePath(vhd_file).stem+' is\n')
fv.write('\n')


symbol = pathlib.PurePath(h_file).name.upper().replace(".","_")
fh = open(h_file, 'w')
fh.write('//******************************************************************************\n')
fh.write('// %s\n' % pathlib.PurePath(h_file).name)
fh.write('//  (generated from %s by %s)\n' % (pathlib.PurePath(csv_file).name,pathlib.PurePath(script).name))
fh.write('//******************************************************************************\n')
fh.write('\n')
fh.write('#ifndef _%s_\n' % symbol)
fh.write('#define _%s_\n' % symbol)
fh.write('\n')

for name, offset, comment in rows:
    padding = ' '*(name_max_len-len(name))
    s = '  constant RA_%s '+padding+': std_logic_vector(%d downto 0) := x"%0'+addr_digits+'X"; -- %s\n'
    fv.write(s % (name, addr_width-1, offset, comment))
    s = '#define RA_%s '+padding+'0x%0'+addr_digits+'X // %s\n'
    fh.write(s % (name, offset, comment))

fv.write('\n')
fv.write('end package '+pathlib.PurePath(vhd_file).stem+';\n')
fv.write('\n')
fv.write('--------------------------------------------------------------------------------\n')
fv.close()
    
fh.write('\n')
fh.write('#endif\n')
fh.close()
