#!/usr/bin/env python3
"""Author repeatable, mip-filtered microgeometry for the native material study.

Normal maps encode surface slope, not painted highlights. Light remains fully movable.
Bake strength levels here so the iPhone never regenerates images during a slider drag.
"""
from pathlib import Path
import struct
import zlib
import argparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, required=True, help='Candidate directory for native maps')
parser.add_argument('--browser-output', type=Path, help='Optional directory for four browser maps')
parser.add_argument('--overwrite', action='store_true')
args = parser.parse_args()
folder = args.output.resolve()
browser = args.browser_output.resolve() if args.browser_output else None
names = [f'{kind}-{level}' for kind in ('brush', 'glaze') for level in range(1, 9)] + ['dial', 'roughness']
targets = [folder / f'ElementStudio-surface-{name}.png' for name in names]
if browser:
    targets += [browser / f'{name}.png' for name in ('brush-4', 'glaze-4', 'dial', 'roughness')]
if not args.overwrite and any(path.exists() for path in targets):
    parser.error('Output files exist; choose new directories or pass --overwrite')
try:
    import numpy as np
except ImportError:
    parser.error('Install scripts/requirements-authoring.txt in a Python virtual environment first')
folder.mkdir(parents=True, exist_ok=True)
if browser:
    browser.mkdir(parents=True, exist_ok=True)

size = 512
y, x = np.mgrid[0:size, 0:size].astype(float) / size
rng = np.random.default_rng(240910)

def save(name, rgb):
    data = np.concatenate((np.clip(np.rint(rgb * 255), 0, 255).astype(np.uint8),
                           np.full((size, size, 1), 255, np.uint8)), axis=-1)
    raw = b"".join(b"\0" + row.tobytes() for row in data)
    def chunk(kind, value):
        return struct.pack(">I", len(value)) + kind + value + struct.pack(">I", zlib.crc32(kind + value))
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">2I5B", size, size, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    (folder / f"ElementStudio-surface-{name}.png").write_bytes(png)
    if browser and name in ["brush-4", "glaze-4", "dial", "roughness"]:
        (browser / f"{name}.png").write_bytes(png)

def normal(name, dx, dy):
    n = np.stack((-dx, -dy, np.ones_like(x)), axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    save(name, n * .5 + .5)

# Long irregular tool traces. Integer frequencies meet at texture boundaries.
across = np.zeros_like(x)
along = np.zeros_like(x)
for f, amp in [(31, .12), (67, .18), (113, .24), (179, .18)]:
    phase = 2 * np.pi * (y * f + .17 * np.sin(x * 2 * np.pi)) + rng.random() * 6.28
    across += np.cos(phase) * amp
    along += np.cos(phase) * amp * .008 * np.cos(x * 2 * np.pi)

# Band-limited stochastic glaze skin; a sinusoidal lattice makes distracting moiré.
frequency = np.fft.fftfreq(size)
fy, fx = np.meshgrid(frequency, frequency, indexing="ij")
filtering = np.exp(-2 * np.pi**2 * 1.4**2 * (fx**2 + fy**2))
height = np.fft.ifft2(np.fft.fft2(rng.normal(size=(size, size))) * filtering).real
peel_x = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) / 2
peel_y = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) / 2
deviation = np.sqrt(np.mean(peel_x**2 + peel_y**2))
peel_x /= deviation
peel_y /= deviation

for level in range(1, 9):
    strength = level / 8
    normal(f"brush-{level}", along * strength, across * (.035 + strength * .23))
    normal(f"glaze-{level}", peel_x * strength * .022, peel_y * strength * .022)

# Circular engine turning on the dial's planar UVs, beneath its blue glaze.
radius = np.hypot(x - .5, y - .5)
radial = np.cos(radius * 2 * np.pi * 94) * .095
normal("dial", radial * (x - .5) / np.maximum(radius, .001) + peel_x * .014,
       radial * (y - .5) / np.maximum(radius, .001) + peel_y * .014)
roughness = .94 + .045 * across + .009 * peel_x
save("roughness", np.repeat(roughness[..., None], 3, axis=-1))
print("Baked 18 native surface maps; highlights remain controlled by the studio light.")
