"""Hace enlazable en mosaico una textura cuadrada: fundido con su copia desplazada w/2,h/2 en una franja junto a los bordes (Claude, 2026-10-24)."""
import sys
from PIL import Image, ImageChops, ImageFilter

src, dst, band = sys.argv[1], sys.argv[2], float(sys.argv[3]) if len(sys.argv) > 3 else 0.08
im = Image.open(src).convert('RGB')
w, h = im.size
off = ImageChops.offset(im, w // 2, h // 2)
bw, bh = int(w * band), int(h * band)

def ramp(n, b):
    # 0 en el borde → 1 a distancia b, con smoothstep.
    out = []
    for i in range(n):
        d = min(i, n - 1 - i) / b
        d = max(0.0, min(1.0, d))
        out.append(int(255 * d * d * (3 - 2 * d)))
    return out

rx, ry = ramp(w, bw), ramp(h, bh)
mx = Image.new('L', (w, 1)); mx.putdata(rx); mx = mx.resize((w, h))
my = Image.new('L', (1, h)); my.putdata(ry); my = my.resize((w, h))
mask = ImageChops.darker(mx, my)
Image.composite(im, off, mask).save(dst, optimize=False)
print('ok', dst, w, h, 'franja', bw)
