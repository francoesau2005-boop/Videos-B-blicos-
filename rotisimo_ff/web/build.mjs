// Junta app.html + datos + fuente Outfit + íconos Lucide en un solo index.html (funciona sin internet)
import { readFileSync, writeFileSync, readdirSync } from "node:fs";
const dir = new URL(".", import.meta.url).pathname;
const leer = (f) => readFileSync(dir + f, "utf8");
const fuentes = [400, 500, 600, 700].map((w) => {
  const b64 = readFileSync(`${dir}vendor/outfit-latin-${w}-normal.woff2`).toString("base64");
  return `@font-face{font-family:"Outfit";font-weight:${w};font-style:normal;font-display:swap;src:url(data:font/woff2;base64,${b64}) format("woff2");}`;
}).join("\n");
const iconos = {};
for (const f of readdirSync(dir + "vendor/iconos")) {
  const svg = readFileSync(`${dir}vendor/iconos/${f}`, "utf8");
  iconos[f.replace(".svg", "")] = svg.slice(svg.indexOf(">", svg.indexOf("<svg")) + 1, svg.lastIndexOf("</svg>")).replace(/\s*\n\s*/g, "");
}
let html = leer("app.html");
const poner = (marca, txt) => { if (!html.includes(marca)) throw new Error("falta " + marca); html = html.replace(marca, () => txt); };
poner("/*FUENTES*/", fuentes);
poner("/*ICONOS*/", "// Íconos: Lucide (licencia ISC)\nconst ICONOS = " + JSON.stringify(iconos) + ";");
poner("/*DATOS*/", leer("datos.js"));
poner("/*ROTI*/", leer("roti.js"));
poner("/*ADMIN*/", leer("admin.js"));
poner("/*PERSONAJES*/", leer("personajes.js"));
writeFileSync(dir + "index.html", html);
console.log("index.html listo:", Math.round(html.length / 1024), "KB");
