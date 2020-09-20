#!/usr/bin/python

# horrible hack to convert a 96x192 w/h PNG to an assembly include file
# loads input.png, writes to standard output
# input file MUST be monochrome (1-bit) 

# 192 bytes representing 8 bits are stored in reverse order (bottom to top)
# with 3 columns stored, aligned to $100, per data section
# RODATA, RODATA1... etc.
# the 0th byte is null (reserved for header + simplifies offset in draw loop)

from PIL import Image

im = Image.open('input.png', 'r')
pixels = list(im.getdata())
width, height = im.size

pixels = [pixels[i * width:(i + 1) * width] for i in range(height)]

pixels.reverse()

block = []
for i in range(0,12):
    block.append([])

for i in range(0,12):
    block[i] = ".align $100\nbitmap" + str(i) + ":\n.byte 0\n"

def repack(input):
    out = list(".byte   %")
    for i in input:
        out.append(str(i))
    out.append('\n')
    return ''.join(out)

for i in pixels:
    block[0] = block[0] + repack(i[:8])
    block[1] = block[1] + repack(i[8:16])
    block[2] = block[2] + repack(i[16:24])
    block[3] = block[3] + repack(i[24:32])
    block[4] = block[4] + repack(i[32:40])
    block[5] = block[5] + repack(i[40:48])
    block[6] = block[6] + repack(i[48:56])
    block[7] = block[7] + repack(i[56:64])
    block[8] = block[8] + repack(i[64:72])
    block[9] = block[9] + repack(i[72:80])
    block[10]= block[10] + repack(i[80:88])
    block[11]= block[11] + repack(i[88:96])

print("\n.segment \"RODATA\"")
print (''.join(block[0]))
print (''.join(block[1]))
print (''.join(block[2]))
print("\n.segment \"RODATA1\"")
print (''.join(block[3]))
print (''.join(block[4]))
print (''.join(block[5]))
print("\n.segment \"RODATA2\"")
print (''.join(block[6]))
print (''.join(block[7]))
print (''.join(block[8]))
print("\n.segment \"RODATA3\"")
print (''.join(block[9]))
print (''.join(block[10]))
print (''.join(block[11]))
