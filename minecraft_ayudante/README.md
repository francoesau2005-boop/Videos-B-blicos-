# Ayudante Survival (Minecraft Bedrock)

Add-on y panel web para jugar survival con ayuda:

- **Construcciones fantasma**: eliges una maqueta y aparecen bloques transparentes de colores
  en el mundo, capa por capa, donde va cada bloque. Pasa sola a la siguiente capa,
  marca en rojo los bloques equivocados y te dice qué materiales faltan.
- **Portales al Nether**: te dice las coordenadas exactas donde construir el otro portal
  para que queden enlazados, y te guía hasta ahí.
- **Coordenadas en pantalla** con su equivalente en el Nether y hacia dónde miras.
- **Puntos guardados** (casa, minas, aldeas) con indicaciones de distancia y giro.

## Instalar

1. Descarga `dist/AyudanteSurvival.mcaddon` y ábrelo con Minecraft.
2. Edita tu mundo → Paquetes de comportamiento → activa **Ayudante Survival**.
3. Al entrar recibes la **Guía de Construcción**. Úsala para abrir el menú.
   - Receta: 1 palo + 1 papel (sin forma).
   - Comandos: `/scriptevent ayudante:menu` y `/scriptevent ayudante:guia`.

Requiere Minecraft Bedrock 1.21.50 o más reciente. No necesita experimentos.

## Construcciones incluidas

Casa inicial 7x7, Portal al Nether, Granja de trigo 9x9, Generador de piedra,
Torre de vigilancia y Granja de hierro compacta.

## Agregar tus propias construcciones

Edita `construcciones.js` (explica el formato al inicio) y ejecuta:

```
node build.mjs
```

Eso regenera `dist/*.mcaddon` y `panel/index.html` (el panel web con calculadora
de portales y visor de maquetas por capas).
