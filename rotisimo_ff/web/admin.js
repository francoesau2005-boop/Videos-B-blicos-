// ================= MODO ADMIN Y PAQUETE DE IMÁGENES =================
// - Las imágenes publicadas (PAQUETE) se descargan de un archivo JSON en GitHub y se guardan en el celular.
// - Solo el admin (con PIN en su celular y su clave de GitHub) puede cambiarlas y publicarlas.
const PAQUETE_URL = "https://raw.githubusercontent.com/francoesau2005-boop/Videos-B-blicos-/HEAD/rotisimo_ff/imagenes/imagenes.json";
const GH_DEF = { owner: "francoesau2005-boop", repo: "Videos-B-blicos-", ruta: "rotisimo_ff/imagenes/imagenes.json", rama: "" };

// ---------- almacenamiento grande (IndexedDB) ----------
const BD = {
  _db: null,
  abrir() {
    if (this._db) return Promise.resolve(this._db);
    return new Promise((ok, mal) => {
      try {
        const r = indexedDB.open("rotisimo", 1);
        r.onupgradeneeded = () => r.result.createObjectStore("kv");
        r.onsuccess = () => ok((this._db = r.result));
        r.onerror = () => mal(r.error);
      } catch (e) { mal(e); }
    });
  },
  async get(k) { try { const db = await this.abrir(); return await new Promise((ok) => { const q = db.transaction("kv").objectStore("kv").get(k); q.onsuccess = () => ok(q.result); q.onerror = () => ok(undefined); }); } catch { return undefined; } },
  async set(k, v) { try { const db = await this.abrir(); return await new Promise((ok) => { const t = db.transaction("kv", "readwrite"); t.objectStore("kv").put(v, k); t.oncomplete = () => ok(true); t.onerror = () => ok(false); }); } catch { return false; } },
};

let PAQUETE = { version: 0, imagenes: {} };   // lo publicado (todos lo ven)
let BORRADOR = {};                            // cambios del admin sin publicar
let ADMIN = false;
try { ADMIN = sessionStorage.getItem("rot-admin") === "1"; } catch {}

// orden: cambio del admin > lo publicado > imágenes incluidas en la app > dibujo
function imagenDe(nombre) { return (ADMIN && BORRADOR[nombre]) || PAQUETE.imagenes[nombre] || IMAGENES_BASE[nombre] || null; }

async function cargarImagenes() {
  PAQUETE = (await BD.get("paquete")) || PAQUETE;
  BORRADOR = (await BD.get("borrador")) || {};
  // migrar fotos guardadas por versiones anteriores
  const viejas = leer("rot-fotos", null);
  if (viejas) { Object.assign(BORRADOR, viejas); await BD.set("borrador", BORRADOR); try { localStorage.removeItem("rot-fotos"); } catch {} }
  repintarImagenes();
  descargarPaquete();
}
async function descargarPaquete(avisar) {
  try {
    const ctrl = new AbortController(); setTimeout(() => ctrl.abort(), 15000);
    const r = await fetch(PAQUETE_URL + "?t=" + Date.now(), { signal: ctrl.signal, cache: "no-store" });
    if (!r.ok) { if (avisar) toast(r.status === 404 ? "Aún no hay imágenes publicadas" : "No se pudo descargar"); return; }
    const p = await r.json();
    if (p && p.imagenes && (p.version || 0) !== PAQUETE.version) {
      PAQUETE = { version: p.version || 0, adminPin: p.adminPin || null, imagenes: p.imagenes };
      await BD.set("paquete", PAQUETE);
      if (PAQUETE.adminPin && leer("rot-admin-pin", null) !== PAQUETE.adminPin) {
        try { localStorage.removeItem("rot-admin-pin"); sessionStorage.removeItem("rot-admin"); } catch {}
        if (ADMIN) { ADMIN = false; marcarAdmin(); }
      }
      repintarImagenes();
      if (avisar) toast("Imágenes actualizadas");
    } else if (avisar) toast("Ya tienes las imágenes más nuevas");
  } catch { if (avisar) toast("Sin conexión: se usan las imágenes guardadas"); }
}
function repintarImagenes() {
  try { pintarGaleria(); } catch {}
  try { if (combo) pintarResultado(); } catch {}
  try { pintarFavs(); } catch {}
  try { if (!$("admin").hidden) pintarAdmin(); } catch {}
}
async function ponerImagen(nombre, url) { BORRADOR[nombre] = url; await BD.set("borrador", BORRADOR); repintarImagenes(); }
async function quitarImagen(nombre) {
  // si está publicada, se marca para quitar ("" = sin imagen)
  if (PAQUETE.imagenes[nombre]) BORRADOR[nombre] = ""; else delete BORRADOR[nombre];
  await BD.set("borrador", BORRADOR); repintarImagenes();
}
const pendientes = () => Object.keys(BORRADOR).filter((n) => BORRADOR[n] !== PAQUETE.imagenes[n]).length;
function paqueteFinal() {
  const imgs = { ...PAQUETE.imagenes };
  for (const [n, v] of Object.entries(BORRADOR)) { if (v) imgs[n] = v; else delete imgs[n]; }
  // el PIN (cifrado) viaja con el paquete: en otros celulares solo funcionará el PIN del admin
  return { version: Date.now(), app: "rotisimo", adminPin: leer("rot-admin-pin", null) || PAQUETE.adminPin || null, imagenes: imgs };
}

// ---------- PIN ----------
async function hashPin(pin) {
  try {
    const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode("rotisimo:" + pin));
    return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
  } catch { let h = 0; for (const c of "rotisimo:" + pin) h = (h * 131 + c.charCodeAt(0)) >>> 0; return "s" + h; }
}
let toquesVersion = 0, tVersion = 0;
function tocarVersion() {
  const ahora = Date.now();
  toquesVersion = ahora - tVersion < 900 ? toquesVersion + 1 : 1; tVersion = ahora;
  if (ADMIN) { abrirAdmin(); return; }
  if (toquesVersion >= 5) { toquesVersion = 0; pedirPin(); }
}
function pedirPin() {
  const existe = !!(PAQUETE.adminPin || leer("rot-admin-pin", null));
  $("pin-titulo").textContent = existe ? "Modo admin" : "Crea tu PIN de admin";
  $("pin-texto").textContent = existe ? "Escribe tu PIN para entrar." : "Elige un PIN de 4 a 8 números. Solo tú lo sabrás; guárdalo bien.";
  $("pin-in").value = ""; $("pin-error").textContent = "";
  $("pin-modal").hidden = $("hoja-fondo").hidden = false;
  setTimeout(() => $("pin-in").focus(), 50);
}
async function enviarPin(e) {
  e.preventDefault();
  const pin = $("pin-in").value.trim();
  if (!/^\d{4,8}$/.test(pin)) { $("pin-error").textContent = "Usa de 4 a 8 números."; return; }
  // si ya hay un paquete publicado, manda el PIN del admin que viene en él
  const guardado = PAQUETE.adminPin || leer("rot-admin-pin", null) || null, h = await hashPin(pin);
  if (!guardado) escribir("rot-admin-pin", h);
  else if (guardado !== h) {
    const fallos = leer("rot-admin-fallos", 0) + 1; escribir("rot-admin-fallos", fallos);
    $("pin-error").textContent = fallos >= 5 ? "Demasiados intentos. Espera un momento." : "PIN incorrecto.";
    if (fallos >= 5) setTimeout(() => escribir("rot-admin-fallos", 0), 60000);
    return;
  }
  escribir("rot-admin-fallos", 0); escribir("rot-admin-pin", h);
  ADMIN = true; try { sessionStorage.setItem("rot-admin", "1"); } catch {}
  cerrarPin(); marcarAdmin(); abrirAdmin(); repintarImagenes();
  toast(guardado ? "Bienvenido, admin" : "PIN creado. Ya eres admin");
}
function cerrarPin() { $("pin-modal").hidden = true; if ($("hoja").hidden) $("hoja-fondo").hidden = true; }
function salirAdmin() { ADMIN = false; try { sessionStorage.removeItem("rot-admin"); } catch {} marcarAdmin(); abrir("roti"); repintarImagenes(); toast("Saliste del modo admin"); }
function marcarAdmin() { const v = $("version"); v.textContent = ADMIN ? "ADMIN" : "v1.8"; v.classList.toggle("es-admin", ADMIN); }

// ---------- panel de admin ----------
function abrirAdmin() {
  if (!ADMIN) return;
  tabs.forEach((b) => b.setAttribute("aria-selected", false));
  document.querySelectorAll("section.wrap").forEach((s) => (s.hidden = s.id !== "admin"));
  scrollTo(0, 0); pintarAdmin();
}
function pintarAdmin() {
  const total = Object.keys(PAQUETE.imagenes).length, pend = pendientes();
  const fecha = PAQUETE.version ? new Date(PAQUETE.version).toLocaleString() : "nunca";
  $("adm-estado").innerHTML = `<div class="tabla"><div><span>Publicadas</span><b>${total} imágenes</b></div><div><span>Última publicación</span><b>${esc(fecha)}</b></div><div><span>Cambios sin publicar</span><b style="color:${pend ? "var(--gold)" : "inherit"}">${pend}</b></div></div>`;
  const gh = leer("rot-gh", GH_DEF);
  $("gh-owner").value = gh.owner; $("gh-repo").value = gh.repo; $("gh-ruta").value = gh.ruta; $("gh-rama").value = gh.rama || "";
  $("gh-token").placeholder = leer("rot-gh-token", "") ? "Clave guardada (escribe otra para cambiarla)" : "github_pat_…";
  const el = $("adm-lista"); el.innerHTML = "";
  for (const [lista, tipo] of [[ACTIVOS, "activa"], [PASIVOS, "pasiva"], [MASCOTAS, "mascota"]]) {
    el.insertAdjacentHTML("beforeend", `<div class="sub-t">${tipo === "mascota" ? "MASCOTAS" : "HABILIDAD " + tipo.toUpperCase()}</div>`);
    for (const x of lista) {
      const cambiado = x.n in BORRADOR && BORRADOR[x.n] !== PAQUETE.imagenes[x.n];
      const b = document.createElement("button"); b.className = "gal";
      b.innerHTML = `<div class="ret">${retrato(x.n)}</div><small style="color:${cambiado ? "var(--gold)" : imagenDe(x.n) ? "var(--green)" : "var(--muted)"}">${cambiado ? "SIN PUBLICAR" : imagenDe(x.n) ? "CON IMAGEN" : "DIBUJO"}</small><b>${esc(x.n)}</b>`;
      b.addEventListener("click", () => abrirHoja(x, tipo));
      el.append(b);
    }
  }
}
function guardarGh() {
  const gh = { owner: $("gh-owner").value.trim(), repo: $("gh-repo").value.trim(), ruta: $("gh-ruta").value.trim().replace(/^\/+/, ""), rama: $("gh-rama").value.trim() };
  escribir("rot-gh", gh);
  const t = $("gh-token").value.trim(); if (t) { escribir("rot-gh-token", t); $("gh-token").value = ""; }
  return gh;
}
async function publicar() {
  const gh = guardarGh(), token = leer("rot-gh-token", "");
  if (!token) { toast("Primero pega tu clave de GitHub"); $("gh-token").focus(); return; }
  const paq = paqueteFinal(), json = JSON.stringify(paq);
  const b64 = btoa(unescape(encodeURIComponent(json)));
  const api = `https://api.github.com/repos/${encodeURIComponent(gh.owner)}/${encodeURIComponent(gh.repo)}/contents/${gh.ruta.split("/").map(encodeURIComponent).join("/")}`;
  const cab = { Authorization: "Bearer " + token, Accept: "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28" };
  const btn = $("adm-publicar"); btn.disabled = true; btn.lastChild.textContent = "Publicando…";
  try {
    let sha;
    const q = await fetch(api + (gh.rama ? "?ref=" + encodeURIComponent(gh.rama) : ""), { headers: cab, cache: "no-store" });
    if (q.status === 401 || q.status === 403) throw new Error("La clave de GitHub no tiene permiso (revisa que tenga acceso de escritura a Contents).");
    if (q.ok) sha = (await q.json()).sha;
    const cuerpo = { message: `Rotísimo: imágenes de personajes (${Object.keys(paq.imagenes).length})`, content: b64 };
    if (sha) cuerpo.sha = sha; if (gh.rama) cuerpo.branch = gh.rama;
    const r = await fetch(api, { method: "PUT", headers: { ...cab, "Content-Type": "application/json" }, body: JSON.stringify(cuerpo) });
    if (!r.ok) { const e = await r.json().catch(() => ({})); throw new Error(e.message || "GitHub respondió " + r.status); }
    PAQUETE = { version: paq.version, adminPin: paq.adminPin, imagenes: paq.imagenes }; BORRADOR = {};
    await BD.set("paquete", PAQUETE); await BD.set("borrador", BORRADOR);
    toast("¡Publicado! Todos lo verán en unos minutos"); pintarAdmin(); repintarImagenes();
  } catch (e) { toast("No se publicó: " + e.message); }
  finally { btn.disabled = false; btn.lastChild.textContent = "Publicar para todos"; }
}
function exportar() {
  const json = JSON.stringify(paqueteFinal());
  if (APP && Android.guardarArchivo) { Android.guardarArchivo("imagenes.json", json); return; }
  const a = document.createElement("a"); a.href = URL.createObjectURL(new Blob([json], { type: "application/json" })); a.download = "imagenes.json"; a.click();
}
function importar(archivo) {
  const r = new FileReader();
  r.onload = async () => {
    try {
      const p = JSON.parse(r.result);
      if (!p.imagenes) throw 0;
      Object.assign(BORRADOR, p.imagenes); await BD.set("borrador", BORRADOR);
      toast(`Importadas ${Object.keys(p.imagenes).length} imágenes (sin publicar)`); pintarAdmin(); repintarImagenes();
    } catch { toast("Ese archivo no es un paquete de imágenes"); }
  };
  r.readAsText(archivo);
}
