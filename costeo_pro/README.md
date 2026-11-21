# Costeo Pro

Aplicación Android (Flutter + SQLite) para calcular costos, precios y ganancias de
negocios de comida: panaderías, pizzerías, restaurantes y emprendimientos.
Funciona **sin internet**, en **español** y con **dólares (USD)**.

## Instalar el APK

1. Copia `release/CosteoPro-arm64.apk` al teléfono (sirve para casi todos los
   Android de los últimos años). Si tu teléfono es muy antiguo (32 bits), usa
   `release/CosteoPro-armv7.apk`.
2. Ábrelo y acepta "Instalar apps de origen desconocido" si Android lo pide.

> El APK está firmado con una clave de desarrollo. Para publicarlo en Google Play
> hay que firmarlo con una clave propia (ver "Firma para Play Store").

## Qué hace

| Área | Funciones |
|---|---|
| **Insumos** | Nombre, categoría, presentación (saco, bolsa, bote…), contenido y unidad, precio total, marca, proveedor, fecha, foto, densidad opcional, historial de precios automático. Precio opcional: si falta queda como *precio pendiente* (nunca se inventa). |
| **Unidades** | g, kg, lb, oz (peso), ml, L, fl oz (líquidas), galón y unidades. Las onzas de peso y las líquidas son distintas; peso ↔ volumen solo con densidad registrada. Sin redondeo interno: se redondea solo al mostrar. |
| **Recetas** | Ilimitadas, por categorías; editar, duplicar, eliminar; recetas compuestas (una pizza usa 1 bola de "Masa de pizza"); rendimiento, precio de venta, costo por unidad, ganancia y margen en vivo. Cambiar el rendimiento (10 → 12 pizzas) se ve al instante sin modificar la receta. |
| **Costos adicionales** | Gas, electricidad, mano de obra, empaques, transporte, comisiones de apps, impuestos y otros: por preparación, por unidad o % del precio de venta. Merma (%). Gastos fijos mensuales repartidos por unidad. |
| **Resultados** | Costo de ingredientes, costo total de producción, ganancia bruta, *ganancia estimada después de gastos registrados* (nunca se llama "neta"), margen y recargo. |
| **Calculadora** | Ganancia por producto y total, margen, recargo y precio recomendado para un margen objetivo (30 %, 40 %, 50 %…). |
| **Comparador** | Dos o más recetas: diferencias de ingredientes y cantidades, costo total, ahorro/gasto extra, rendimiento, costo y ganancia por unidad, y cuál cuesta menos / deja más ganancia (mismo criterio: por unidad). |
| **Simulador** | Cambia cantidades, precios de insumos, rendimiento y precio de venta sin tocar los datos reales. Opción de guardar como nueva versión de la receta. |
| **Inventario (opcional)** | Existencia inicial, compras, ajustes, descuento SOLO al registrar una producción real, alertas de existencia baja. |
| **Reportes** | PDF profesional por receta y resumen de recetas; CSV de insumos, recetas, detalle, costeos e historial de precios. Compartir o guardar en el teléfono. |
| **Datos** | SQLite local, costeos guardados con los precios de su fecha, respaldo/restauración en JSON, copia automática diaria, confirmación antes de borrar, validaciones (negativos, vacíos, división entre cero). |

## Estructura

```
lib/
  core/units.dart        Unidades y conversiones
  core/costing.dart      Motor de costeo, margen, recargo, precio objetivo
  core/format.dart       Formato de moneda/números y lectura (coma o punto)
  models/models.dart     Modelos de datos
  data/database.dart     SQLite (tablas, historial, respaldo/restauración)
  state/app_state.dart   Estado de la app y reglas de negocio
  services/              PDF, CSV, compartir/guardar archivos
  ui/                    Tema, componentes y pantallas
test/                    Pruebas automáticas (40)
test_screens/            Capturas de pantalla generadas y PDF de ejemplo
```

## Desarrollo

Requisitos: Flutter 3.47+ y Android SDK.

```bash
flutter pub get
flutter test                      # cálculos, persistencia, PDF/CSV e interfaz
flutter build apk --release --split-per-abi
# Capturas de pantalla para revisar el diseño:
flutter test test_screens/screenshots_test.dart --update-goldens
```

### Firma para Play Store

Crea una clave con `keytool -genkey -v -keystore costeo.jks -keyalg RSA -keysize 2048 -validity 10000 -alias costeo`
y configura `android/app/build.gradle.kts` con un `signingConfig` de release
(https://docs.flutter.dev/deployment/android#sign-the-app).
