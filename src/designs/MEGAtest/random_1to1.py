# random_1to1.py
# Generate VHDL package containing constants for 1:1 sequential:random table.
# We do this in Python because doing it in a VHDL function brings Vivado's xelab
# to its knees (although it's OK on other simulators).

import sys,random

n_log2 = int(sys.argv[1])
n = 2**n_log2
l = len(str(n))
random.seed(123)
v = [-1]*n
for i in range(n):
    while True:
        r = random.randrange(0,n)
        if r not in v:
            break
    v[i] = r
print("package random_1to1_pkg is")
print("")
print("  constant random_1to1 : integer_vector(0 to %d) := (" % (n-1))
i = 0
while i < n:
    print("    ",end='')
    j = 0
    while j < 8 and i+j < n:
        print("%s" % str(v[i+j]).rjust(l),end='')
        if i+j == n-1:
            print("")
        elif j == 7:
            print(",")
        else:
            print(", ",end='')
        j += 1
    i += 8
print("  );")
print("")
print("end package random_1to1_pkg;")
