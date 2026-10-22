#!/usr/bin/env python3
"""Small deterministic Adobe PSD/PSB composites; no user photos or dependencies.
Format: https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/
ZIP predictor is row delta; 32-bit data first splits into four byte planes.
"""
import json
import struct
import sys
import zlib
from pathlib import Path

root = Path(sys.argv[1]); root.mkdir(parents=True, exist_ok=True)
manifest = []
def header(version, channels, width, height, depth, mode, resources=b'', layers=b''):
    return (b'8BPS' + struct.pack('>H', version) + b'\0' * 6 +
            struct.pack('>HIIHH', channels, height, width, depth, mode) +
            struct.pack('>I', 0) + struct.pack('>I', len(resources)) + resources +
            len(layers).to_bytes(8 if version == 2 else 4, 'big') + layers)

def packbits(row):
    # Literal runs suffice for small fixtures; large fixtures use repeated runs.
    return b''.join(bytes([len(row[i:i+128])-1])+row[i:i+128] for i in range(0,len(row),128))

for version in [1, 2]:
    for mode, channels in [(1, 1), (1, 2), (3, 3), (3, 4), (4, 4)]:
        for depth in [8, 16, 32]:
            if mode == 4 and depth == 32: continue  # Photoshop CMYK is 8/16 bit.
            for compression in range(4):
                width, height = 5, 3
                fmt = {8:'B', 16:'H', 32:'f'}[depth]
                values = [((x*0.15 + y*0.1 + channel*0.21) % 1)
                          for channel in range(channels) for y in range(height) for x in range(width)]
                if depth < 32:
                    values = [round(value*((1<<depth)-1)) for value in values]
                raw = b''.join(struct.pack('>'+fmt, value) for value in values)
                row_size = width * depth // 8
                rows = [raw[i:i+row_size] for i in range(0, len(raw), row_size)]
                if compression == 0:
                    encoded = raw
                elif compression == 1:
                    packed = [packbits(row) for row in rows]
                    encoded = (b''.join(struct.pack('>I' if version==2 else '>H', len(row)) for row in packed)
                               + b''.join(packed))
                elif compression == 2:
                    encoded = zlib.compress(raw)
                else:
                    predicted = bytearray()
                    for row in rows:
                        if depth == 16:
                            samples = struct.unpack('>'+str(width)+'H', row)
                            deltas = [samples[0]] + [(samples[i]-samples[i-1]) & 65535 for i in range(1,width)]
                            predicted.extend(struct.pack('>'+str(width)+'H', *deltas))
                        else:
                            if depth == 32:
                                row = b''.join(row[byte::4] for byte in range(4))
                            predicted.extend(bytes([row[0]] + [(row[i]-row[i-1]) & 255 for i in range(1,len(row))]))
                    encoded = zlib.compress(predicted)
                suffix = 'psb' if version == 2 else 'psd'
                name = f'v{version}-m{mode}-c{channels}-d{depth}-z{compression}.{suffix}'
                (root/name).write_bytes(header(version,channels,width,height,depth,mode)+struct.pack('>H',compression)+encoded)
                manifest.append(dict(name=name,version=version,mode=mode,channels=channels,depth=depth,compression=compression))

# Real layer structures distinguish a saved user channel from merged alpha.
# The 16/32-bit forms also exercise the global Lr16/Lr32 tagged layer body.
alpha_manifest = []
def integer(value, size): return value.to_bytes(size, 'big', signed=value < 0)
def samples(value, depth, count=15):
    sample = struct.pack('>f', value) if depth == 32 else integer(round(value*((1<<depth)-1)),depth//8)
    return sample*count

for version in [1,2]:
    for mode in [1,3]:
        for depth in [8,16,32]:
            locations = ['primary','marker'] + (['tag'] if depth > 8 else [])
            for location in locations:
                for merged in [False,True]:
                    base_channels = 1 if mode == 1 else 3
                    values = [0.5] if mode == 1 else [1.0,0.25,0.5]
                    channels = [(i,samples(v,depth)) for i,v in enumerate(values)]
                    if merged: channels.append((-1,samples(0.25,depth)))
                    layer = integer(0,4)*2+integer(3,4)+integer(5,4)+integer(len(channels),2)
                    layer += b''.join(integer(ch,2)+integer(len(data)+2,8 if version==2 else 4) for ch,data in channels)
                    layer += b'8BIMnorm'+bytes([255,0,0,0])
                    extra = b'\0'*8+b'\x03RGB'
                    layer += integer(len(extra),4)+extra
                    count = -1 if merged and location != 'marker' else 1
                    info = integer(count,2)+layer+b''.join(b'\0\0'+data for _,data in channels)
                    info += b'\0' * (-len(info)%4)
                    size_bytes = 8 if version==2 else 4
                    if location == 'tag':
                        key = b'Lr16' if depth==16 else b'Lr32'
                        layers = b'\0'*size_bytes+b'\0'*4+b'8BIM'+key+integer(len(info),size_bytes)+info
                    else:
                        layers = integer(len(info),size_bytes)+info+b'\0'*4
                        if location == 'marker' and merged:
                            key = {8:b'Mtrn',16:b'Mt16',32:b'Mt32'}[depth]
                            layers += b'8BIM'+key+b'\0'*size_bytes
                    # Photoshop's RGB/grayscale merged preview is white-matted.
                    stored = [v*0.25+0.75 if merged else v for v in values]
                    composite = b''.join(samples(v,depth) for v in stored)+samples(0.25,depth)
                    for compression in [0,2]:
                        encoded = composite if compression==0 else zlib.compress(composite)
                        suffix = 'psb' if version==2 else 'psd'
                        name = f'alpha-v{version}-m{mode}-d{depth}-{location}-{int(merged)}-z{compression}.{suffix}'
                        (root/name).write_bytes(header(version,base_channels+1,5,3,depth,mode,layers=layers)+integer(compression,2)+encoded)
                        alpha_manifest.append(dict(name=name,merged=merged,version=version,mode=mode,depth=depth,location=location,compression=compression))

for version in [1,2]:
    suffix='psb' if version==2 else 'psd'
    (root/f'bitmap-rle.{suffix}').write_bytes(header(version,1,8,1,1,0)+b'\0\1'+integer(2,4 if version==2 else 2)+b'\0\xaa')

# Wide, genuinely PSB-sized > 32 MP image, compact PackBits composite. It must
# retain the 300,000-pixel width while allocating only a sampled preview.
width,height,channels=300_000,128,3
run = bytes([129,255]) * (width//128)
if width % 128: run += bytes([257-width%128,255])
large = (header(2,channels,width,height,8,3)+b'\0\1'+
         struct.pack('>I',len(run))*(height*channels)+run*(height*channels))
(root/'large.psb').write_bytes(large)

base=(root/'v2-m3-c3-d8-z0.psb').read_bytes()
bad={
 'bad-signature.psb': b'xxxx'+base[4:],
 'bad-version.psb': base[:4]+b'\0\3'+base[6:],
 'bad-reserved.psb': base[:6]+b'\1'+base[7:],
 'bad-channels.psb': base[:12]+b'\xff\xff'+base[14:],
 'bad-width.psb': base[:18]+b'\xff'*4+base[22:],
 'bad-layer-length.psb': base[:34]+b'\xff'*8+base[42:],
 'bad-resource-length.psb': base[:30]+b'\xff'*4+base[34:],
 'missing-composite.psb': base[:42],
 'truncated-raw.psb': base[:-3],
}
zip_data=(root/'v2-m3-c3-d8-z3.psb').read_bytes()
bad['truncated-zip.psb']=zip_data[:-2]
bad['bad-checksum.psb']=zip_data[:-1]+bytes([zip_data[-1]^255])
rle=(root/'v2-m3-c3-d8-z1.psb').read_bytes()
bad['bad-rle-length.psb']=rle[:44]+b'\xff'*4+rle[48:]
# Version-info resource explicitly states that maximize compatibility was off.
resource=b'8BIM'+struct.pack('>H',1057)+b'\0\0'+struct.pack('>I',5)+b'\0\0\0\1\0'+b'\0'
bad['no-compatibility.psb']=header(2,3,5,3,8,3,resource)+b'\0\0'+bytes(45)
for name,data in bad.items(): (root/name).write_bytes(data)
# A legal PackBits row padded with no-ops must remain cancellable inside it.
nop_row = b'\x80' * 1_048_576 + bytes([1, 255, 255])
(root/'long-noop-row.psb').write_bytes(header(2,1,1,1,16,1)+b'\0\1'+struct.pack('>I',len(nop_row))+nop_row)
(root/'manifest.json').write_text(json.dumps(manifest))
(root/'alpha-manifest.json').write_text(json.dumps(alpha_manifest))
(root/'bad.json').write_text(json.dumps(list(bad)))
print(f'Generated {len(manifest)} codec combinations, {len(alpha_manifest)} layer-alpha cases, one large PSB and {len(bad)} invalid cases')
