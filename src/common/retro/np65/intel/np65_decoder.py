################################################################################
## np65_decoder.py                                                            ##
## Generates np65_decoder.vhd and np65_decoder.mif from CSV                   ##
## For Intel builds of the np65 CPU.                                          ##
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

import sys, csv

tab_size = 4

def tab_align(prefix, s, maxlen):
	global dbg
	p = ''
	for c in prefix:
		if c == '\t':
			c = ' '*(tab_size-(len(p) % tab_size))
		p += c
	l = len(p)+maxlen+1
	l += (4-(l % tab_size)) % tab_size
	spaces = l-(len(p)+len(s))
	tabs = 1+int((spaces - 1)/tab_size)
	return '\t'*tabs

print('usage: np65_decoder.py [<infile> [<outpath>]]')
print('   infile: input CSV file (defaults to ../6502.csv)')
print('  outpath: output directory path (defaults to ./)')

input_file = '../6502.csv'
if len(sys.argv) >= 2:
    input_file = sys.argv[1]

output_path = './'
if len(sys.argv) >= 3:
    output_path = sys.argv[2]

# read CSV file

rows = []
with open(input_file, 'r') as f:
	reader = csv.reader(f)
	for row in reader:
		rows.append(row)

# basic checks

if rows[1][0] != 'decoder':
	print('expected row 2 to begin with "decoder"; found "%s" instead' % rows[1][0])
	sys.exit(1)
if rows[2][0] != 'BIT FIELD':
	print('expected row 3 to begin with "BIT FIELD"; found "%s" instead' % rows[2][0])
	sys.exit(1)

# read bit field substitution definitions

r = 3
i = 0
bfs_names = []
bfs_sizes = []
bfs_values = []
while rows[r][0] != '':
	bfs_names.append(rows[r][0])
	try:
		bfs_sizes.append(int(rows[r][1]))
	except:
		print('invalid bit field size at row %d' % (r+1))
		sys.exit(1)
	values = []
	#for j in range(0,2**bfs_sizes[i]):
	n = 0
	while True:
		s = rows[r][2+n]
		if s != '':
			values.append(s)
		else:
			break;
		n += 1
	if n != 2**bfs_sizes[i]:
		print('error: incorrect number of bit field substitution values at row %d' % (r+1))
		sys.exit(1)
	bfs_values.append(values)
	r += 1
	i += 1

# skip any blank lines

while rows[r][0] == '':
	r += 1

# get bit field names and sizes

if rows[r][0] != 'BIT FIELD/SIZE =>':
	print('expected row %d to begin with "BIT FIELD/SIZE =>"; found "%s" instead' % (r+1, rows[r][0]))
	sys.exit(1)
bf_names = []
bf_sizes = []
bf_maxlen = 0
for i in range(2,len(rows[r])):
	n = rows[r][i]
	if len(n) > bf_maxlen:
		bf_maxlen = len(n)
	bf_names.append(n)
	try:
		bf_sizes.append(int(rows[r+1][i]))
	except:
		print('error: expected bit field size in row %d column %d' % (r+2,i+1))
		sys.exit(1)
r += 2
if bf_maxlen < len('opcode'):
	bf_maxlen = len('opcode')

bit_fields = len(bf_names)
bit_width = sum(bf_sizes)

# sanity check bit field substitution definitions

for i in range(0, len(bfs_names)):
	if bfs_names[i] not in bf_names:
		print('substitution name %s not found in bit fields' % bfs_names[i])
		sys.exit(1)
	if bf_sizes[bf_names.index(bfs_names[i])] != bfs_sizes[i]:
		print('substitution size mismatch for %s (%d vs %d)' % (bfs_names[i], bfs_sizes[i], bf_sizes[bf_names.index(bfs_names[i])]))
		sys.exit(1)

# create 256 instruction definitions, zero all bit fields by default

instruction_definitions = []
for i in range(0, 256):
	idef = ['BAD_%0.2X' % i]
	for j in range(0, bit_fields):
		idef.append('0'	* bf_sizes[j])
	instruction_definitions.append(idef)

# read opcode definitions

mnemonic_maxlen = 0
while r < len(rows):
	opcode = int(rows[r][1])
	mnemonic = rows[r][0]
	if len(mnemonic) > mnemonic_maxlen:
		mnemonic_maxlen = len(mnemonic)
	instruction_definitions[opcode][0] = mnemonic
	for i in range(0, bit_fields):
		value = rows[r][2+i]
		if bf_names[i] in bfs_names:
			if value == '.':
				value = bfs_values[bfs_names.index(bf_names[i])][0]
			if value in bfs_values[bfs_names.index(bf_names[i])]:
				value = bin(bfs_values[bfs_names.index(bf_names[i])].index(value))[2:]
			else:
				print('value %s not valid for %s' % (value, bf_names[i]))
				sys.exit(1)
		else:
			if value == '.':
				value = '0'
			elif value == 'x':
				value = '1'
			else:
				try:
					value = bin(int(value))[2:]
				except:
					print('bad value in row %d for bit field %s' % (r+1, bf_names[i]))
					sys.exit(1)
		value = value.zfill(bf_sizes[i])
		instruction_definitions[opcode][1+i] = value
	r += 1

# convert instruction definitions to simple vectors

instruction_vectors = []
for i in range(0, 256):
	v = ''
	for j in range(0, bit_fields):
		v = instruction_definitions[i][1+j] + v
	instruction_vectors.append(v)

# get max constant name length

constant_names = []
constant_name_maxlen = 0
for i in range(0, len(bfs_names)):
	for j in range(0, len(bfs_values[i])):
		n = "ID_"+bfs_names[i].upper()+"_"+bfs_values[i][j].upper()
		if len(n) > constant_name_maxlen:
			constant_name_maxlen = len(n)
		constant_names.append(n)

# output main VHDL file

f = open(output_path+'np65_decoder.vhd', 'w')
f.write('--------------------------------------------------------------------------------\n')
f.write('-- np65_decoder.vhd\n')
f.write('-- Intel Cyclone V version\n')
f.write('--------------------------------------------------------------------------------\n')
f.write('\n')
f.write('library ieee;\n')
f.write('use ieee.std_logic_1164.all;\n')
f.write('\n')
f.write('package np65_decoder_pkg is\n')
f.write('\n')
for i, bfs_name in enumerate(bfs_names):
	for j in range(0, len(bfs_values[i])):
		n = "ID_"+bfs_name.upper()+"_"+bfs_values[i][j].upper()
		f.write('\tconstant '+n)
		f.write(tab_align('\tconstant ', n, constant_name_maxlen))
		if bfs_sizes[i] > 1:
			f.write(': std_logic_vector('+str(bfs_sizes[i]-1)+' downto 0) := "'+bin(j)[2:].zfill(bfs_sizes[i])+'";\n')
		else:
			f.write(": std_logic := '"+str(j)+"';\n")
f.write('\n')
f.write('\tcomponent np65_decoder is\n')
f.write('\t\tport (\n')
f.write('\t\t\topcode')
f.write(tab_align('\t\t\t', 'opcode', bf_maxlen))
f.write(': in  std_logic_vector(7 downto 0);\n')
for i, bf_name in enumerate(bf_names):
	f.write('\t\t\t%s' % bf_name)
	f.write(tab_align('\t\t\t', bf_name, bf_maxlen))
	f.write(': out std_logic')
	if bf_sizes[i] > 1:
		f.write('_vector(%d downto 0)' % (bf_sizes[i]-1))
	if i < bit_fields-1:
		f.write(';')
	f.write('\n')
f.write('\t\t);\n')
f.write('\tend component np65_decoder;\n')
f.write('\n')
f.write('\ttype mnemonic_type is (\n')
for i in range(0, 256):
	n = instruction_definitions[i][0]
	if i < 255:
		n = n+','
	else:
		n = n+' '
	f.write('\t\t%s' % n)
	f.write(tab_align('\t\t', n, mnemonic_maxlen+1))
	f.write('-- %0.2X\n' % i)
f.write('\t);\n')
f.write('\n')
f.write('end package np65_decoder_pkg;\n')
f.write('\n')
f.write('--------------------------------------------------------------------------------\n')
f.write('\n')
f.write('library ieee;\n')
f.write('use ieee.std_logic_1164.all;\n')
f.write('use ieee.numeric_std.all;\n')
f.write('\n')
f.write('use work.np65_decoder_pkg.all;\n')
f.write('\n')
f.write('library altera_mf;\n')
f.write('use altera_mf.altera_mf_components.all;\n')
f.write('\n')
f.write('entity np65_decoder is\n')
f.write('\tport (\n')
f.write('\t\topcode')
f.write(tab_align('\t\t', 'opcode', bf_maxlen))
f.write(': in  std_logic_vector(7 downto 0);\n')
for i, bf_name in enumerate(bf_names):
	f.write('\t\t%s' % bf_name)
	f.write(tab_align('\t\t', bf_name, bf_maxlen))
	f.write(': out std_logic')
	if bf_sizes[i] > 1:
		f.write('_vector(%d downto 0)' % (bf_sizes[i]-1))
	if i < bit_fields-1:
		f.write(';')
	f.write('\n')
f.write('\t);\n')
f.write('end entity np65_decoder;\n')
f.write('\n')
f.write('architecture synth of np65_decoder is\n')
f.write('\n')
f.write('\tsignal data : std_logic_vector(%d downto 0);\n' % (bit_width-1))
f.write('\n')
f.write('\ttype mnemonic_type is (\n')
for i in range(0, 256):
	n = instruction_definitions[i][0]
	if i < 255:
		n = n+','
	else:
		n = n+' '
	f.write('\t\t%s' % n)
	f.write(tab_align('\t\t', n, mnemonic_maxlen+1))
	f.write('-- %0.2X\n' % i)
f.write('\t);\n')
f.write('\n')
f.write('\tsignal mnemonic : mnemonic_type;\n')
f.write('\n')
f.write('begin\n')
f.write('\n')
f.write('    ROM : component altdpram\n')
f.write('    generic map (\n')
f.write('                                  lpm_file => "np65_decoder.mif",\n')
f.write('                               indata_aclr => "OFF",\n')
f.write('                                indata_reg => "INCLOCK",\n')
f.write('                    intended_device_family => "Cyclone V",\n')
f.write('                                  lpm_type => "altdpram",\n')
f.write('                              outdata_aclr => "OFF",\n')
f.write('                               outdata_reg => "UNREGISTERED",\n')
f.write('                            ram_block_type => "MLAB",\n')
f.write('                            rdaddress_aclr => "OFF",\n')
f.write('                             rdaddress_reg => "UNREGISTERED",\n')
f.write('                            rdcontrol_aclr => "OFF",\n')
f.write('                             rdcontrol_reg => "UNREGISTERED",\n')
f.write('        read_during_write_mode_mixed_ports => "DONT_CARE",\n')
f.write('                                     width => 59,\n')
f.write('                                   widthad => 8,\n')
f.write('                             width_byteena => 1,\n')
f.write('                            wraddress_aclr => "OFF",\n')
f.write('                             wraddress_reg => "INCLOCK",\n')
f.write('                            wrcontrol_aclr => "OFF",\n')
f.write('                             wrcontrol_reg => "INCLOCK"\n')
f.write('    )\n')
f.write('    port map (\n')
f.write('        data      => (others => \'0\'),\n')
f.write('        inclock   => \'0\',\n')
f.write('        outclock  => \'0\',\n')
f.write('        rdaddress => opcode,\n')
f.write('        wraddress => (others => \'0\'),\n')
f.write('        wren      => \'0\',\n')
f.write('        q         => data\n')
f.write('    );\n')
f.write('\n')
n = 0
for i, bf_name in enumerate(bf_names):
	f.write('\t%s' % bf_name)
	f.write(tab_align('\t', bf_name, bf_maxlen))
	f.write(' <= data(');
	if bf_sizes[i] > 1:
		f.write('%d downto %d' % (n+(bf_sizes[i]-1), n))
	else:
		f.write('%d' % n)
	f.write(');\n')
	n += bf_sizes[i]
f.write('\n')
f.write('\tmnemonic <= -- for simulation (waveform display) only\n')
for i in range(0, 256):
	n = instruction_definitions[i][0]
	if i < 255:
		f.write('\t\t%s' % n)
		f.write(tab_align('\t\t', n, mnemonic_maxlen))
		f.write('when opcode = x"%0.2X" else\n' % i)

	else:
		f.write('\t\t%s;\n' % instruction_definitions[i][0])
f.write('\n')
f.write('end architecture synth;\n')
f.write('\n')
f.close()

# output MIF file

f = open(output_path+'np65_decoder.mif', 'w')
f.write('WIDTH=%d;\n' % bit_width)
f.write('DEPTH=256;\n')
f.write('ADDRESS_RADIX=HEX;\n')
f.write('DATA_RADIX=BIN;\n')
f.write('CONTENT BEGIN\n')
for i in range(256):
    f.write('%02X : %s;\n' % (i, instruction_vectors[i]));
f.write('END;\n')
f.close()

# output instance VHDL file

f = open(output_path+'np65_decoder_inst.vhd', 'w')
for i, bf_name in enumerate(bf_names):
	f.write('\tsignal id_%s' % bf_name)
	f.write(tab_align('\tsignal id_', bf_name, bf_maxlen))
	f.write(': std_logic')
	if bf_sizes[i] > 1:
		f.write('_vector(%d downto 0)' % (bf_sizes[i]-1))
	f.write(';\n');
f.write('\n')
f.write('\n')
f.write('\n')
f.write('\t-- instruction decoder\n')
f.write('\n')
f.write('\tDECODER: decode\n')
f.write('\tport map (\n')
f.write('\n')
f.write('\t\topcode')
f.write(tab_align('\t\t', 'opcode', bf_maxlen))
f.write('=> opcode,\n')
for i, bf_name in enumerate(bf_names):
	f.write('\t\t%s' % bf_name)
	f.write(tab_align('\t\t', bf_name, bf_maxlen))
	f.write('=> id_%s' % bf_name)
	if i < len(bf_names)-1:
		f.write(',\n')
f.write('\n\n')
f.write('\t);\n')
f.write('\n')
f.close()

# the end

print('done!')
