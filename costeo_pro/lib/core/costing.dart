import '../models/models.dart';
import 'units.dart';

/// Fórmulas de precio, margen y recargo. Sin redondeos internos.
class ProfitMath {
  ProfitMath._();

  /// Margen (%) = (precio − costo) / precio × 100. Se calcula sobre el PRECIO.
  static double? marginPercent(double cost, double price) {
    if (price <= 0) return null;
    return (price - cost) / price * 100;
  }

  /// Recargo (%) = (precio − costo) / costo × 100. Se calcula sobre el COSTO.
  static double? markupPercent(double cost, double price) {
    if (cost <= 0) return null;
    return (price - cost) / cost * 100;
  }

  /// Precio necesario para obtener un margen objetivo (%).
  /// precio = costo / (1 − margen). Margen debe ser < 100 %.
  static double? priceForMargin(double cost, double marginPct) {
    if (cost < 0 || marginPct < 0 || marginPct >= 100) return null;
    return cost / (1 - marginPct / 100);
  }

  /// Precio aplicando un recargo (%) sobre el costo.
  static double? priceForMarkup(double cost, double markupPct) {
    if (cost < 0 || markupPct < 0) return null;
    return cost * (1 + markupPct / 100);
  }

  /// Costo de la porción usada de un producto comprado:
  /// (cantidad usada / cantidad comprada) × precio de compra,
  /// convirtiendo primero la cantidad usada a la unidad de compra.
  static double usageCost({
    required double usedQty,
    required Unit usedUnit,
    required double purchaseQty,
    required Unit purchaseUnit,
    required double purchasePrice,
    double? density,
  }) {
    if (purchaseQty <= 0) {
      throw UnitConversionException('La cantidad comprada debe ser mayor que cero.');
    }
    final usedInPurchaseUnit =
        convert(usedQty, usedUnit, purchaseUnit, density: density);
    return usedInPurchaseUnit / purchaseQty * purchasePrice;
  }

  static double safeDiv(double a, double b) => b == 0 ? 0 : a / b;
}

/// Datos necesarios para costear: catálogo de insumos, recetas y gastos fijos.
class CostingContext {
  CostingContext({
    required this.ingredients,
    required this.recipes,
    this.fixedCostPerUnit = 0,
  });

  final Map<int, Ingredient> ingredients;
  final Map<int, Recipe> recipes;

  /// Parte de los gastos fijos mensuales asignada a cada unidad producida.
  final double fixedCostPerUnit;

  CostingContext copyWith({
    Map<int, Ingredient>? ingredients,
    Map<int, Recipe>? recipes,
    double? fixedCostPerUnit,
  }) =>
      CostingContext(
        ingredients: ingredients ?? this.ingredients,
        recipes: recipes ?? this.recipes,
        fixedCostPerUnit: fixedCostPerUnit ?? this.fixedCostPerUnit,
      );
}

/// Resultado de costear una línea de la receta.
class LineCost {
  LineCost({
    required this.item,
    required this.name,
    this.cost,
    this.error,
    this.missingPrice = false,
    this.packagePrice,
    this.packageQty,
    this.packageUnit,
    this.subCostPerUnit,
    this.subYieldUnit,
  });

  final RecipeItem item;
  final String name;

  /// Costo de la cantidad usada. `null` si falta precio o hay error.
  final double? cost;
  final String? error;
  final bool missingPrice;

  /// Precio y presentación utilizados (para conservar el histórico).
  final double? packagePrice;
  final double? packageQty;
  final Unit? packageUnit;

  /// Para sub-recetas: costo por unidad producida utilizado.
  final double? subCostPerUnit;
  final String? subYieldUnit;

  bool get ok => cost != null;
}

class ExtraCostLine {
  ExtraCostLine(this.extra, this.batchAmount);
  final ExtraCost extra;

  /// Monto total por preparación.
  final double batchAmount;
}

/// Resultado completo del costeo de una receta (por preparación).
class RecipeCosting {
  RecipeCosting({
    required this.recipe,
    required this.lines,
    required this.productionExtras,
    required this.saleExtras,
    required this.fixedCostPerUnit,
  });

  final Recipe recipe;
  final List<LineCost> lines;
  final List<ExtraCostLine> productionExtras;
  final List<ExtraCostLine> saleExtras;
  final double fixedCostPerUnit;

  double get yieldQty => recipe.yieldQty;
  double? get salePrice => recipe.salePrice;

  /// Faltan precios o hay líneas con error: el costo está incompleto.
  bool get isComplete => lines.every((l) => l.ok);
  List<LineCost> get problemLines => lines.where((l) => !l.ok).toList();

  /// Costo de ingredientes (insumos y sub-recetas) de una preparación.
  double get ingredientsCost =>
      lines.fold(0.0, (s, l) => s + (l.cost ?? 0));

  double get wasteCost => ingredientsCost * recipe.wastePercent / 100;

  double get productionExtrasTotal =>
      productionExtras.fold(0.0, (s, e) => s + e.batchAmount);

  /// Costo total de producción por preparación
  /// = ingredientes + merma + costos de producción (gas, luz, mano de obra, empaques...).
  double get productionCost =>
      ingredientsCost + wasteCost + productionExtrasTotal;

  /// Costo por unidad producida. 0 si el rendimiento no es válido.
  double get costPerUnit => ProfitMath.safeDiv(productionCost, yieldQty);
  double get ingredientsCostPerUnit =>
      ProfitMath.safeDiv(ingredientsCost, yieldQty);

  bool get hasSalePrice => salePrice != null && salePrice! > 0;

  /// Ingresos potenciales si se vende todo lo producido.
  double? get potentialRevenue => hasSalePrice ? salePrice! * yieldQty : null;

  /// Ganancia bruta = ingresos − costo total de producción.
  double? get grossProfit =>
      hasSalePrice ? potentialRevenue! - productionCost : null;
  double? get grossProfitPerUnit =>
      hasSalePrice ? salePrice! - costPerUnit : null;

  /// Gastos de venta (comisiones, impuestos) por preparación.
  double get saleExtrasTotal => saleExtras.fold(0.0, (s, e) => s + e.batchAmount);

  double get fixedCostTotal =>
      recipe.includeFixedCosts ? fixedCostPerUnit * yieldQty : 0;

  /// Ganancia estimada después de los gastos registrados (no es "ganancia neta").
  double? get estimatedProfit =>
      hasSalePrice ? grossProfit! - saleExtrasTotal - fixedCostTotal : null;
  double? get estimatedProfitPerUnit =>
      hasSalePrice ? ProfitMath.safeDiv(estimatedProfit!, yieldQty) : null;

  double? get grossMarginPercent =>
      hasSalePrice ? ProfitMath.marginPercent(costPerUnit, salePrice!) : null;
  double? get estimatedMarginPercent => hasSalePrice
      ? ProfitMath.safeDiv(estimatedProfit!, potentialRevenue!) * 100
      : null;
  double? get markupPercent =>
      hasSalePrice ? ProfitMath.markupPercent(costPerUnit, salePrice!) : null;

  /// Costo total por unidad incluyendo gastos de venta y fijos asignados.
  double get fullCostPerUnit => ProfitMath.safeDiv(
      productionCost + saleExtrasTotal + fixedCostTotal, yieldQty);

  Map<String, Object?> toDetail() => {
        'yield_qty': yieldQty,
        'yield_unit': recipe.yieldUnit,
        'sale_price': salePrice,
        'waste_percent': recipe.wastePercent,
        'waste_cost': wasteCost,
        'complete': isComplete,
        'lines': [
          for (final l in lines)
            {
              'name': l.name,
              'quantity': l.item.quantity,
              'unit': l.item.isSubRecipe ? (l.subYieldUnit ?? 'u') : l.item.unit.symbol,
              'sub_recipe': l.item.isSubRecipe,
              'cost': l.cost,
              'package_price': l.packagePrice,
              'package_qty': l.packageQty,
              'package_unit': l.packageUnit?.symbol,
              'sub_cost_per_unit': l.subCostPerUnit,
              'error': l.error,
            }
        ],
        'production_extras': [
          for (final e in productionExtras)
            {
              'name': e.extra.displayName,
              'mode': e.extra.mode.label,
              'amount': e.extra.amount,
              'total': e.batchAmount,
            }
        ],
        'sale_extras': [
          for (final e in saleExtras)
            {
              'name': e.extra.displayName,
              'mode': e.extra.mode.label,
              'amount': e.extra.amount,
              'total': e.batchAmount,
            }
        ],
        'fixed_cost_per_unit': recipe.includeFixedCosts ? fixedCostPerUnit : 0,
        'fixed_cost_total': fixedCostTotal,
        'production_extras_total': productionExtrasTotal,
        'sale_extras_total': saleExtrasTotal,
      };
}

/// Motor de costeo de recetas (incluye recetas compuestas).
class CostingEngine {
  CostingEngine(this.ctx);
  final CostingContext ctx;

  RecipeCosting cost(Recipe recipe) => _cost(recipe, <int>{});

  RecipeCosting _cost(Recipe recipe, Set<int> visiting) {
    if (recipe.id != null) visiting = {...visiting, recipe.id!};
    final lines = <LineCost>[];
    for (final item in recipe.items) {
      lines.add(_lineCost(item, visiting));
    }
    final prodExtras = <ExtraCostLine>[];
    final saleExtras = <ExtraCostLine>[];
    final y = recipe.yieldQty > 0 ? recipe.yieldQty : 0.0;
    for (final e in recipe.extraCosts) {
      final amount = e.amount < 0 ? 0.0 : e.amount;
      switch (e.mode) {
        case ExtraCostMode.perBatch:
          prodExtras.add(ExtraCostLine(e, amount));
          break;
        case ExtraCostMode.perUnit:
          prodExtras.add(ExtraCostLine(e, amount * y));
          break;
        case ExtraCostMode.percentOfSale:
          final price = recipe.salePrice ?? 0;
          saleExtras.add(ExtraCostLine(e, price * amount / 100 * y));
          break;
      }
    }
    return RecipeCosting(
      recipe: recipe,
      lines: lines,
      productionExtras: prodExtras,
      saleExtras: saleExtras,
      fixedCostPerUnit: ctx.fixedCostPerUnit,
    );
  }

  LineCost _lineCost(RecipeItem item, Set<int> visiting) {
    if (item.quantity < 0) {
      return LineCost(item: item, name: _name(item), error: 'Cantidad negativa');
    }
    if (item.isSubRecipe) {
      final sub = ctx.recipes[item.subRecipeId];
      if (sub == null) {
        return LineCost(item: item, name: 'Receta eliminada', error: 'La receta ya no existe');
      }
      if (visiting.contains(sub.id)) {
        return LineCost(item: item, name: sub.name, error: 'Referencia circular entre recetas');
      }
      if (sub.yieldQty <= 0) {
        return LineCost(item: item, name: sub.name, error: 'La sub-receta no tiene rendimiento');
      }
      final subCosting = _cost(sub, visiting);
      if (!subCosting.isComplete) {
        return LineCost(
          item: item,
          name: sub.name,
          missingPrice: true,
          error: 'La sub-receta tiene precios pendientes',
          subYieldUnit: sub.yieldUnit,
        );
      }
      final cpu = subCosting.costPerUnit;
      return LineCost(
        item: item,
        name: sub.name,
        cost: cpu * item.quantity,
        subCostPerUnit: cpu,
        subYieldUnit: sub.yieldUnit,
      );
    }
    final ing = ctx.ingredients[item.ingredientId];
    if (ing == null) {
      return LineCost(item: item, name: 'Insumo eliminado', error: 'El insumo ya no existe');
    }
    if (ing.price == null) {
      return LineCost(
        item: item,
        name: ing.name,
        missingPrice: true,
        error: 'Precio de compra pendiente',
        packageQty: ing.quantity,
        packageUnit: ing.unit,
      );
    }
    try {
      final c = ProfitMath.usageCost(
        usedQty: item.quantity,
        usedUnit: item.unit,
        purchaseQty: ing.quantity,
        purchaseUnit: ing.unit,
        purchasePrice: ing.price!,
        density: ing.density,
      );
      return LineCost(
        item: item,
        name: ing.name,
        cost: c,
        packagePrice: ing.price,
        packageQty: ing.quantity,
        packageUnit: ing.unit,
      );
    } on UnitConversionException catch (e) {
      return LineCost(item: item, name: ing.name, error: e.message);
    }
  }

  String _name(RecipeItem item) => item.isSubRecipe
      ? (ctx.recipes[item.subRecipeId]?.name ?? 'Receta')
      : (ctx.ingredients[item.ingredientId]?.name ?? 'Insumo');

  /// Cantidad de cada insumo (en la unidad de compra del insumo) que consume
  /// [batches] preparaciones de la receta, expandiendo sub-recetas.
  Map<int, double> requirements(Recipe recipe, double batches,
      [Set<int>? visiting]) {
    visiting ??= <int>{};
    final out = <int, double>{};
    if (recipe.id != null) {
      if (visiting.contains(recipe.id)) return out;
      visiting = {...visiting, recipe.id!};
    }
    for (final item in recipe.items) {
      if (item.isSubRecipe) {
        final sub = ctx.recipes[item.subRecipeId];
        if (sub == null || sub.yieldQty <= 0) continue;
        final subBatches = item.quantity / sub.yieldQty * batches;
        requirements(sub, subBatches, visiting).forEach((k, v) {
          out[k] = (out[k] ?? 0) + v;
        });
      } else {
        final ing = ctx.ingredients[item.ingredientId];
        if (ing == null) continue;
        try {
          final q = convert(item.quantity, item.unit, ing.unit,
                  density: ing.density) *
              batches;
          out[ing.id!] = (out[ing.id!] ?? 0) + q;
        } on UnitConversionException {
          // Línea inválida: se omite (se avisa en el costeo).
        }
      }
    }
    return out;
  }

  /// IDs de recetas que no pueden usarse como sub-receta de [recipeId]
  /// (ella misma y las que la contienen, para evitar ciclos).
  Set<int> forbiddenSubRecipes(int? recipeId) {
    if (recipeId == null) return {};
    final out = <int>{recipeId};
    bool changed = true;
    while (changed) {
      changed = false;
      for (final r in ctx.recipes.values) {
        if (r.id == null || out.contains(r.id)) continue;
        if (r.items.any((i) => i.isSubRecipe && out.contains(i.subRecipeId))) {
          out.add(r.id!);
          changed = true;
        }
      }
    }
    return out;
  }
}
