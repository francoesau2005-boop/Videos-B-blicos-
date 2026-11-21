import '../core/costing.dart';
import '../models/models.dart';

/// Genera archivos CSV (UTF-8 con BOM para que Excel muestre bien los acentos).
class CsvBuilder {
  CsvBuilder._();

  static String _esc(Object? v) {
    if (v == null) return '';
    var s = v is double ? _num(v) : v.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _num(double v) {
    if (v.isNaN || v.isInfinite) return '';
    final s = v.toStringAsFixed(6);
    return s.contains('.') ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '') : s;
  }

  static String _date(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String build(List<String> header, List<List<Object?>> rows) {
    final b = StringBuffer('﻿');
    b.writeln(header.map(_esc).join(','));
    for (final r in rows) {
      b.writeln(r.map(_esc).join(','));
    }
    return b.toString();
  }

  static String ingredients(List<Ingredient> list) => build(
        ['Nombre', 'Categoría', 'Presentación', 'Contenido', 'Unidad', 'Precio (USD)',
          'Costo por unidad', 'Marca', 'Proveedor', 'Fecha de compra', 'Existencia', 'Alerta mínima'],
        [
          for (final i in list)
            [
              i.name, i.category, i.presentation, i.quantity, i.unit.symbol, i.price,
              i.price == null || i.quantity <= 0 ? null : i.price! / i.quantity,
              i.brand, i.supplier, _date(i.purchaseDate),
              i.trackStock ? i.stock : null, i.minStock,
            ]
        ],
      );

  static String recipes(List<RecipeCosting> list) => build(
        ['Receta', 'Categoría', 'Rendimiento', 'Unidad', 'Costo ingredientes', 'Costo producción',
          'Costo por unidad', 'Precio de venta', 'Ingresos potenciales', 'Ganancia bruta',
          'Ganancia estimada después de gastos registrados', 'Margen bruto %', 'Recargo %', 'Completo'],
        [
          for (final c in list)
            [
              c.recipe.name, c.recipe.category, c.yieldQty, c.recipe.yieldUnit, c.ingredientsCost,
              c.productionCost, c.costPerUnit, c.salePrice, c.potentialRevenue, c.grossProfit,
              c.estimatedProfit, c.grossMarginPercent, c.markupPercent, c.isComplete ? 'Sí' : 'No',
            ]
        ],
      );

  static String recipeLines(List<RecipeCosting> list) => build(
        ['Receta', 'Ingrediente', 'Cantidad', 'Unidad', 'Costo', 'Precio presentación',
          'Contenido presentación', 'Unidad presentación'],
        [
          for (final c in list)
            for (final l in c.lines)
              [
                c.recipe.name, l.name, l.item.quantity,
                l.item.isSubRecipe ? (l.subYieldUnit ?? 'u') : l.item.unit.symbol,
                l.cost, l.packagePrice, l.packageQty, l.packageUnit?.symbol,
              ]
        ],
      );

  static String costings(List<CostingSnapshot> list) => build(
        ['Fecha', 'Receta', 'Rendimiento', 'Unidad', 'Costo ingredientes', 'Costo producción',
          'Costo por unidad', 'Precio de venta', 'Ganancia bruta', 'Ganancia estimada', 'Margen %'],
        [
          for (final s in list)
            [
              '${_date(s.date)} ${s.date.hour.toString().padLeft(2, '0')}:${s.date.minute.toString().padLeft(2, '0')}',
              s.recipeName, s.yieldQty, s.yieldUnit, s.ingredientsCost, s.productionCost,
              s.costPerUnit, s.salePrice, s.grossProfit, s.estimatedProfit, s.marginPercent,
            ]
        ],
      );

  static String priceHistory(List<Ingredient> ings, Map<int, List<PriceRecord>> hist) => build(
        ['Insumo', 'Fecha', 'Precio', 'Contenido', 'Unidad', 'Proveedor', 'Nota'],
        [
          for (final i in ings)
            for (final h in hist[i.id] ?? const <PriceRecord>[])
              [i.name, _date(h.date), h.price, h.quantity, h.unit.symbol, h.supplier, h.note]
        ],
      );
}
