// ================= AVATARES DE PERSONAJES (dibujos propios) =================
// Cada personaje tiene: g (h/m), piel, pelo (estilo), pc (color de pelo), ropa (color),
// prenda (chaqueta/sudadera/chaleco/camiseta), acc (accesorio) e i (ícono de su habilidad).
const PIEL = { clara: "#f1c7a5", media: "#d9a27a", morena: "#a96f4a", oscura: "#6f4630" };
const AV = {
  // activas
  "Alok": { g: "h", piel: "morena", pelo: "rapado", pc: "#1a1a1a", ropa: "#2b2b33", prenda: "chaqueta", acc: "audifonos", i: "music" },
  "Tatsuya": { g: "h", piel: "clara", pelo: "flequillo", pc: "#3a2a20", ropa: "#b3262e", prenda: "chaqueta", acc: "", i: "zap" },
  "Chrono": { g: "h", piel: "clara", pelo: "puntas", pc: "#e8e8ee", ropa: "#1d3b8f", prenda: "chaqueta", acc: "", i: "clock" },
  "Skyler": { g: "h", piel: "clara", pelo: "corto", pc: "#2c6fd6", ropa: "#1b1b22", prenda: "sudadera", acc: "audifonos", i: "activity" },
  "Xayne": { g: "m", piel: "clara", pelo: "mohawk", pc: "#ff6a2a", ropa: "#3b3b44", prenda: "chaleco", acc: "", i: "shield" },
  "K": { g: "h", piel: "clara", pelo: "corto", pc: "#e8e8ee", ropa: "#25252c", prenda: "chaqueta", acc: "lentes", i: "dumbbell" },
  "Dimitri": { g: "h", piel: "clara", pelo: "puntas", pc: "#6fd6ff", ropa: "#2f2f38", prenda: "sudadera", acc: "", i: "heart-pulse" },
  "Wukong": { g: "h", piel: "media", pelo: "puntas", pc: "#4a3020", ropa: "#c47a1c", prenda: "camiseta", acc: "corona", i: "leaf" },
  "Clu": { g: "m", piel: "clara", pelo: "coleta", pc: "#2a2a2a", ropa: "#5a2c8f", prenda: "chaqueta", acc: "visor", i: "radar" },
  "Steffie": { g: "m", piel: "clara", pelo: "largo", pc: "#ff6fae", ropa: "#2a2a33", prenda: "sudadera", acc: "", i: "spray-can" },
  "Homer": { g: "h", piel: "media", pelo: "rapado", pc: "#9a9aa3", ropa: "#3d5a2a", prenda: "chaleco", acc: "lentes", i: "radar" },
  "Kenta": { g: "h", piel: "clara", pelo: "chongo", pc: "#1a1a1a", ropa: "#2a2a33", prenda: "camiseta", acc: "bandana", i: "sword" },
  "Orion": { g: "h", piel: "clara", pelo: "corto", pc: "#b3262e", ropa: "#1a1a1f", prenda: "chaqueta", acc: "mascara", i: "flame" },
  // pasivas
  "Jota": { g: "h", piel: "media", pelo: "corto", pc: "#1a1a1a", ropa: "#2f3a52", prenda: "chaqueta", acc: "gorra", i: "crosshair" },
  "Dasha": { g: "m", piel: "clara", pelo: "chongo", pc: "#d65fd6", ropa: "#2bb3a6", prenda: "camiseta", acc: "", i: "target" },
  "Shirou": { g: "h", piel: "clara", pelo: "puntas", pc: "#1a1a1a", ropa: "#2a2a33", prenda: "sudadera", acc: "mascara", i: "scan-eye" },
  "Hayato": { g: "h", piel: "clara", pelo: "chongo", pc: "#1a1a1a", ropa: "#8f2a2a", prenda: "camiseta", acc: "bandana", i: "sword" },
  "Kelly": { g: "m", piel: "clara", pelo: "coleta", pc: "#3a2a20", ropa: "#2c6fd6", prenda: "camiseta", acc: "", i: "footprints" },
  "Moco": { g: "m", piel: "clara", pelo: "largo", pc: "#1a1a1a", ropa: "#6a3ad6", prenda: "sudadera", acc: "lentes", i: "eye" },
  "Laura": { g: "m", piel: "clara", pelo: "largo", pc: "#c9a24a", ropa: "#3d5a2a", prenda: "chaleco", acc: "", i: "crosshair" },
  "Maro": { g: "h", piel: "media", pelo: "corto", pc: "#2a2018", ropa: "#5a4a2a", prenda: "chaleco", acc: "gorra", i: "scan-eye" },
  "Rafael": { g: "h", piel: "clara", pelo: "flequillo", pc: "#1a1a1a", ropa: "#1a1a1f", prenda: "chaqueta", acc: "mascara", i: "volume-x" },
  "Maxim": { g: "h", piel: "clara", pelo: "corto", pc: "#c47a1c", ropa: "#d64545", prenda: "camiseta", acc: "", i: "apple" },
  "Luqueta": { g: "h", piel: "media", pelo: "rizado", pc: "#1a1a1a", ropa: "#f5c451", prenda: "camiseta", acc: "", i: "trophy" },
  "Leon": { g: "h", piel: "media", pelo: "rapado", pc: "#1a1a1a", ropa: "#d6762c", prenda: "camiseta", acc: "", i: "heart" },
  "Andrew": { g: "h", piel: "clara", pelo: "corto", pc: "#6a4a2a", ropa: "#2a3d6a", prenda: "chaleco", acc: "gorra", i: "shield-plus" },
  "Antonio": { g: "h", piel: "clara", pelo: "corto", pc: "#1a1a1a", ropa: "#1a1a1f", prenda: "chaqueta", acc: "lentes", i: "heart" },
  "Kapella": { g: "m", piel: "clara", pelo: "coleta", pc: "#ffffff", ropa: "#ff6fae", prenda: "camiseta", acc: "audifonos", i: "music" },
  "Thiva": { g: "h", piel: "morena", pelo: "rizado", pc: "#1a1a1a", ropa: "#2bb35a", prenda: "sudadera", acc: "", i: "bandage" },
  "Olivia": { g: "m", piel: "clara", pelo: "largo", pc: "#c47a1c", ropa: "#ffffff", prenda: "chaqueta", acc: "", i: "syringe" },
  "Miguel": { g: "h", piel: "media", pelo: "rapado", pc: "#1a1a1a", ropa: "#3d5a2a", prenda: "chaleco", acc: "bandana", i: "zap" },
  "Ford": { g: "h", piel: "clara", pelo: "corto", pc: "#c9a24a", ropa: "#2a3d6a", prenda: "chaqueta", acc: "", i: "shield" },
  "D-bee": { g: "h", piel: "oscura", pelo: "rizado", pc: "#1a1a1a", ropa: "#f5c451", prenda: "sudadera", acc: "audifonos", i: "music" },
  "Caroline": { g: "m", piel: "clara", pelo: "largo", pc: "#e8c36a", ropa: "#d64545", prenda: "camiseta", acc: "", i: "footprints" },
  "Joseph": { g: "h", piel: "clara", pelo: "corto", pc: "#6a4a2a", ropa: "#2a2a33", prenda: "chaqueta", acc: "", i: "footprints" },
  "Wolfrahh": { g: "h", piel: "clara", pelo: "puntas", pc: "#e8e8ee", ropa: "#1a1a1f", prenda: "chaqueta", acc: "mascara", i: "skull" },
  "Paloma": { g: "m", piel: "media", pelo: "largo", pc: "#1a1a1a", ropa: "#c47a1c", prenda: "chaqueta", acc: "lentes", i: "package" },
};
// mascotas: animal + color + detalle
const AV_MASC = {
  "Mr. Waggor": { a: "pinguino", c: "#1f2a3a", i: "shield" },
  "Rockie": { a: "mapache", c: "#7d7d88", i: "timer" },
  "Ottero": { a: "nutria", c: "#8a5a3a", i: "droplet" },
  "Detective Panda": { a: "panda", c: "#f2f2f2", i: "search" },
  "Falco": { a: "ave", c: "#c46a2a", i: "wind" },
  "Dreki": { a: "dragon", c: "#2bb35a", i: "eye" },
  "Beaston": { a: "oso", c: "#6a4a2a", i: "hammer" },
  "Agent Hop": { a: "conejo", c: "#e8e8ee", i: "zap" },
};

function emblema(i, x = 76, y = 80, r = 12) {
  return `<circle cx="${x + 8}" cy="${y + 8}" r="${r}" fill="#000" stroke="#fff" stroke-width="1.6"/><svg x="${x}" y="${y}" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">${ICONOS[i] || ""}</svg>`;
}
function oscurecer(hex, f) {
  const n = parseInt(hex.slice(1), 16);
  const c = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((v) => Math.round(v * f));
  return `rgb(${c.join(",")})`;
}

function avatarPersona(nombre, grande) {
  const h = tono(nombre);
  const a = AV[nombre] || { g: h % 2 ? "h" : "m", piel: Object.keys(PIEL)[h % 4], pelo: ["corto", "largo", "puntas", "coleta"][h % 4], pc: "#2a2a2a", ropa: `hsl(${h} 50% 35%)`, prenda: "chaqueta", acc: "", i: "star" };
  const piel = PIEL[a.piel], pielO = oscurecer(piel, 0.82), pc = a.pc, ropa = a.ropa, ropaO = a.ropa.startsWith("#") ? oscurecer(a.ropa, 0.7) : a.ropa;
  const id = "av" + h + (grande ? "g" : "");
  let s = `<defs><radialGradient id="${id}" cx="50%" cy="40%" r="70%"><stop offset="0" stop-color="hsl(${h} 60% 32%)"/><stop offset="1" stop-color="#0b0b0d"/></radialGradient></defs>`;
  s += grande ? `<ellipse cx="50" cy="54" rx="47" ry="47" fill="url(#${id})"/>` : `<rect width="100" height="105" fill="url(#${id})"/>`;
  // capucha detrás
  if (a.prenda === "sudadera") s += `<path d="M30 44c0-18 9-28 20-28s20 10 20 28v22H30z" fill="${ropaO}"/>`;
  // pelo largo detrás
  if (a.pelo === "largo") s += `<path d="M33 40c0-14 7-22 17-22s17 8 17 22v30c-4 3-8 4-17 4s-13-1-17-4z" fill="${pc}"/>`;
  if (a.pelo === "coleta") s += `<path d="M64 34c10 2 13 14 9 30-3-4-6-6-10-7z" fill="${pc}"/>`;
  // torso
  s += `<path d="M12 105c2-22 17-33 38-33s36 11 38 33z" fill="${ropa}"/>`;
  if (a.prenda === "chaqueta") s += `<path d="M50 74l-8 31M50 74l8 31" stroke="${ropaO}" stroke-width="3"/><path d="M44 72l6 10 6-10" fill="${a.g === "m" ? "#f2f2f2" : "#e8e8ee"}"/>`;
  if (a.prenda === "chaleco") s += `<rect x="30" y="80" width="40" height="25" rx="4" fill="${ropaO}"/><path d="M36 86h10M54 86h10" stroke="#ffffff40" stroke-width="2"/>`;
  if (a.prenda === "sudadera") s += `<path d="M38 74c4 6 8 8 12 8s8-2 12-8" fill="none" stroke="${ropaO}" stroke-width="3"/><path d="M46 82v10M54 82v10" stroke="#ffffffaa" stroke-width="1.6"/>`;
  if (a.prenda === "camiseta") s += `<path d="M42 73q8 7 16 0" fill="none" stroke="${ropaO}" stroke-width="2.5"/>`;
  // cuello y cabeza
  s += `<rect x="44" y="56" width="12" height="16" rx="4" fill="${pielO}"/>`;
  s += `<ellipse cx="34.5" cy="45" rx="3" ry="4.5" fill="${pielO}"/><ellipse cx="65.5" cy="45" rx="3" ry="4.5" fill="${pielO}"/>`;
  s += `<ellipse cx="50" cy="42" rx="15.5" ry="18" fill="${piel}"/>`;
  // cara
  const ojoY = 45;
  if (a.acc !== "lentes" && a.acc !== "visor") s += `<ellipse cx="44" cy="${ojoY}" rx="1.9" ry="2.4" fill="#1a1a1a"/><ellipse cx="56" cy="${ojoY}" rx="1.9" ry="2.4" fill="#1a1a1a"/>`;
  s += `<path d="M40.5 ${ojoY - 5}q3.5-${a.g === "m" ? 2 : 1.2} 7 0M52.5 ${ojoY - 5}q3.5-${a.g === "m" ? 2 : 1.2} 7 0" stroke="${pc === "#ffffff" || pc === "#e8e8ee" ? "#8d8d96" : pc}" stroke-width="1.6" fill="none" stroke-linecap="round"/>`;
  if (a.acc !== "mascara") s += `<path d="M46.5 53q3.5 ${a.g === "m" ? 2.5 : 2} 7 0" stroke="#7a3a2a" stroke-width="1.6" fill="none" stroke-linecap="round"/>`;
  if (a.g === "m" && a.acc !== "mascara") s += `<ellipse cx="41" cy="50" rx="2.4" ry="1.3" fill="#ff8a8a55"/><ellipse cx="59" cy="50" rx="2.4" ry="1.3" fill="#ff8a8a55"/>`;
  // pelo delante
  const P = {
    corto: `<path d="M34 40c0-14 7-21 16-21s16 7 16 21c-3-6-6-9-9-10-3 3-9 4-16 4-3 1-5 3-7 6z" fill="${pc}"/>`,
    rapado: `<path d="M35 36c1-11 8-16 15-16s14 5 15 16c-5-4-10-5-15-5s-10 1-15 5z" fill="${pc}" opacity=".85"/>`,
    puntas: `<path d="M33 40l1-9-4-5 7 1 2-8 5 6 6-9 3 9 7-6-1 8 7-1-4 6 2 8c-4-5-9-7-16-7s-11 2-15 7z" fill="${pc}"/>`,
    flequillo: `<path d="M34 42c-1-15 7-23 17-23 9 0 16 7 15 20-6-7-14-9-22-6-4 2-7 5-10 9z" fill="${pc}"/><path d="M52 22c-6 5-10 11-12 18" stroke="${oscurecer(pc.length === 7 ? pc : "#333333", 0.7)}" stroke-width="1.4" fill="none"/>`,
    largo: `<path d="M34 40c0-14 7-22 16-22s16 8 16 22c-6-8-11-10-16-10s-10 3-16 10z" fill="${pc}"/>`,
    coleta: `<path d="M34 40c0-14 7-22 16-22s16 8 16 22c-5-6-10-9-16-9s-11 3-16 9z" fill="${pc}"/>`,
    chongo: `<circle cx="50" cy="20" r="6" fill="${pc}"/><path d="M34 40c0-14 7-21 16-21s16 7 16 21c-5-6-10-8-16-8s-11 2-16 8z" fill="${pc}"/>`,
    mohawk: `<path d="M35 38c2-6 5-9 8-10l7-12 7 12c3 1 6 4 8 10-5-3-10-4-15-4s-10 1-15 4z" fill="${pc}"/><path d="M36 36c1-5 4-8 7-9M64 36c-1-5-4-8-7-9" stroke="${pielO}" stroke-width="1"/>`,
    rizado: `<g fill="${pc}"><circle cx="38" cy="32" r="6"/><circle cx="45" cy="25" r="6.5"/><circle cx="54" cy="24" r="6.5"/><circle cx="62" cy="30" r="6"/><circle cx="36" cy="40" r="4"/><circle cx="64" cy="39" r="4"/></g>`,
  };
  s += P[a.pelo] || P.corto;
  // accesorios
  const A = {
    audifonos: `<path d="M32 44c0-17 8-26 18-26s18 9 18 26" fill="none" stroke="#e8e8ee" stroke-width="3"/><rect x="28" y="40" width="7" height="12" rx="3" fill="#e8e8ee"/><rect x="65" y="40" width="7" height="12" rx="3" fill="#e8e8ee"/>`,
    lentes: `<rect x="38.5" y="41.5" width="10" height="7" rx="2" fill="#0b0b0d" stroke="#e8e8ee" stroke-width="1.2"/><rect x="51.5" y="41.5" width="10" height="7" rx="2" fill="#0b0b0d" stroke="#e8e8ee" stroke-width="1.2"/><path d="M48.5 44h3" stroke="#e8e8ee" stroke-width="1.2"/>`,
    visor: `<rect x="35" y="40" width="30" height="8" rx="4" fill="#2ec5ff" opacity=".9"/><path d="M38 42h10" stroke="#fff" stroke-width="1.2" opacity=".8"/>`,
    mascara: `<path d="M35 47c4 2 9 3 15 3s11-1 15-3c0 9-6 14-15 14s-15-5-15-14z" fill="#1a1a1f"/><path d="M40 53h20" stroke="#ffffff30" stroke-width="1.2"/>`,
    gorra: `<path d="M34 34c1-10 8-15 16-15s15 5 16 15z" fill="${ropaO}"/><path d="M32 34h28c6 0 10 1 12 3H32z" fill="${ropaO}"/>`,
    bandana: `<path d="M34.5 33c5-2 10-3 15.5-3s10.5 1 15.5 3v4c-5-2-10-3-15.5-3s-10.5 1-15.5 3z" fill="#d64545"/><path d="M65 35l6 4-5 2" fill="#d64545"/>`,
    corona: `<path d="M35 33c5-2 10-3 15-3s10 1 15 3v3c-5-2-10-3-15-3s-10 1-15 3z" fill="#f5c451"/><circle cx="50" cy="31" r="2" fill="#d64545"/>`,
  };
  s += A[a.acc] || "";
  s += emblema(a.i);
  return `<svg viewBox="0 0 100 105" aria-hidden="true">${s}</svg>`;
}

function avatarMascota(nombre, grande) {
  const h = tono(nombre);
  const m = AV_MASC[nombre] || { a: "oso", c: `hsl(${h} 40% 45%)`, i: "paw-print" };
  const c = m.c, cO = c.startsWith("#") ? oscurecer(c, 0.7) : c;
  const id = "am" + h + (grande ? "g" : "");
  let s = `<defs><radialGradient id="${id}" cx="50%" cy="40%" r="70%"><stop offset="0" stop-color="hsl(${h} 55% 30%)"/><stop offset="1" stop-color="#0b0b0d"/></radialGradient></defs>`;
  s += grande ? `<ellipse cx="50" cy="54" rx="47" ry="47" fill="url(#${id})"/>` : `<rect width="100" height="105" fill="url(#${id})"/>`;
  const ojos = (y = 50, col = "#111") => `<circle cx="42" cy="${y}" r="3" fill="${col}"/><circle cx="58" cy="${y}" r="3" fill="${col}"/><circle cx="43" cy="${y - 1}" r="1" fill="#fff"/><circle cx="59" cy="${y - 1}" r="1" fill="#fff"/>`;
  const cuerpo = `<ellipse cx="50" cy="92" rx="24" ry="16" fill="${c}"/>`;
  const F = {
    panda: `${cuerpo}<circle cx="34" cy="34" r="8" fill="#1a1a1a"/><circle cx="66" cy="34" r="8" fill="#1a1a1a"/><circle cx="50" cy="52" r="22" fill="${c}"/><ellipse cx="42" cy="50" rx="6" ry="7" fill="#1a1a1a"/><ellipse cx="58" cy="50" rx="6" ry="7" fill="#1a1a1a"/>${ojos(50, "#fff")}<ellipse cx="50" cy="60" rx="4" ry="3" fill="#1a1a1a"/><path d="M30 33h40l-4-10H34z" fill="#5a4a2a"/><rect x="26" y="32" width="48" height="4" rx="2" fill="#5a4a2a"/>`,
    nutria: `${cuerpo}<circle cx="34" cy="38" r="5" fill="${cO}"/><circle cx="66" cy="38" r="5" fill="${cO}"/><circle cx="50" cy="52" r="21" fill="${c}"/><ellipse cx="50" cy="60" rx="11" ry="8" fill="#e8d2b8"/>${ojos(49)}<ellipse cx="50" cy="56" rx="3.5" ry="2.5" fill="#1a1a1a"/><path d="M38 60l-8-1M38 62l-8 2M62 60l8-1M62 62l8 2" stroke="#e8d2b8" stroke-width="1"/>`,
    ave: `${cuerpo}<path d="M30 40l8 6M70 40l-8 6" stroke="${cO}" stroke-width="5" stroke-linecap="round"/><circle cx="50" cy="50" r="20" fill="${c}"/><ellipse cx="50" cy="56" rx="12" ry="10" fill="#f2e2c4"/>${ojos(46)}<path d="M45 54l5 8 5-8z" fill="#f5c451"/>`,
    dragon: `${cuerpo}<path d="M36 36l-6-14 12 10M64 36l6-14-12 10" fill="#f5c451"/><circle cx="50" cy="52" r="21" fill="${c}"/><ellipse cx="50" cy="61" rx="11" ry="7" fill="${cO}"/>${ojos(48, "#111")}<circle cx="46" cy="60" r="1.4" fill="#111"/><circle cx="54" cy="60" r="1.4" fill="#111"/><path d="M34 70l-6 6M66 70l6 6" stroke="${cO}" stroke-width="4"/>`,
    conejo: `${cuerpo}<ellipse cx="40" cy="22" rx="6" ry="17" fill="${c}"/><ellipse cx="60" cy="22" rx="6" ry="17" fill="${c}"/><ellipse cx="40" cy="22" rx="3" ry="12" fill="#ffb3c8"/><ellipse cx="60" cy="22" rx="3" ry="12" fill="#ffb3c8"/><circle cx="50" cy="54" r="20" fill="${c}"/><rect x="36" y="46" width="11" height="7" rx="3" fill="#111"/><rect x="53" y="46" width="11" height="7" rx="3" fill="#111"/><path d="M47 49h6" stroke="#111" stroke-width="1.5"/><ellipse cx="50" cy="60" rx="3" ry="2" fill="#ff8aa8"/>`,
    oso: `${cuerpo}<circle cx="34" cy="36" r="7" fill="${c}"/><circle cx="66" cy="36" r="7" fill="${c}"/><circle cx="50" cy="53" r="21" fill="${c}"/><ellipse cx="50" cy="61" rx="10" ry="7.5" fill="#d9b89a"/>${ojos(49)}<ellipse cx="50" cy="58" rx="3.5" ry="2.5" fill="#1a1a1a"/>`,
    mapache: `${cuerpo}<path d="M32 40l2-12 10 8M68 40l-2-12-10 8" fill="${c}"/><circle cx="50" cy="53" r="21" fill="${c}"/><path d="M30 50c6-6 14-6 20-2 6-4 14-4 20 2-6 4-14 4-20 0-6 4-14 4-20 0z" fill="#1a1a1a"/>${ojos(50, "#fff")}<ellipse cx="50" cy="62" rx="8" ry="5" fill="#e8e8ee"/><ellipse cx="50" cy="60" rx="3" ry="2" fill="#1a1a1a"/>`,
    pinguino: `<ellipse cx="50" cy="92" rx="22" ry="16" fill="${c}"/><ellipse cx="50" cy="95" rx="13" ry="12" fill="#f2f2f2"/><circle cx="50" cy="52" r="21" fill="${c}"/><ellipse cx="50" cy="56" rx="14" ry="13" fill="#f2f2f2"/>${ojos(50)}<path d="M45 57l5 5 5-5z" fill="#f5a524"/>`,
  };
  s += F[m.a] || F.oso;
  s += emblema(m.i);
  return `<svg viewBox="0 0 100 105" aria-hidden="true">${s}</svg>`;
}

// ---------- fotos propias del usuario ----------
let FOTOS = leer("rot-fotos", {});
function guardarFoto(nombre, dataURL) {
  FOTOS[nombre] = dataURL;
  try { localStorage.setItem("rot-fotos", JSON.stringify(FOTOS)); return true; }
  catch { delete FOTOS[nombre]; toast("No hay espacio para más fotos"); return false; }
}
function quitarFoto(nombre) { delete FOTOS[nombre]; escribir("rot-fotos", FOTOS); }
// reduce la imagen a 320 px para que ocupe poco
function leerImagen(archivo, listo) {
  const lector = new FileReader();
  lector.onload = () => {
    const img = new Image();
    img.onload = () => {
      const lado = 320, cv = document.createElement("canvas");
      const esc = Math.max(lado / img.width, lado / img.height);
      cv.width = lado; cv.height = Math.round(lado * 1.05);
      const w = img.width * esc, h = img.height * esc;
      cv.getContext("2d").drawImage(img, (lado - w) / 2, (cv.height - h) / 2.6, w, h);
      listo(cv.toDataURL("image/jpeg", 0.82));
    };
    img.onerror = () => toast("No se pudo abrir esa imagen");
    img.src = lector.result;
  };
  lector.readAsDataURL(archivo);
}

// retrato que usa toda la app: foto propia si existe; si no, el avatar dibujado
function retrato(nombre, grande) {
  if (FOTOS[nombre]) return `<img class="foto" src="${FOTOS[nombre]}" alt="">`;
  if (AV_MASC[nombre] || (typeof MASCOTAS !== "undefined" && MASCOTAS.some((m) => m.n === nombre))) return avatarMascota(nombre, grande);
  if (AV[nombre]) return avatarPersona(nombre, grande);
  // armas: mira con el nombre del arma principal
  if (/\+/.test(nombre) || (typeof ARMAS_DB !== "undefined" && ARMAS_DB.some((x) => nombre.startsWith(x.n)))) {
    const h = tono(nombre), primera = nombre.split("+")[0].trim();
    return `<svg viewBox="0 0 100 105" aria-hidden="true"><rect width="100" height="105" fill="hsl(${h} 30% 14%)"/><svg x="25" y="14" width="50" height="50" viewBox="0 0 24 24" fill="none" stroke="#f5c451" stroke-width="1.6" stroke-linecap="round">${ICONOS.crosshair}</svg><text x="50" y="88" text-anchor="middle" font-family="Outfit, sans-serif" font-weight="700" font-size="${primera.length > 6 ? 13 : 17}" fill="#fff">${esc(primera)}</text></svg>`;
  }
  // otros: silueta neutra con iniciales
  const h = tono(nombre), ini = nombre.replace(/[^A-Za-z0-9]/g, "").slice(0, 2).toUpperCase();
  return `<svg viewBox="0 0 100 105" aria-hidden="true"><rect width="100" height="105" fill="hsl(${h} 35% 16%)"/><text x="50" y="62" text-anchor="middle" font-family="Outfit, sans-serif" font-weight="700" font-size="26" fill="hsl(${h} 60% 70%)">${ini}</text></svg>`;
}
