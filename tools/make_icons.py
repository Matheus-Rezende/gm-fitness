"""Gera o ícone do app (Android e iOS) a partir da marca: anilha azul com aro
amarelo e as letras GM em Barlow Condensed.

Uso: python3 tools/make_icons.py
"""
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, 'assets', 'fonts', 'BarlowCondensed-ExtraBold.ttf')
BLUE = (31, 79, 216)
YELLOW = (245, 183, 0)
WHITE = (255, 255, 255)


def draw_icon(size, round_mask=False):
    s = size * 4  # desenha maior e reduz para suavizar
    img = Image.new('RGBA', (s, s), BLUE + (255,))
    d = ImageDraw.Draw(img)
    c = s / 2
    # aro da anilha
    r = s * 0.36
    w = s * 0.06
    d.ellipse([c - r, c - r, c + r, c + r], outline=YELLOW, width=int(w))
    font = ImageFont.truetype(FONT, int(s * 0.36))
    text = 'GM'
    box = d.textbbox((0, 0), text, font=font)
    tw, th = box[2] - box[0], box[3] - box[1]
    d.text((c - tw / 2 - box[0], c - th / 2 - box[1]), text, font=font, fill=WHITE)
    img = img.resize((size, size), Image.LANCZOS)
    if round_mask:
        mask = Image.new('L', (size * 4, size * 4), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, size * 4 - 1, size * 4 - 1], fill=255)
        mask = mask.resize((size, size), Image.LANCZOS)
        out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        out.paste(img, (0, 0), mask)
        return out
    return img


def android():
    sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
    for name, px in sizes.items():
        path = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res', f'mipmap-{name}', 'ic_launcher.png')
        draw_icon(px).save(path)
    print('Android: ícones gerados')


def ios():
    folder = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    for fn in os.listdir(folder):
        m = re.match(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$', fn)
        if not m:
            continue
        px = round(float(m.group(1)) * int(m.group(2)))
        # iOS não aceita transparência no ícone
        draw_icon(px).convert('RGB').save(os.path.join(folder, fn))
    print('iOS: ícones gerados')


def splash_android():
    for folder in ('drawable', 'drawable-v21'):
        path = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res', folder, 'launch_background.xml')
        if not os.path.exists(path):
            continue
        with open(path, encoding='utf-8') as f:
            s = f.read()
        s = re.sub(r'<item android:drawable="[^"]+" />', '<item android:drawable="@color/gm_splash" />', s, count=1)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(s)
    colors = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res', 'values', 'colors.xml')
    with open(colors, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                '    <color name="gm_splash">#1F4FD8</color>\n</resources>\n')
    print('Android: cor da tela de abertura')


if __name__ == '__main__':
    android()
    ios()
    splash_android()
    draw_icon(512).save(os.path.join(ROOT, 'tools', 'icon-preview.png'))
