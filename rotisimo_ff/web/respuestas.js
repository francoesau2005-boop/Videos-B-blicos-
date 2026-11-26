const RESP = {
  lag: { texto: "Para quitar el lag:\n• Gráficos en Fluido y activa FPS altos solo si tu celular no se calienta.\n• Cierra las apps de fondo antes de jugar.\n• Usa Wi-Fi de 5 GHz si tu módem lo tiene, o datos con buena señal.\n• Libera al menos 3 GB de almacenamiento.\n• Activa el modo juego / Game Turbo de tu celular.\n• Borra la caché del juego desde Ajustes del celular → Apps." },
  calienta: { texto: "Si se te calienta:\n• Quítale la funda mientras juegas.\n• No juegues cargando.\n• Baja el brillo y los gráficos a Fluido.\n• Desactiva sombras y FPS altos.\n• Juega en un lugar fresco, no en la cama.\nUn celular caliente baja los FPS y la mira se siente más lenta." },
  cabeza: { texto: "Para dar más tiros a la cabeza:\n• Camina con la mira a la altura de la cabeza.\n• Toca disparar y en el mismo movimiento jala el pulgar hacia arriba.\n• Usa punto rojo de cerca.\n• Con escopeta: espera la cabeza, no dispares al cuerpo.\nPractica el movimiento en Entrenar.", ops: [["Ir a Entrenar", () => abrir("entrenar")], ["Mi sensi", () => pedirGama()]] },
  calibrar: { texto: "Para calibrar tu mira:\n1. Ve al campo de entrenamiento con Desert Eagle.\n2. Dispara a la cabeza de un muñeco a 20 m.\n3. Si la mira se pasa de largo, baja 5 la General.\n4. Si no llega, súbele 5.\n5. Repite hasta que llegues justo a la cabeza con un solo movimiento.", ops: [["Ver mi sensi", ir("sensi")]] },
  hud: { texto: "HUD rotísimo:\n• Botón de disparo grande (55-65%) y algo arriba del centro derecho.\n• Transparencia 30-40%.\n• Agacharse y pared gloo al alcance del índice si juegas con 3 o 4 dedos.\n• Mira y recargar cerca del pulgar derecho." },
  cs: { texto: "Tips para CS (Duelo de escuadras):\n• Compra chaleco antes que arma si tienes poco dinero.\n• Juega en pareja: nunca entres solo.\n• Guarda paredes gloo para el final de la ronda.\n• Si quedas último, usa combo de Escudo o Vida.", ops: [["Combo para CS", () => { modo = "cs"; escribir("rot-modo", "cs"); comboDeEstilo("escudo"); }]] },
  br: { texto: "Tips para BR:\n• Cae en zonas medias, no en las más calientes, si quieres subir de rango.\n• Rota temprano hacia la zona.\n• Busca altura antes del cierre final.\n• Lleva siempre 6+ paredes gloo.", ops: [["Combo para BR", () => { modo = "br"; escribir("rot-modo", "br"); comboDeEstilo("rusher"); }]] },
  hack: { texto: "No te recomiendo hacks, regedit ni \"sensi hack\". Garena los detecta y banea la cuenta para siempre, y muchos traen virus. Lo que sí funciona: una buena sensi, HUD cómodo y 10 minutos de práctica diaria.", ops: [["Hacer mi sensi", pedirGama]] },
};
const ARMAS_INFO = {
  m1887: "M1887: dos tiros a la cabeza tumban. Ideal para rusher; combínala con Jota o Caroline.",
  mp40: "MP40: dispara rapidísimo de cerca. Jala suave hacia arriba mientras disparas.",
  ump: "UMP: buena penetración de armadura y control fácil. Muy cómoda para empezar.",
  awm: "AWM: un tiro a la cabeza derriba. Usa sensi baja en la mira y combo de Sniper.",
  desert: "Desert Eagle: mucho daño a la cabeza. Es la mejor para practicar precisión.",
  woodpecker: "Woodpecker: atraviesa armadura. Apunta al casco a media distancia.",
  scar: "SCAR: estable y con buen daño. Rifle cómodo para todo.",
  m4a1: "M4A1: mucha munición y poco retroceso. Buena para media distancia.",
  ak: "AK: mucho daño pero retroceso alto. Agáchate al disparar.",
  m1014: "M1014: escopeta con buen alcance. Apunta a la cabeza en el primer tiro.",
  svd: "SVD: francotirador semiautomático; dispara varias veces seguidas.",
  vector: "Vector: subfusil muy rápido para entrar con todo de cerca.",
};
