#!/usr/bin/env python3
"""Genera el video "David y Goliat" (1 Samuel 17): escenas ilustradas en
silueta, texto en pantalla y música original. Requiere Pillow, numpy y ffmpeg.

Uso: python3 generar_video.py [carpeta_salida]
"""
import math
import os
import random
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1920, 1080
FPS = 30
SS = 2  # supermuestreo para bordes suaves
BW, BH = int(W * 1.1), int(H * 1.1)  # fondo más grande para el movimiento de cámara
FADE = 0.9  # segundos de fundido entre escenas

FONT_DIR = "/usr/share/fonts/truetype"
F_TITLE = f"{FONT_DIR}/liberation/LiberationSerif-Bold.ttf"
F_TEXT = f"{FONT_DIR}/liberation/LiberationSerif-Regular.ttf"
F_QUOTE = f"{FONT_DIR}/liberation/LiberationSerif-Italic.ttf"

SIL = (14, 10, 12)  # color de las siluetas


# --------------------------------------------------------------- dibujo base
def gradient(top, bottom, w=BW * SS, h=BH * SS):
    t = np.linspace(0, 1, h)[:, None, None]
    a = np.array(top, float)[None, None, :]
    b = np.array(bottom, float)[None, None, :]
    g = a + (b - a) * t
    return Image.fromarray(np.broadcast_to(g, (h, w, 3)).astype(np.uint8))


def glow(img, cx, cy, r, color, strength=0.9):
    w, h = img.size
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / r
    a = np.clip(np.exp(-d * d) * strength, 0, 1)[..., None]
    base = np.asarray(img, float)
    out = base * (1 - a) + np.array(color, float) * a
    return Image.fromarray(out.astype(np.uint8))


def stars(d, n, seed=1, max_y=0.6):
    rnd = random.Random(seed)
    for _ in range(n):
        x = rnd.random() * BW * SS
        y = rnd.random() * BH * SS * max_y
        r = rnd.choice([1, 1, 2, 2, 3]) * SS / 2 + 0.5
        c = rnd.randint(170, 255)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(c, c, min(255, c + 20)))


def hill(d, pts_y, color, base=None):
    """Colina a partir de una lista de alturas relativas (0..1 del alto)."""
    w, h = BW * SS, BH * SS
    n = len(pts_y)
    pts = []
    for i in range(201):
        u = i / 200 * (n - 1)
        k = min(int(u), n - 2)
        f = u - k
        f = f * f * (3 - 2 * f)
        y = pts_y[k] * (1 - f) + pts_y[k + 1] * f
        pts.append((w * i / 200, y * h))
    pts += [(w, h), (0, h)]
    d.polygon(pts, fill=color)


def S(v):
    return v * SS


def person(d, x, gy, h, color=SIL, arm=None, staff=False, spear=False,
           helmet=False, shield=False, sling=False, facing=1, wide=1.0):
    """Silueta humana. x, gy en píxeles del fondo (sin supermuestreo)."""
    x, gy, h = S(x), S(gy), S(h)
    hr = h * 0.075
    head_y = gy - h + hr
    sh_y = head_y + hr * 1.6
    sw = h * 0.13 * wide
    # cabeza y cuello
    d.ellipse([x - hr, head_y - hr, x + hr, head_y + hr], fill=color)
    d.rectangle([x - hr * 0.45, head_y, x + hr * 0.45, sh_y + hr * 0.3], fill=color)
    # túnica
    hem_y = gy - h * 0.2
    d.polygon([(x - sw, sh_y), (x + sw, sh_y), (x + sw * 1.15, hem_y),
               (x - sw * 1.15, hem_y)], fill=color)
    # piernas
    lw = max(2, int(h * 0.045))
    d.line([(x - sw * 0.45, hem_y - 5), (x - sw * 0.6, gy)], fill=color, width=lw)
    d.line([(x + sw * 0.45, hem_y - 5), (x + sw * 0.6, gy)], fill=color, width=lw)
    aw = max(2, int(h * 0.04))
    # brazos
    hand_far = (x - facing * sw * 1.3, sh_y + h * 0.3)
    d.line([(x - facing * sw * 0.9, sh_y + 4), hand_far], fill=color, width=aw)
    if arm == "up":
        hand = (x + facing * sw * 1.2, sh_y - h * 0.3)
    elif arm == "forward":
        hand = (x + facing * sw * 2.6, sh_y + h * 0.05)
    else:
        hand = (x + facing * sw * 1.3, sh_y + h * 0.3)
    d.line([(x + facing * sw * 0.9, sh_y + 4), hand], fill=color, width=aw)
    if helmet:
        d.polygon([(x - hr * 1.15, head_y), (x + hr * 1.15, head_y),
                   (x, head_y - hr * 2.0)], fill=color)
        d.ellipse([x - hr * 0.3, head_y - hr * 2.4, x + hr * 0.3, head_y - hr * 1.8], fill=color)
    if staff:
        d.line([(hand[0], hand[1] - h * 0.55), (hand[0] + facing * 3, gy)],
               fill=color, width=aw)
        d.arc([hand[0] - h * 0.1, hand[1] - h * 0.68, hand[0] + h * 0.05,
               hand[1] - h * 0.48], 180, 360, fill=color, width=aw)
    if spear:
        d.line([(hand[0], hand[1] - h * 0.75), (hand[0], gy + 6)], fill=color, width=aw)
        tip = hand[1] - h * 0.75
        d.polygon([(hand[0] - aw * 2, tip), (hand[0] + aw * 2, tip),
                   (hand[0], tip - h * 0.1)], fill=color)
    if shield:
        sx = x - facing * sw * 1.5
        d.ellipse([sx - h * 0.12, sh_y + h * 0.05, sx + h * 0.12, sh_y + h * 0.42], fill=color)
    if sling:
        # cuerda de la honda girando sobre la cabeza
        cx, cy = hand
        d.arc([cx - h * 0.22, cy - h * 0.12, cx + h * 0.22, cy + h * 0.12],
              200, 520, fill=color, width=max(2, aw // 2))
        d.ellipse([cx + h * 0.2, cy - 8, cx + h * 0.2 + 16, cy + 8], fill=color)
    return hand


def sheep(d, x, gy, s, color=SIL):
    x, gy, s = S(x), S(gy), S(s)
    for dx, dy in [(-0.35, 0), (0.0, -0.15), (0.35, 0), (0, 0.05)]:
        d.ellipse([x + dx * s - s * 0.35, gy - s * 0.75 + dy * s - s * 0.3,
                   x + dx * s + s * 0.35, gy - s * 0.75 + dy * s + s * 0.3], fill=color)
    d.ellipse([x + s * 0.55, gy - s * 0.95, x + s * 0.9, gy - s * 0.65], fill=color)
    for lx in (-0.35, -0.1, 0.2, 0.4):
        d.line([(x + lx * s, gy - s * 0.5), (x + lx * s, gy)], fill=color, width=max(2, int(s * 0.08)))


def tent(d, x, gy, s, color=SIL):
    x, gy, s = S(x), S(gy), S(s)
    d.polygon([(x - s, gy), (x, gy - s * 0.9), (x + s, gy)], fill=color)
    d.line([(x, gy - s * 0.9), (x, gy - s * 1.3)], fill=color, width=max(2, int(s * 0.05)))
    d.polygon([(x, gy - s * 1.3), (x + s * 0.4, gy - s * 1.2), (x, gy - s * 1.1)], fill=color)


def army(d, x0, x1, gy_fn, h, seed, spear_every=2, color=SIL, facing=1):
    rnd = random.Random(seed)
    x = x0
    i = 0
    while x < x1:
        hh = h * rnd.uniform(0.9, 1.08)
        person(d, x, gy_fn(x), hh, color=color, spear=(i % spear_every == 0),
               helmet=True, shield=(i % 3 == 1), facing=facing)
        x += h * rnd.uniform(0.28, 0.42)
        i += 1


SHIFT = 0.12  # sube el horizonte para dejar el suelo libre para el texto


def finish(img):
    w, h = img.size
    dy = int(h * SHIFT)
    out = Image.new("RGB", (w, h), SIL)
    out.paste(img.crop((0, dy, w, h)), (0, 0))
    return out.resize((BW, BH), Image.LANCZOS)


# --------------------------------------------------------------- escenas
def sc_title():
    img = gradient((6, 8, 28), (40, 22, 48))
    img = glow(img, S(BW * 0.72), S(BH * 0.28), S(150), (240, 230, 200), 0.95)
    img = glow(img, S(BW * 0.72), S(BH * 0.28), S(420), (90, 80, 120), 0.35)
    d = ImageDraw.Draw(img)
    stars(d, 380, 7)
    d.ellipse([S(BW * 0.72 - 55), S(BH * 0.28 - 55), S(BW * 0.72 + 55), S(BH * 0.28 + 55)],
              fill=(250, 244, 222))
    hill(d, [0.78, 0.72, 0.8, 0.74, 0.79], (24, 18, 34))
    hill(d, [0.9, 0.85, 0.88, 0.83, 0.9], SIL)
    sheep(d, BW * 0.2, BH * 0.86, 40)
    sheep(d, BW * 0.26, BH * 0.865, 34)
    person(d, BW * 0.32, BH * 0.86, 150, staff=True)
    return finish(img)


def valley_ground(x):
    # alturas de las dos colinas con el valle en medio
    u = x / BW
    return BH * (0.62 + 0.28 * math.exp(-((u - 0.5) / 0.16) ** 2))


def sc_valley():
    img = gradient((70, 110, 160), (232, 180, 120))
    img = glow(img, S(BW * 0.5), S(BH * 0.55), S(260), (255, 220, 160), 0.8)
    d = ImageDraw.Draw(img)
    hill(d, [0.52, 0.48, 0.58, 0.47, 0.53], (110, 90, 100))
    hill(d, [0.6, 0.62, 0.9, 0.62, 0.6], (52, 38, 44))
    # suelo con el valle
    pts = [(S(x), S(valley_ground(x))) for x in range(0, BW + 1, 8)]
    d.polygon(pts + [(S(BW), S(BH)), (0, S(BH))], fill=SIL)
    for x in (120, 260, 400):
        tent(d, x, valley_ground(x), 55)
    for x in (BW - 140, BW - 300, BW - 450):
        tent(d, x, valley_ground(x), 55)
    army(d, 470, 760, valley_ground, 70, 3, facing=1)
    army(d, BW - 760, BW - 480, valley_ground, 70, 4, facing=-1)
    # arroyo en el fondo del valle
    d.line([(S(BW * 0.44), S(BH * 0.93)), (S(BW * 0.56), S(BH * 0.93))],
           fill=(120, 140, 170), width=S(5))
    return finish(img)


def sc_goliath():
    img = gradient((60, 8, 10), (210, 90, 40))
    img = glow(img, S(BW * 0.5), S(BH * 0.78), S(380), (255, 170, 80), 0.75)
    d = ImageDraw.Draw(img)
    hill(d, [0.84, 0.82, 0.83, 0.81, 0.84], SIL)
    # Goliat gigante
    person(d, BW * 0.5, BH * 0.84, 760, spear=True, helmet=True, shield=True,
           wide=1.35, facing=1)
    # armadura: placas en el pecho
    for i in range(4):
        yy = S(BH * 0.84 - 760 * (0.68 - i * 0.07))
        d.line([(S(BW * 0.5 - 110), yy), (S(BW * 0.5 + 110), yy)], fill=(60, 30, 25), width=S(3))
    # escudero pequeño
    person(d, BW * 0.33, BH * 0.84, 150, shield=True, helmet=True, facing=1)
    return finish(img)


def sc_fear():
    img = gradient((30, 32, 52), (96, 84, 100))
    d = ImageDraw.Draw(img)
    hill(d, [0.7, 0.68, 0.72, 0.69, 0.7], (50, 46, 62))
    hill(d, [0.86, 0.85, 0.87, 0.85, 0.86], SIL)
    rnd = random.Random(11)
    for i, x in enumerate(range(160, BW - 100, 140)):
        h = rnd.uniform(190, 240)
        person(d, x, BH * 0.86 + rnd.uniform(-4, 4), h, helmet=True,
               spear=(i % 2 == 0), shield=(i % 3 == 0), facing=-1 if i % 2 else 1)
    # Goliat lejano sobre el monte opuesto (sombra)
    person(d, BW * 0.5, BH * 0.69, 300, color=(40, 36, 52), helmet=True, spear=True,
           shield=True, wide=1.35)
    return finish(img)


def sc_shepherd():
    img = gradient((120, 170, 220), (255, 214, 150))
    img = glow(img, S(BW * 0.78), S(BH * 0.62), S(200), (255, 240, 190), 0.95)
    d = ImageDraw.Draw(img)
    hill(d, [0.62, 0.66, 0.6, 0.64, 0.6], (150, 140, 120))
    hill(d, [0.8, 0.76, 0.82, 0.78, 0.8], (96, 110, 80))
    hill(d, [0.9, 0.88, 0.89, 0.87, 0.9], SIL)
    person(d, BW * 0.36, BH * 0.89, 300, staff=True)
    # bolsa con comida al hombro
    d.ellipse([S(BW * 0.36 - 70), S(BH * 0.89 - 220), S(BW * 0.36 - 20), S(BH * 0.89 - 160)], fill=SIL)
    rnd = random.Random(5)
    for _ in range(9):
        sheep(d, BW * rnd.uniform(0.45, 0.8), BH * 0.875 + rnd.uniform(-6, 4), rnd.uniform(45, 65))
    return finish(img)


def sc_courage():
    img = gradient((40, 50, 90), (230, 160, 100))
    img = glow(img, S(BW * 0.5), S(BH * 0.2), S(500), (255, 230, 170), 0.55)
    d = ImageDraw.Draw(img)
    hill(d, [0.86, 0.85, 0.87, 0.85, 0.86], SIL)
    # rayos de luz
    for a in range(-5, 6):
        ang = math.radians(90 + a * 9)
        x2 = BW * 0.5 + math.cos(ang) * 1400
        y2 = BH * 0.2 + math.sin(ang) * 1400
        d.line([(S(BW * 0.5), S(BH * 0.2)), (S(x2), S(y2))], fill=(250, 210, 150), width=S(6))
    img = img.filter(ImageFilter.GaussianBlur(S(6)))
    d = ImageDraw.Draw(img)
    hill(d, [0.86, 0.85, 0.87, 0.85, 0.86], SIL)
    person(d, BW * 0.5, BH * 0.86, 330, arm="up")
    for x in (BW * 0.2, BW * 0.28, BW * 0.72, BW * 0.8):
        person(d, x, BH * 0.86, 260, helmet=True, spear=True)
    return finish(img)


def sc_stones():
    img = gradient((90, 140, 170), (200, 210, 180))
    d = ImageDraw.Draw(img)
    hill(d, [0.55, 0.5, 0.56, 0.52, 0.55], (110, 120, 110))
    # arroyo
    d.polygon([(0, S(BH * 0.7)), (S(BW), S(BH * 0.62)), (S(BW), S(BH * 0.8)), (0, S(BH * 0.9))],
              fill=(110, 160, 190))
    for i in range(12):
        y = BH * (0.68 + i * 0.015)
        d.line([(S(BW * 0.1 + i * 60), S(y)), (S(BW * 0.25 + i * 70), S(y - 8))],
               fill=(180, 215, 230), width=S(2))
    hill(d, [0.93, 0.9, 0.92, 0.9, 0.93], SIL)
    person(d, BW * 0.3, BH * 0.92, 380, arm="forward", facing=1)
    # cinco piedras lisas
    for i in range(5):
        x = BW * (0.45 + i * 0.06)
        d.ellipse([S(x - 26), S(BH * 0.885 - 18), S(x + 26), S(BH * 0.885 + 14)],
                  fill=(205, 200, 190), outline=SIL, width=S(3))
    return finish(img)


def sc_faceoff():
    img = gradient((20, 24, 50), (200, 120, 70))
    img = glow(img, S(BW * 0.5), S(BH * 0.75), S(320), (255, 200, 130), 0.8)
    d = ImageDraw.Draw(img)
    hill(d, [0.86, 0.86, 0.86, 0.86, 0.86], SIL)
    person(d, BW * 0.28, BH * 0.86, 240, sling=False, staff=True, facing=1)
    person(d, BW * 0.72, BH * 0.86, 780, spear=True, helmet=True, shield=True,
           wide=1.35, facing=-1)
    return finish(img)


def sc_sling():
    img = gradient((30, 40, 80), (240, 170, 90))
    img = glow(img, S(BW * 0.35), S(BH * 0.45), S(300), (255, 230, 170), 0.6)
    d = ImageDraw.Draw(img)
    hill(d, [0.86, 0.86, 0.86, 0.86, 0.86], SIL)
    hand = person(d, BW * 0.26, BH * 0.86, 300, arm="up", sling=True, facing=1)
    # trayectoria de la piedra
    sx, sy = hand[0] / SS + 60, hand[1] / SS
    tx, ty = BW * 0.72, BH * 0.86 - 760 + 50
    for i in range(1, 18):
        f = i / 18
        x = sx + (tx - sx) * f
        y = sy + (ty - sy) * f - math.sin(f * math.pi) * 60
        r = 3 + f * 6
        c = int(160 + 90 * f)
        d.ellipse([S(x - r), S(y - r), S(x + r), S(y + r)], fill=(c, c, c - 20))
    person(d, BW * 0.72, BH * 0.86, 780, spear=True, helmet=True, shield=True,
           wide=1.35, facing=-1)
    img = glow(img, S(tx), S(ty), S(40), (255, 250, 220), 0.9)
    return finish(img)


def sc_fallen():
    img = gradient((70, 120, 190), (250, 220, 160))
    img = glow(img, S(BW * 0.5), S(BH * 0.35), S(450), (255, 245, 210), 0.7)
    d = ImageDraw.Draw(img)
    hill(d, [0.86, 0.86, 0.86, 0.86, 0.86], SIL)
    # gigante caído (silueta horizontal)
    gy = BH * 0.86
    d.ellipse([S(BW * 0.43), S(gy - 70), S(BW * 0.5), S(gy)], fill=SIL)  # cabeza
    d.polygon([(S(BW * 0.43), S(gy - 75)), (S(BW * 0.47), S(gy - 130)),
               (S(BW * 0.47), S(gy - 60))], fill=SIL)  # casco
    d.polygon([(S(BW * 0.5), S(gy - 80)), (S(BW * 0.82), S(gy - 60)),
               (S(BW * 0.82), S(gy)), (S(BW * 0.5), S(gy))], fill=SIL)
    d.line([(S(BW * 0.82), S(gy - 30)), (S(BW * 0.97), S(gy - 10))], fill=SIL, width=S(18))
    d.line([(S(BW * 0.35), S(gy - 10)), (S(BW * 0.9), S(gy - 120))], fill=SIL, width=S(8))
    d.ellipse([S(BW * 0.58), S(gy - 150), S(BW * 0.68), S(gy - 40)], fill=SIL)  # escudo
    person(d, BW * 0.26, gy, 320, arm="up", facing=1)
    for x in (BW * 0.06, BW * 0.11, BW * 0.16):
        person(d, x, gy, 200, arm="up", helmet=True, spear=True)
    return finish(img)


def sc_lesson():
    img = gradient((10, 20, 60), (250, 190, 120))
    img = glow(img, S(BW * 0.5), S(BH * 0.78), S(360), (255, 230, 170), 0.95)
    d = ImageDraw.Draw(img)
    stars(d, 120, 3, max_y=0.3)
    hill(d, [0.84, 0.8, 0.83, 0.79, 0.84], SIL)
    person(d, BW * 0.5, BH * 0.81, 260, arm="up", staff=False)
    sheep(d, BW * 0.58, BH * 0.815, 46)
    sheep(d, BW * 0.43, BH * 0.82, 40)
    return finish(img)


# (escena, duración en s, texto, estilo)
SCENES = [
    (sc_title, 6.5, ("David y Goliat", "1 Samuel 17"), "title"),
    (sc_valley, 7.5, "En el valle de Elá, el ejército de Israel y el de los filisteos "
     "acampaban frente a frente, cada uno sobre un monte.", "text"),
    (sc_goliath, 7.5, "Cada día salía un gigante llamado Goliat, de casi tres metros de altura, "
     "y desafiaba a Israel: «¡Denme un hombre que pelee conmigo!»", "text"),
    (sc_fear, 7.0, "Durante cuarenta días nadie se atrevió a enfrentarlo. "
     "Todo el pueblo tenía mucho miedo.", "text"),
    (sc_shepherd, 7.0, "Entonces llegó David, un joven pastor de ovejas, "
     "llevando comida a sus hermanos.", "text"),
    (sc_courage, 7.0, "«¿Quién es este filisteo para desafiar a los ejércitos del Dios viviente?»\n"
     "— 1 Samuel 17:26", "quote"),
    (sc_stones, 7.5, "No llevó armadura ni espada. Tomó su cayado, su honda "
     "y escogió cinco piedras lisas del arroyo.", "text"),
    (sc_faceoff, 8.0, "«Tú vienes contra mí con espada y lanza; mas yo vengo a ti "
     "en el nombre del Señor.»\n— 1 Samuel 17:45", "quote"),
    (sc_sling, 7.0, "David corrió, puso una piedra en su honda y la lanzó... "
     "y la piedra se clavó en la frente del gigante.", "text"),
    (sc_fallen, 7.0, "Goliat cayó sobre su rostro en tierra, e Israel alcanzó la victoria.", "text"),
    (sc_lesson, 8.5, ("«La batalla es del Señor.»  — 1 Samuel 17:47",
                      "Con Dios, ningún gigante es demasiado grande."), "end"),
]


# --------------------------------------------------------------- texto
def wrap(draw, text, font, maxw):
    lines = []
    for para in text.split("\n"):
        words, cur = para.split(), ""
        for w in words:
            t = (cur + " " + w).strip()
            if draw.textlength(t, font=font) <= maxw:
                cur = t
            else:
                lines.append(cur)
                cur = w
        lines.append(cur)
    return lines


def text_layer(text, style):
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    if style == "title":
        f1 = ImageFont.truetype(F_TITLE, 150)
        f2 = ImageFont.truetype(F_QUOTE, 56)
        t1, t2 = text
        for dx, dy in [(4, 4)]:
            d.text((W / 2 + dx, H * 0.36 + dy), t1, font=f1, anchor="mm", fill=(0, 0, 0, 160))
        d.text((W / 2, H * 0.36), t1, font=f1, anchor="mm", fill=(250, 228, 170, 255))
        d.text((W / 2, H * 0.5), t2, font=f2, anchor="mm", fill=(235, 225, 210, 255))
        return layer
    if style == "end":
        f1 = ImageFont.truetype(F_QUOTE, 64)
        f2 = ImageFont.truetype(F_TITLE, 58)
        t1, t2 = text
        d.rounded_rectangle([W * 0.08, H * 0.12, W * 0.92, H * 0.42], 30, fill=(0, 0, 0, 120))
        d.text((W / 2, H * 0.21), t1, font=f1, anchor="mm", fill=(250, 232, 180, 255))
        d.text((W / 2, H * 0.33), t2, font=f2, anchor="mm", fill=(255, 255, 255, 255))
        return layer
    font = ImageFont.truetype(F_QUOTE if style == "quote" else F_TEXT, 46)
    lines = wrap(d, text, font, W * 0.8)
    lh = 58
    block = lh * len(lines)
    top = H - 70 - block
    band = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(band)
    bd.rounded_rectangle([W * 0.07, top - 24, W * 0.93, H - 46], 24, fill=(0, 0, 0, 110))
    layer = Image.alpha_composite(layer, band)
    d = ImageDraw.Draw(layer)
    for i, ln in enumerate(lines):
        is_ref = ln.startswith("—")
        f = ImageFont.truetype(F_TEXT, 36) if is_ref else font
        col = (250, 225, 160, 255) if (style == "quote" and not is_ref) else (245, 240, 230, 255)
        d.text((W / 2, top + i * lh + lh / 2), ln, font=f, anchor="mm", fill=col)
    return layer


# --------------------------------------------------------------- música
def music(duration, sr=44100):
    t_all = np.arange(int(duration * sr)) / sr
    out = np.zeros_like(t_all)

    def note(f):
        return 440.0 * 2 ** ((f - 69) / 12)

    # progresión: tensa (re menor) que se resuelve en mayor hacia el final
    chords = [
        [50, 57, 62, 65], [46, 53, 58, 62], [48, 55, 60, 64], [45, 52, 57, 61],
        [50, 57, 62, 65], [46, 53, 58, 65], [43, 50, 55, 58], [45, 52, 57, 61],
        [50, 57, 62, 65], [46, 53, 58, 62], [48, 55, 60, 64], [45, 52, 57, 61],
        [46, 53, 58, 62], [48, 55, 60, 64], [50, 57, 62, 66], [43, 50, 55, 59],
        [48, 55, 60, 64], [50, 57, 62, 66], [50, 57, 62, 66], [50, 57, 62, 66],
    ]
    cd = duration / len(chords)
    rng = np.random.default_rng(0)
    for i, ch in enumerate(chords):
        s0 = int(i * cd * sr)
        n = int((cd + 2.5) * sr)
        t = np.arange(n) / sr
        env = np.minimum(t / 1.4, 1) * np.exp(-np.maximum(t - cd, 0) / 0.9)
        seg = np.zeros(n)
        for m in ch:
            f = note(m)
            for det in (-0.12, 0.0, 0.13):
                ph = rng.random() * 6.28
                seg += np.sin(2 * np.pi * (f + det) * t + ph) * 0.06
                seg += np.sin(2 * np.pi * 2 * (f + det) * t + ph) * 0.012
        bass = np.sin(2 * np.pi * note(ch[0] - 12) * t) * 0.16
        seg = (seg + bass) * env
        e = min(len(out), s0 + n)
        out[s0:e] += seg[: e - s0]
        # arpegio suave
        for k in range(4):
            a0 = s0 + int(k * cd / 4 * sr)
            m = ch[[1, 2, 3, 2][k]] + 12
            nn = int(1.6 * sr)
            tt = np.arange(nn) / sr
            pl = np.sin(2 * np.pi * note(m) * tt) * np.exp(-tt * 3.2) * 0.05
            e2 = min(len(out), a0 + nn)
            if a0 < len(out):
                out[a0:e2] += pl[: e2 - a0]
    # tambor grave en la escena de la honda y la caída
    for tb in (sum(s[1] for s in SCENES[:8]) + 4.5, sum(s[1] for s in SCENES[:9]) + 0.3):
        s0 = int(tb * sr)
        nn = int(1.5 * sr)
        tt = np.arange(nn) / sr
        boom = np.sin(2 * np.pi * (55 * np.exp(-tt * 3) + 35) * tt) * np.exp(-tt * 3.5) * 0.6
        out[s0:s0 + nn] += boom[: len(out) - s0]
    # reverberación sencilla
    ir_n = int(2.2 * sr)
    ir = rng.standard_normal(ir_n) * np.exp(-np.arange(ir_n) / sr / 0.6)
    ir[0] = 6.0
    L = len(out) + ir_n
    nfft = 1 << (L - 1).bit_length()
    wet = np.fft.irfft(np.fft.rfft(out, nfft) * np.fft.rfft(ir, nfft), nfft)[: len(out)]
    mix = out * 0.6 + wet / np.max(np.abs(wet)) * np.max(np.abs(out)) * 0.5
    fade = np.minimum(1, np.minimum(t_all / 2.0, (duration - t_all) / 3.0))
    mix *= np.clip(fade, 0, 1)
    mix = mix / np.max(np.abs(mix)) * 0.8
    return (mix * 32767).astype(np.int16), sr


# --------------------------------------------------------------- render
def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
    os.makedirs(outdir, exist_ok=True)
    print("Dibujando escenas...")
    bgs = [np.asarray(fn()) for fn, *_ in SCENES]
    texts = [np.asarray(text_layer(t, st), dtype=np.float32) / 255.0 for _, _, t, st in SCENES]
    durs = [s[1] for s in SCENES]
    starts = np.cumsum([0] + durs[:-1])
    total = sum(durs)

    for i, b in enumerate(bgs):  # miniaturas de control
        Image.fromarray(b).resize((480, 270)).save(os.path.join(outdir, f"_escena_{i:02d}.jpg")) if os.environ.get("THUMBS") else None

    print("Componiendo música...")
    audio, sr = music(total)
    wav_path = os.path.join(outdir, "musica.wav")
    with wave.open(wav_path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(audio.tobytes())

    def scene_frame(i, lt):
        d = durs[i]
        p = min(max(lt / d, 0), 1)
        p = p * p * (3 - 2 * p) * 0.6 + p * 0.4
        z = 1.0 + 0.09 * p if i % 2 == 0 else 1.09 - 0.09 * p
        cw, ch = BW / z / 1.0, BH / z / 1.0
        cw, ch = min(BW, cw), min(BH, ch)
        pan = (p - 0.5) * (BW - cw) * (0.6 if i % 3 else -0.6)
        x0 = (BW - cw) / 2 + pan
        y0 = (BH - ch) / 2
        img = Image.fromarray(bgs[i]).resize((W, H), Image.BILINEAR,
                                             box=(x0, y0, x0 + cw, y0 + ch))
        frame = np.asarray(img, dtype=np.float32) / 255.0
        tl = texts[i]
        ta = min(1, max(0, (lt - 0.6) / 0.8), max(0, (d - lt - 0.2) / 0.6))
        a = tl[..., 3:4] * ta
        return frame * (1 - a) + tl[..., :3] * a

    video_tmp = os.path.join(outdir, "_video_sin_audio.mp4")
    ff = subprocess.Popen([
        "ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24",
        "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-c:v", "libx264", "-preset", "medium",
        "-crf", "19", "-pix_fmt", "yuv420p", video_tmp], stdin=subprocess.PIPE)
    nframes = int(total * FPS)
    print(f"Renderizando {nframes} cuadros...")
    for fi in range(nframes):
        t = fi / FPS
        i = int(np.searchsorted(starts, t, side="right") - 1)
        lt = t - starts[i]
        f = scene_frame(i, lt)
        if i + 1 < len(SCENES) and lt > durs[i] - FADE:
            k = (lt - (durs[i] - FADE)) / FADE
            f = f * (1 - k) + scene_frame(i + 1, lt - durs[i]) * k
        # fundido de entrada y salida a negro
        f *= min(1.0, t / 1.0, (total - t) / 1.5)
        ff.stdin.write((np.clip(f, 0, 1) * 255).astype(np.uint8).tobytes())
        if fi % 300 == 0:
            print(f"  {fi}/{nframes}")
    ff.stdin.close()
    ff.wait()

    final = os.path.join(outdir, "david_y_goliat.mp4")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", video_tmp, "-i", wav_path,
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest",
                    "-movflags", "+faststart", final], check=True)
    os.remove(video_tmp)
    print("Listo:", final)


if __name__ == "__main__":
    main()
