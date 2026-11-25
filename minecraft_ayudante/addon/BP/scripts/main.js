// Ayudante Survival - add-on para Minecraft Bedrock
// Abre el menú usando el objeto "Guía de Construcción" o con el comando /ayudante:menu
import { world, system, ItemStack, MolangVariableMap, CommandPermissionLevel } from "@minecraft/server";
import { ActionFormData, ModalFormData } from "@minecraft/server-ui";
import { CONSTRUCCIONES, PALETA } from "./construcciones.js";

const PROP = "ayudante:datos";
const ITEM_GUIA = "ayudante:guia";
const PARTICULA = "ayudante:fantasma";
const MAX_PARTICULAS = 700;
const DIST_MAX = 48;

const porId = Object.fromEntries(CONSTRUCCIONES.map((c) => [c.id, c]));
const estado = new Map();

const DIM_NOMBRE = {
  "minecraft:overworld": "Mundo normal",
  "minecraft:nether": "Nether",
  "minecraft:the_end": "End",
};

// ---------- Datos del jugador ----------
function datos(p) {
  if (estado.has(p.id)) return estado.get(p.id);
  let d = {};
  try {
    d = JSON.parse(p.getDynamicProperty(PROP) ?? "{}");
  } catch {
    d = {};
  }
  d.hud ??= true;
  d.puntos ??= [];
  estado.set(p.id, d);
  return d;
}
function guardar(p) {
  try {
    p.setDynamicProperty(PROP, JSON.stringify(datos(p)));
  } catch (e) {
    console.warn("No se pudo guardar: " + e);
  }
}

// ---------- Utilidades ----------
const entrada = (c, ch) => (c.paleta && c.paleta[ch]) || PALETA[ch];

function coincide(e, typeId) {
  if (typeId === e.id) return true;
  if (e.acepta && e.acepta.includes(typeId)) return true;
  if (e.contiene && typeId.includes(e.contiene)) return true;
  return false;
}

function medidas(c) {
  let ancho = 0;
  for (const capa of c.capas) for (const fila of capa) ancho = Math.max(ancho, fila.length);
  return { ancho, fondo: Math.max(...c.capas.map((k) => k.length)), alto: c.capas.length };
}

// yaw de Bedrock: 0 = sur (+z), 90 = oeste (-x), 180 = norte (-z), -90 = este (+x)
function frente(yaw) {
  const a = ((yaw % 360) + 360) % 360;
  if (a >= 315 || a < 45) return [0, 1];
  if (a < 135) return [-1, 0];
  if (a < 225) return [0, -1];
  return [1, 0];
}
function nombreDireccion(yaw) {
  const a = ((yaw % 360) + 360) % 360;
  const nombres = ["Sur (+Z)", "Suroeste", "Oeste (-X)", "Noroeste", "Norte (-Z)", "Noreste", "Este (+X)", "Sureste"];
  return nombres[Math.round(a / 45) % 8];
}

function posMundo(g, x, y, z) {
  return {
    x: g.o.x + g.r[0] * x + g.f[0] * z,
    y: g.o.y + y,
    z: g.o.z + g.r[1] * x + g.f[1] * z,
  };
}

function bloque(dim, pos) {
  try {
    return dim.getBlock(pos);
  } catch {
    return undefined;
  }
}

function piso(v) {
  return { x: Math.floor(v.x), y: Math.floor(v.y), z: Math.floor(v.z) };
}

function mensaje(p, txt) {
  p.sendMessage("§6[Ayudante]§r " + txt);
}

function sonido(p, id) {
  try {
    p.playSound(id);
  } catch {}
}

// ---------- Guía fantasma ----------
function crearGuia(p, c) {
  const pb = piso(p.location);
  const f = frente(p.getRotation().y);
  const r = [-f[1], f[0]];
  const { ancho } = medidas(c);
  const mitad = Math.floor(ancho / 2);
  const o = {
    x: pb.x + f[0] * 2 - r[0] * mitad,
    y: pb.y + (c.offsetY ?? -1),
    z: pb.z + f[1] * 2 - r[1] * mitad,
  };
  const d = datos(p);
  d.guia = { id: c.id, o, f, r, dim: p.dimension.id, capa: 0, todo: false, terminada: false };
  guardar(p);
  mensaje(p, `§aGuía colocada: §f${c.nombre}§a. Ve poniendo los bloques fantasma, capa por capa.`);
  sonido(p, "random.orb");
}

// Revisa una capa: devuelve listas de faltantes y bloques equivocados
function revisarCapa(dim, g, c, y) {
  const faltan = [];
  const malos = [];
  let total = 0;
  const capa = c.capas[y];
  for (let z = 0; z < capa.length; z++) {
    const fila = capa[z];
    for (let x = 0; x < fila.length; x++) {
      const ch = fila[x];
      if (ch === "." || ch === " ") continue;
      const e = entrada(c, ch);
      if (!e) continue;
      total++;
      const pos = posMundo(g, x, y, z);
      const b = bloque(dim, pos);
      if (!b) continue; // chunk no cargado: no se cuenta
      const t = b.typeId;
      if (coincide(e, t)) continue;
      const vacio = t === "minecraft:air" || t.includes("water") || t.includes("lava") || t === "minecraft:tallgrass" || t === "minecraft:short_grass";
      // tierra/pasto donde debe ir tierra arada, o piedra natural: cuenta como "falta", no como error
      if (vacio || t === "minecraft:grass_block" || t === "minecraft:dirt" || t === "minecraft:grass") faltan.push({ pos, ch, e });
      else malos.push({ pos, ch, e, t });
    }
  }
  return { faltan, malos, total };
}

function resumenFaltantes(lista) {
  const cuenta = {};
  for (const it of lista) cuenta[it.ch] = (cuenta[it.ch] ?? 0) + 1;
  return cuenta;
}

function textoMateriales(c, cuenta, max = 4) {
  const partes = Object.entries(cuenta)
    .sort((a, b) => b[1] - a[1])
    .map(([ch, n]) => {
      const e = entrada(c, ch);
      return `${e.nombre} x${Math.ceil(n / (e.porItem ?? 1))}`;
    });
  if (partes.length > max) return partes.slice(0, max).join(", ") + "...";
  return partes.join(", ");
}

function particula(dim, pos, color, alfa) {
  try {
    const v = new MolangVariableMap();
    v.setColorRGBA("variable.color", { red: color[0], green: color[1], blue: color[2], alpha: alfa });
    dim.spawnParticle(PARTICULA, { x: pos.x + 0.5, y: pos.y + 0.5, z: pos.z + 0.5 }, v);
  } catch {}
}

function distancia2(a, b) {
  const dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
  return dx * dx + dy * dy + dz * dz;
}

// Devuelve el texto de la guía para la barra de acción y dibuja los fantasmas
function procesarGuia(p, d, tick) {
  const g = d.guia;
  const c = porId[g.id];
  if (!c) {
    delete d.guia;
    guardar(p);
    return "";
  }
  if (p.dimension.id !== g.dim) return `§7Guía "${c.nombre}" está en ${DIM_NOMBRE[g.dim] ?? g.dim}`;
  const dim = p.dimension;
  const alto = c.capas.length;

  let faltan = [];
  let malos = [];
  if (g.todo) {
    for (let y = 0; y < alto; y++) {
      const res = revisarCapa(dim, g, c, y);
      faltan = faltan.concat(res.faltan);
      malos = malos.concat(res.malos);
    }
  } else {
    // salta las capas que ya están completas
    for (;;) {
      const res = revisarCapa(dim, g, c, g.capa);
      faltan = res.faltan;
      malos = res.malos;
      if (faltan.length || malos.length || g.capa >= alto - 1) break;
      g.capa++;
      guardar(p);
      mensaje(p, `§aCapa completa. Sigue con la capa ${g.capa + 1}/${alto}.`);
      sonido(p, "random.levelup");
    }
  }

  // dibujar
  let n = 0;
  const dMax = DIST_MAX * DIST_MAX;
  for (const it of malos) {
    if (n++ > MAX_PARTICULAS) break;
    if (distancia2(it.pos, p.location) > dMax) continue;
    particula(dim, it.pos, tick % 20 < 10 ? [1, 0.1, 0.1] : [1, 0.5, 0.5], 0.9);
  }
  for (const it of faltan) {
    if (n++ > MAX_PARTICULAS) break;
    if (distancia2(it.pos, p.location) > dMax) continue;
    particula(dim, it.pos, it.e.color ?? [1, 1, 1], 0.75);
  }

  // construcción terminada
  if (!g.todo && faltan.length === 0 && malos.length === 0 && g.capa >= alto - 1 && !g.terminada) {
    g.terminada = true;
    guardar(p);
    mensaje(p, `§a§l¡${c.nombre} terminada!§r Puedes quitar la guía desde el menú.`);
    sonido(p, "random.levelup");
  }

  const titulo = g.todo ? "Todas las capas" : `Capa ${g.capa + 1}/${alto}`;
  if (g.terminada && !g.todo) return `§a${c.nombre}: ¡terminada!`;
  let txt = `§e${c.nombre} §7| §f${titulo}`;
  if (malos.length) txt += ` §7| §c${malos.length} bloque(s) incorrecto(s)`;
  if (faltan.length) txt += `\n§7Faltan: §f${textoMateriales(c, resumenFaltantes(faltan))}`;
  return txt;
}

// ---------- HUD de coordenadas y destino ----------
function textoCoordenadas(p) {
  const l = piso(p.location);
  const dim = p.dimension.id;
  let txt = `§7XYZ §f${l.x} ${l.y} ${l.z}`;
  if (dim === "minecraft:overworld") txt += ` §7| Nether §c${Math.floor(l.x / 8)} ${Math.floor(l.z / 8)}`;
  else if (dim === "minecraft:nether") txt += ` §7| Mundo §a${l.x * 8} ${l.z * 8}`;
  txt += ` §7| §b${nombreDireccion(p.getRotation().y)}`;
  return txt;
}

function textoObjetivo(p, d) {
  const o = d.objetivo;
  if (!o) return "";
  if (o.dim !== p.dimension.id) return `§d> ${o.nombre}: está en ${DIM_NOMBRE[o.dim] ?? o.dim}`;
  const dx = o.x + 0.5 - p.location.x;
  const dz = o.z + 0.5 - p.location.z;
  const dist = Math.round(Math.sqrt(dx * dx + dz * dz));
  if (dist <= 2) return `§a> ¡Llegaste a ${o.nombre}! (Y ${o.y})`;
  const yawObj = (Math.atan2(-dx, dz) * 180) / Math.PI;
  let dif = yawObj - p.getRotation().y;
  dif = ((((dif + 180) % 360) + 360) % 360) - 180;
  let giro;
  if (Math.abs(dif) < 20) giro = "de frente";
  else if (Math.abs(dif) > 150) giro = "detrás de ti";
  else if (dif > 0) giro = `gira a la derecha ${Math.round(dif)}°`;
  else giro = `gira a la izquierda ${Math.round(-dif)}°`;
  const dy = o.y - Math.floor(p.location.y);
  const alt = dy > 3 ? ` §7(sube ${dy})` : dy < -3 ? ` §7(baja ${-dy})` : "";
  return `§d> ${o.nombre}: §f${dist} m§d, ${giro}${alt}`;
}

let tick = 0;
system.runInterval(() => {
  tick += 10;
  for (const p of world.getAllPlayers()) {
    const d = datos(p);
    const lineas = [];
    if (d.guia) lineas.push(procesarGuia(p, d, tick));
    const obj = textoObjetivo(p, d);
    if (obj) lineas.push(obj);
    if (d.hud) lineas.push(textoCoordenadas(p));
    const txt = lineas.filter(Boolean).join("\n");
    if (txt) {
      try {
        p.onScreenDisplay.setActionBar(txt);
      } catch {}
    }
  }
}, 10);

// ---------- Menús ----------
async function mostrar(p, form) {
  // reintenta si el jugador tiene el chat u otra pantalla abierta
  for (let i = 0; i < 20; i++) {
    const r = await form.show(p);
    if (r.canceled && r.cancelationReason === "UserBusy") {
      await new Promise((res) => system.runTimeout(() => res(undefined), 10));
      continue;
    }
    return r;
  }
  return { canceled: true };
}

async function menuPrincipal(p) {
  const d = datos(p);
  const opciones = [];
  const f = new ActionFormData().title("§lAyudante Survival").body(textoCoordenadas(p) + "\n§r¿Qué quieres hacer?");
  const add = (texto, fn) => {
    f.button(texto);
    opciones.push(fn);
  };
  add("Construcciones\n§8Elegir y colocar maqueta", menuConstrucciones);
  if (d.guia) add("Guía actual\n§8Capas, materiales, mover", menuGuia);
  add("Portales al Nether\n§8Coordenadas para enlazar", menuPortales);
  add("Puntos guardados\n§8Casa, minas, aldeas...", menuPuntos);
  if (d.objetivo) add("Dejar de seguir\n§8" + d.objetivo.nombre, (pl) => {
    delete datos(pl).objetivo;
    guardar(pl);
  });
  add(d.hud ? "Ocultar coordenadas" : "Mostrar coordenadas", (pl) => {
    datos(pl).hud = !datos(pl).hud;
    guardar(pl);
  });
  add("Ayuda", menuAyuda);
  const r = await mostrar(p, f);
  if (r.canceled) return;
  await opciones[r.selection](p);
}

async function menuConstrucciones(p) {
  const f = new ActionFormData().title("Construcciones").body("Elige una construcción. Se colocará 2 bloques frente a ti, en la dirección que miras.");
  for (const c of CONSTRUCCIONES) {
    const m = medidas(c);
    f.button(`${c.nombre}\n§8${c.categoria} · ${m.ancho}x${m.fondo}, ${m.alto} capas`);
  }
  f.button("« Volver");
  const r = await mostrar(p, f);
  if (r.canceled) return;
  if (r.selection === CONSTRUCCIONES.length) return menuPrincipal(p);
  await detalleConstruccion(p, CONSTRUCCIONES[r.selection]);
}

function materialesTotales(c) {
  const cuenta = {};
  for (const capa of c.capas) for (const fila of capa) for (const ch of fila) {
    if (ch === "." || ch === " " || !entrada(c, ch)) continue;
    cuenta[ch] = (cuenta[ch] ?? 0) + 1;
  }
  return cuenta;
}

function listaMateriales(c, cuenta) {
  return Object.entries(cuenta)
    .sort((a, b) => b[1] - a[1])
    .map(([ch, n]) => {
      const e = entrada(c, ch);
      const items = Math.ceil(n / (e.porItem ?? 1));
      const pilas = items >= 64 ? ` §8(${Math.floor(items / 64)} pila(s) + ${items % 64})` : "";
      return `§f- ${e.nombre}: §e${items}${pilas}`;
    })
    .join("\n");
}

async function detalleConstruccion(p, c) {
  const m = medidas(c);
  const notas = (c.notas ?? []).map((n) => "§7* " + n).join("\n");
  const f = new ActionFormData()
    .title(c.nombre)
    .body(`${c.descripcion}\n\n§lTamaño:§r ${m.ancho} x ${m.fondo}, ${m.alto} de alto\n\n§lMateriales:§r\n${listaMateriales(c, materialesTotales(c))}\n\n${notas}`)
    .button("§2Colocar guía aquí\n§8Frente a ti")
    .button("« Volver");
  const r = await mostrar(p, f);
  if (r.canceled) return;
  if (r.selection === 0) crearGuia(p, c);
  else await menuConstrucciones(p);
}

async function menuGuia(p) {
  const d = datos(p);
  const g = d.guia;
  if (!g) return;
  const c = porId[g.id];
  const alto = c.capas.length;
  const f = new ActionFormData()
    .title(c.nombre)
    .body(`Viendo: ${g.todo ? "todas las capas" : `capa ${g.capa + 1} de ${alto}`}\n§7Los bloques fantasma tienen el color del material. Los rojos que parpadean están equivocados.`)
    .button("Capa siguiente »")
    .button("« Capa anterior")
    .button(g.todo ? "Ver solo la capa actual" : "Ver todas las capas")
    .button("Lo que me falta\n§8Lista de materiales")
    .button("Mover guía aquí\n§8Usa hacia dónde miras")
    .button("§4Quitar guía")
    .button("« Volver");
  const r = await mostrar(p, f);
  if (r.canceled) return;
  switch (r.selection) {
    case 0:
      g.capa = Math.min(alto - 1, g.capa + 1);
      g.todo = false;
      break;
    case 1:
      g.capa = Math.max(0, g.capa - 1);
      g.todo = false;
      g.terminada = false;
      break;
    case 2:
      g.todo = !g.todo;
      break;
    case 3:
      return menuFaltantes(p);
    case 4:
      crearGuia(p, c);
      return;
    case 5:
      delete d.guia;
      mensaje(p, "Guía quitada.");
      break;
    case 6:
      return menuPrincipal(p);
  }
  guardar(p);
}

async function menuFaltantes(p) {
  const g = datos(p).guia;
  const c = porId[g.id];
  if (p.dimension.id !== g.dim) return mensaje(p, "La guía está en otra dimensión.");
  let faltan = [];
  let malos = 0;
  let total = 0;
  for (let y = 0; y < c.capas.length; y++) {
    const res = revisarCapa(p.dimension, g, c, y);
    faltan = faltan.concat(res.faltan);
    malos += res.malos.length;
    total += res.total;
  }
  const hecho = total ? Math.round(((total - faltan.length - malos) / total) * 100) : 0;
  const cuerpo = faltan.length
    ? listaMateriales(c, resumenFaltantes(faltan))
    : "§a¡No falta nada!";
  const f = new ActionFormData()
    .title("Lo que falta")
    .body(`§lProgreso: ${hecho}%§r\n${malos ? `§c${malos} bloque(s) incorrecto(s)\n` : ""}\n${cuerpo}`)
    .button("« Volver");
  const r = await mostrar(p, f);
  if (!r.canceled) await menuGuia(p);
}

// ---------- Portales ----------
function destinoPortal(dim, x, y, z) {
  if (dim === "minecraft:overworld") return { dim: "minecraft:nether", x: Math.floor(x / 8), y: Math.min(Math.max(y, 32), 120), z: Math.floor(z / 8) };
  if (dim === "minecraft:nether") return { dim: "minecraft:overworld", x: x * 8, y, z: z * 8 };
  return null;
}

async function menuPortales(p) {
  const d = datos(p);
  const l = piso(p.location);
  const dest = destinoPortal(p.dimension.id, l.x, l.y, l.z);
  let cuerpo = `Estás en el §l${DIM_NOMBRE[p.dimension.id]}§r en §f${l.x} ${l.y} ${l.z}§r.\n\n`;
  if (dest) {
    cuerpo += `Para que un portal construido AQUÍ quede enlazado, construye el otro en el §l${DIM_NOMBRE[dest.dim]}§r en:\n§e  X ${dest.x}   Y ~${dest.y}   Z ${dest.z}§r\n\n`;
    cuerpo += "§7Regla: Nether = Mundo ÷ 8. El juego busca un portal en un radio de 128 bloques en el Mundo y 16 en el Nether. Si construyes el segundo portal en las coordenadas exactas, siempre se enlazan bien.\n";
  } else cuerpo += "§cEn el End no hay portales al Nether.\n";
  const portales = d.puntos.filter((pt) => pt.portal);
  if (portales.length) {
    cuerpo += "\n§lTus portales:§r\n";
    for (const pt of portales) {
      const par = destinoPortal(pt.dim, pt.x, pt.y, pt.z);
      cuerpo += `§f- ${pt.nombre} (${DIM_NOMBRE[pt.dim]} ${pt.x} ${pt.y} ${pt.z})` + (par ? ` §7-> pareja en ${par.x} ${par.z}\n` : "\n");
    }
  }
  const opciones = [];
  const f = new ActionFormData().title("Portales al Nether").body(cuerpo);
  const add = (t, fn) => {
    f.button(t);
    opciones.push(fn);
  };
  add("Guardar este portal\n§8Como punto guardado", async (pl) => {
    const n = d.puntos.filter((x) => x.portal).length + 1;
    d.puntos.push({ nombre: `Portal ${n} (${DIM_NOMBRE[pl.dimension.id]})`, dim: pl.dimension.id, x: l.x, y: l.y, z: l.z, portal: true });
    guardar(pl);
    mensaje(pl, "Portal guardado.");
  });
  if (dest)
    add("Llévame al punto de enlace\n§8Cuando cruces, te guío", async (pl) => {
      d.objetivo = { nombre: "Portal enlazado", ...dest };
      guardar(pl);
      mensaje(pl, `Cuando estés en el ${DIM_NOMBRE[dest.dim]}, sigue las indicaciones de la barra para llegar a ${dest.x} ${dest.z}.`);
    });
  add("Colocar guía de portal\n§8Marco de obsidiana", async (pl) => crearGuia(pl, porId.portal_nether));
  add("Calculadora manual", calculadoraPortal);
  add("« Volver", menuPrincipal);
  const r = await mostrar(p, f);
  if (r.canceled) return;
  await opciones[r.selection](p);
}

async function calculadoraPortal(p) {
  const l = piso(p.location);
  const f = new ModalFormData()
    .title("Calculadora de portales")
    .dropdown("Las coordenadas que escribo son del:", ["Mundo normal", "Nether"], { defaultValueIndex: p.dimension.id === "minecraft:nether" ? 1 : 0 })
    .textField("X", "ej. 800", { defaultValue: String(l.x) })
    .textField("Z", "ej. -240", { defaultValue: String(l.z) });
  const r = await mostrar(p, f);
  if (r.canceled) return;
  const [origen, xs, zs] = r.formValues;
  const x = parseInt(String(xs), 10);
  const z = parseInt(String(zs), 10);
  if (Number.isNaN(x) || Number.isNaN(z)) return mensaje(p, "§cEscribe números válidos.");
  if (origen === 0) mensaje(p, `Mundo ${x} ${z}  ->  §cNether ${Math.floor(x / 8)} ${Math.floor(z / 8)}`);
  else mensaje(p, `Nether ${x} ${z}  ->  §aMundo ${x * 8} ${z * 8}`);
}

// ---------- Puntos guardados ----------
async function menuPuntos(p) {
  const d = datos(p);
  const f = new ActionFormData().title("Puntos guardados").body(d.puntos.length ? "Elige un punto para seguirlo o borrarlo." : "Aún no tienes puntos. Guarda tu casa, una mina o una aldea.");
  f.button("§2+ Guardar donde estoy");
  for (const pt of d.puntos) f.button(`${pt.nombre}\n§8${DIM_NOMBRE[pt.dim] ?? ""} ${pt.x} ${pt.y} ${pt.z}`);
  f.button("« Volver");
  const r = await mostrar(p, f);
  if (r.canceled) return;
  if (r.selection === 0) return nuevoPunto(p);
  if (r.selection === d.puntos.length + 1) return menuPrincipal(p);
  await detallePunto(p, r.selection - 1);
}

async function nuevoPunto(p) {
  const l = piso(p.location);
  const f = new ModalFormData().title("Guardar punto").textField(`Nombre (${l.x} ${l.y} ${l.z})`, "Casa, mina, aldea...", { defaultValue: "Casa" });
  const r = await mostrar(p, f);
  if (r.canceled) return;
  const nombre = String(r.formValues[0] || "Punto").slice(0, 32);
  datos(p).puntos.push({ nombre, dim: p.dimension.id, x: l.x, y: l.y, z: l.z });
  guardar(p);
  mensaje(p, `Punto "${nombre}" guardado en ${l.x} ${l.y} ${l.z}.`);
}

async function detallePunto(p, i) {
  const d = datos(p);
  const pt = d.puntos[i];
  const f = new ActionFormData()
    .title(pt.nombre)
    .body(`${DIM_NOMBRE[pt.dim] ?? pt.dim}: §e${pt.x} ${pt.y} ${pt.z}`)
    .button("Seguir este punto\n§8Indicaciones en pantalla")
    .button("§4Borrar")
    .button("« Volver");
  const r = await mostrar(p, f);
  if (r.canceled) return;
  if (r.selection === 0) {
    d.objetivo = { ...pt };
    mensaje(p, `Siguiendo "${pt.nombre}".`);
  } else if (r.selection === 1) {
    d.puntos.splice(i, 1);
    mensaje(p, "Punto borrado.");
  } else return menuPuntos(p);
  guardar(p);
}

async function menuAyuda(p) {
  const f = new ActionFormData()
    .title("Ayuda")
    .body(
      [
        "§l1. Construcciones:§r elige una, mira hacia donde la quieres y pulsa Colocar. Aparecen bloques fantasma de colores: pon el bloque correcto en cada uno.",
        "§l2. Capas:§r la guía muestra una capa a la vez y pasa sola a la siguiente cuando la terminas.",
        "§l3. Rojo parpadeando:§r ahí hay un bloque equivocado. Rómpelo y pon el correcto.",
        "§l4. Portales:§r el menú te dice dónde construir el otro portal para que se enlacen.",
        "§l5. Puntos:§r guarda lugares y sigue la flecha en la barra de abajo.",
        "",
        "§7Si pierdes la Guía, craftéala con 1 palo + 1 papel, o escribe /ayudante:guia. El menú también se abre con /ayudante:menu",
      ].join("\n")
    )
    .button("« Volver");
  const r = await mostrar(p, f);
  if (!r.canceled) await menuPrincipal(p);
}

// ---------- Comandos (funcionan sin activar trucos) ----------
system.beforeEvents.startup.subscribe((ev) => {
  const registrar = (name, description, fn) => {
    try {
      ev.customCommandRegistry.registerCommand({ name, description, permissionLevel: CommandPermissionLevel.Any }, (origin) => {
        const p = origin.sourceEntity;
        if (!p || p.typeId !== "minecraft:player") return;
        system.run(() => fn(p));
      });
    } catch (e) {
      console.warn("No se pudo registrar " + name + ": " + e);
    }
  };
  registrar("ayudante:menu", "Abre el menú del Ayudante Survival", (p) => menuPrincipal(p));
  registrar("ayudante:guia", "Te da la Guía de Construcción", (p) => darGuia(p));
});

// ---------- Eventos ----------
const ultimoUso = new Map();
function abrirDesdeObjeto(p, item) {
  if (!item || item.typeId !== ITEM_GUIA) return;
  const ahora = system.currentTick;
  if (ahora - (ultimoUso.get(p.id) ?? -100) < 10) return;
  ultimoUso.set(p.id, ahora);
  system.run(() => menuPrincipal(p));
}

world.afterEvents.itemUse.subscribe((ev) => abrirDesdeObjeto(ev.source, ev.itemStack));

system.afterEvents.scriptEventReceive.subscribe((ev) => {
  const p = ev.sourceEntity;
  if (!p || p.typeId !== "minecraft:player") return;
  if (ev.id === "ayudante:menu") system.run(() => menuPrincipal(p));
  else if (ev.id === "ayudante:guia") darGuia(p);
});

function darGuia(p) {
  try {
    p.getComponent("minecraft:inventory").container.addItem(new ItemStack(ITEM_GUIA, 1));
  } catch {}
}

world.afterEvents.playerSpawn.subscribe((ev) => {
  const p = ev.player;
  if (!ev.initialSpawn) return;
  const d = datos(p);
  if (!d.recibioGuia) {
    darGuia(p);
    d.recibioGuia = true;
    guardar(p);
    mensaje(p, "§aTe di la §fGuía de Construcción§a. Úsala para abrir el menú.");
  }
});

world.afterEvents.playerLeave.subscribe((ev) => estado.delete(ev.playerId));
