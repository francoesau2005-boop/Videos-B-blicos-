# Genera las texturas PNG del add-on (sin dependencias).
import zlib, struct, sys
def png(path, w, h, px):
    raw = b"".join(b"\x00" + bytes(sum((px(x, y) for x in range(w)), ())) for y in range(h))
    ch = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw, 9)) + ch(b"IEND", b""))
# bloque fantasma: borde blanco sólido, relleno translúcido, cruz de esquinas
def fantasma(x, y):
    borde = x in (0, 15) or y in (0, 15)
    borde2 = x in (1, 14) or y in (1, 14)
    if borde: return (255, 255, 255, 255)
    if borde2: return (255, 255, 255, 170)
    return (255, 255, 255, 60)
png("addon/RP/textures/particle/ayudante_fantasma.png", 16, 16, fantasma)
# icono 64x64: maqueta de bloques (pasto/tierra) con contorno fantasma
def icono(x, y):
    bx, by = x // 8, y // 8
    if by >= 5:
        g = (bx * 7 + by * 3) % 3
        return (110 + g * 10, 78 + g * 6, 48, 255) if by > 5 else (88 + g * 12, 160 + g * 10, 60, 255)
    if 1 <= bx <= 6 and 1 <= by <= 4:
        edge = x % 8 in (0, 7) or y % 8 in (0, 7)
        return (255, 255, 255, 255) if edge else (120, 200, 255, 110)
    return (40, 52, 70, 255)
for p in ("addon/BP/pack_icon.png", "addon/RP/pack_icon.png"):
    png(p, 64, 64, icono)
