# Icono de la app: mira roja sobre fondo oscuro con borde lima (sin dependencias)
import zlib, struct, math
def png(path, w, h, px):
    raw = b"".join(b"\x00" + bytes(sum((px(x, y) for x in range(w)), ())) for y in range(h))
    ch = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw, 9)) + ch(b"IEND", b""))
def icono(t):
    def px(x, y):
        u, v = (x + 0.5) / t * 2 - 1, (y + 0.5) / t * 2 - 1
        r = math.hypot(u, v)
        if r > 0.98: return (0, 0, 0, 0)
        if r > 0.86: return (182, 255, 59, 255)
        ring = abs(r - 0.5) < 0.06
        cross = (abs(u) < 0.05 or abs(v) < 0.05) and 0.18 < r < 0.72
        if r < 0.1: return (255, 59, 59, 255)
        if ring or cross: return (255, 138, 31, 255)
        return (20, 24, 33, 255)
    return px
for carpeta, t in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)):
    png(f"app_android/app/src/main/res/mipmap-{carpeta}/ic_launcher.png", t, t, icono(t))
