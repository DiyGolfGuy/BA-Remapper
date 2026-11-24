"""Build the 4-choice GSPro 4 relief fixtures (water with mulligans on).

Bruce's photos of the projector (2026-11-23) show water relief with
mulligans on as four choices: 1 LATERAL DROP, 2 FLAG LINE, 3 REHIT,
4 MULLIGAN ("Replay the shot, it doesn't count", green NO STROKE badge).
His real screenshot relief-water-lateral.jpg has the same panel with
three; this script adds the fourth card in the panel's own pixels (the
REHIT card copied one card pitch down, its text redrawn) so the Windows
OCR tests read a clean screen picture:

  relief-water-mulligan.jpg         Lateral Drop highlighted (as GSPro opens)
  relief-water-mulligan-picked.jpg  Mulligan highlighted (after Ctrl+M)
  relief-water-mulligan-callout.jpg the same with GSPro's Mulligan callout
                                    right beside the panel
  relief-water-mulligan-callout-row.jpg  the callout's last line on card 4's
                                    title row, map label under the panel

Edited pictures, not captures: see fixtures/gspro/README.md.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent / "fixtures" / "gspro"
FONTS = Path("/usr/share/fonts/truetype/dejavu")
PITCH = 150                      # card to card in the 3427-wide screenshot
CARD = {1: 347, 2: 497, 3: 647}  # card tops; each card is 132 tall
X0, X1 = 22, 782                 # panel edges

def font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)

TITLE = font("DejaVuSansCondensed-Bold.ttf", 44)
DETAIL = font("DejaVuSans.ttf", 23)
NUM = font("DejaVuSans-Bold.ttf", 27)
BADGE = font("DejaVuSansCondensed-Bold.ttf", 19)

def blank(d, top, bg, circle):
    # title, detail line, badge and number of one card
    d.rectangle([150, top + 28, 660, top + 112], fill=bg)
    d.rectangle([660, top + 40, 740, top + 92], fill=bg)
    d.ellipse([76, top + 38, 132, top + 94], fill=circle)

def card_text(d, top, number, title, detail, badge, numcolor):
    d.text((157, top + 30), title, font=TITLE, fill=(255, 255, 255))
    d.text((157, top + 84), detail, font=DETAIL, fill=(160, 170, 190))
    w = d.textlength(str(number), font=NUM)
    d.text((104 - w / 2, top + 50), str(number), font=NUM, fill=numcolor)
    if badge == "+1":
        d.rounded_rectangle([670, top + 48, 728, top + 85], radius=5, fill=(196, 64, 52))
        d.text((683, top + 54), "+1", font=BADGE, fill=(255, 255, 255))
    else:
        d.rounded_rectangle([594, top + 50, 728, top + 83], radius=5, fill=(64, 176, 96))
        d.text((604, top + 55), badge, font=BADGE, fill=(255, 255, 255))

def four_cards(src):
    im = src.copy()
    # card 3 and the panel's bottom edge, one pitch lower = card 4
    strip = src.crop((X0, CARD[3] - 7, X1, CARD[3] + 161))
    im.paste(strip, (X0, CARD[3] - 7 + PITCH))
    return im

def main():
    src = Image.open(HERE / "relief-water-lateral.jpg").convert("RGB")
    plain_bg, plain_circle = src.getpixel((400, CARD[3] + 66)), src.getpixel((90, CARD[3] + 66))
    blue_bg, blue_circle = src.getpixel((400, CARD[1] + 120)), src.getpixel((90, CARD[1] + 66))
    top4 = CARD[3] + PITCH

    # Lateral Drop highlighted
    a = four_cards(src)
    d = ImageDraw.Draw(a)
    blank(d, top4, plain_bg, plain_circle)
    card_text(d, top4, 4, "MULLIGAN", "Replay the shot, it doesn't count", "NO STROKE", (230, 236, 245))
    a.save(HERE / "relief-water-mulligan.jpg", quality=95)

    # Mulligan highlighted: card 1 gets the plain look, card 4 the blue one
    b = four_cards(src)
    b.paste(src.crop((X0, CARD[2], X1, CARD[2] + 136)), (X0, CARD[1]))
    b.paste(src.crop((X0, CARD[1], X1, CARD[1] + 136)), (X0, top4))
    d = ImageDraw.Draw(b)
    blank(d, CARD[1], plain_bg, plain_circle)
    card_text(d, CARD[1], 1, "LATERAL DROP", "Rough  ·  160 yd to pin", "+1", (230, 236, 245))
    blank(d, top4, blue_bg, blue_circle)
    card_text(d, top4, 4, "MULLIGAN", "Replay the shot, it doesn't count", "NO STROKE", (255, 255, 255))
    b.save(HERE / "relief-water-mulligan-picked.jpg", quality=95)

    # Mulligan highlighted with GSPro's callout for it right beside the
    # panel (Bruce's photos, 2026-11-24: the callout sits at the ball's
    # last spot, which can be just right of the list).  Its lines share
    # rows with card 4 and reach into the panel corner that is read.
    c = b.copy()
    d = ImageDraw.Draw(c)
    cx0, cy0, cx1, cy1 = X1, top4 - 58, X1 + 494, top4 + 110
    d.rounded_rectangle([cx0, cy0, cx1, cy1], radius=8, fill=(30, 34, 48), outline=(120, 220, 210), width=3)
    mid = (cx0 + cx1) / 2
    for text, f, fill, y in [("MULLIGAN", TITLE, (255, 255, 255), top4 - 40)
                             , ("From your last spot  ·  475 yd to pin", DETAIL, (225, 230, 240), top4 + 30)
                             , ("No stroke, replay the shot", font("DejaVuSans-Bold.ttf", 23), (140, 230, 200), top4 + 68)]:
        d.text((mid - d.textlength(text, font=f) / 2, y), text, font=f, fill=fill)
    c.save(HERE / "relief-water-mulligan-callout.jpg", quality=95)

    # As in Bruce's photo 5301 (2026-11-24): the callout's last line,
    # "No stroke, replay the shot", on the same row as card 4's title
    # and badge, its left part inside the corner that is read, and the
    # map's "3 REHIT" label just under the panel.  Moving the map moves
    # these away - which is when the Mulligan button worked.
    e = b.copy()
    d = ImageDraw.Draw(e)
    cx0, cy0, cx1, cy1 = X1 + 7, top4 - 96, X1 + 487, top4 + 94
    d.rounded_rectangle([cx0, cy0, cx1, cy1], radius=8, fill=(30, 34, 48), outline=(120, 220, 210), width=3)
    mid = (cx0 + cx1) / 2
    for text, f, fill, y in [("MULLIGAN", TITLE, (255, 255, 255), top4 - 62)
                             , ("From your last spot  ·  475 yd to pin", DETAIL, (225, 230, 240), top4 - 2)
                             , ("No stroke, replay the shot", font("DejaVuSans-Bold.ttf", 23), (140, 230, 200), top4 + 41)]:
        d.text((mid - d.textlength(text, font=f) / 2, y), text, font=f, fill=fill)
    lab = font("DejaVuSans-Bold.ttf", 24)
    d.rounded_rectangle([332, top4 + 222, 470, top4 + 262], radius=5, fill=(28, 30, 38))
    d.text((344, top4 + 228), "3 REHIT", font=lab, fill=(255, 255, 255))
    e.save(HERE / "relief-water-mulligan-callout-row.jpg", quality=95)

if __name__ == "__main__":
    main()
