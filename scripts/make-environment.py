#!/usr/bin/env python3
"""Bake the authored linear HDR lighting panorama, not a picture of the objects."""
from array import array
from pathlib import Path
from math import atan2, sin, cos, exp, pi
import argparse
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, required=True, help='Candidate .bin path; 1024x512 little-endian float32 RGBA')
parser.add_argument('--overwrite', action='store_true')
args = parser.parse_args()
target = args.output.resolve()
if target.exists() and not args.overwrite:
    parser.error(f'Output exists: {target}; choose a new path or pass --overwrite')
target.parent.mkdir(parents=True, exist_ok=True)

width, height = 1024, 512
pixels = array('f')
def panel(yaw, pitch, center, elevation, breadth, tall):
    dx = atan2(sin(yaw - center), cos(yaw - center)) / breadth
    dy = (pitch - elevation) / tall
    return exp(-abs(dx)**8 - abs(dy)**8)

for y in range(height):
    pitch = pi * (0.5 - y / height)
    for x in range(width):
        yaw = x / width * 2 * pi - pi
        key = panel(yaw, pitch, -.65, .48, .42, .61) * 5.5
        fill = panel(yaw, pitch, 1.05, .13, .56, .5) * .85
        rim = panel(yaw, pitch, 2.35, .36, .1, .72) * 7
        bounce = panel(yaw, pitch, -.2, -.7, .74, .12) * .4
        pixels.extend((.055 + key + fill * .75 + rim * .85 + bounce,
                       .065 + key * .97 + fill * .88 + rim * .94 + bounce,
                       .080 + key * .91 + fill + rim + bounce, 1))
if sys.byteorder != 'little':
    pixels.byteswap()
target.write_bytes(pixels.tobytes())
print(f'Wrote {width}×{height} linear HDR studio environment: {len(pixels) * 4} bytes')
