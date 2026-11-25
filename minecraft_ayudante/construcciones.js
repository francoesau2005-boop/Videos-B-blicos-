// Planos de construcciones del Ayudante Survival.
// Este archivo es la ÚNICA fuente de los planos: el add-on y el panel web lo usan.
//
// Cómo se lee un plano:
//  - `capas` va de abajo hacia arriba (capa 0 = la más baja).
//  - Cada capa es una lista de filas. La fila 0 es la más cercana a ti
//    y las siguientes se alejan hacia donde estás mirando.
//  - Dentro de cada fila, el carácter 0 está a tu izquierda y el último a tu derecha.
//  - "." o " " = no importa / aire (no se revisa).
//  - offsetY: cuántos bloques por debajo de tus pies empieza la capa 0
//    (-1 = la capa 0 reemplaza el suelo donde estás parado).
//
// Para agregar tu propia construcción copia una de las de abajo y cambia las letras.

export const PALETA = {
  C: { id: "minecraft:cobblestone", nombre: "Piedra labrada", color: [0.55, 0.55, 0.58] },
  P: { id: "minecraft:oak_planks", nombre: "Tablones de roble", acepta: ["minecraft:planks"], color: [0.78, 0.6, 0.36] },
  L: { id: "minecraft:oak_log", nombre: "Tronco de roble", acepta: ["minecraft:log"], color: [0.42, 0.31, 0.18] },
  G: { id: "minecraft:glass", nombre: "Vidrio", acepta: ["minecraft:glass_pane"], contiene: "stained_glass", color: [0.62, 0.88, 1.0] },
  D: { id: "minecraft:wooden_door", nombre: "Puerta de madera", contiene: "door", porItem: 2, color: [0.6, 0.42, 0.22] },
  T: { id: "minecraft:torch", nombre: "Antorcha", color: [1.0, 0.85, 0.2] },
  B: { id: "minecraft:bed", nombre: "Cama", porItem: 2, color: [0.85, 0.15, 0.15] },
  M: { id: "minecraft:crafting_table", nombre: "Mesa de crafteo", color: [0.66, 0.45, 0.25] },
  H: { id: "minecraft:furnace", nombre: "Horno", acepta: ["minecraft:lit_furnace"], color: [0.35, 0.35, 0.35] },
  K: { id: "minecraft:chest", nombre: "Cofre", acepta: ["minecraft:trapped_chest"], color: [0.85, 0.6, 0.2] },
  O: { id: "minecraft:obsidian", nombre: "Obsidiana", color: [0.3, 0.12, 0.5] },
  W: { id: "minecraft:water", nombre: "Agua (cubo)", acepta: ["minecraft:flowing_water"], color: [0.2, 0.4, 1.0] },
  Y: { id: "minecraft:lava", nombre: "Lava (cubo)", acepta: ["minecraft:flowing_lava"], color: [1.0, 0.45, 0.0] },
  F: { id: "minecraft:farmland", nombre: "Tierra arada (azada)", color: [0.45, 0.3, 0.15] },
  N: { id: "minecraft:oak_fence", nombre: "Valla de madera", contiene: "fence", color: [0.7, 0.52, 0.3] },
  Q: { id: "minecraft:fence_gate", nombre: "Puerta de valla", contiene: "fence_gate", color: [0.9, 0.7, 0.4] },
  U: { id: "minecraft:hopper", nombre: "Tolva", color: [0.3, 0.3, 0.33] },
  S: { id: "minecraft:oak_sign", nombre: "Cartel", contiene: "sign", color: [0.95, 0.8, 0.5] },
  E: { id: "minecraft:ladder", nombre: "Escalera de mano", color: [0.7, 0.5, 0.25] },
};

export const CONSTRUCCIONES = [
  {
    id: "casa_inicial",
    nombre: "Casa inicial 7x7",
    categoria: "Casas",
    descripcion: "Casa de madera con piso de piedra, ventanas, cama, cofre, horno y mesa de crafteo. Ideal para la primera noche.",
    offsetY: -1,
    notas: [
      "Pon la cama al final: haz clic en el bloque marcado más cercano a la puerta.",
      "Las antorchas van pegadas a la pared interior.",
    ],
    capas: [
      ["CCCCCCC", "CCCCCCC", "CCCCCCC", "CCCCCCC", "CCCCCCC", "CCCCCCC", "CCCCCCC"],
      ["LPPDPPL", "P.....P", "P.....P", "P.....P", "PK...BP", "PMH..BP", "LPPPPPL"],
      ["LPPDPPL", "P.....P", "G.....G", "G.....G", "P.....P", "P.....P", "LPGGGPL"],
      ["LPPPPPL", "P.....P", "P.....P", "PT...TP", "P.....P", "P.....P", "LPPPPPL"],
      ["PPPPPPP", "PPPPPPP", "PPPPPPP", "PPPPPPP", "PPPPPPP", "PPPPPPP", "PPPPPPP"],
    ],
  },
  {
    id: "portal_nether",
    nombre: "Portal al Nether",
    categoria: "Portales",
    descripcion: "Marco de obsidiana 4x5 (10 bloques, sin esquinas). Enciéndelo con mechero o carga de fuego.",
    offsetY: 0,
    notas: [
      "Usa el menú Portales para saber en qué coordenadas construirlo y que quede enlazado.",
      "Las esquinas no son necesarias.",
    ],
    capas: [[".OO."], ["O..O"], ["O..O"], ["O..O"], [".OO."]],
  },
  {
    id: "granja_trigo",
    nombre: "Granja de trigo 9x9",
    categoria: "Granjas",
    descripcion: "Un solo bloque de agua en el centro hidrata las 80 casillas de tierra. Cercada para que no entren mobs.",
    offsetY: -1,
    notas: [
      "Ara la tierra con una azada después de poner el agua.",
      "Planta semillas, zanahorias o papas en la tierra arada.",
    ],
    capas: [
      [
        "LLLLLLLLLLL",
        "LFFFFFFFFFL",
        "LFFFFFFFFFL",
        "LFFFFFFFFFL",
        "LFFFFFFFFFL",
        "LFFFFWFFFFL",
        "LFFFFFFFFFL",
        "LFFFFFFFFFL",
        "LFFFFFFFFFL",
        "LFFFFFFFFFL",
        "LLLLLLLLLLL",
      ],
      [
        "NNNNNQNNNNN",
        "N.........N",
        "N.........N",
        "N.........N",
        "N.........N",
        "N.........N",
        "N.........N",
        "N.........N",
        "N.........N",
        "N.........N",
        "NNNNNNNNNNN",
      ],
      ["T.........T", "...........", "...........", "...........", "...........", "...........", "...........", "...........", "...........", "...........", "T.........T"],
    ],
  },
  {
    id: "generador_piedra",
    nombre: "Generador de piedra",
    categoria: "Granjas",
    descripcion: "Generador infinito de piedra labrada. La piedra aparece en el bloque entre la lava y el hoyo.",
    offsetY: -3,
    notas: [
      "Pon primero el AGUA (va a caer en el hoyo), luego la LAVA.",
      "Pica la piedra que aparece en la 3ª casilla de la zanja; se regenera sola.",
    ],
    capas: [
      [".......", "....C..", "......."],
      ["....C..", "CCCC.CC", "....C.."],
      ["CCCCCCC", "CY...WC", "CCCCCCC"],
    ],
  },
  {
    id: "torre_vigilancia",
    nombre: "Torre de vigilancia",
    categoria: "Casas",
    descripcion: "Torre de piedra de 10 bloques con escalera de mano y mirador con vallas.",
    offsetY: -1,
    notas: ["La escalera de mano va pegada a la pared del fondo."],
    capas: [
      ["CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC"],
      ["CC.CC", "C...C", "C...C", "C.E.C", "CCCCC"],
      ["CC.CC", "C...C", "C...C", "C.E.C", "CCCCC"],
      ["CCCCC", "C...C", "C...C", "C.E.C", "CCCCC"],
      ["CCGCC", "G...G", "C...C", "C.E.C", "CCCCC"],
      ["CCCCC", "C...C", "C...C", "C.E.C", "CCCCC"],
      ["CCGCC", "G...G", "C...C", "C.E.C", "CCGCC"],
      ["CCCCC", "C...C", "C...C", "C.E.C", "CCCCC"],
      ["CCCCC", "CCCCC", "CCCCC", "CCECC", "CCCCC"],
      ["NNNNN", "N...N", "N...N", "N...N", "NNNNN"],
      ["T...T", ".....", ".....", ".....", "T...T"],
    ],
  },
  {
    id: "granja_hierro",
    nombre: "Granja de hierro compacta",
    categoria: "Granjas",
    descripcion: "3 aldeanos asustados por un zombi hacen aparecer gólems. El agua los empuja a la cuchilla de lava y el hierro cae en las tolvas.",
    offsetY: -1,
    notas: [
      "Arriba van 3 aldeanos con 3 camas y un zombi (con etiqueta de nombre) detrás del vidrio.",
      "Coloca las 3 tolvas haciendo clic en los cofres de abajo.",
      "Los carteles de la capa de lava: usa carteles colgantes o pon un bloque temporal y quítalo.",
      "Pon el agua al fondo del cuarto; debe llegar justo hasta las tolvas.",
      "Si no aparecen gólems, agrega más aldeanos y camas: en Bedrock más aldea = más gólems.",
    ],
    capas: [
      [".....", ".KKK.", ".....", ".....", ".....", ".....", ".....", "....."],
      ["CCCCC", "CUUUC", "CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC"],
      ["GGGGG", "G...G", "G...G", "G...G", "G...G", "G...G", "GWWWG", "GGGGG"],
      ["GGGGG", "GSSSG", "G...G", "G...G", "G...G", "G...G", "G...G", "GGGGG"],
      ["GGGGG", "GYYYG", "GSSSG", "G...G", "G...G", "G...G", "G...G", "GGGGG"],
      ["GGGGG", "GGGGG", "G...G", "G...G", "G...G", "G...G", "G...G", "GGGGG"],
      ["CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC"],
      ["CCCCC", "C...C", "CGGGC", "C...C", "C...C", "CBBBC", "CBBBC", "CCCCC"],
      ["CCCCC", "G...G", "CGGGC", "G...G", "G...G", "G...G", "G...G", "CCCCC"],
      ["CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC", "CCCCC"],
    ],
  },
];
