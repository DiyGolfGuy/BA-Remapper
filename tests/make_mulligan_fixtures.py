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

if __name__ == "__main__":
    main()
