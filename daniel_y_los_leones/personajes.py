"""Personajes y utilería en estilo plano de colores (dibujados con Pillow).

Cada función devuelve (imagen RGBA, (ax, ay)): el punto de anclaje son los pies.
"""
import math

from PIL import Image, ImageDraw, ImageOps

SS = 3  # supermuestreo


def dark(c, f=0.62):
    return tuple(int(v * f) for v in c[:3])


def light(c, f=0.35):
    return tuple(int(v + (255 - v) * f) for v in c[:3])


SKIN = (214, 160, 118)
SKIN_D = (190, 136, 98)


class Pen:
    """Dibuja en unidades de altura del personaje (y hacia arriba, x hacia la derecha)."""

    def __init__(self, H, wf=1.0, hf=1.25):
        self.Hs = H * SS
        self.w = int(self.Hs * wf)
        self.h = int(self.Hs * hf)
        self.cx = self.w / 2
        self.fy = self.h - self.Hs * 0.03
        self.img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)
        self.ow = max(2, int(self.Hs * 0.007))

    def P(self, x, y):
        return (self.cx + x * self.Hs, self.fy - y * self.Hs)

    def poly(self, pts, fill, outline=True):
        self.d.polygon([self.P(*p) for p in pts], fill=fill,
                       outline=dark(fill) if outline else None, width=self.ow if outline else 0)

    def ell(self, x, y, rx, ry, fill, outline=True):
        x0, y0 = self.P(x - rx, y + ry)
        x1, y1 = self.P(x + rx, y - ry)
        self.d.ellipse([x0, y0, x1, y1], fill=fill,
                       outline=dark(fill) if outline else None, width=self.ow if outline else 0)

    def line(self, pts, fill, w, outline=True):
        pp = [self.P(*p) for p in pts]
        ww = int(w * self.Hs)
        if outline:
            self.d.line(pp, fill=dark(fill), width=ww + 2 * self.ow, joint="curve")
            for p in (pp[0], pp[-1]):
                r = ww / 2 + self.ow
                self.d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=dark(fill))
        self.d.line(pp, fill=fill, width=ww, joint="curve")
        for p in (pp[0], pp[-1]):
            r = ww / 2
            self.d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=fill)

    def arc(self, x, y, rx, ry, a0, a1, fill, w=None):
        x0, y0 = self.P(x - rx, y + ry)
        x1, y1 = self.P(x + rx, y - ry)
        self.d.arc([x0, y0, x1, y1], a0, a1, fill=fill, width=w or self.ow)

    def done(self, H, facing=1):
        img = self.img.resize((self.w // SS, self.h // SS), Image.LANCZOS)
        ax = self.cx / SS
        if facing < 0:
            img = ImageOps.mirror(img)
            ax = img.width - ax
        return img, (ax, self.fy / SS)


def person(H, robe, inner, sash, hair=(60, 38, 26), beard=1.0, head="turban",
           headc=(240, 236, 225), pose="stand", facing=1, mood="calm", skin=SKIN,
           wings=False, glow=False, prop=None, step=0):
    p = Pen(H, wf=1.1)
    kneel = pose == "kneel"
    dy = 0.27 if kneel else 0.0  # cuánto baja la parte superior al arrodillarse

    if wings:
        for s in (-1, 1):
            p.poly([(0.06 * s, 0.72), (0.42 * s, 0.98), (0.48 * s, 0.7), (0.36 * s, 0.46),
                    (0.1 * s, 0.5)], (250, 248, 240))
            for k in range(3):
                p.line([(0.12 * s, 0.68 - k * 0.06), (0.4 * s, 0.86 - k * 0.12)], (225, 222, 210), 0.01, False)

    # pies
    for s in (-1, 1):
        if not kneel:
            fx = 0.07 * s + 0.02 + (0.09 * step * s if step else 0)
            fy = 0.018 + (0.025 if step and s * step < 0 else 0)
            p.ell(fx, fy, 0.055, 0.022, (110, 72, 44))
    # túnica
    if kneel:
        p.poly([(-0.13, 0.78 - dy), (0.13, 0.78 - dy), (0.17, 0.16), (0.34, 0.13),
                (0.35, 0.0), (-0.17, 0.0)], robe)
        p.poly([(-0.035, 0.78 - dy), (0.035, 0.78 - dy), (0.07, 0.0), (-0.07, 0.0)], inner)
        p.ell(-0.18, 0.02, 0.05, 0.02, (110, 72, 44))
    else:
        sw = 0.03 * step
        p.poly([(-0.13, 0.78), (0.13, 0.78), (0.19 + sw, 0.03), (-0.19 + sw, 0.03)], robe)
        p.poly([(-0.035, 0.78), (0.035, 0.78), (0.06 + sw, 0.03), (-0.06 + sw, 0.03)], inner)
    p.poly([(-0.15, 0.53 - dy), (0.15, 0.53 - dy), (0.155, 0.48 - dy), (-0.155, 0.48 - dy)], sash)
    p.line([(0.05, 0.5 - dy), (0.07, 0.36 - dy)], sash, 0.025, False)
    # hombros y cuello
    p.ell(0, 0.75 - dy, 0.14, 0.05, robe)
    p.poly([(-0.03, 0.76 - dy), (0.03, 0.76 - dy), (0.03, 0.83 - dy), (-0.03, 0.83 - dy)], skin, False)

    sh = [(-0.12, 0.73 - dy), (0.12, 0.73 - dy)]
    hands = {
        "stand": [(-0.17, 0.44), (0.17, 0.44)],
        "point": [(-0.17, 0.44), (0.36, 0.68)],
        "arms_up": [(-0.24, 1.0), (0.24, 1.0)],
        "open": [(-0.3, 0.6), (0.3, 0.6)],
        "pray": [(0.03, 0.67), (0.07, 0.67)],
        "kneel": [(0.06, 0.67 - dy + 0.02), (0.1, 0.67 - dy + 0.02)],
        "sad": [(-0.17, 0.44), (0.04, 0.86)],
        "scroll": [(0.14, 0.58), (0.26, 0.58)],
        "call": [(-0.17, 0.44), (0.09, 0.86)],
        "bow": [(0.05, 0.55), (0.1, 0.55)],
    }[pose]

    def arm(i):
        s, h = sh[i], hands[i]
        mx, my = (s[0] + h[0]) / 2, (s[1] + h[1]) / 2
        elbow = (mx + (0.05 if h[0] > s[0] else -0.05) * (1 if pose in ("pray", "kneel", "bow") else 0.4),
                 my - 0.03)
        p.line([s, elbow, h], robe, 0.072)
        p.ell(h[0], h[1], 0.03, 0.03, skin)

    # brazo de atrás antes de la cabeza
    arm(0)

    # cabeza
    hy = 0.885 - dy - (0.02 if pose == "bow" else 0)
    hx = 0.02 if pose == "bow" else 0
    if head in ("veil",):
        p.poly([(-0.1 + hx, hy + 0.08), (0.1 + hx, hy + 0.08), (0.16 + hx, hy - 0.2),
                (-0.16 + hx, hy - 0.2)], headc)
    if head not in ("bald",):
        p.ell(hx - 0.008, hy + 0.012, 0.083, 0.09, hair)
    p.ell(hx + 0.012, hy, 0.075, 0.085, skin)
    p.ell(hx - 0.06, hy, 0.016, 0.022, skin)  # oreja
    if beard > 0:
        p.poly([(hx - 0.07, hy + 0.0), (hx + 0.087, hy + 0.0), (hx + 0.085, hy - 0.05),
                (hx + 0.02, hy - 0.085 - beard * 0.06), (hx - 0.05, hy - 0.06)], hair)
        p.ell(hx + 0.03, hy - 0.035, 0.022, 0.009, (150, 70, 60), False)  # boca
        if mood == "happy" or mood == "shout":
            p.ell(hx + 0.03, hy - 0.04, 0.026, 0.017 if mood == "shout" else 0.011, (110, 40, 40), False)
    else:
        if mood in ("happy", "shout"):
            p.ell(hx + 0.03, hy - 0.04, 0.024, 0.014, (120, 50, 50), False)
        else:
            p.line([(hx + 0.015, hy - 0.04), (hx + 0.045, hy - 0.04)], (130, 70, 60), 0.006, False)
    # nariz
    p.ell(hx + 0.05, hy - 0.005, 0.014, 0.018, SKIN_D if skin == SKIN else dark(skin, 0.88), False)
    # ojos
    ex = [hx - 0.008, hx + 0.045]
    for x in ex:
        if mood in ("closed", "pray"):
            p.arc(x, hy + 0.02, 0.013, 0.008, 200, 340, (40, 28, 22), max(2, int(p.Hs * 0.005)))
        else:
            p.ell(x, hy + 0.017, 0.0085, 0.011, (30, 22, 20), False)
            p.ell(x + 0.003, hy + 0.022, 0.003, 0.003, (255, 255, 255), False)
    # cejas
    bw = max(2, int(p.Hs * 0.006))
    for i, x in enumerate(ex):
        if mood == "angry":
            a = (-0.012, 0.05 + (0.0 if i else 0.012)), (0.012, 0.05 + (0.012 if i else 0.0))
        elif mood in ("sad",):
            a = (-0.012, 0.05 + (0.012 if i else 0.0)), (0.012, 0.05 + (0.0 if i else 0.012))
        else:
            a = (-0.012, 0.052), (0.012, 0.052)
        p.line([(x + a[0][0], hy + a[0][1]), (x + a[1][0], hy + a[1][1])], hair, 0.006, False)

    # tocado
    if head == "turban":
        p.ell(hx + 0.005, hy + 0.065, 0.088, 0.045, headc)
        p.line([(hx - 0.07, hy + 0.06), (hx + 0.08, hy + 0.075)], dark(headc, 0.85), 0.008, False)
    elif head == "crown":
        pts = [(hx - 0.07, hy + 0.06), (hx + 0.085, hy + 0.06), (hx + 0.085, hy + 0.15), (hx + 0.055, hy + 0.1),
               (hx + 0.03, hy + 0.16), (hx + 0.005, hy + 0.1), (hx - 0.02, hy + 0.16), (hx - 0.045, hy + 0.1),
               (hx - 0.07, hy + 0.15)]
        p.poly(pts, (240, 190, 60))
        p.ell(hx + 0.008, hy + 0.08, 0.012, 0.012, (200, 40, 60), False)
    elif head == "tallhat":
        p.poly([(hx - 0.075, hy + 0.05), (hx + 0.09, hy + 0.05), (hx + 0.065, hy + 0.17),
                (hx - 0.05, hy + 0.17)], headc)
        p.line([(hx - 0.07, hy + 0.08), (hx + 0.085, hy + 0.08)], dark(headc, 0.8), 0.01, False)
    elif head == "veil":
        p.poly([(-0.09 + hx, hy + 0.1), (0.1 + hx, hy + 0.1), (0.09 + hx, hy + 0.04), (-0.08 + hx, hy + 0.0)], headc)
    elif head == "curly":
        for k in range(6):
            p.ell(hx - 0.06 + k * 0.026, hy + 0.075, 0.025, 0.025, hair, False)

    # brazo de adelante
    arm(1)
    if prop == "scroll" or pose == "scroll":
        h1, h0 = hands[1], hands[0]
        p.poly([(h0[0], h0[1] + 0.08), (h1[0], h1[1] + 0.08), (h1[0], h1[1] - 0.08), (h0[0], h0[1] - 0.08)],
               (246, 234, 200))
        for k in range(4):
            yy = h0[1] + 0.045 - k * 0.03
            p.line([(h0[0] + 0.02, yy), (h1[0] - 0.02, yy)], (150, 120, 90), 0.004, False)
        p.ell(h0[0], h0[1], 0.03, 0.03, skin)
        p.ell(h1[0], h1[1], 0.03, 0.03, skin)
    return p.done(H, facing)


def lion(L, pose="stand", facing=1, mood="roar"):
    """León de perfil mirando a la derecha (facing=1). L = largo del cuerpo."""
    p = Pen(L, wf=1.3, hf=0.9)
    p.cx = p.w * 0.45
    body = (222, 160, 72)
    mane = (150, 78, 32)
    face = (238, 184, 98)
    lying = pose == "lying"
    by = 0.17 if lying else 0.27
    # cola
    if lying:
        p.line([(-0.33, 0.06), (-0.5, 0.04), (-0.6, 0.08)], body, 0.035)
        p.ell(-0.62, 0.09, 0.05, 0.04, mane)
    else:
        p.line([(-0.33, by + 0.05), (-0.48, by + 0.1), (-0.52, by + 0.25)], body, 0.035)
        p.ell(-0.52, by + 0.27, 0.04, 0.05, mane)
    # patas traseras
    if lying:
        p.ell(-0.12, 0.05, 0.12, 0.05, body)
        p.ell(0.28, 0.04, 0.14, 0.04, body)
    else:
        for x in (-0.24, -0.12):
            p.line([(x, by), (x, 0.04)], dark(body, 0.88), 0.1)
    p.ell(0.0, by + 0.04, 0.36, 0.15 if not lying else 0.13, body)
    if not lying:
        for x in (0.14, 0.25):
            p.line([(x, by), (x, 0.04)], body, 0.1)
            p.ell(x + 0.02, 0.03, 0.06, 0.03, light(body, 0.2))
    # melena
    mx, my = 0.33, by + 0.17 + (0.0 if not lying else 0.02)
    pts = []
    for k in range(22):
        a = 2 * math.pi * k / 22
        r = 0.2 if k % 2 == 0 else 0.16
        pts.append((mx + math.cos(a) * r, my + math.sin(a) * r * 1.05))
    p.poly(pts, mane)
    # cara
    fx = mx + 0.04
    p.ell(fx, my, 0.115, 0.125, face)
    for s in (-1, 1):
        p.ell(fx + s * 0.07, my + 0.1, 0.035, 0.035, face)
        p.ell(fx + s * 0.07, my + 0.1, 0.017, 0.017, mane, False)
    p.ell(fx + 0.03, my - 0.045, 0.06, 0.045, light(face, 0.3), False)  # hocico
    p.poly([(fx + 0.0, my - 0.005), (fx + 0.06, my - 0.005), (fx + 0.03, my - 0.035)], (80, 40, 30))
    for s in (-1, 1):
        x = fx + 0.03 + s * 0.045
        if mood == "calm":
            p.arc(x, my + 0.04, 0.02, 0.012, 200, 340, (60, 30, 20), max(2, int(p.Hs * 0.006)))
        else:
            p.ell(x, my + 0.04, 0.015, 0.017 if mood != "roar" else 0.012, (40, 25, 20), False)
            if mood == "roar":
                p.line([(x - 0.025, my + 0.07 + s * 0.0), (x + 0.02, my + 0.06 - s * 0.012)], mane, 0.008, False)
    if mood == "roar":
        p.ell(fx + 0.03, my - 0.075, 0.05, 0.045, (110, 30, 35))
        for s in (-1, 1):
            x = fx + 0.03 + s * 0.028
            p.poly([(x - 0.01, my - 0.035), (x + 0.01, my - 0.035), (x, my - 0.065)], (255, 255, 245), False)
    else:
        p.arc(fx + 0.015, my - 0.05, 0.016, 0.012, 20, 160, (80, 40, 30))
        p.arc(fx + 0.045, my - 0.05, 0.016, 0.012, 20, 160, (80, 40, 30))
    return p.done(L, facing)


def table(Wd):
    p = Pen(Wd, wf=1.2, hf=0.7)
    wood = (140, 92, 56)
    for x in (-0.42, 0.42):
        p.poly([(x - 0.03, 0.0), (x + 0.03, 0.0), (x + 0.03, 0.36), (x - 0.03, 0.36)], dark(wood, 0.85))
    p.poly([(-0.5, 0.36), (0.5, 0.36), (0.5, 0.42), (-0.5, 0.42)], wood)
    p.poly([(-0.25, 0.42), (0.2, 0.42), (0.2, 0.46), (-0.25, 0.46)], (246, 234, 200))
    p.ell(-0.25, 0.44, 0.025, 0.03, (220, 200, 160))
    p.ell(0.2, 0.44, 0.025, 0.03, (220, 200, 160))
    p.ell(0.33, 0.46, 0.04, 0.04, (90, 70, 120))  # tintero
    return p.done(Wd)


def stone(R):
    p = Pen(R, wf=1.2, hf=1.1)
    p.ell(0, 0.5, 0.5, 0.5, (150, 140, 130))
    p.ell(-0.12, 0.62, 0.18, 0.12, (175, 166, 156), False)
    p.ell(0.15, 0.3, 0.08, 0.06, (125, 116, 108), False)
    return p.done(R)
