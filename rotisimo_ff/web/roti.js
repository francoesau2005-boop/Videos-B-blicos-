// ================= ROTI: base de conocimiento =================
// Cada tema tiene palabras clave (k), respuestas (r: varias para no repetirse),
// una ilustración opcional (img) y botones de seguimiento (ops).

// ---------- Ilustraciones (dibujos propios en SVG) ----------
const IMG = {
  marco: (alto, contenido) => `<svg viewBox="0 0 300 ${alto}" class="ilus-svg" role="img">${contenido}</svg>`,

  // HUD en un celular horizontal según los dedos
  hud(dedos) {
    const btn = (x, y, r, txt, dedo) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${dedo ? "#ffffff" : "#1b1b1f"}" stroke="#fff" stroke-opacity=".5"/><text x="${x}" y="${y + 3.5}" text-anchor="middle" font-size="${txt.length > 4 ? 7.5 : 9}" font-weight="700" fill="${dedo ? "#000" : "#cfcfd6"}">${txt}</text>`;
    const d = +dedos;
    let c = `<rect x="6" y="6" width="288" height="150" rx="22" fill="#0c0c0e" stroke="#fff" stroke-opacity=".35"/><rect x="18" y="16" width="264" height="130" rx="12" fill="#141417"/>`;
    c += `<circle cx="62" cy="108" r="26" fill="none" stroke="#fff" stroke-opacity=".35" stroke-dasharray="3 3"/><circle cx="62" cy="108" r="11" fill="#2a2a30"/><text x="62" y="146" text-anchor="middle" font-size="8.5" fill="#8d8d96">mover</text>`;
    c += btn(232, 94, 20, "FUEGO", true) + btn(262, 58, 12, "MIRA", false) + btn(198, 128, 11, "SALTO", d === 2);
    c += btn(252, 128, 13, "AGACH", d >= 3) + btn(150, 32, 11, "GLOO", d >= 3) + btn(115, 32, 10, "REC", d === 4);
    if (d >= 3) c += `<text x="150" y="58" text-anchor="middle" font-size="8.5" fill="#3ddc84">índice izq.</text>`;
    if (d === 4) c += `<text x="230" y="40" text-anchor="middle" font-size="8.5" fill="#3ddc84">índice der.</text>`;
    c += `<text x="150" y="172" text-anchor="middle" font-size="10" fill="#cfcfd6">Botones en blanco = los que tocas con cada dedo extra</text>`;
    return IMG.marco(178, c);
  },

  // mira a la altura de la cabeza vs. al pecho
  altura() {
    const persona = (x, col) => `<circle cx="${x}" cy="40" r="11" fill="${col}"/><rect x="${x - 14}" y="54" width="28" height="44" rx="6" fill="#4a4a52"/><rect x="${x - 11}" y="100" width="22" height="34" rx="4" fill="#36363c"/>`;
    const mira = (x, y, col) => `<g stroke="${col}" stroke-width="2.4" stroke-linecap="round"><path d="M${x - 14} ${y}h8M${x + 6} ${y}h8M${x} ${y - 14}v8M${x} ${y + 6}v8"/></g>`;
    return IMG.marco(170, `<rect width="300" height="170" rx="14" fill="#0c0c0e"/>
      <line x1="10" y1="40" x2="290" y2="40" stroke="#3ddc84" stroke-dasharray="5 4" stroke-opacity=".7"/>
      ${persona(80, "#ff4d4d")}${mira(80, 76, "#ff4d4d")}
      ${persona(220, "#3ddc84")}${mira(220, 40, "#3ddc84")}
      <text x="80" y="156" text-anchor="middle" font-size="11" font-weight="700" fill="#ff4d4d">Mira al pecho ✗</text>
      <text x="220" y="156" text-anchor="middle" font-size="11" font-weight="700" fill="#3ddc84">Mira a la cabeza ✓</text>`);
  },

  // gesto de arrastre hacia arriba
  arrastre() {
    return IMG.marco(170, `<rect width="300" height="170" rx="14" fill="#0c0c0e"/>
      <circle cx="150" cy="128" r="26" fill="#fff"/><text x="150" y="132" text-anchor="middle" font-size="10" font-weight="700" fill="#000">FUEGO</text>
      <path d="M150 100 C 152 70, 158 52, 168 30" fill="none" stroke="#3ddc84" stroke-width="4" stroke-linecap="round" stroke-dasharray="2 8"/>
      <path d="M160 32 L168 28 L170 37" fill="none" stroke="#3ddc84" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
      <text x="196" y="40" font-size="11" fill="#cfcfd6">2. jala hacia arriba</text>
      <text x="196" y="132" font-size="11" fill="#cfcfd6">1. toca y no sueltes</text>
      <text x="20" y="40" font-size="11" fill="#8d8d96">1-3 cm</text><path d="M44 48v70" stroke="#8d8d96" stroke-width="1.5" stroke-dasharray="3 3"/>`);
  },

  // pared gloo: vista desde arriba
  gloo() {
    return IMG.marco(170, `<rect width="300" height="170" rx="14" fill="#0c0c0e"/>
      <circle cx="70" cy="85" r="12" fill="#3ddc84"/><text x="70" y="114" text-anchor="middle" font-size="10" fill="#3ddc84">Tú</text>
      <circle cx="240" cy="85" r="12" fill="#ff4d4d"/><text x="240" y="114" text-anchor="middle" font-size="10" fill="#ff4d4d">Enemigo</text>
      <path d="M112 50 Q 122 85 112 120" fill="none" stroke="#2ec5ff" stroke-width="9" stroke-linecap="round"/>
      <text x="112" y="140" text-anchor="middle" font-size="10" fill="#2ec5ff">Gloo pegada a ti</text>
      <path d="M150 85h60" stroke="#ff4d4d" stroke-width="2" stroke-dasharray="4 4"/><text x="180" y="78" text-anchor="middle" font-size="9" fill="#8d8d96">balas</text>
      <text x="150" y="26" text-anchor="middle" font-size="11" fill="#cfcfd6">Lánzala 1-2 pasos frente a ti, hacia el enemigo</text>`);
  },

  // rotación de zona
  zona() {
    return IMG.marco(190, `<rect width="300" height="190" rx="14" fill="#0c0c0e"/>
      <circle cx="150" cy="95" r="80" fill="#1b1b1f" stroke="#ffffff55" stroke-width="2"/>
      <circle cx="172" cy="80" r="40" fill="#3ddc8418" stroke="#3ddc84" stroke-width="2"/>
      <circle cx="96" cy="140" r="7" fill="#fff"/><text x="96" y="160" text-anchor="middle" font-size="9.5" fill="#fff">Tú</text>
      <path d="M100 132 Q 120 112 136 98" fill="none" stroke="#f5c451" stroke-width="3" stroke-dasharray="5 5" stroke-linecap="round"/>
      <path d="M130 96 l8 -1 -2 8" fill="none" stroke="#f5c451" stroke-width="3" stroke-linecap="round"/>
      <text x="230" y="40" font-size="9.5" fill="#3ddc84">siguiente zona</text>
      <text x="16" y="182" font-size="10" fill="#cfcfd6">Entra por el borde, temprano, con cobertura cerca</text>`);
  },

  // escalera de rangos
  rangos() {
    const r = [["Bronce", "#b07a4f"], ["Plata", "#c9cdd6"], ["Oro", "#f5c451"], ["Platino", "#7fd6d0"], ["Diamante", "#2ec5ff"], ["Heroico", "#a77bff"], ["Gran Maestro", "#ff4d4d"]];
    let c = `<rect width="300" height="${r.length * 26 + 16}" rx="14" fill="#0c0c0e"/>`;
    r.forEach(([n, col], i) => {
      const y = 8 + (r.length - 1 - i) * 26, w = 120 + i * 22;
      c += `<rect x="${150 - w / 2}" y="${y}" width="${w}" height="20" rx="6" fill="${col}" fill-opacity=".18" stroke="${col}"/><text x="150" y="${y + 14}" text-anchor="middle" font-size="11" font-weight="700" fill="${col}">${n}</text>`;
    });
    return IMG.marco(r.length * 26 + 16, c);
  },

  // silueta de arma por tipo
  arma(tipo, nombre) {
    const s = `fill="#1b1b1f" stroke="#fff" stroke-width="2" stroke-linejoin="round"`;
    const formas = {
      escopeta: `<path d="M40 70h150l10-8h60v14H120l-10 10H70l-12 22H38l8-24z" ${s}/><path d="M150 76h40v6h-40z" ${s}/>`,
      subfusil: `<path d="M60 64h150v12h40v8h-40v6H150l-8 30h-18l6-30H96l-14 24H62l12-26-14-4z" ${s}/><path d="M130 90h14v30h-14z" ${s}/>`,
      rifle: `<path d="M30 70l40-6h150v-6h50v10h-50v10H170l-6 30h-18l4-30h-28l-10 14H90l-4-14H58l-28 10z" ${s}/><path d="M120 78h16l4 22h-16z" ${s}/>`,
      sniper: `<path d="M20 74l50-8h200v8H170v6h-40l-6 22h-16l2-22H80l-60 10z" ${s}/><rect x="110" y="48" width="70" height="12" rx="6" ${s}/><path d="M130 60v6M160 60v6" stroke="#fff" stroke-width="2"/>`,
      pistola: `<path d="M100 60h110v18H150l-8 40h-24l8-40h-26z" ${s}/><path d="M140 78h12v10h-12z" ${s}/>`,
    };
    return IMG.marco(140, `<rect width="300" height="140" rx="14" fill="#0c0c0e"/>${formas[tipo] || formas.rifle}<text x="150" y="130" text-anchor="middle" font-size="12" font-weight="700" fill="#fff">${nombre}</text><text x="280" y="22" text-anchor="end" font-size="9.5" fill="#8d8d96">${tipo.toUpperCase()}</text>`);
  },

  // tarjeta de personaje con silueta
  personaje(x, tipo) {
    return `<div class="pj-card"><div class="ret">${retrato(x.n, false)}</div><div><small>${tipo.toUpperCase()}</small><b>${esc(x.n)}</b><p>${esc(x.h)}</p></div></div>`;
  },

  // movimiento: agacharse y levantarse
  movimiento() {
    return IMG.marco(150, `<rect width="300" height="150" rx="14" fill="#0c0c0e"/>
      <g fill="#cfcfd6"><circle cx="60" cy="40" r="9"/><rect x="49" y="52" width="22" height="40" rx="6"/><rect x="51" y="94" width="18" height="30" rx="4"/></g>
      <g fill="#3ddc84"><circle cx="150" cy="70" r="9"/><rect x="139" y="82" width="22" height="26" rx="6"/><rect x="141" y="110" width="18" height="14" rx="4"/></g>
      <g fill="#cfcfd6"><circle cx="240" cy="40" r="9"/><rect x="229" y="52" width="22" height="40" rx="6"/><rect x="231" y="94" width="18" height="30" rx="4"/></g>
      <path d="M80 60 Q 110 40 132 62M170 62 Q 195 40 220 60" fill="none" stroke="#f5c451" stroke-width="2.5" stroke-dasharray="4 4"/>
      <text x="150" y="142" text-anchor="middle" font-size="10.5" fill="#cfcfd6">De pie → agachado → de pie mientras disparas</text>`);
  },
};

// ---------- Armas ----------
const ARMAS_DB = [
  { n: "M1887", k: ["m1887", "1887"], t: "escopeta", h: "Escopeta de palanca: dos tiros a la cabeza tumban. La reina del 1 vs 1 de cerca.", tip: "Espera a tener la cabeza en la mira; un tiro al cuerpo te deja vendido mientras recarga." },
  { n: "M1014", k: ["m1014", "1014"], t: "escopeta", h: "Escopeta semiautomática con buen alcance para ser escopeta.", tip: "Apunta a la cabeza en el primer tiro y muévete de lado entre disparos." },
  { n: "SPAS12", k: ["spas", "spas12"], t: "escopeta", h: "Escopeta con mucho daño de cerca.", tip: "Úsala en casas y esquinas, nunca a media distancia." },
  { n: "MP40", k: ["mp40", "mp 40"], t: "subfusil", h: "Subfusil rapidísimo para pelear de cerca.", tip: "Jala suave y constante hacia arriba mientras disparas." },
  { n: "UMP", k: ["ump"], t: "subfusil", h: "Subfusil con buena penetración de armadura y fácil de controlar.", tip: "Excelente para empezar: dispara en ráfagas y apunta al casco." },
  { n: "MP5", k: ["mp5"], t: "subfusil", h: "Subfusil estable y equilibrado.", tip: "Buena opción si te cuesta controlar el retroceso." },
  { n: "Vector", k: ["vector"], t: "subfusil", h: "Subfusil muy rápido para entrar con todo.", tip: "Vacía el cargador cerca; recarga detrás de una gloo." },
  { n: "Thompson", k: ["thompson"], t: "subfusil", h: "Subfusil con cargador grande.", tip: "Sirve para sostener el fuego contra varias personas." },
  { n: "P90", k: ["p90"], t: "subfusil", h: "Subfusil con muchísima munición.", tip: "Ideal para limpiar escuadras de cerca." },
  { n: "M4A1", k: ["m4a1", "m4"], t: "rifle", h: "Rifle con mucha munición y poco retroceso.", tip: "Para media distancia; agáchate y dispara en ráfagas." },
  { n: "SCAR", k: ["scar"], t: "rifle", h: "Rifle estable con buen daño.", tip: "Cómodo para todo: buena primera arma si no sabes cuál usar." },
  { n: "AK", k: ["ak", "ak47", "ak 47"], t: "rifle", h: "Rifle con mucho daño pero retroceso fuerte.", tip: "Agáchate y dispara en ráfagas cortas para no perder la mira." },
  { n: "Groza", k: ["groza"], t: "rifle", h: "Rifle potente de los cofres y lanzamientos.", tip: "Si la encuentras, quédatela: daño alto y buen control." },
  { n: "FAMAS", k: ["famas"], t: "rifle", h: "Rifle de ráfagas de 3 tiros.", tip: "Cada ráfaga apúntala a la cabeza; no la uses como automática." },
  { n: "XM8", k: ["xm8"], t: "rifle", h: "Rifle con mira integrada y buen control.", tip: "Muy cómoda a media distancia." },
  { n: "AWM", k: ["awm"], t: "sniper", h: "Francotirador: un tiro a la cabeza derriba.", tip: "Usa sensi baja en la mira y dispara cuando el enemigo se detenga." },
  { n: "Kar98k", k: ["kar98", "kar 98", "kar98k"], t: "sniper", h: "Francotirador de cerrojo con mucho daño.", tip: "Apunta un poco adelante si el enemigo corre de lado." },
  { n: "M82B", k: ["m82b", "m82"], t: "sniper", h: "Francotirador que atraviesa paredes gloo.", tip: "Úsalo para romper la gloo del rival y que tu escuadra entre." },
  { n: "SVD", k: ["svd"], t: "sniper", h: "Francotirador semiautomático.", tip: "Dispara varias veces seguidas en lugar de un solo tiro." },
  { n: "Woodpecker", k: ["woodpecker", "pajaro carpintero", "carpintero"], t: "rifle", h: "Rifle de tirador que atraviesa armadura.", tip: "Apunta al casco a media distancia y combínala con un subfusil." },
  { n: "Desert Eagle", k: ["desert", "deagle", "desierto", "eagle"], t: "pistola", h: "Pistola con mucho daño a la cabeza.", tip: "La mejor para practicar precisión en el campo de entrenamiento." },
  { n: "M500", k: ["m500"], t: "pistola", h: "Pistola con mira 2x.", tip: "Sirve para rematar de lejos cuando te quedas sin balas." },
];

// ---------- Nombres con letras especiales ----------
const NOMBRES = {
  pre: ["꧁", "亗", "乂", "メ", "ღ", "★", "☬", "ᴿᴼᵀ", "×", "⚡"],
  suf: ["꧂", "亗", "乂", "メ", "ღ", "★", "☬", "ツ", "×", "⚡"],
  base: ["Sombra", "Rayo", "Fantasma", "Lobo", "Dragón", "Rey", "Cuervo", "Titán", "Ninja", "Fénix", "Toxic", "Zeus", "Kira", "Raven", "Vandal", "Rush", "Héroe", "Diablo", "Ángel", "Shadow"],
  extra: ["FF", "YT", "OP", "GG", "Pro", "XD", "MX", "777", "99", "TTV"],
};
function generarNombres(base) {
  const out = new Set();
  const fancy = (t) => [...t].map((c) => ({ a: "ᴀ", e: "ᴇ", o: "ᴏ", r: "ʀ", n: "ɴ", i: "ɪ", s: "ꜱ", t: "ᴛ", l: "ʟ", k: "ᴋ", g: "ɢ", d: "ᴅ", m: "ᴍ", h: "ʜ", u: "ᴜ", y: "ʏ", z: "ᴢ", c: "ᴄ", p: "ᴘ", b: "ʙ", f: "ꜰ", w: "ᴡ", v: "ᴠ", j: "ᴊ", x: "x" })[c.toLowerCase()] || c).join("");
  while (out.size < 5) {
    const b = base || azar(NOMBRES.base);
    const i = Math.floor(Math.random() * NOMBRES.pre.length);
    const forma = azar([
      () => `${NOMBRES.pre[i]}${b}${NOMBRES.suf[i]}`,
      () => `${NOMBRES.pre[i]}${fancy(b)}${NOMBRES.suf[i]}`,
      () => `${b}ㅤ${azar(NOMBRES.extra)}`,
      () => `${azar(NOMBRES.extra)}亗${b}`,
      () => `${fancy(b)}ツ`,
    ]);
    out.add(forma().slice(0, 12));
  }
  return [...out];
}

// ---------- Chistes y frases ----------
const CHISTES = [
  "¿Por qué la pared gloo nunca va a fiestas? Porque siempre se queda en medio de todo.",
  "Mi escuadra es como el Wi-Fi del vecino: aparece cuando no la necesito.",
  "Le pregunté a un campero dónde estaba… y todavía estoy esperando que salga.",
  "Dicen que el rusher y el sniper nunca se entienden: uno dice 'entra' y el otro ya está en el avión.",
  "¿Qué le dijo la M1887 a la MP40? 'Tú dispara mucho, yo solo necesito dos'.",
];
const MOTIVACION = [
  "Todos los pros perdieron miles de partidas antes de ser buenos. Lo importante es aprender de cada una.",
  "Una mala racha no define cómo juegas. Descansa 10 minutos, toma agua y vuelve con la mente fría.",
  "Graba tus partidas y mira dónde moriste: casi siempre es por la posición, no por la puntería.",
];

// ---------- Temas ----------
// k: palabras clave (sin acentos). r: texto o lista de textos. img: función de ilustración.
const TEMAS = [
  // --- Charla ---
  { id: "saludo", k: ["hola", "buenas", "buenos dias", "buenas tardes", "buenas noches", "hey", "que onda", "que tal", "ola", "holi", "saludos", "wenas"], r: ["¡Hola! ¿Qué hacemos hoy: combo, sensi o tips para la cabeza?", "¡Qué onda! Listo para ayudarte a romperla. ¿Qué necesitas?", "¡Buenas! Pregúntame lo que quieras de Free Fire."], ops: "menu" },
  { id: "como-estas", k: ["como estas", "como te va", "todo bien", "como andas"], r: ["¡Al cien! Con la batería llena y la mira a la altura de la cabeza. ¿Y tú?", "Muy bien, practicando arrastres. ¿En qué te ayudo?"], ops: "menu" },
  { id: "quien", k: ["quien eres", "que eres", "como te llamas", "tu nombre", "presentate"], r: "Soy Roti, el asistente de Rotísimo. Te ayudo con combos, sensibilidad, armas, personajes, HUD, lag y tips para subir de rango.", ops: "menu" },
  { id: "eres-ia", k: ["eres una ia", "eres ia", "inteligencia artificial", "eres un robot", "eres real", "chatgpt", "eres humano"], r: "Soy un asistente con respuestas preparadas: entiendo muchos temas de Free Fire, pero no soy una IA que piensa como persona. A cambio funciono sin internet y no guardo lo que escribes." },
  { id: "creador", k: ["quien te creo", "quien te hizo", "tu creador", "quien te programo"], r: "Me hicieron para la app Rotísimo, pensado para jugadores de Free Fire que quieren mejorar sin hacks." },
  { id: "que-puedes", k: ["que puedes hacer", "que sabes", "ayuda", "que haces", "opciones", "menu", "que te puedo preguntar", "comandos"], r: "Puedo ayudarte con:\n• Combos por estilo o personaje\n• Sensibilidad por celular y marca\n• Armas y personajes\n• HUD de 2, 3 y 4 dedos\n• Tiros a la cabeza, paredes gloo y movimiento\n• Rotar zona, subir de rango y CS\n• Lag, calentamiento y FPS\n• Nombres con letras especiales\nTambién te cuento un chiste si quieres.", ops: "temas" },
  { id: "gracias", k: ["gracias", "grax", "thank", "te pasaste", "eres el mejor", "muy bien", "excelente", "genial", "chido", "bacano", "chevere"], r: ["¡De nada! A romperla.", "¡Para eso estoy! Que te salga todo rojo.", "¡Con gusto! Cualquier cosa me escribes."] },
  { id: "adios", k: ["adios", "bye", "chao", "nos vemos", "me voy", "hasta luego"], r: ["¡Suerte en tus partidas! Vuelve cuando quieras.", "¡Nos vemos! Que caigas en buena zona."] },
  { id: "chiste", k: ["chiste", "algo gracioso", "hazme reir", "broma", "cuentame algo"], r: CHISTES, ops: [["Otro chiste", "chiste"]] },
  { id: "insulto", k: ["tonto", "inutil", "no sirves", "malo", "feo", "basura"], r: "Uy, eso dolió más que un tiro a la cabeza. Dime qué necesitas y lo intento mejor.", ops: "menu" },
  { id: "edad", k: ["cuantos anos tienes", "tu edad", "cuantos años"], r: "Nací con la última versión de la app, así que soy un novato… pero con muchas horas de entrenamiento." },
  { id: "amor", k: ["te quiero", "te amo", "eres lindo", "me caes bien"], r: "¡Yo también te aprecio! Sobre todo si me haces caso con la sensi." },

  // --- Ánimo ---
  { id: "frustrado", k: ["pierdo siempre", "siempre pierdo", "soy malo", "no puedo ganar", "estoy frustrado", "me matan", "me mataron", "no mato a nadie", "tilt", "me enoje", "estoy enojado"], r: MOTIVACION, ops: [["Rutina de práctica", "rutina"], ["Tips de cabeza", "cabeza"]] },

  // --- Cabeza ---
  { id: "cabeza", k: ["cabeza", "headshot", "head shot", "todo rojo", "dar rojo", "punteria", "apuntar", "dar cabeza", "tiro a la cabeza", "tiros a la cabeza"], r: "Para dar más tiros a la cabeza:\n1. Camina con la mira a la altura de la cabeza (mira el dibujo).\n2. Toca disparar y en el mismo movimiento jala hacia arriba.\n3. Usa punto rojo de cerca.\n4. Con escopeta, espera la cabeza: no dispares al cuerpo.", img: () => IMG.altura(), ops: [["El arrastre", "arrastre"], ["Ir a Entrenar", "@entrenar"]] },
  { id: "arrastre", k: ["arrastre", "arrastrar", "jalar", "jalar para arriba", "deslizar", "drag", "como se jala"], r: "El arrastre es tocar el botón de disparo y, sin soltar, subir el pulgar 1 a 3 cm. Si tu sensi General es alta, el movimiento es corto. Practícalo 2 minutos al día en Entrenar.", img: () => IMG.arrastre(), ops: [["Ir a Entrenar", "@entrenar"], ["Mi sensibilidad", "sensi"]] },
  { id: "mira-pasa", k: ["se me pasa la mira", "la mira se pasa", "se va muy arriba", "se me va arriba", "se pasa de la cabeza"], r: "Si la mira se pasa de la cabeza, tu sensi General está alta para tu pulgar. Bájala de 5 en 5 hasta que llegues justo a la cabeza con un solo movimiento.", ops: [["Calibrar mi mira", "calibrar"]] },
  { id: "mira-no-sube", k: ["no me sube la mira", "no sube la mira", "no llega a la cabeza", "mira no sube", "no subo la mira"], r: "Si la mira no llega a la cabeza, sube la General de 5 en 5, o haz el arrastre un poco más largo. También revisa que el botón de disparo no esté pegado al borde de la pantalla.", ops: [["Calibrar mi mira", "calibrar"], ["El arrastre", "arrastre"]] },
  { id: "calibrar", k: ["calibrar", "calibra", "ajustar la mira", "probar sensi"], r: "Para calibrar tu mira:\n1. Campo de entrenamiento con Desert Eagle.\n2. Dispara a la cabeza de un muñeco a 20 m.\n3. Si te pasas, baja 5 la General.\n4. Si no llegas, súbele 5.\n5. Repite hasta llegar justo con un solo movimiento." },
  { id: "escopeta-cabeza", k: ["cabeza con escopeta", "headshot escopeta", "m1887 cabeza", "rojo con escopeta"], r: "Con escopeta: mira a la cabeza ANTES de disparar, salta y dispara al caer, y no dispares si la mira está en el cuerpo. Dos tiros limpios con M1887 ganan cualquier 1 vs 1.", img: () => IMG.arma("escopeta", "M1887") },

  // --- Gloo y movimiento ---
  { id: "gloo", k: ["gloo", "pared", "paredes", "muro", "gloo rapido", "poner gloo"], r: "Paredes gloo como pro:\n• Lánzala 1-2 pasos frente a ti, hacia el enemigo (mira el dibujo).\n• Ponla en cuanto te disparen, antes de buscar al rival.\n• Cúrate detrás de la gloo, nunca al aire libre.\n• Lleva al menos 6 en BR.\n• Con 3 o 4 dedos, pon el botón de gloo al alcance del índice.", img: () => IMG.gloo(), ops: [["HUD de 3 dedos", "hud3"]] },
  { id: "movimiento", k: ["moverme", "movimiento", "esquivar", "agacharse", "agacharme", "como me muevo", "no me den", "jiggle"], r: "Para que no te den:\n• Muévete de lado mientras disparas.\n• Agáchate y levántate durante el disparo: tu cabeza cambia de altura.\n• Salta solo de cerca, para cambiar el ángulo.\n• Nunca te quedes quieto al aire libre.", img: () => IMG.movimiento() },
  { id: "salto", k: ["saltar", "salto", "brincar"], r: "Salta en peleas cercanas: al caer, la mira tiende a la cabeza del rival. A media distancia no saltes: pierdes precisión y eres blanco fácil." },

  // --- HUD ---
  { id: "hud2", k: ["2 dedos", "dos dedos"], r: "HUD de 2 dedos: todo con los pulgares. Pon disparo grande abajo a la derecha, salto cerca del pulgar derecho y gloo encima del joystick. Cuando te acostumbres, prueba 3 dedos.", img: () => IMG.hud(2), ops: [["HUD de 3 dedos", "hud3"]] },
  { id: "hud3", k: ["3 dedos", "tres dedos"], r: "HUD de 3 dedos: el índice izquierdo toca gloo y agacharse. Así puedes moverte, disparar y poner pared al mismo tiempo.", img: () => IMG.hud(3), ops: [["HUD de 4 dedos", "hud4"]] },
  { id: "hud4", k: ["4 dedos", "cuatro dedos", "garra", "claw"], r: "HUD de 4 dedos (garra): los dos índices tocan gloo, agacharse y recargar. Es el más rápido, pero tarda unas semanas en acostumbrarse.", img: () => IMG.hud(4) },
  { id: "hud", k: ["hud", "botones", "controles", "configurar botones", "mejor hud"], r: "Reglas para un buen HUD:\n• Botón de disparo 55-65% y algo arriba del centro derecho.\n• Transparencia 30-40%.\n• Mira cerca del pulgar derecho.\n• Gloo y agacharse al alcance de un dedo libre.\n¿Con cuántos dedos juegas?", ops: [["2 dedos", "hud2"], ["3 dedos", "hud3"], ["4 dedos", "hud4"]] },

  // --- Sensi y celulares ---
  { id: "dpi", k: ["dpi", "ancho minimo", "densidad"], r: "El DPI se cambia en Opciones de desarrollador → \"Ancho mínimo\". Subirlo un poco (por ejemplo de 400 a 450) hace que todo se vea más pequeño y la mira se mueva más con el mismo arrastre. Cambia solo un poco y anota el valor original para regresarlo si no te gusta. No es obligatorio: una buena sensi funciona igual." },
  { id: "sensi-awm", k: ["sensi awm", "sensi sniper", "sensi para awm", "sensi francotirador"], r: "Para francotirador: mira AWM baja (40-55 de 100, u 80-110 de 200). Así no se te pasa la cabeza al hacer zoom. Dispara cuando el enemigo se detenga.", ops: [["Mi sensibilidad", "sensi"]] },
  { id: "sensi-escopeta", k: ["sensi m1887", "sensi escopeta", "sensi para escopeta"], r: "Para escopeta se usa la General (disparas sin mira). Súbela hasta que, con un arrastre corto, la mira pase del pecho a la cabeza.", ops: [["Mi sensibilidad", "sensi"]] },
  { id: "iphone", k: ["iphone", "ios", "ipad", "apple"], r: "En iPhone la pantalla responde muy rápido, así que usa la sensi un poco más baja que en Android (unos 5-10 puntos menos de 100). En iPad, el HUD de 4 dedos funciona muy bien.", ops: [["Mi sensibilidad", "sensi"]] },
  { id: "samsung", k: ["samsung", "galaxy"], r: "Samsung: los Galaxy A de 4-6 GB son gama media; los S y los A con 8 GB son gama alta. Activa Game Booster y desactiva el ahorro de batería al jugar.", ops: [["Sensi gama media", "sensi-media"], ["Sensi gama alta", "sensi-alta"]] },
  { id: "xiaomi", k: ["xiaomi", "redmi", "poco"], r: "Xiaomi, Redmi y Poco: activa Game Turbo, pon el modo Rendimiento y quita las animaciones. Los Poco suelen aguantar FPS altos; los Redmi baratos, mejor gráficos Fluido.", ops: [["Sensi gama baja", "sensi-baja"], ["Sensi gama media", "sensi-media"]] },
  { id: "motorola", k: ["motorola", "moto g", "moto e"], r: "Motorola: los Moto G suelen ser gama media y los Moto E gama baja. Libera almacenamiento y cierra apps antes de jugar.", ops: [["Sensi gama baja", "sensi-baja"], ["Sensi gama media", "sensi-media"]] },
  { id: "huawei", k: ["huawei", "honor"], r: "Huawei y Honor: activa el modo Rendimiento en Batería y Game Center si lo tienes.", ops: [["Sensi gama media", "sensi-media"]] },
  { id: "tecno", k: ["tecno", "infinix", "itel", "zte", "alcatel", "lg"], r: "En estos celulares casi siempre conviene tratarlos como gama baja: gráficos Fluido, sensi alta y cerrar todo antes de jugar.", ops: [["Sensi gama baja", "sensi-baja"]] },
  { id: "tablet", k: ["tablet", "tableta"], r: "En tablet la pantalla es grande: sube la sensi para no hacer arrastres muy largos, y prueba 4 dedos.", ops: [["Mi sensibilidad", "sensi"]] },

  // --- Rendimiento ---
  { id: "lag", k: ["lag", "traba", "se traba", "lento", "ping", "congela", "laguea", "tironea", "va lento"], r: "Para quitar el lag:\n• Gráficos Fluido; FPS altos solo si no se calienta.\n• Cierra apps de fondo.\n• Wi-Fi de 5 GHz o datos con buena señal.\n• Libera al menos 3 GB.\n• Activa el modo juego de tu celular.\n• Borra la caché del juego (Ajustes → Apps)." },
  { id: "ping", k: ["ping alto", "ping rojo", "internet malo", "se desconecta", "conexion"], r: "Ping alto es problema de internet, no del celular:\n• Acércate al módem o usa 5 GHz.\n• Que nadie descargue o vea videos en tu red mientras juegas.\n• Con datos, busca señal 4G/5G estable.\n• Reinicia el módem si lleva días encendido." },
  { id: "calienta", k: ["calienta", "caliente", "temperatura", "se quema", "calor"], r: "Si se te calienta:\n• Quita la funda.\n• No juegues cargando.\n• Baja brillo y gráficos.\n• Desactiva sombras y FPS altos.\n• Juega en un lugar fresco.\nUn celular caliente baja los FPS." },
  { id: "bateria", k: ["bateria", "se descarga", "pila"], r: "Para que dure la batería: brillo al 60%, FPS normales, sin Bluetooth ni GPS y modo avión con Wi-Fi si juegas en casa." },
  { id: "fps", k: ["fps", "90 fps", "60 fps", "120 fps", "graficos", "calidad"], r: "FPS altos hacen que la mira se sienta más suave. Si tu celular aguanta 60, 90 o 120 sin calentarse, úsalos. Prefiere FPS altos con gráficos Fluido a gráficos Ultra con pocos FPS." },
  { id: "cierra", k: ["se cierra", "se sale el juego", "crashea", "se crashea", "no abre"], r: "Si el juego se cierra:\n• Libera almacenamiento (3 GB o más).\n• Borra caché del juego.\n• Actualiza el juego desde la tienda.\n• Reinicia el celular.\n• Si sigue, baja gráficos a Fluido." },
  { id: "max", k: ["free fire max", "ff max", "max o normal", "cual es mejor max"], r: "Free Fire MAX tiene mejores gráficos pero pide más celular. Si tienes gama baja o media, el normal va más fluido. Tu cuenta es la misma en los dos." },

  // --- Estrategia ---
  { id: "zona", k: ["zona", "rotar", "rotacion", "gas", "circulo"], r: "Para rotar bien:\n• Muévete temprano, antes de que cierre.\n• Entra por el borde de la zona, no por el centro.\n• Usa vehículos de lejos y bájate antes de llegar.\n• Busca casas o rocas en el borde.", img: () => IMG.zona() },
  { id: "caer", k: ["donde caer", "donde aterrizar", "aterrizar", "caer", "lanzarme", "avion"], r: "Para subir de rango, cae en zonas medias: lejos del recorrido del avión pero con casas. Si quieres practicar peleas, cae en zonas calientes. Lo más importante: tener arma en los primeros 20 segundos." },
  { id: "rango", k: ["subir de rango", "rango", "heroico", "gran maestro", "maestro", "clasificatoria", "ranked", "puntos"], r: "Para subir de rango en BR, sobrevivir da muchos puntos:\n• Cae en zona media.\n• Rota temprano.\n• Pelea solo cuando tengas ventaja.\n• En el final, prioriza la posición sobre las kills.", img: () => IMG.rangos() },
  { id: "final", k: ["final", "ultima zona", "top 1", "booyah", "ganar la partida", "como gano"], r: "Para el final:\n• Llega con 6+ gloo y botiquines.\n• Busca posición alta o cobertura sólida.\n• Deja que los demás peleen entre ellos.\n• Ataca solo al que quede débil." },
  { id: "solo", k: ["solo", "jugar solo", "solitario"], r: "Jugando solo: sé paciente, usa combo de Vida o Tanque, evita peleas de 1 contra escuadra y aprovecha cuando dos equipos se están peleando.", ops: [["Combo de Vida", "!vida"]] },
  { id: "escuadra", k: ["escuadra", "equipo", "squad", "duo", "jugar con amigos"], r: "En escuadra: uno entra (rusher), uno apoya, uno cubre de lejos y uno cura. Avisen a quién marcan y nunca entren de uno en uno.", ops: [["Combo de Soporte", "!apoyo"], ["Combo Rusher", "!rusher"]] },
  { id: "cs", k: ["cs", "duelo de escuadras", "contra escuadra", "4 vs 4", "4v4"], r: "Tips para CS:\n• Compra chaleco antes que arma si tienes poco dinero.\n• Entra en pareja, nunca solo.\n• Guarda gloo para el final de la ronda.\n• Si quedas último, juega por vida y escudo.", ops: [["Combo para CS", "!cs"]] },
  { id: "campear", k: ["campear", "campero", "campeo", "esconderme"], r: "Campear sirve en el final de BR, pero si lo haces toda la partida te quedas sin botín. Combínalo: rota, consigue equipo y campea solo en las últimas zonas." },
  { id: "rush", k: ["como rushear", "rushear", "entrar a matar", "ser rusher"], r: "Para rushear:\n• Rompe la gloo del rival y entra justo después.\n• Usa escopeta o subfusil.\n• Activa tu habilidad al entrar, no después.\n• Si fallas, pon gloo y cúrate.", ops: [["Combo Rusher", "!rusher"]] },
  { id: "botiquin", k: ["botiquin", "curar", "curarme", "medkit", "vida"], r: "Cúrate siempre detrás de una gloo, nunca al aire libre. Personajes como Maxim curan más rápido y Kapella hace que curen más." },
  { id: "rutina", k: ["rutina", "entrenar", "practicar", "como mejorar", "mejorar", "entrenamiento"], r: "Rutina de 10 minutos:\n• 2 min en el Entrenador de Rotísimo.\n• 3 min con Desert Eagle a la cabeza de muñecos.\n• 3 min con M1887 moviéndote de lado.\n• 2 min con MP40 a media distancia.", ops: [["Ir a Entrenar", "@entrenar"]] },

  // --- Cuenta y seguridad ---
  { id: "hack", k: ["hack", "regedit", "aimbot", "trampa", "chetos", "mod menu", "apk mod", "auto headshot", "aim lock", "panel hack"], r: "No te recomiendo hacks, regedit, aim lock ni \"paneles\". Garena los detecta, banea la cuenta para siempre y muchos traen virus que roban tus datos. Lo que sí funciona: buena sensi, HUD cómodo y práctica.", ops: [["Mi sensibilidad", "sensi"], ["Rutina de práctica", "rutina"]] },
  { id: "ban", k: ["baneo", "baneada", "baneado", "ban", "suspendida", "suspendieron"], r: "Si te banearon, solo Garena puede revisarlo desde su soporte oficial. No pagues a nadie que prometa desbanear: es estafa. Para la próxima, evita apps de hacks y mods." },
  { id: "diamantes", k: ["diamantes gratis", "diamantes", "dimas", "recargar"], r: "No existen generadores de diamantes gratis: son estafas para robar cuentas. Recarga solo dentro del juego o en sitios oficiales de Garena. Una opción legal es ganar saldo de Google Play con encuestas de Google Opinion Rewards." },
  { id: "codigos", k: ["codigo", "codigos", "canje", "canjear", "redeem"], r: "Los códigos de canje se usan solo en la página oficial de canje de Garena (reward.ff.garena.com), iniciando sesión con tu cuenta vinculada. Nunca des tu contraseña en otras páginas." },
  { id: "vincular", k: ["vincular", "invitado", "perdi mi cuenta", "recuperar cuenta", "cuenta"], r: "Vincula tu cuenta (Google, Facebook u otra) desde tu perfil en el juego. Una cuenta de invitado se pierde si borras el juego o cambias de celular." },

  // --- Nombres ---
  { id: "nombres", k: ["nombre", "nombres", "nick", "apodo", "letras especiales", "nombre bonito", "nombre para free fire"], r: "Aquí tienes nombres con letras especiales. Toca uno para copiarlo:", especial: "nombres" },

  // --- Navegación ---
  { id: "nav-sensi", k: ["abre sensi", "ir a sensi", "pestaña sensi"], r: "Te llevo a Sensi.", ir: "sensi" },
  { id: "nav-entrenar", k: ["abre entrenar", "ir a entrenar", "jugar el entrenador", "minijuego"], r: "¡Vamos a entrenar!", ir: "entrenar" },
  { id: "nav-combos", k: ["abre combos", "ir a combos"], r: "Te llevo a Combos.", ir: "combos" },
];

// ---------- Motor de Roti ----------
const usados = {};
function textoDe(tema) {
  const r = tema.r;
  if (!Array.isArray(r)) return r;
  const i = ((usados[tema.id] ?? -1) + 1) % r.length;
  usados[tema.id] = i;
  return r[i];
}
// convierte un destino a acción: "tema", "@pestaña", "!estilo", "sensi-baja"
function accion(dest) {
  if (dest.startsWith("@")) return () => abrir(dest.slice(1));
  if (dest === "!cs") return () => { modo = "cs"; escribir("rot-modo", "cs"); pintarConfig(); comboDeEstilo("escudo"); };
  if (dest.startsWith("!")) return () => comboDeEstilo(dest.slice(1));
  if (dest === "sensi") return pedirGama;
  if (dest.startsWith("sensi-")) return () => pedirDedos(dest.slice(6));
  return () => mostrarTema(TEMAS.find((t) => t.id === dest));
}
const OPS_TEMAS = () => [["Combos", pedirEstilo], ["Sensi", pedirGama], ["Cabeza", accion("cabeza")], ["Gloo", accion("gloo")], ["HUD", accion("hud")], ["Lag", accion("lag")], ["Zona", accion("zona")], ["Rango", accion("rango")], ["Nombres", accion("nombres")], ["Chiste", accion("chiste")]];
function mostrarTema(tema) {
  if (tema.ir) { msgBot({ texto: tema.r }); setTimeout(() => abrir(tema.ir), 700); return; }
  if (tema.especial === "nombres") return mostrarNombres();
  let ops;
  if (tema.ops === "menu") ops = OPS_MENU();
  else if (tema.ops === "temas") ops = OPS_TEMAS();
  else if (tema.ops) ops = tema.ops.map(([et, dest]) => [et, accion(dest)]);
  msgBot({ texto: textoDe(tema), img: tema.img ? tema.img() : "", ops });
}
function mostrarNombres(base) {
  const lista = generarNombres(base);
  msgBot({
    texto: "Toca un nombre para copiarlo (máx. 12 caracteres):",
    html: `<div class="nombres">${lista.map((n) => `<button class="nom-btn">${esc(n)}</button>`).join("")}</div>`,
    ops: [["Más nombres", () => mostrarNombres(base)]],
    alMostrar: (m) => m.querySelectorAll(".nom-btn").forEach((b) => b.addEventListener("click", () => copiar(b.textContent))),
  });
}
function buscarPersonaje(t) {
  for (const [lista, tipo] of [[ACTIVOS, "activa"], [PASIVOS, "pasiva"], [MASCOTAS, "mascota"]])
    for (const x of lista) { const k = norm(x.n); if (new RegExp(`(^| )${k.replace(/[.\-]/g, "\\$&")}( |$)`).test(t)) return { x, tipo }; }
  return null;
}
function buscarArma(t) { return ARMAS_DB.find((a) => a.k.some((k) => new RegExp(`(^| )${k}( |$)`).test(t))); }
function mejorTema(t) {
  let mejor = null, puntos = 0;
  for (const tema of TEMAS) {
    let p = 0;
    for (const k of tema.k) if ((" " + t + " ").includes(" " + k + " ") || (k.length > 5 && t.includes(k))) p += k.length;
    if (p > puntos) { puntos = p; mejor = tema; }
  }
  return mejor;
}
function estiloEn(t) {
  const e = ESTILOS.find((e) => t.includes(norm(e.n)));
  if (e) return e;
  if (tiene(t, "escudo", "aguantar")) return ESTILOS[1];
  if (tiene(t, "apoyo", "support")) return ESTILOS[2];
  if (tiene(t, "curar", "medico", "healer")) return ESTILOS[3];
  if (tiene(t, "francotirador", "lejos")) return ESTILOS[4];
  return null;
}
function entender(texto) {
  const t = norm(texto); if (!t) return;
  const est = estiloEn(t), pj = buscarPersonaje(t), arma = buscarArma(t);
  // 1) combos
  if (tiene(t, "combo", "armame", "arma un", "habilidades")) {
    if (tiene(t, "cs", "duelo")) { modo = "cs"; escribir("rot-modo", "cs"); }
    else if (tiene(t, " br", "battle", "clasificatoria")) { modo = "br"; escribir("rot-modo", "br"); }
    if (pj && pj.tipo === "activa") return comboDeEstilo(est ? est.id : (ESTILOS.find((e) => pj.x.t.includes(e.id)) || ESTILOS[0]).id, pj.x.n);
    if (est) return comboDeEstilo(est.id);
    if (tiene(t, "cs", "duelo")) return comboDeEstilo("escudo");
    return pedirEstilo();
  }
  // 2) "mejor ..."
  if (tiene(t, "mejor")) {
    if (tiene(t, "mascota")) return msgBot({ texto: "Depende de tu estilo:\n• Rusher: Rockie (baja el enfriamiento) o Detective Panda (vida al matar).\n• Tanque: Mr. Waggor (te da gloo).\n• Curandero: Ottero.\n• Sniper: Dreki.", ops: [["Armar un combo", pedirEstilo]] });
    if (tiene(t, "activa", "personaje", "habilidad")) return msgBot({ texto: "Las activas más usadas: Tatsuya y Chrono para rushear, Alok y Dimitri para curar, Kenta y Orion para aguantar, Clu para encontrar enemigos. La mejor es la que encaja con tu estilo.", ops: [["Armar un combo", pedirEstilo]] });
    if (tiene(t, "pasiva")) return msgBot({ texto: "Pasivas muy usadas: Jota y Hayato para rusher, Dasha para controlar el retroceso, Kelly y D-bee para velocidad, Kapella y Thiva para curar, Moco y Laura para sniper." });
    if (tiene(t, "escopeta")) return mostrarArma(ARMAS_DB[0]);
    if (tiene(t, "subfusil", "smg")) return mostrarArma(ARMAS_DB.find((a) => a.n === "MP40"));
    if (tiene(t, "rifle")) return mostrarArma(ARMAS_DB.find((a) => a.n === "SCAR"));
    if (tiene(t, "sniper", "francotirador")) return mostrarArma(ARMAS_DB.find((a) => a.n === "AWM"));
    if (tiene(t, "pistola")) return mostrarArma(ARMAS_DB.find((a) => a.n === "Desert Eagle"));
    if (tiene(t, "arma")) return msgBot({ texto: "No hay una sola mejor arma; la clave es la combinación:\n• Rusher: M1887 + MP40\n• Equilibrado: SCAR + UMP\n• Sniper: AWM + M4A1\n• Media distancia: Woodpecker + MP40", ops: [["M1887", () => mostrarArma(ARMAS_DB[0])], ["MP40", () => mostrarArma(ARMAS_DB.find((a) => a.n === "MP40"))]] });
    if (tiene(t, "sensi")) return pedirGama();
  }
  // 3) personaje o arma mencionados
  if (pj) {
    const ops = pj.tipo === "activa" ? [[`Combo con ${pj.x.n}`, () => comboDeEstilo((ESTILOS.find((e) => pj.x.t.includes(e.id)) || ESTILOS[0]).id, pj.x.n)]] : [["Armar un combo", pedirEstilo]];
    const estilos = pj.x.t.map((id) => (ESTILOS.find((e) => e.id === id) || { n: id }).n.toLowerCase()).join(", ");
    return msgBot({ texto: `Va bien para: ${estilos}.`, html: IMG.personaje(pj.x, pj.tipo === "activa" ? "Habilidad activa" : pj.tipo === "pasiva" ? "Habilidad pasiva" : "Mascota"), ops, antes: true });
  }
  if (arma && !tiene(t, "sensi")) return mostrarArma(arma);
  // 4) nombres con base dada: "nombre con lobo"
  if (tiene(t, "nombre", "nick", "apodo")) { const m = t.match(/(?:con|de|para)\s+([a-z0-9]{3,10})$/); return mostrarNombres(m ? m[1][0].toUpperCase() + m[1].slice(1) : undefined); }
  // 5) sensi con marca o gama
  if (tiene(t, "sensi", "sensibilidad")) {
    const marca = mejorTema(t);
    if (marca && ["iphone", "samsung", "xiaomi", "motorola", "huawei", "tecno", "tablet", "dpi", "sensi-awm", "sensi-escopeta"].includes(marca.id)) return mostrarTema(marca);
    if (tiene(t, "baja", "gama baja")) return pedirDedos("baja");
    if (tiene(t, "alta", "gama alta")) return pedirDedos("alta");
    if (tiene(t, "media", "gama media")) return pedirDedos("media");
    return pedirGama();
  }
  // 6) temas
  const tema = mejorTema(t);
  if (tema) return mostrarTema(tema);
  if (est) return comboDeEstilo(est.id);
  msgBot({ texto: "No te entendí del todo. Prueba con algo como: \"combo con Tatsuya\", \"qué hace Jota\", \"sensi para Samsung\", \"cómo poner gloo rápido\", \"HUD de 3 dedos\" o \"nombre para Free Fire\".", ops: OPS_TEMAS() });
}
function mostrarArma(a) {
  msgBot({ texto: `${a.h}\nTip: ${a.tip}`, img: IMG.arma(a.t, a.n), ops: [["Practicar cabeza", () => abrir("entrenar")], ["Mejor combinación", () => entender("mejor arma")]] });
}
