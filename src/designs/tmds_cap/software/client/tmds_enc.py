import sys
import array

def N1(D):
    return D.count(1)

def N0(D):
    return D.count(0)

def inv(a):
    return (~a)&1;

def xor(a,b):
    return (a^b)&1

def xnor(a,b):
    return (~(a^b))&1

cnt = 0

def tmds_encode(D):
    global cnt
    r = None
    D = [int(i) for i in reversed(format(D,'#010b')[2:])]
    q_m = [0]*9
    q_out = [0]*10
    if N1(D) > 4 or (N1(D) == 4 and D[0] == 0):
        q_m[0] = D[0]
        for i in range(1,8): q_m[i] = xnor(q_m[i-1],D[i])
        q_m[8] = 0
    else:
        q_m[0] = D[0]
        for i in range(1,8): q_m[i] = xor(q_m[i-1],D[i])
        q_m[8] = 1
    if cnt == 0 or (N1(q_m[0:8]) == N0(q_m[0:8])):
        q_out[9] = inv(q_m[8])
        q_out[8] = q_m[8]
        if q_m[8]:
            q_out[0:8] = q_m[0:8] if q_m[8] else [inv(x) for x in q_m[0:8]]
        else:
            q_out[0:8] = [inv(x) for x in q_m[0:8]]
        if q_m[8]:
            cnt = cnt+(N0(q_m[0:8])-N1(q_m[0:8]))
        else:
            cnt = cnt-(N1(q_m[0:8])-N0(q_m[0:8]))
    else:
        if (cnt > 0 and (N1(q_m[0:8]) > N0(q_m[0:8]))) or (cnt < 0 and (N0(q_m[0:8]) > N1(q_m[0:8]))):
            q_out[9] = 1
            q_out[8] = q_m[8]
            q_out[0:8] = [inv(x) for x in q_m[0:8]]
            cnt = cnt+(2*q_m[8])+(N0(q_m[0:8])-N1(q_m[0:8]))
        else:
            q_out[9] = 0
            q_out[8] = q_m[8]
            q_out[0:8] = q_m[0:8]
            cnt = cnt-(2*inv(q_m[8]))+(N1(q_m[0:8])-N0(q_m[0:8]))
    r = int(''.join(reversed([str(x) for x in q_out])),2)
    return r

tmds = []
for i in range(1024):
    tmds.append({})

# fill in video data values
for D in range(256):
    for cnt in range(-1,2):
        tmds[tmds_encode(D)]['video']=D

# fill in TERC4 values
tmds[0b1010011100]['terc4']=0b0000
tmds[0b1001100011]['terc4']=0b0001
tmds[0b1011100100]['terc4']=0b0010
tmds[0b1011100010]['terc4']=0b0011
tmds[0b0101110001]['terc4']=0b0100
tmds[0b0100011110]['terc4']=0b0101
tmds[0b0110001110]['terc4']=0b0110
tmds[0b0100111100]['terc4']=0b0111
tmds[0b1011001100]['terc4']=0b1000
tmds[0b0100111001]['terc4']=0b1001
tmds[0b0110011100]['terc4']=0b1010
tmds[0b1011000110]['terc4']=0b1011
tmds[0b1010001110]['terc4']=0b1100
tmds[0b1001110001]['terc4']=0b1101
tmds[0b0101100011]['terc4']=0b1110
tmds[0b1011000011]['terc4']=0b1111

# fill in control values
tmds[0b1101010100]['ctrl']=0b00
tmds[0b0010101011]['ctrl']=0b01
tmds[0b0101010100]['ctrl']=0b10
tmds[0b1010101011]['ctrl']=0b11

# fill in guardbands
for i in range(len(tmds)):
    tmds[i]['gb']=[]
tmds[0b1010001110]['gb']+=['d0c0']
tmds[0b1001110001]['gb']+=['d0c1']
tmds[0b0101100011]['gb']+=['d0c2']
tmds[0b1011000011]['gb']+=['d0c3']
tmds[0b0100110011]['gb']+=['d1']
tmds[0b0100110011]['gb']+=['d2']
tmds[0b1011001100]['gb']+=['v0']
tmds[0b0100110011]['gb']+=['v1']
tmds[0b1011001100]['gb']+=['v2']
#for i in range(len(tmds)):
#    if len(tmds[i]['gb']) == 0:
#        tmds[i]['gb'].pop()

for i in range(len(tmds)):
    print(format(i,'#012b'),': ',end=' ')
    if 'ctrl' in tmds[i]:
        print(format(tmds[i]['ctrl'],'#04b'),end=' ')
    else:
        print('....',end=' ')
    if 'terc4' in tmds[i]:
        print(format(tmds[i]['terc4'],'#06b'),end=' ')
    else:
        print('......',end=' ')
    if 'video' in tmds[i]:
        print(format(tmds[i]['video'],'#010b'),end=' ')
    else:
        print('..........',end=' ')
    if 'gb' in tmds[i]:
        for s in tmds[i]['gb']:
            print(s,end=' ')
    print()

#count_data = 0
#count_terc4 = 0
#count_ctrl = 0
#for i in range(len(tmds_data)):
#    print(format(i,'#012b'),': ',tmds_usage[i],' ',end='')
#    if tmds_type[i] == 'data':
#        print('data  ',format(tmds_data[i],'#010b'))
#    elif tmds_type[i] == 'terc4':
#        print('terc4 ',format(tmds_data[i],'#06b'))
#    elif tmds_type[i] == 'ctrl':
#        print('ctrl  ',format(tmds_data[i],'#04b'))
#    else:
#        print('')
#    if tmds_type[i] == 'data': count_data += 1
#    if tmds_type[i] == 'terc4': count_terc4 += 1
#    if tmds_type[i] == 'ctrl': count_ctrl += 1
#
#print("count_data =",count_data)
#print("count_terc4 =",count_terc4)
#print("count_ctrl =",count_ctrl)
#

print(tmds[0])
