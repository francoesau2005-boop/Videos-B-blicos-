// Compila el add-on (.mcaddon) y el panel web a partir de construcciones.js
// Uso: node build.mjs
import { readFileSync, writeFileSync, copyFileSync, mkdirSync, rmSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { PALETA, CONSTRUCCIONES } from "./construcciones.js";

const raiz = new URL(".", import.meta.url).pathname;
const dist = raiz + "dist/";
mkdirSync(dist, { recursive: true });

// 1. Validar planos
for (const c of CONSTRUCCIONES) {
  for (const [i, capa] of c.capas.entries())
    for (const fila of capa)
      for (const ch of fila)
        if (ch !== "." && ch !== " " && !(c.paleta?.[ch] ?? PALETA[ch]))
          throw new Error(`${c.id}: letra desconocida "${ch}" en la capa ${i}`);
}

// 2. Add-on
copyFileSync(raiz + "construcciones.js", raiz + "addon/BP/scripts/construcciones.js");
for (const f of ["AyudanteSurvival_BP.mcpack", "AyudanteSurvival_RP.mcpack", "AyudanteSurvival.mcaddon"]) rmSync(dist + f, { force: true });
execFileSync("zip", ["-qr", dist + "AyudanteSurvival_BP.mcpack", "."], { cwd: raiz + "addon/BP" });
execFileSync("zip", ["-qr", dist + "AyudanteSurvival_RP.mcpack", "."], { cwd: raiz + "addon/RP" });
execFileSync("zip", ["-qj", dist + "AyudanteSurvival.mcaddon", dist + "AyudanteSurvival_BP.mcpack", dist + "AyudanteSurvival_RP.mcpack"]);

// 3. Panel web
const plantilla = readFileSync(raiz + "panel/plantilla.html", "utf8");
const datos = `const PALETA = ${JSON.stringify(PALETA)};\nconst CONSTRUCCIONES = ${JSON.stringify(CONSTRUCCIONES)};`;
writeFileSync(raiz + "panel/index.html", plantilla.replace("/*DATOS*/", () => datos));

console.log("Listo: dist/AyudanteSurvival.mcaddon y panel/index.html");
