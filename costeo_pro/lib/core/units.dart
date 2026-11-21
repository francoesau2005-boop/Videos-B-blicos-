/// Unidades de medida y conversiones.
///
/// Todas las conversiones se hacen a una unidad base por dimensión:
///   - masa   : gramos (g)
///   - volumen: mililitros (ml)
///   - conteo : unidades (u)
///
/// Las onzas de peso (oz) y las onzas líquidas (fl oz) son unidades distintas
/// y pertenecen a dimensiones distintas. Nunca se convierte masa ↔ volumen
/// a menos que el insumo tenga una densidad (g/ml) registrada explícitamente.
library;

enum Dimension { mass, volume, count }

enum Unit {
  g('g', 'Gramos', Dimension.mass, 1.0),
  kg('kg', 'Kilogramos', Dimension.mass, 1000.0),
  lb('lb', 'Libras', Dimension.mass, 453.59237),
  oz('oz', 'Onzas (peso)', Dimension.mass, 28.349523125),
  ml('ml', 'Mililitros', Dimension.volume, 1.0),
  l('L', 'Litros', Dimension.volume, 1000.0),
  floz('fl oz', 'Onzas líquidas', Dimension.volume, 29.5735295625),
  gal('gal', 'Galones (EE. UU.)', Dimension.volume, 3785.411784),
  unit('u', 'Unidades', Dimension.count, 1.0);

  const Unit(this.symbol, this.label, this.dimension, this.toBase);

  /// Abreviatura para mostrar (g, kg, lb, ...).
  final String symbol;

  /// Nombre completo en español.
  final String label;
  final Dimension dimension;

  /// Factor para convertir 1 de esta unidad a la unidad base de su dimensión.
  final double toBase;

  /// Clave estable usada en la base de datos.
  String get key => name;

  static Unit fromKey(String? key) {
    for (final u in Unit.values) {
      if (u.name == key) return u;
    }
    return Unit.unit;
  }

  static List<Unit> ofDimension(Dimension d) =>
      Unit.values.where((u) => u.dimension == d).toList();
}

String dimensionLabel(Dimension d) {
  switch (d) {
    case Dimension.mass:
      return 'Peso';
    case Dimension.volume:
      return 'Volumen';
    case Dimension.count:
      return 'Unidades';
  }
}

class UnitConversionException implements Exception {
  UnitConversionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Convierte [value] de la unidad [from] a la unidad [to].
///
/// [density] es gramos por mililitro y solo se usa al convertir entre masa y
/// volumen. Si las dimensiones no son compatibles y no hay densidad, lanza
/// [UnitConversionException]. No se redondea: se conserva la precisión.
double convert(double value, Unit from, Unit to, {double? density}) {
  if (from == to) return value;
  if (from.dimension == to.dimension) {
    return value * from.toBase / to.toBase;
  }
  final bothMassVolume = {from.dimension, to.dimension}
      .containsAll({Dimension.mass, Dimension.volume});
  if (bothMassVolume) {
    if (density == null || density <= 0) {
      throw UnitConversionException(
          'No se puede convertir ${from.label.toLowerCase()} a '
          '${to.label.toLowerCase()} sin una densidad registrada (g/ml).');
    }
    final base = value * from.toBase; // g o ml
    if (from.dimension == Dimension.mass) {
      final ml = base / density;
      return ml / to.toBase;
    } else {
      final g = base * density;
      return g / to.toBase;
    }
  }
  throw UnitConversionException(
      'Las unidades ${from.symbol} y ${to.symbol} no son compatibles.');
}

/// Indica si se puede convertir entre dos unidades con la densidad dada.
bool canConvert(Unit from, Unit to, {double? density}) {
  if (from.dimension == to.dimension) return true;
  final mv = {from.dimension, to.dimension}
      .containsAll({Dimension.mass, Dimension.volume});
  return mv && density != null && density > 0;
}

/// Unidades en las que se puede expresar un insumo comprado en [purchaseUnit].
List<Unit> compatibleUnits(Unit purchaseUnit, {double? density}) =>
    Unit.values.where((u) => canConvert(purchaseUnit, u, density: density)).toList();
