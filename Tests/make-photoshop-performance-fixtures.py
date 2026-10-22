#!/usr/bin/env python3
"""Bounded, synthetic PackBits/embedded-thumbnail fixtures; no user files.
JPEG fixture is a generated 64 × 48 solid green image; only Python stdlib needed.
"""
import base64
import struct
import sys
from pathlib import Path

root = Path(sys.argv[1]); root.mkdir(parents=True, exist_ok=True)
JPEG = base64.b64decode('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAIBAQEBAQIBAQECAgICAgQDAgICAgUEBAMEBgUGBgYFBgYGBwkIBgcJBwYGCAsICQoKCgoKBggLDAsKDAkKCgr/2wBDAQICAgICAgUDAwUKBwYHCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgr/wAARCAAwAEADAREAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDsK/h8/wAqwoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKACgAoAKAP/2Q==')

def integer(value, size): return value.to_bytes(size, 'big', signed=value < 0)
def header(width, height, resources=b''):
    # Four-channel RGB plus explicit merged alpha forces the bounded reader path.
    layers = integer(2, 8) + integer(-1, 2) + integer(0, 4)
    return (b'8BPS\0\2' + b'\0'*6 + struct.pack('>HIIHH',4,height,width,8,3)
            + integer(0,4) + integer(len(resources),4) + resources
            + integer(len(layers),8) + layers)
def resource(payload=JPEG, *, rid=1036, width=64, height=48, kind=1, depth=24):
    row_bytes=((width*depth+31)//32)*4
    data=struct.pack('>6I2H',kind,width,height,row_bytes,row_bytes*height,len(payload),depth,1)+payload
    return b'8BIM'+integer(rid,2)+b'\0\0'+integer(len(data),4)+data+b'\0'*(len(data)%2)
def write_rle(name,width,height,rows,resources=b''):
    assert len(rows)==height*4
    data=header(width,height,resources)+b'\0\1'+b''.join(integer(len(row),4) for row in rows)+b''.join(rows)
    (root/name).write_bytes(data)
def pack(row, count=128):
    return b''.join(bytes([len(row[i:i+count])-1])+row[i:i+count] for i in range(0,len(row),count))

width,height=1024,384
rows=[bytes(((x*19+y*7+c*53)&255) if c<3 else 255 for x in range(width)) for c in range(4) for y in range(height)]
(root/'literal-raw.psb').write_bytes(header(width,height)+b'\0\0'+b''.join(rows))
write_rle('literal-1.psb',width,height,[pack(row,1) for row in rows])
write_rle('literal-128.psb',width,height,[pack(row) for row in rows])

for name,prefix,kind in [('boundary-literal.psb',65535,'literal'),('boundary-run.psb',65535,'run'),('boundary-payload.psb',65471,'literal')]:
    encoded=[]
    for value in [201,43,91,255]:
        first=bytes([127])+bytes([value])*128 if kind=='literal' else bytes([129,value])
        encoded.append(b'\x80'*prefix+first+bytes([1,value,value])+b'\x80'*97)
    write_rle(name,130,1,encoded)
width,height=128,96
solid_rows=[bytes([129,value]) for value in [220,20,40,255] for _ in range(height)]
slow_rows=solid_rows.copy();slow_rows[0]=b'\x80'*(8*1024*1024)+slow_rows[0]
write_rle('embedded.psb',width,height,slow_rows,resource())
for name,res in [('bad-jpeg.psb',resource(b'not a JPEG')),('wrong-dimensions.psb',resource(width=65)),('wrong-depth.psb',resource(depth=8)),('wrong-format.psb',resource(kind=0)),('legacy-thumbnail.psb',resource(rid=1033))]:
    write_rle(name,width,height,solid_rows,res)
write_rle('composite.psb',width,height,solid_rows)
write_rle('cancel-noop.psb',130,1,[b'\x80'*(8*1024*1024)+bytes([129,100,1,100,100])]+[bytes([129,255,1,255,255])]*3)
for name,badrow in [('literal-truncated.psb',bytes([127,44])),('run-truncated.psb',bytes([129])),('run-overflow.psb',bytes([129,44,129,44])),('run-underflow.psb',bytes([129,44])),('nop-empty.psb',b'\x80'*65537),('extra-output.psb',bytes([129,44,1,44,44,0,44]))]:
    write_rle(name,130,1,[badrow]+[bytes([129,255,1,255,255])]*3)
for name,width,height in [('portrait-alpha-a.psb',2582,3318),('portrait-alpha-b.psb',2843,3361)]:
    rows=[]
    for value in [255,207,223,64]:
        row=bytes([129,value])*(width//128)
        if width%128: row+=bytes([257-width%128,value])
        rows.extend([row]*height)
    write_rle(name,width,height,rows)
# Reproduces the macOS ImageIO small-PSD failure using the stock system profile,
# without including user images, user metadata, or a copied profile in the source.
profile=Path('/System/Library/ColorSync/Profiles/Generic RGB Profile.icc').read_bytes()
(root/'GenericRGB.icc').write_bytes(profile)
def icc_resource(payload):
    return b'8BIM'+integer(1039,2)+b'\0\0'+integer(len(payload),4)+payload+b'\0'*(len(payload)%2)
for name in ['portrait-alpha-a.psb','portrait-alpha-b.psb']:
    original=(root/name).read_bytes()
    assert original[30:34]==b'\0'*4
    resources=icc_resource(profile)
    (root/('icc-'+name)).write_bytes(original[:30]+integer(len(resources),4)+resources+original[34:])
bad_profile=profile[:36]+b'XXXX'+profile[40:]
resources=icc_resource(bad_profile)
original=(root/'portrait-alpha-a.psb').read_bytes()
(root/'invalid-icc.psb').write_bytes(original[:30]+integer(len(resources),4)+resources+original[34:])
native=(b'8BPS\0\1'+b'\0'*6+struct.pack('>HIIHH',3,256,199,8,3)+integer(0,4)
        +integer(len(resources),4)+resources+integer(0,4)+b'\0\0'
        +b''.join(bytes([v])*(199*256) for v in [255,64,128]))
(root/'invalid-icc-native.psd').write_bytes(native)
truncated=(root/'literal-128.psb').read_bytes()[:-1]
(root/'file-truncated.psb').write_bytes(truncated)
print('Generated bounded PackBits and embedded-thumbnail fixtures')
