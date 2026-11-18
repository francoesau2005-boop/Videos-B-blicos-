#!/usr/bin/env python3
"""Video vertical (TikTok / Shorts) de Daniel y los leones (Daniel 6).

Uso:
  python3 generar_video.py                 # sin voz: tiempos estimados
  python3 generar_video.py --voz voz.m4a   # con la narración grabada
  python3 generar_video.py --muestra       # solo una hoja con todas las escenas
  python3 generar_video.py --voz voz.wav --sin-subtitulos
"""
import argparse
import math
import os
import random
import re
import subprocess
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

from personajes import lion, person, stone, table, dark, light

W, H = 1080, 1920
BW, BH = int(W * 1.1), int(H * 1.1)
FPS = 30
SSB = 2  # supermuestreo de fondos
AQUI = os.path.dirname(os.path.abspath(__file__))
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

LINES = [l.split(". ", 1)[1] for l in open(os.path.join(AQUI, "guion.md"), encoding="utf-8")
         .read().splitlines() if re.match(r"^\d+\. ", l)]

# --------------------------------------------------------------- personajes
DAN = dict(robe=(52, 96, 170), inner=(236, 226, 200), sash=(220, 170, 60), head="turban")
KING = dict(robe=(120, 50, 140), inner=(235, 200, 90), sash=(240, 190, 60), head="crown",
            hair=(30, 22, 20), beard=1.6)
OFF1 = dict(robe=(170, 50, 45), inner=(230, 210, 170), sash=(60, 120, 90), head="tallhat",
            headc=(90, 60, 40), hair=(40, 28, 22))
OFF2 = dict(robe=(46, 120, 96), inner=(226, 214, 180), sash=(170, 60, 50), head="tallhat",
            headc=(60, 50, 70), hair=(70, 46, 30), beard=0.6)
ANGEL = dict(robe=(250, 248, 240), inner=(255, 240, 190), sash=(240, 200, 90), hair=(230, 190, 90),
             beard=0, head="curly", wings=True)


# --------------------------------------------------------------- fondos
def S(v):
    return v * SSB


def canvas(top, bottom):
    h, w = BH * SSB, BW * SSB
    t = np.linspace(0, 1, h)[:, None, None]
    g = np.array(top, float) + (np.array(bottom, float) - np.array(top, float)) * t
    return Image.fromarray(np.broadcast_to(g, (h, w, 3)).astype(np.uint8))


def glow(img, cx, cy, r, color, strength=0.8):
    w, h = img.size
    sc = 4
    yy, xx = np.mgrid[0:h // sc, 0:w // sc]
    d = np.sqrt((xx * sc - S(cx)) ** 2 + (yy * sc - S(cy)) ** 2) / S(r)
    a = np.clip(np.exp(-d * d) * strength, 0, 1)
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).resize((w, h), Image.BILINEAR),
                   float)[..., None] / 255
    out = np.asarray(img, float) * (1 - a) + np.array(color, float) * a
    return Image.fromarray(out.astype(np.uint8))


def R(d, x0, y0, x1, y1, fill, outline=None, w=0):
    d.rectangle([S(x0), S(y0), S(x1), S(y1)], fill=fill, outline=outline, width=S(w))


def E(d, x0, y0, x1, y1, fill, outline=None, w=0):
    d.ellipse([S(x0), S(y0), S(x1), S(y1)], fill=fill, outline=outline, width=S(w))


def Pg(d, pts, fill, outline=None, w=0):
    d.polygon([(S(x), S(y)) for x, y in pts], fill=fill, outline=outline, width=S(w) if outline else 0)


FLOOR = 0.80 * BH  # línea del piso en interiores


def column(d, x, w, top, bottom, c=(236, 218, 180)):
    R(d, x - w / 2, top + 40, x + w / 2, bottom - 30, c)
    for k in range(1, 5):
        xx = x - w / 2 + w * k / 5
        d.line([(S(xx), S(top + 50)), (S(xx), S(bottom - 40))], fill=dark(c, 0.85), width=S(3))
    R(d, x - w * 0.7, top, x + w * 0.7, top + 44, light(c, 0.2), dark(c, 0.8), 2)
    E(d, x - w * 0.85, top + 8, x - w * 0.45, top + 46, c, dark(c, 0.8), 2)
    E(d, x + w * 0.45, top + 8, x + w * 0.85, top + 46, c, dark(c, 0.8), 2)
    R(d, x - w * 0.7, bottom - 34, x + w * 0.7, bottom, light(c, 0.2), dark(c, 0.8), 2)


def tiles_band(d, y0, y1):
    R(d, 0, y0, BW, y1, (38, 86, 170))
    bh = (y1 - y0) / 4
    for r in range(5):
        y = y0 + r * bh
        d.line([(0, S(y)), (S(BW), S(y))], fill=(26, 64, 130), width=S(3))
        off = 0 if r % 2 else 40
        for x in range(-80 + off, BW + 80, 80):
            d.line([(S(x), S(y)), (S(x), S(y + bh))], fill=(26, 64, 130), width=S(3))
    for x in range(60, BW, 150):
        cy = (y0 + y1) / 2
        for a in range(8):
            ang = a * math.pi / 4
            E(d, x + math.cos(ang) * 18 - 9, cy + math.sin(ang) * 18 - 9,
              x + math.cos(ang) * 18 + 9, cy + math.sin(ang) * 18 + 9, (240, 200, 90))
        E(d, x - 10, cy - 10, x + 10, cy + 10, (255, 236, 170))


def floor(d, y0, c1=(176, 122, 82), c2=(156, 104, 70)):
    R(d, 0, y0, BW, BH, c1)
    rows = 6
    for r in range(rows):
        y = y0 + (BH - y0) * (r / rows) ** 1.3
        d.line([(0, S(y)), (S(BW), S(y))], fill=c2, width=S(3))
    for k in range(-8, 9):
        x0 = BW / 2 + k * 70
        x1 = BW / 2 + k * 260
        d.line([(S(x0), S(y0)), (S(x1), S(BH))], fill=c2, width=S(3))


def curtains(d):
    red = (170, 36, 46)
    for s in (0, 1):
        x = 0 if s == 0 else BW
        sg = 1 if s == 0 else -1
        Pg(d, [(x, 0), (x + sg * 300, 0), (x + sg * 120, 520), (x + sg * 60, 900), (x, 900)], red,
           dark(red), 3)
        for k in range(1, 4):
            d.line([(S(x + sg * 70 * k), 0), (S(x + sg * (25 + 18 * k)), S(860))], fill=dark(red, 0.8),
                   width=S(4))
        E(d, x + sg * 80 - 22, 860, x + sg * 80 + 22, 900, (240, 190, 60))
    R(d, 0, 0, BW, 60, (150, 30, 40))
    for x in range(0, BW, 60):
        E(d, x, 40, x + 60, 100, (150, 30, 40))


def palace(night=False, throne=False):
    img = canvas((236, 206, 160), (214, 176, 126))
    d = ImageDraw.Draw(img)
    tiles_band(d, BH * 0.5, BH * 0.6)
    if throne:
        gold = (232, 182, 64)
        Pg(d, [(BW * 0.5 - 170, FLOOR - 520), (BW * 0.5 + 170, FLOOR - 520), (BW * 0.5 + 200, FLOOR),
               (BW * 0.5 - 200, FLOOR)], gold, dark(gold), 3)
        E(d, BW * 0.5 - 180, FLOOR - 640, BW * 0.5 + 180, FLOOR - 400, gold, dark(gold), 3)
        R(d, BW * 0.5 - 120, FLOOR - 470, BW * 0.5 + 120, FLOOR - 60, (150, 40, 60))
        R(d, BW * 0.5 - 240, FLOOR - 40, BW * 0.5 + 240, FLOOR + 20, (200, 160, 110), dark((200, 160, 110)), 2)
    for x in (110, BW - 110):
        column(d, x, 130, BH * 0.22, FLOOR)
    floor(d, FLOOR)
    curtains(d)
    if night:
        a = np.asarray(img, float)
        a = a * np.array([0.35, 0.38, 0.62])
        img = Image.fromarray(a.astype(np.uint8))
        d = ImageDraw.Draw(img)
        # ventana con luna
        R(d, BW * 0.5 - 150, BH * 0.18, BW * 0.5 + 150, BH * 0.42, (20, 26, 60), (60, 50, 50), 10)
        E(d, BW * 0.5 + 10, BH * 0.22, BW * 0.5 + 100, BH * 0.22 + 90, (250, 244, 214))
        for k in range(14):
            rnd = random.Random(k)
            x = BW * 0.5 - 140 + rnd.random() * 280
            y = BH * 0.19 + rnd.random() * BH * 0.22
            E(d, x - 3, y - 3, x + 3, y + 3, (230, 230, 250))
        img = glow(img, BW * 0.75, FLOOR - 300, 300, (255, 180, 90), 0.35)
    return img


def pit(angel=False):
    img = canvas((20, 16, 24), (70, 52, 40))
    d = ImageDraw.Draw(img)
    rnd = random.Random(4)
    for _ in range(140):
        x = rnd.random() * BW
        y = rnd.random() * BH * 0.85
        r = rnd.uniform(40, 110)
        c = rnd.randint(38, 70)
        E(d, x - r, y - r * 0.7, x + r, y + r * 0.7, (c + 10, c, c - 8), (c - 15, c - 22, c - 28), 3)
    # boca del foso arriba
    E(d, BW * 0.5 - 260, BH * 0.06, BW * 0.5 + 260, BH * 0.06 + 150, (24, 34, 74), (30, 24, 20), 10)
    E(d, BW * 0.5 + 60, BH * 0.075, BW * 0.5 + 120, BH * 0.075 + 60, (240, 238, 210))
    R(d, 0, FLOOR, BW, BH, (88, 66, 46))
    for _ in range(90):
        x = rnd.random() * BW
        y = FLOOR + rnd.random() * (BH - FLOOR)
        d.line([(S(x), S(y)), (S(x + rnd.uniform(-30, 30)), S(y - 14))], fill=(170, 140, 80), width=S(3))
    beam = Image.new("L", img.size, 0)
    bd = ImageDraw.Draw(beam)
    bd.polygon([(S(BW * 0.5 - 220), S(BH * 0.12)), (S(BW * 0.5 + 220), S(BH * 0.12)),
                (S(BW * 0.5 + 420), S(FLOOR + 80)), (S(BW * 0.5 - 420), S(FLOOR + 80))], fill=70)
    beam = beam.filter(ImageFilter.GaussianBlur(S(30)))
    col = Image.new("RGB", img.size, (170, 190, 255) if not angel else (255, 236, 170))
    img = Image.composite(col, img, beam)
    if angel:
        img = glow(img, BW * 0.5, FLOOR - 450, 520, (255, 236, 170), 0.75)
    return img


def house():
    img = canvas((226, 190, 140), (206, 168, 120))
    d = ImageDraw.Draw(img)
    # ventana abierta hacia Jerusalén
    x0, x1, y0, y1 = BW * 0.5 - 250, BW * 0.5 + 250, BH * 0.2, BH * 0.62
    sky = canvas((90, 70, 140), (250, 160, 90)).crop((0, 0, S(x1 - x0), S(y1 - y0)))
    img.paste(sky, (int(S(x0)), int(S(y0))))
    d = ImageDraw.Draw(img)
    E(d, BW * 0.5 - 70, y1 - 230, BW * 0.5 + 70, y1 - 90, (255, 214, 140))
    Pg(d, [(x0, y1 - 60), (x0 + 120, y1 - 140), (x0 + 260, y1 - 90), (x0 + 380, y1 - 160), (x1, y1 - 80),
           (x1, y1), (x0, y1)], (120, 80, 100))
    # Jerusalén a lo lejos
    for i, (bx, bw_, bh_) in enumerate([(70, 50, 60), (130, 40, 90), (180, 70, 50), (260, 46, 110),
                                        (316, 60, 70), (386, 40, 56)]):
        R(d, x0 + bx, y1 - 90 - bh_, x0 + bx + bw_, y1 - 60, (90, 56, 80))
    R(d, x0 - 30, y0 - 30, x1 + 30, y0, (120, 80, 50))
    R(d, x0 - 30, y1, x1 + 30, y1 + 40, (120, 80, 50))
    R(d, x0 - 30, y0, x0, y1, (120, 80, 50))
    R(d, x1, y0, x1 + 30, y1, (120, 80, 50))
    # postigos abiertos
    for s in (-1, 1):
        xe = x0 - 30 if s < 0 else x1 + 30
        Pg(d, [(xe, y0), (xe + s * 150, y0 + 40), (xe + s * 150, y1 - 10), (xe, y1)], (150, 96, 56),
           (100, 64, 36), 3)
        for k in range(1, 6):
            yy = y0 + (y1 - y0) * k / 6
            d.line([(S(xe), S(yy)), (S(xe + s * 150), S(yy + 20 - k * 3))], fill=(110, 70, 40), width=S(3))
    floor(d, FLOOR, (168, 116, 78), (150, 100, 66))
    E(d, BW * 0.5 - 380, FLOOR + 80, BW * 0.5 + 380, FLOOR + 300, (160, 40, 50), (120, 30, 40), 4)
    E(d, BW * 0.5 - 300, FLOOR + 115, BW * 0.5 + 300, FLOOR + 265, None, (240, 190, 90), 4)
    img = glow(img, BW * 0.5, BH * 0.42, 420, (255, 200, 130), 0.35)
    return img


def outside(dawn=False, night=False, pit_mouth=True, sealed=False, sunset=False):
    if night:
        img = canvas((14, 18, 46), (60, 50, 90))
    elif sunset:
        img = canvas((70, 50, 120), (252, 150, 80))
    else:
        img = canvas((120, 150, 210), (255, 200, 150)) if dawn else canvas((110, 170, 230), (220, 230, 240))
    d = ImageDraw.Draw(img)
    if night:
        for k in range(120):
            rnd = random.Random(k)
            x, y = rnd.random() * BW, rnd.random() * BH * 0.5
            E(d, x - 2.5, y - 2.5, x + 2.5, y + 2.5, (220, 220, 250))
        E(d, BW * 0.7, BH * 0.12, BW * 0.7 + 120, BH * 0.12 + 120, (250, 244, 214))
    else:
        img = glow(img, BW * 0.5, BH * 0.55, 380, (255, 232, 170), 0.6 if (dawn or sunset) else 0.3)
        d = ImageDraw.Draw(img)
    gy = BH * 0.62
    hills = (120, 90, 120) if not night else (40, 40, 70)
    Pg(d, [(0, gy - 60), (BW * 0.3, gy - 130), (BW * 0.6, gy - 70), (BW, gy - 150), (BW, gy), (0, gy)], hills)
    # muralla de Babilonia
    wall = (196, 150, 104) if not night else (70, 60, 80)
    R(d, BW * 0.05, gy - 260, BW * 0.95, gy, wall, dark(wall, 0.8), 3)
    for x in np.arange(BW * 0.05, BW * 0.95, 60):
        R(d, x, gy - 290, x + 34, gy - 260, wall)
    for r in range(1, 8):
        y = gy - 260 + r * 33
        d.line([(S(BW * 0.05), S(y)), (S(BW * 0.95), S(y))], fill=dark(wall, 0.88), width=S(2))
    R(d, BW * 0.5 - 70, gy - 170, BW * 0.5 + 70, gy, dark(wall, 0.55))
    E(d, BW * 0.5 - 70, gy - 240, BW * 0.5 + 70, gy - 100, dark(wall, 0.55))
    ground = (196, 150, 96) if not night else (60, 52, 66)
    R(d, 0, gy, BW, BH, ground)
    rnd = random.Random(9)
    for _ in range(60):
        x, y = rnd.random() * BW, gy + 20 + rnd.random() * (BH - gy)
        d.line([(S(x), S(y)), (S(x + 10), S(y - 12))], fill=dark(ground, 0.8), width=S(3))
    if pit_mouth:
        cx, cy = BW * 0.5, BH * 0.86
        E(d, cx - 330, cy - 110, cx + 330, cy + 110, (120, 110, 100), dark((120, 110, 100)), 4)
        E(d, cx - 280, cy - 80, cx + 280, cy + 80, (16, 12, 14))
        if sealed:
            E(d, cx - 300, cy - 120, cx + 300, cy + 100, (150, 140, 130), dark((150, 140, 130)), 4)
            E(d, cx - 200, cy - 95, cx + 40, cy - 30, (175, 166, 156))
            E(d, cx - 30, cy - 40, cx + 30, cy + 10, (180, 30, 40), (120, 20, 30), 3)
    return img


# --------------------------------------------------------------- escenas
FL = FLOOR + 10  # pies en interiores
GY = BH * 0.80   # pies en exteriores


def sprite(fn, x, y, bob=0.0, move=(0, 0), delay=0.0):
    img, anchor = fn
    return dict(img=img, ax=anchor[0], ay=anchor[1], x=x, y=y, bob=bob, move=move, delay=delay, steps=None)


def walker(H, x0, x1, y, frac=0.75, **kw):
    """Personaje que camina de x0 a x1 durante la primera parte de la escena y luego se detiene."""
    base = sprite(person(H, **kw), x1, y, bob=2)
    base["walk"] = (x0, x1, frac)
    base["steps"] = [person(H, step=st, **kw)[0] for st in (1, -1)]
    return base


def scenes():
    big = 880
    sc = []
    # 1 gancho
    sc.append((pit(), [
        sprite(person(big, pose="pray", mood="closed", **DAN), BW / 2, FL - 60, bob=3),
        sprite(lion(600, mood="roar", facing=1), 170, FL + 230, bob=4),
        sprite(lion(600, mood="roar", facing=-1), BW - 170, FL + 230, bob=4),
    ]))
    # 2 Daniel sirve al rey
    sc.append((palace(throne=True), [
        sprite(person(big, pose="stand", mood="happy", facing=-1, **KING), BW * 0.68, FL, bob=3),
        walker(big * 0.95, -250, BW * 0.3, FL + 10, pose="stand", facing=1, **DAN),
    ]))
    # 3 el rey lo quiere poner sobre el reino
    sc.append((palace(throne=True), [
        sprite(person(big, pose="point", mood="happy", facing=-1, **KING), BW * 0.7, FL, bob=3),
        sprite(person(big * 0.95, pose="stand", mood="happy", facing=1, **DAN), BW * 0.3, FL + 10, bob=2),
    ]))
    # 4 envidia
    sc.append((palace(), [
        walker(big, -200, BW * 0.32, FL, frac=0.5, pose="stand", mood="angry", facing=1, **OFF1),
        walker(big, BW + 200, BW * 0.7, FL + 10, frac=0.5, pose="sad", mood="angry", facing=-1, **OFF2),
    ]))
    # 5 buscan un error
    sc.append((palace(), [
        sprite(person(big * 0.9, pose="stand", mood="calm", facing=-1, **DAN), BW * 0.68, FL - 10),
        sprite(table(560), BW * 0.62, FL + 40),
        walker(big * 0.85, -300, BW * 0.14, FL + 30, frac=0.9, pose="sad", mood="angry", facing=1, **OFF1),
        walker(big * 0.85, -120, BW * 0.3, FL + 50, frac=0.9, pose="stand", mood="angry", facing=1, **OFF2),
    ]))
    # 6 la ley
    sc.append((palace(throne=True), [
        sprite(person(big, pose="scroll", mood="calm", facing=1, **KING), BW * 0.5, FL, bob=2),
        sprite(person(big * 0.85, pose="bow", mood="happy", facing=1, **OFF1), BW * 0.15, FL + 40, bob=2),
        sprite(person(big * 0.85, pose="point", mood="happy", facing=-1, **OFF2), BW * 0.86, FL + 40, bob=2),
    ]))
    # 7 los leones
    sc.append((pit(), [
        sprite(lion(520, mood="roar", facing=1), BW * 0.3, FL - 90, bob=5),
        sprite(lion(760, mood="roar", facing=-1), BW * 0.62, FL + 220, bob=5),
    ]))
    # 8 Daniel abre la ventana
    sc.append((house(), [
        walker(big, BW * 0.12, BW * 0.5, FL + 30, frac=0.7, pose="stand", mood="calm", facing=1, **DAN),
    ]))
    # 9 ora tres veces al día
    sc.append((house(), [
        sprite(person(big, pose="kneel", mood="pray", facing=1, **DAN), BW * 0.45, FL + 60, bob=2),
    ]))
    # 10 lo acusan
    sc.append((palace(throne=True), [
        sprite(person(big * 0.95, pose="sad", mood="sad", facing=-1, **KING), BW * 0.5, FL - 20, bob=2),
        sprite(person(big * 0.85, pose="point", mood="angry", facing=1, **OFF1), BW * 0.16, FL + 50, bob=2),
        sprite(person(big * 0.85, pose="point", mood="angry", facing=-1, **OFF2), BW * 0.84, FL + 50, bob=2),
    ]))
    # 11 echado al foso y sellado
    sc.append((outside(night=True, sealed=True), [
        sprite(person(big * 0.8, pose="sad", mood="sad", facing=1, **KING), BW * 0.15, GY + 40, bob=2),
        walker(big * 0.72, BW * 0.6, BW + 300, GY + 20, frac=1.0, pose="stand", mood="calm", facing=1, **OFF1),
    ]))
    # 12 el rey no duerme
    sc.append((palace(night=True), [
        sprite(person(big, pose="sad", mood="sad", facing=1, **KING), BW * 0.5, FL, bob=2),
    ]))
    # 13 al amanecer grita
    sc.append((outside(dawn=True), [
        sprite(stone(330), BW * 0.12, BH * 0.92),
        walker(big * 0.95, -250, BW * 0.28, GY + 20, frac=0.45, pose="call", mood="shout", facing=1, **KING),
    ]))
    # 14 el ángel
    sc.append((pit(angel=True), [
        sprite(person(big * 0.95, pose="open", mood="calm", **ANGEL), BW * 0.5, FL - 330, bob=10),
        sprite(lion(520, pose="lying", mood="calm", facing=1), BW * 0.24, FL + 120, bob=2),
        sprite(lion(520, pose="lying", mood="calm", facing=-1), BW * 0.78, FL + 140, bob=2),
        sprite(person(big * 0.8, pose="pray", mood="happy", facing=1, **DAN), BW * 0.5, FL + 160, bob=2),
    ]))
    # 15 sale sin heridas
    sc.append((outside(), [
        walker(big, -250, BW * 0.33, GY + 20, frac=0.6, pose="open", mood="happy", facing=1, **DAN),
        sprite(person(big, pose="open", mood="happy", facing=-1, **KING), BW * 0.7, GY + 20, bob=3),
    ]))
    # 16 mensaje
    sc.append((outside(sunset=True, pit_mouth=False), [
        sprite(person(big * 1.05, pose="arms_up", mood="happy", facing=1, **DAN), BW * 0.5, GY + 120, bob=4),
    ]))
    # 17 cierre
    sc.append((outside(sunset=True, pit_mouth=False), [
        sprite(lion(520, pose="lying", mood="calm", facing=1), BW * 0.3, GY + 200, bob=2),
        walker(big * 0.95, BW + 250, BW * 0.7, GY + 160, frac=0.6, pose="stand", mood="happy", facing=-1, **DAN),
    ]))
    return sc


# --------------------------------------------------------------- tiempos
def syl(word):
    return max(1, len(re.findall(r"[aeiouáéíóúü]+", word.lower())))


def word_weights(line):
    words = line.split()
    ws = []
    for w in words:
        k = syl(w)
        if re.search(r"[,;:]$", w):
            k += 1.2
        if re.search(r"(…|\.|\?|!|»)$", w):
            k += 1.8
        ws.append(k)
    return words, ws


def estimate_segments():
    t, segs = 0.6, []
    for ln in LINES:
        _, ws = word_weights(ln)
        d = sum(ws) * 0.165
        segs.append((t, t + d))
        t += d + 0.55
    return segs, t + 0.8


def voice_segments(path, n):
    """Detecta las frases en la voz grabada usando los silencios."""
    out = subprocess.run(["ffmpeg", "-hide_banner", "-i", path, "-af",
                          "silencedetect=noise=-35dB:d=0.45", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    dur = float(re.search(r"Duration: (\d+):(\d+):([\d.]+)", out).groups()[2]) + \
        60 * float(re.search(r"Duration: (\d+):(\d+)", out).group(2)) + \
        3600 * float(re.search(r"Duration: (\d+)", out).group(1))
    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", out)]
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", out)]
    speech, cur = [], 0.0
    for s, e in zip(starts, ends + [dur] * (len(starts) - len(ends))):
        if s - cur > 0.15:
            speech.append([cur, s])
        cur = e
    if dur - cur > 0.15:
        speech.append([cur, dur])
    # agrupar los tramos de voz en n frases según la duración esperada (programación dinámica)
    if len(speech) > n:
        syls = [sum(syl(w) for w in ln.split()) for ln in LINES]
        m = len(speech)
        k = sum(e - s for s, e in speech) / sum(syls)
        INF = float("inf")
        cost = [[INF] * (n + 1) for _ in range(m + 1)]
        back = [[0] * (n + 1) for _ in range(m + 1)]
        cost[0][0] = 0
        for j in range(1, n + 1):
            for i in range(j, m + 1):
                for a in range(j - 1, i):
                    if cost[a][j - 1] == INF:
                        continue
                    dd = speech[i - 1][1] - speech[a][0]
                    c = cost[a][j - 1] + (dd - k * syls[j - 1] * 1.08) ** 2
                    if c < cost[i][j]:
                        cost[i][j], back[i][j] = c, a
        groups, i = [], m
        for j in range(n, 0, -1):
            a = back[i][j]
            groups.append([speech[a][0], speech[i - 1][1], speech[a:i]])
            i = a
        speech = groups[::-1]
    while len(speech) < n:
        i = int(np.argmax([e - s for s, e in speech]))
        s, e = speech[i]
        speech[i:i + 1] = [[s, (s + e) / 2], [(s + e) / 2, e]]
    return [tuple(x) for x in speech], dur + 1.2


def word_times(segs):
    out = []
    for ln, seg in zip(LINES, segs):
        s, e = seg[0], seg[1]
        parts = seg[2] if len(seg) > 2 else [(s, e)]
        words, ws = word_weights(ln)
        if len(parts) > 1:  # con pausas internas: repartir solo sobre el tiempo con voz
            ws = [syl(w) + (0.6 if re.search(r"[,;:….?!»]$", w) else 0) for w in words]
        speech = sum(b - a for a, b in parts)

        def real(x):  # tiempo de voz -> tiempo real saltando silencios
            for a, b in parts:
                if x <= b - a + 1e-9:
                    return a + x
                x -= b - a
            return parts[-1][1]
        tot = sum(ws)
        acc = 0.0
        for w, k in zip(words, ws):
            d = speech * k / tot
            out.append((w, real(acc), real(acc + d) if acc + d < speech - 1e-6 else parts[-1][1], len(out)))
            acc += d
    return out


def chunks(words_t):
    """Agrupa palabras de cada frase en bloques cortos (como subtítulos de TikTok)."""
    res, li = [], 0
    idx = 0
    for ln in LINES:
        n = len(ln.split())
        ws = words_t[idx:idx + n]
        idx += n
        cur = []
        for w in ws:
            cur.append(w)
            txt = " ".join(x[0] for x in cur)
            if len(cur) >= 4 or len(txt) > 20 or re.search(r"[,.:;…?!»]$", w[0]):
                res.append(cur)
                cur = []
        if cur:
            res.append(cur)
        li += 1
    return res


# --------------------------------------------------------------- subtítulos
FNT = ImageFont.truetype(FONT, 78)


def draw_caption(img, chunk, t):
    d = ImageDraw.Draw(img)
    words = [w[0] for w in chunk]
    space = d.textlength(" ", font=FNT)
    widths = [d.textlength(w, font=FNT) for w in words]
    maxw = W * 0.86
    lines, cur, cw = [], [], 0
    for i, wd in enumerate(widths):
        if cur and cw + space + wd > maxw:
            lines.append(cur)
            cur, cw = [], 0
        cw += (space if cur else 0) + wd
        cur.append(i)
    lines.append(cur)
    y = H * 0.25
    lh = 100
    pop = 0
    for li, ln in enumerate(lines):
        tw = sum(widths[i] for i in ln) + space * (len(ln) - 1)
        x = (W - tw) / 2
        for i in ln:
            w, t0, t1, _ = chunk[i]
            active = t0 <= t < t1
            done = t >= t1
            yy = y + li * lh
            if active:
                pop = min(1.0, (t - t0) / 0.08)
                pad = 14
                d.rounded_rectangle([x - pad, yy - 10, x + widths[i] + pad, yy + 92], 18,
                                    fill=(255, 196, 40))
                d.text((x, yy), w, font=FNT, fill=(30, 20, 10))
            else:
                col = (255, 255, 255) if done else (196, 190, 182)
                d.text((x, yy), w, font=FNT, fill=col, stroke_width=6, stroke_fill=(20, 14, 10))
            x += widths[i] + space
    return img


# --------------------------------------------------------------- música
def music(duration, sr=44100):
    n = int(duration * sr)
    out = np.zeros(n)

    def hz(m):
        return 440.0 * 2 ** ((m - 69) / 12)
    prog = [[45, 52, 57, 60, 64], [41, 48, 53, 57, 60], [43, 50, 55, 59, 62], [40, 47, 52, 55, 59]]
    prog_end = [[41, 48, 53, 57, 60], [43, 50, 55, 59, 62], [48, 55, 60, 64, 67], [48, 55, 60, 64, 67]]
    cd = 4.0
    rng = np.random.default_rng(1)
    k = 0
    t0 = 0.0
    while t0 < duration:
        ch = (prog_end if t0 > duration * 0.75 else prog)[k % 4]
        s0 = int(t0 * sr)
        m = int((cd + 2) * sr)
        t = np.arange(m) / sr
        env = np.minimum(t / 1.2, 1) * np.exp(-np.maximum(t - cd, 0) / 0.8)
        seg = np.zeros(m)
        for note in ch:
            for det in (-0.15, 0.15):
                seg += np.sin(2 * np.pi * (hz(note) + det) * t + rng.random() * 6) * 0.05
        seg += np.sin(2 * np.pi * hz(ch[0] - 12) * t) * 0.12
        e = min(n, s0 + m)
        out[s0:e] += (seg * env)[:e - s0]
        for j in range(8):
            a0 = s0 + int(j * cd / 8 * sr)
            mm = int(1.2 * sr)
            tt = np.arange(mm) / sr
            note = ch[[2, 3, 4, 3, 2, 3, 4, 1][j]] + 12
            pl = np.sin(2 * np.pi * hz(note) * tt) * np.exp(-tt * 4) * 0.035
            e2 = min(n, a0 + mm)
            if a0 < n:
                out[a0:e2] += pl[:e2 - a0]
        k += 1
        t0 += cd
    tt = np.arange(n) / sr
    out *= np.clip(np.minimum(tt / 1.5, (duration - tt) / 2.0), 0, 1)
    return out / np.max(np.abs(out)) * 0.9, sr


def write_wav(path, x, sr):
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())


# --------------------------------------------------------------- render
def compose(bg, sprites, lt, d, i):
    img = bg.copy()
    for s in sprites:
        f = min(1, lt / max(d, 0.1))
        ph = lt * 2 * math.pi * 0.6 + s["x"] * 0.01
        x = s["x"] + s["move"][0] * f
        y = s["y"] + s["move"][1] * f - math.sin(ph) * s["bob"]
        im = s["img"]
        if s.get("walk"):
            x0, x1, frac = s["walk"]
            wd = max(0.8, d * frac)
            g = min(1.0, lt / wd)
            if g < 1:
                eg = g * (2 - g) * 0.35 + g * 0.65  # frena al final
                x = x0 + (x1 - x0) * eg
                cyc = lt / 0.34  # un paso cada 0.34 s
                k = int(cyc) % 2
                im = s["steps"][k]
                y = s["y"] - abs(math.sin(cyc * math.pi)) * 14
            else:
                y = s["y"] - math.sin(ph) * s["bob"]
        img.alpha_composite(im, (int(x - s["ax"]), int(y - s["ay"])))
    p = min(max(lt / d, 0), 1)
    z = 1.0 + 0.07 * p if i % 2 == 0 else 1.07 - 0.07 * p
    cw, ch = BW / z / 1.1 * 1.1, BH / z
    cw = min(BW, BW / z)
    x0 = (BW - cw) / 2 + (p - 0.5) * (BW - cw) * (0.5 if i % 3 else -0.5)
    y0 = (BH - ch) / 2
    return img.resize((W, H), Image.BILINEAR, box=(x0, y0, x0 + cw, y0 + ch)).convert("RGB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--voz")
    ap.add_argument("--muestra", action="store_true")
    ap.add_argument("--sin-subtitulos", action="store_true")
    ap.add_argument("--salida", default=os.path.join(AQUI, "daniel_y_los_leones.mp4"))
    a = ap.parse_args()

    print("Dibujando escenas...")
    sc = [(bg.resize((BW, BH), Image.LANCZOS).convert("RGBA"), sp) for bg, sp in scenes()]
    if a.muestra:
        th = []
        for i, (bg, sp) in enumerate(sc):
            th.append(compose(bg, sp, 0, 1, 0).resize((270, 480)))
        sheet = Image.new("RGB", (270 * 6, 480 * 3))
        for i, t in enumerate(th):
            sheet.paste(t, ((i % 6) * 270, (i // 6) * 480))
        out = os.path.join(AQUI, "_muestra.jpg")
        sheet.save(out)
        print(out)
        return

    if a.voz:
        segs, total = voice_segments(a.voz, len(LINES))
    else:
        segs, total = estimate_segments()
    wt = word_times(segs)
    ch = chunks(wt)
    # cada escena empieza con su frase
    sstart = [0.0] + [segs[i][0] - 0.15 for i in range(1, len(segs))]
    send = sstart[1:] + [total]

    print("Mezclando audio...")
    mus, sr = music(total)
    if a.voz:
        raw = subprocess.run(["ffmpeg", "-v", "error", "-i", a.voz, "-ac", "1", "-ar", str(sr), "-f", "s16le",
                              "-"], capture_output=True).stdout
        v = np.frombuffer(raw, np.int16).astype(float) / 32767
        v = v / (np.max(np.abs(v)) + 1e-9) * 0.95
        mix = np.zeros(max(len(mus), len(v)))
        mix[:len(mus)] += mus * 0.16
        mix[:len(v)] += v
    else:
        mix = mus * 0.7
    wav = os.path.join(AQUI, "_audio.wav")
    write_wav(wav, mix / max(1.0, np.max(np.abs(mix))), sr)

    tmp = os.path.join(AQUI, "_video.mp4")
    ff = subprocess.Popen(["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24",
                           "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-c:v", "libx264", "-preset", "medium",
                           "-crf", "23", "-pix_fmt", "yuv420p", tmp], stdin=subprocess.PIPE)
    nf = int(total * FPS)
    XF = 0.3
    print(f"Renderizando {nf} cuadros...")
    for fi in range(nf):
        t = fi / FPS
        i = max(k for k in range(len(sc)) if sstart[k] <= t)
        d = send[i] - sstart[i]
        lt = t - sstart[i]
        frame = compose(sc[i][0], sc[i][1], lt, d, i)
        if i > 0 and lt < XF:
            prev = compose(sc[i - 1][0], sc[i - 1][1], lt + (send[i - 1] - sstart[i - 1]),
                           send[i - 1] - sstart[i - 1], i - 1)
            frame = Image.blend(prev, frame, lt / XF)
        cur = [c for c in ch if c[0][1] - 0.05 <= t <= c[-1][2] + 0.25]
        if cur and not a.sin_subtitulos:
            draw_caption(frame, cur[-1], t)
        if t < 0.4:
            frame = Image.blend(Image.new("RGB", (W, H)), frame, t / 0.4)
        ff.stdin.write(frame.tobytes())
        if fi % 300 == 0:
            print(f"  {fi}/{nf}")
    ff.stdin.close()
    ff.wait()
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-i", wav, "-c:v", "copy", "-c:a", "aac",
                    "-b:a", "192k", "-shortest", "-movflags", "+faststart", a.salida], check=True)
    os.remove(tmp)
    os.remove(wav)
    print("Listo:", a.salida)


if __name__ == "__main__":
    main()
