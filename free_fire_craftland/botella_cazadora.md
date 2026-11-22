# 🍾 BOTELLA CAZADORA — Minijuego para Free Fire Craftland

Guía completa para construir en **Craftland** un minijuego como el del video:
una botella gira en el centro, **al jugador que apunta le toca cazar** durante unos segundos
y los demás tienen que **sobrevivir**. Gana el primero en llegar a **10 puntos**.

> ⚠️ Los mapas de Craftland solo se pueden crear dentro del editor de Free Fire
> (no se pueden importar archivos). Esta guía te dice exactamente qué poner, dónde
> y qué lógica programar. Los nombres de los bloques pueden variar un poco según
> la versión de Craftland; busca el bloque equivalente.

---

## 1. Cómo funciona (lo que se ve en el video)

| Fase | Duración | Qué pasa | Texto en pantalla |
|---|---|---|---|
| 1. GIRANDO | 4–5 s | Todos aparecen alrededor de la plataforma central, **congelados y dorados** (invencibles). La botella gira. | `SPINNING` / `GIRANDO` |
| 2. ELECCIÓN | 1 s | La botella se detiene apuntando a un jugador. | `¡LA BOTELLA TE ELIGIÓ! +1 punto por cada jugador que atrapes en 15 s` |
| 3a. CAZADOR | 15 s | El elegido recibe un arma y caza. **+1 punto por cada jugador eliminado.** | `HUNT 15s` / `CAZA 15s` |
| 3b. SOBREVIVIENTES | 15 s | Todos los demás sin armas, corren y se esconden detrás de muros. | `SURVIVE 15s` / `SOBREVIVE 15s` |
| 4. ELIMINADO | hasta fin de ronda | Si te atrapan quedas fuera hasta la próxima ronda. | `ELIMINATED` / `ELIMINADO` |
| 5. FIN DE RONDA | — | Todos vuelven al centro, se reinicia el giro. | — |
| VICTORIA | — | El primero con **10 puntos** gana la partida. | `¡GANADOR: Nombre!` |

**HUD superior** (en todo momento):
`NV 2 · PUNTOS 0 · MEJOR 5 · PRIMERO A 10` + barra de experiencia `150 / 420 XP`.

---

## 2. Diseño del mapa

```
        ┌──────────────── MURO EXTERIOR (madera + paredes crema) ────────────────┐
        │   ▢ arco        ▢ arco            ▢ arco          ▢ arco                │
        │                                                                         │
        │   ███ muro         ▄▄▄ barra            ███ muro         ▄▄▄ barra      │
        │                                                                         │
        │            ★  ★  ★   (spawns alrededor)  ★  ★  ★                        │
        │          ★   ┌───────────────────────┐   ★                              │
        │         ★   /    PLATAFORMA OCTAGONAL  \   ★                            │
        │         ★  |          🍾 BOTELLA        |  ★                            │
        │         ★   \      (centro, giratoria) /   ★                            │
        │          ★   └───────────────────────┘   ★                              │
        │            ★  ★  ★                 ★  ★  ★                              │
        │                                                                         │
        │   ▄▄▄ barra        ███ muro              ▄▄▄ barra       ███ muro       │
        │                                                                         │
        │   ▢ arco        ▢ arco            ▢ arco          ▢ arco                │
        └─────────────────────────────────────────────────────────────────────────┘
```

### Medidas recomendadas
- **Arena:** cuadrada de ~40 × 40 bloques, piso de baldosas de piedra clara.
- **Muro exterior:** 6–8 bloques de alto, estilo madera oscura con paneles crema, con **arcos** cada 8 bloques (dan sensación de salidas, pero cierra el fondo para que no se salga nadie).
- **Plataforma central:** octágono de ~10 bloques de diámetro, 1,5 bloques de alto, base de piedra azul y borde de madera.
- **Botella:** objeto/prop de botella (o un cilindro verde + cuello) **acostado** encima de la plataforma, escalado ×3–4.
- **Coberturas:** 6–8 muros de madera sueltos y barras/mostradores repartidos por la arena (para esconderse del cazador). Que ninguno quede a más de 8 bloques de otro.
- **Spawns:** 12 puntos de aparición en círculo alrededor de la plataforma (radio ~7 bloques), todos mirando al centro.
- **Cielo:** día soleado.

### Objetos que tienes que colocar y nombrar
| Nombre (ID) | Tipo | Dónde |
|---|---|---|
| `Botella` | Prop / objeto móvil | Centro de la plataforma |
| `Spawn_1` … `Spawn_12` | Punto de aparición | Círculo alrededor del octágono |
| `Zona_Arena` | Zona/área (trigger) | Cubre todo el piso jugable |
| `Arma_Cazador` | Arma cuerpo a cuerpo o ballesta | Se entrega por lógica (no en el piso) |

---

## 3. Variables

**Globales (del juego):**
| Variable | Tipo | Inicial | Uso |
|---|---|---|---|
| `Fase` | texto | `"GIRANDO"` | GIRANDO / CAZA / FIN |
| `Tiempo` | número | 0 | cuenta regresiva |
| `Cazador` | jugador | ninguno | quién tiene la botella |
| `PuntosParaGanar` | número | 10 | meta |
| `TiempoGiro` | número | 5 | segundos de giro |
| `TiempoCaza` | número | 15 | segundos de caza |

**Por jugador:**
| Variable | Inicial | Uso |
|---|---|---|
| `Puntos` | 0 | puntos de la partida |
| `Mejor` | 0 | mejor marca (guardar si Craftland lo permite) |
| `XP` | 0 | experiencia |
| `Nivel` | 1 | nivel |
| `Vivo` | verdadero | si sigue en la ronda |

---

## 4. Lógica (programación por bloques)

Escríbelo como eventos en el editor de lógica de Craftland.

### Evento: Al iniciar la partida
```
poner PuntosParaGanar = 10
para cada jugador:
    Puntos = 0 ; XP = 0 ; Nivel = 1
llamar IniciarRonda
```

### Función: IniciarRonda
```
Fase = "GIRANDO"
Cazador = ninguno
i = 1
para cada jugador:
    Vivo = verdadero
    revivir jugador (si estaba eliminado)
    teletransportar a Spawn_i ; i = i + 1
    quitar todas las armas
    congelar movimiento
    hacer invencible
    efecto/color DORADO
    mostrar texto superior "GIRANDO"
girar Botella sobre eje Y: 720° + aleatorio(0, 360°) en TiempoGiro segundos
esperar TiempoGiro
llamar ElegirCazador
```

### Función: ElegirCazador
```
// Opción A (exacta): el jugador más cercano a la dirección de la botella
mejor = ninguno ; menorAngulo = 999
para cada jugador:
    ang = diferencia entre (rotación Y de Botella) y (ángulo de Botella → jugador)
    si ang < menorAngulo: menorAngulo = ang ; mejor = jugador
Cazador = mejor

// Opción B (fácil): si no hay bloques de ángulo
// Cazador = jugador aleatorio  (y gira la botella para que apunte hacia él)

mostrar a Cazador: "¡LA BOTELLA TE ELIGIÓ! +1 punto por cada jugador que atrapes en 15 s"
llamar IniciarCaza
```

### Función: IniciarCaza
```
Fase = "CAZA"
Tiempo = TiempoCaza
para cada jugador:
    descongelar ; quitar invencible ; quitar color dorado
    si jugador == Cazador:
        dar Arma_Cazador ; velocidad x1.15
    si no:
        sin armas ; daño recibido normal
repetir cada 1 segundo mientras Fase == "CAZA":
    Cazador ve "CAZA {Tiempo}s"
    los demás ven "SOBREVIVE {Tiempo}s"
    Tiempo = Tiempo - 1
    si Tiempo <= 0 o no queda nadie Vivo (excepto Cazador):
        llamar FinRonda
```

### Evento: Cuando un jugador es eliminado
```
si Fase == "CAZA" y asesino == Cazador:
    víctima.Vivo = falso
    mostrar a víctima "ELIMINADO"
    víctima pasa a modo espectador hasta la próxima ronda
    Cazador.Puntos = Cazador.Puntos + 1
    Cazador.XP = Cazador.XP + 30
    mostrar a Cazador "+1 PUNTO ({Puntos}/10)"
    llamar RevisarNivel(Cazador)
    si Cazador.Puntos >= PuntosParaGanar:
        llamar Victoria(Cazador)
```

### Evento: Daño entre sobrevivientes
```
si atacante != Cazador: cancelar daño   // nadie más puede hacer daño
si Fase == "GIRANDO": cancelar todo daño
```

### Función: FinRonda
```
Fase = "FIN"
para cada jugador vivo que no sea Cazador:
    XP = XP + 10        // premio por sobrevivir
    RevisarNivel(jugador)
quitar arma al Cazador
esperar 2 segundos
llamar IniciarRonda
```

### Función: RevisarNivel(jugador)
```
xpNecesaria = 300 + (Nivel × 60)        // Nv1 = 360, Nv2 = 420, Nv3 = 480…
si XP >= xpNecesaria:
    XP = XP - xpNecesaria
    Nivel = Nivel + 1
    mostrar "¡SUBISTE A NIVEL {Nivel}!"
actualizar barra "{XP} / {xpNecesaria} XP"
```

### Función: Victoria(ganador)
```
Fase = "FIN"
para cada jugador:
    si Puntos > Mejor: Mejor = Puntos
mostrar a todos "¡GANADOR: {ganador}!"
terminar partida (o esperar 5 s, poner Puntos = 0 a todos y llamar IniciarRonda)
```

---

## 5. HUD / interfaz

Crea un panel de texto arriba al centro (estilo letrero de madera):
- **Línea 1 (grande):** fase y tiempo → `GIRANDO` · `CAZA 12s` · `SOBREVIVE 8s` · `ELIMINADO` (en rojo).
- **Línea 2 (pequeña):** `NV {Nivel} · PUNTOS {Puntos} · MEJOR {Mejor} · PRIMERO A 10`.
- **Barra:** progreso de XP `{XP} / {xpNecesaria} XP`.

Actualízalo cada segundo y cada vez que cambien los puntos.

---

## 6. Ajustes de la partida (Configuración del modo)
- Jugadores: **4 a 12**.
- Modo: todos contra todos (sin equipos), fuego amigo **activado** (la lógica bloquea el daño de los que no son cazador).
- Reaparición automática: **desactivada** (la lógica revive al empezar cada ronda).
- Vida: 200. Arma del cazador: que mate en 1–2 golpes para que sea rápido.
- Sin botín en el piso, sin zona/gas.

---

## 7. Ideas extra para hacerlo más divertido
- 🔊 Sonido de “tic-tic-tic” mientras gira la botella y un golpe cuando se detiene.
- ⚡ El cazador brilla en verde o rojo para que todos lo reconozcan de lejos.
- 🏃 Los sobrevivientes reciben +10 % de velocidad los últimos 5 segundos.
- 💀 Si el cazador no atrapa a nadie en su turno, **pierde 1 punto**.
- 🎯 Ronda especial cada 5 rondas: la botella elige **2 cazadores**.

---

## 8. Checklist para probar
- [ ] Todos aparecen congelados y dorados alrededor de la botella.
- [ ] La botella gira y se detiene en una dirección distinta cada vez.
- [ ] Solo el elegido tiene arma y solo él puede hacer daño.
- [ ] El contador baja de 15 a 0 y los textos cambian (CAZA / SOBREVIVE).
- [ ] Cada eliminación da +1 punto y XP al cazador.
- [ ] Los eliminados vuelven en la siguiente ronda.
- [ ] Al llegar a 10 puntos se anuncia el ganador.
