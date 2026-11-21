#!/usr/bin/env python3
"""Arma ReyPolloSV.apk sin Android Studio.

Genera el AndroidManifest binario y resources.arsc a mano, compila la
Activity con javac, la convierte a dex con dx y firma con apksig (v1+v2).
Uso: python3 build.py <carpeta_de_trabajo>
Necesita en la carpeta de trabajo: android-all.jar, dx.jar, apksig.jar
"""
import os, struct, subprocess, sys, zipfile, zlib, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
PKG = "com.reypollo.cuadra"
VERSION_CODE, VERSION_NAME = 4, "1.3"
ICON_ID = 0x7F010000

# ---------------------------------------------------------------- string pool
def string_pool(strings, utf8=False):
    data = b""
    offsets = []
    for s in strings:
        offsets.append(len(data))
        if utf8:
            b = s.encode("utf-8")
            def ln(n):
                return bytes([n]) if n < 0x80 else bytes([0x80 | (n >> 8), n & 0xFF])
            data += ln(len(s)) + ln(len(b)) + b + b"\0"
        else:
            u = s.encode("utf-16-le")
            data += struct.pack("<H", len(u) // 2) + u + b"\0\0"
    while len(data) % 4:
        data += b"\0"
    header_size = 28
    strings_start = header_size + 4 * len(strings)
    size = strings_start + len(data)
    flags = 0x100 if utf8 else 0
    return (struct.pack("<HHIIIIII", 0x0001, header_size, size, len(strings), 0,
                        flags, strings_start, 0)
            + b"".join(struct.pack("<I", o) for o in offsets) + data)

# ---------------------------------------------------------------- AXML
ANDROID_NS = "http://schemas.android.com/apk/res/android"
ATTR = {
    "theme": 0x01010000, "label": 0x01010001, "icon": 0x01010002, "name": 0x01010003,
    "exported": 0x01010010, "configChanges": 0x0101001F, "minSdkVersion": 0x0101020C,
    "versionCode": 0x0101021B, "versionName": 0x0101021C, "windowSoftInputMode": 0x0101022B,
    "targetSdkVersion": 0x01010270, "allowBackup": 0x01010280,
    "hardwareAccelerated": 0x010102D3, "roundIcon": 0x0101052C,
}
T_REF, T_STR, T_DEC, T_HEX, T_BOOL = 0x01, 0x03, 0x10, 0x11, 0x12

def S(v): return (T_STR, v)
def I(v): return (T_DEC, v)
def H(v): return (T_HEX, v)
def B(v): return (T_BOOL, 0xFFFFFFFF if v else 0)
def R(v): return (T_REF, v)

# (tag, [(android?, attr, value)], children)
MANIFEST = ("manifest", [
        (True, "versionCode", I(VERSION_CODE)), (True, "versionName", S(VERSION_NAME)),
        (False, "package", S(PKG))], [
    ("uses-sdk", [(True, "minSdkVersion", I(24)), (True, "targetSdkVersion", I(34))], []),
    ("uses-permission", [(True, "name", S("android.permission.VIBRATE"))], []),
    ("uses-permission", [(True, "name", S("android.permission.WAKE_LOCK"))], []),
    ("application", [
            (True, "label", S("Rey Pollo SV")), (True, "icon", R(ICON_ID)),
            (True, "roundIcon", R(ICON_ID)), (True, "allowBackup", B(True)),
            (True, "hardwareAccelerated", B(True))], [
        ("activity", [
                (True, "theme", R(0x0103022E)),  # Theme.Material.NoActionBar
                (True, "name", S(PKG + ".MainActivity")),
                (True, "exported", B(True)),
                (True, "configChanges", H(0x7B0)),
                (True, "windowSoftInputMode", H(0x10))], [
            ("intent-filter", [], [
                ("action", [(True, "name", S("android.intent.action.MAIN"))], []),
                ("category", [(True, "name", S("android.intent.category.LAUNCHER"))], []),
            ]),
        ]),
    ]),
])

def build_axml(root):
    res_names, other = [], []
    def collect(node):
        tag, attrs, kids = node
        for a, name, (t, v) in attrs:
            if a:
                if name not in res_names: res_names.append(name)
            elif name not in other: other.append(name)
            if t == T_STR and v not in other: other.append(v)
        if tag not in other: other.append(tag)
        for k in kids: collect(k)
    collect(root)
    res_names.sort(key=lambda n: ATTR[n])
    for extra in ("android", ANDROID_NS):
        if extra not in other: other.append(extra)
    strings = res_names + [s for s in other if s not in res_names]
    idx = {s: i for i, s in enumerate(strings)}
    NS = idx[ANDROID_NS]

    body = b""
    body += struct.pack("<HHIIIII", 0x0100, 16, 24, 1, 0xFFFFFFFF, idx["android"], NS)
    line = [1]
    def emit(node):
        nonlocal body
        tag, attrs, kids = node
        line[0] += 1
        enc = []
        for a, name, (t, v) in sorted(attrs, key=lambda x: ATTR.get(x[1], 0xFFFFFFFF) if x[0] else 0):
            ns = NS if a else 0xFFFFFFFF
            raw = idx[v] if t == T_STR else 0xFFFFFFFF
            data = idx[v] if t == T_STR else v
            enc.append(struct.pack("<IIIHBBI", ns, idx[name], raw, 8, 0, t, data & 0xFFFFFFFF))
        size = 36 + 20 * len(enc)
        body += struct.pack("<HHIIIIIHHHHHH", 0x0102, 16, size, line[0], 0xFFFFFFFF,
                            0xFFFFFFFF, idx[tag], 20, 20, len(enc), 0, 0, 0) + b"".join(enc)
        for k in kids: emit(k)
        line[0] += 1
        body += struct.pack("<HHIIIII", 0x0103, 16, 24, line[0], 0xFFFFFFFF, 0xFFFFFFFF, idx[tag])
    emit(root)
    body += struct.pack("<HHIIIII", 0x0101, 16, 24, line[0] + 1, 0xFFFFFFFF, idx["android"], NS)

    pool = string_pool(strings)
    resmap = struct.pack("<HHI", 0x0180, 8, 8 + 4 * len(res_names)) + \
        b"".join(struct.pack("<I", ATTR[n]) for n in res_names)
    total = 8 + len(pool) + len(resmap) + len(body)
    return struct.pack("<HHI", 0x0003, 8, total) + pool + resmap + body

# ---------------------------------------------------------------- ARSC
DENSITIES = [("mdpi", 160, 48), ("hdpi", 240, 72), ("xhdpi", 320, 96),
             ("xxhdpi", 480, 144), ("xxxhdpi", 640, 192)]

def config(density):
    c = bytearray(64)
    struct.pack_into("<I", c, 0, 64)
    struct.pack_into("<H", c, 14, density)   # screenType.density
    struct.pack_into("<H", c, 24, 4)         # sdkVersion (v4, como aapt)
    return bytes(c)

def build_arsc():
    paths = ["res/mipmap-%s-v4/icon.png" % d for d, _, _ in DENSITIES]
    gpool = string_pool(paths, utf8=True)
    type_pool = string_pool(["mipmap"])
    key_pool = string_pool(["icon"])
    spec = struct.pack("<HHIBBHI", 0x0202, 16, 20, 1, 0, 0, 1) + struct.pack("<I", 0x0100)
    types = b""
    for i, (d, dens, _) in enumerate(DENSITIES):
        entry = struct.pack("<HHI", 8, 0, 0) + struct.pack("<HBBI", 8, 0, T_STR, i)
        header_size = 20 + 64
        entries_start = header_size + 4
        size = entries_start + len(entry)
        types += struct.pack("<HHIBBHII", 0x0201, header_size, size, 1, 0, 0, 1,
                             entries_start) + config(dens) + struct.pack("<I", 0) + entry
    name = PKG.encode("utf-16-le").ljust(256, b"\0")
    ph = 288
    type_off = ph
    key_off = ph + len(type_pool)
    pkg_body = type_pool + key_pool + spec + types
    pkg = struct.pack("<HHII", 0x0200, ph, ph + len(pkg_body), 0x7F) + name + \
        struct.pack("<IIIII", type_off, 1, key_off, 1, 0) + pkg_body
    total = 12 + len(gpool) + len(pkg)
    return struct.pack("<HHII", 0x0002, 12, total, 1) + gpool + pkg

# ---------------------------------------------------------------- icono
def make_icons(dst):
    from PIL import Image, ImageDraw, ImageFont
    font = None
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"):
        if os.path.exists(f): font = f
    out = {}
    for d, _, px in DENSITIES:
        S4 = px * 4
        im = Image.new("RGBA", (S4, S4), (0, 0, 0, 0))
        g = ImageDraw.Draw(im)
        g.ellipse((0, 0, S4 - 1, S4 - 1), fill=(38, 62, 73, 255))
        g.ellipse((S4 * .08, S4 * .08, S4 * .92, S4 * .92), outline=(255, 211, 143, 255), width=int(S4 * .035))
        gold = (255, 207, 125, 255)
        # corona (el «Rey» de Rey Pollo)
        c = [(.27, .50), (.24, .25), (.37, .36), (.50, .19), (.63, .36), (.76, .25), (.73, .50)]
        g.polygon([(S4 * x, S4 * y) for x, y in c], fill=gold)
        g.rounded_rectangle((S4 * .27, S4 * .53, S4 * .73, S4 * .59), radius=S4 * .02, fill=gold)
        for x, y in ((.24, .25), (.50, .19), (.76, .25)):
            r = S4 * .035
            g.ellipse((S4 * x - r, S4 * y - r, S4 * x + r, S4 * y + r), fill=gold)
        fnt = ImageFont.truetype(font, int(S4 * .17)) if font else ImageFont.load_default()
        w = g.textlength("SV", font=fnt)
        g.text(((S4 - w) / 2, S4 * .72), "SV", font=fnt, fill=(238, 246, 247, 255), anchor="lm")
        im = im.resize((px, px), Image.LANCZOS)
        p = os.path.join(dst, "icon-%s.png" % d)
        im.save(p, optimize=True)
        out[d] = p
    return out

# ---------------------------------------------------------------- build
def run(cmd):
    print("+", " ".join(cmd)[:160]); subprocess.check_call(cmd)

def main():
    b = os.path.join(WORK, "build"); shutil.rmtree(b, ignore_errors=True); os.makedirs(b)
    cls = os.path.join(b, "classes"); os.makedirs(cls)
    src = os.path.join(HERE, "src", "com", "reypollo", "cuadra", "MainActivity.java")
    run(["javac", "--release", "8", "-nowarn", "-cp", os.path.join(WORK, "android-all.jar"),
         "-d", cls, src])
    run(["java", "-cp", os.path.join(WORK, "dx.jar"), "com.android.dx.command.Main", "--dex",
         "--min-sdk-version=24", "--output=" + os.path.join(b, "classes.dex"), cls])
    icons = make_icons(b)
    unsigned = os.path.join(b, "unsigned.apk")
    html = os.path.join(HERE, "..", "index.html")
    with zipfile.ZipFile(unsigned, "w") as z:
        def add(name, data, store=False):
            zi = zipfile.ZipInfo(name, (2024, 1, 1, 0, 0, 0))
            zi.compress_type = zipfile.ZIP_STORED if store else zipfile.ZIP_DEFLATED
            if store:  # alinear a 4 bytes (obligatorio para resources.arsc en Android 11+)
                pos = z.fp.tell() + 30 + len(name.encode())
                zi.extra = b"\0" * ((4 - pos % 4) % 4)
            z.writestr(zi, data)
        add("AndroidManifest.xml", build_axml(MANIFEST))
        add("classes.dex", open(os.path.join(b, "classes.dex"), "rb").read())
        add("resources.arsc", build_arsc(), store=True)
        for d, _, _ in DENSITIES:
            add("res/mipmap-%s-v4/icon.png" % d, open(icons[d], "rb").read(), store=True)
        add("assets/index.html", open(html, "rb").read())
    ks = os.path.join(WORK, "cuadra.keystore")
    if not os.path.exists(ks):
        run(["keytool", "-genkeypair", "-keystore", ks, "-storepass", "cuadra123", "-keypass",
             "cuadra123", "-alias", "cuadra", "-keyalg", "RSA", "-keysize", "2048",
             "-validity", "10000", "-dname", "CN=Rey Pollo SV"])
    signer = os.path.join(HERE, "Sign.java")
    run(["javac", "-nowarn", "-cp", os.path.join(WORK, "apksig.jar"), "-d", b, signer])
    out = os.path.join(WORK, "ReyPolloSV.apk")
    run(["java", "--add-exports", "java.base/sun.security.x509=ALL-UNNAMED", "--add-exports", "java.base/sun.security.pkcs=ALL-UNNAMED", "-cp", b + os.pathsep + os.path.join(WORK, "apksig.jar"), "Sign",
         ks, "cuadra123", "cuadra", unsigned, out])
    print("OK ->", out, os.path.getsize(out), "bytes")

if __name__ == "__main__":
    main()
