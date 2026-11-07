# Repaint GSPro's scramble button word "USE" as "Select" on the real fixtures.
# Usage: python3 tests/make_select_fixtures.py tests/fixtures/gspro
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
src_dir = Path(sys.argv[1])
for name in ["gspro-2p", "gspro-3p", "gspro-4p"]:
    img = Image.open(src_dir / f"{name}.jpg").convert("RGB")
    a = np.asarray(img).astype(int)
    band = a[1560:1625]
    white = band.min(axis=2) > 185
    cols = np.where(white.any(axis=0))[0]
    clusters, start, prev = [], None, None
    for c in cols:
        if start is None:
            start = prev = c
            continue
        if c - prev > 12:
            clusters.append((start, prev))
            start = c
        prev = c
    clusters.append((start, prev))
    boxes = []
    for x0, x1 in clusters:
        if not (1000 < x0 < 2400 and 44 <= x1 - x0 + 1 <= 56):
            continue
        rows = np.where(white[:, x0:x1 + 1].any(axis=1))[0]
        boxes.append((x0, 1560 + rows.min(), x1, 1560 + rows.max()))
    out = a.copy()
    for x0, y0, x1, y1 in boxes:
        L, R, T, B = x0 - 7, x1 + 7, y0 - 5, y1 + 5
        for y in range(T, B + 1):
            left = np.median(a[y, x0 - 28:x0 - 12], axis=0)
            right = np.median(a[y, x1 + 12:x1 + 28], axis=0)
            for x in range(L, R + 1):
                t = (x - L) / (R - L)
                out[y, x] = left * (1 - t) + right * t
    res = Image.fromarray(out.clip(0, 255).astype("uint8"))
    d = ImageDraw.Draw(res)
    for x0, y0, x1, y1 in boxes:
        cap = y1 - y0 + 1
        size = 10
        while True:
            f = ImageFont.truetype(FONT, size)
            bb = f.getbbox("S")
            if bb[3] - bb[1] >= cap:
                break
            size += 1
        bb = f.getbbox("Select")
        sb = f.getbbox("S")
        w = bb[2] - bb[0]
        cx = (x0 + x1) / 2
        d.text((round(cx - w / 2 - bb[0]), round(y0 - sb[1])), "Select", font=f, fill=(240, 240, 240))
    res.save(src_dir / f"{name}-select.jpg", quality=95)
    print(name, len(boxes), "buttons repainted", boxes)
