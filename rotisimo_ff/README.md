# Rotísimo

App Android con ayudas legales para juegos de disparos tipo battle royale:

- **Roti (asistente)**: entiende más de 60 temas (combos, personajes, 22 armas, sensi por marca, HUD, gloo,
  movimiento, zona, rangos, CS, lag, cuenta y seguridad, nombres con letras especiales, chistes) y responde
  con dibujos propios (HUD, mira, arrastre, gloo, zona, armas, rangos). Base en `web/roti.js`.
  armas y personajes; arma combos guiados (con test de 3 preguntas) y muestra la animación "pensando tu combo".
  Funciona sin internet, con reglas dentro de la app.
- **Combos**: genera 1 activa + 3 pasivas + mascota + armas según tu estilo (Rusher, Sniper,
  Escudo, Vida, Velocidad, Apoyo) y modo (BR/CS). Candados para fijar personajes, copiar y favoritos.
- **Sensi**: calcula General, Punto rojo, 2x, 4x, AWM y Vista libre según tu celular, pantalla,
  dedos y estilo (escala de 100 o 200), más consejos de HUD.
- **Entrenar**: minijuego para practicar el arrastre hacia arriba al disparar a la cabeza.
- **Tips**: técnicas, armas y rutina de práctica. Sin hacks ni regedit.

Compilar: `./compilar.sh` (requiere el SDK de Android). La app queda en `dist/Rotisimo.apk`.

El diseño se edita en `web/app.html` (datos en `web/datos.js` y `web/respuestas.js`); `node web/build.mjs` genera `web/index.html` con la letra Outfit y los íconos Lucide incluidos, para que funcione sin internet.
