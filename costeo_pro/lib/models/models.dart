import '../core/units.dart';

double? _d(Object? v) => v == null ? null : (v as num).toDouble();
DateTime? _dt(Object? v) =>
    v == null ? null : DateTime.fromMillisecondsSinceEpoch((v as num).toInt());
int? _ms(DateTime? d) => d?.millisecondsSinceEpoch;

/// Insumo: un producto comprado (saco, bolsa, bote, paquete...).
class Ingredient {
  Ingredient({
    this.id,
    required this.name,
    this.category = 'General',
    this.presentation = '',
    required this.quantity,
    required this.unit,
    this.price,
    this.brand = '',
    this.supplier = '',
    this.purchaseDate,
    this.photoPath,
    this.density,
    this.pieces,
    this.trackStock = false,
    this.stock = 0,
    this.minStock,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int? id;
  String name;
  String category;

  /// Saco, bolsa, bote, paquete, cartón...
  String presentation;

  /// Contenido de la presentación comprada (ej. 50 para un saco de 50 lb).
  double quantity;
  Unit unit;

  /// Precio total de la presentación. `null` = precio pendiente (no se inventa).
  double? price;
  String brand;
  String supplier;
  DateTime? purchaseDate;
  String? photoPath;

  /// Densidad en g/ml, opcional. Solo con ella se convierte peso ↔ volumen.
  double? density;

  /// Piezas que trae la presentación (ej. paquete de 4 lb con 12 tortas).
  /// Permite usar "unidades" en recetas aunque se compre por peso o volumen.
  double? pieces;

  bool get hasPieces => pieces != null && pieces! > 0 && unit.dimension != Dimension.count;

  bool trackStock;

  /// Existencia actual, expresada en [unit].
  double stock;

  /// Alerta de existencia baja, expresada en [unit].
  double? minStock;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

  bool get hasPrice => price != null;

  /// Costo por unidad base (g, ml o u). `null` si falta el precio.
  double? get costPerBase {
    if (price == null || quantity <= 0) return null;
    return price! / (quantity * unit.toBase);
  }

  bool get isLowStock =>
      trackStock && minStock != null && stock <= (minStock ?? 0);

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'presentation': presentation,
        'quantity': quantity,
        'unit': unit.key,
        'price': price,
        'brand': brand,
        'supplier': supplier,
        'purchase_date': _ms(purchaseDate),
        'photo_path': photoPath,
        'density': density,
        'pieces': pieces,
        'track_stock': trackStock ? 1 : 0,
        'stock': stock,
        'min_stock': minStock,
        'notes': notes,
        'created_at': _ms(createdAt),
        'updated_at': _ms(updatedAt),
      };

  factory Ingredient.fromMap(Map<String, Object?> m) => Ingredient(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        category: (m['category'] as String?) ?? 'General',
        presentation: (m['presentation'] as String?) ?? '',
        quantity: _d(m['quantity']) ?? 0,
        unit: Unit.fromKey(m['unit'] as String?),
        price: _d(m['price']),
        brand: (m['brand'] as String?) ?? '',
        supplier: (m['supplier'] as String?) ?? '',
        purchaseDate: _dt(m['purchase_date']),
        photoPath: m['photo_path'] as String?,
        density: _d(m['density']),
        pieces: _d(m['pieces']),
        trackStock: (m['track_stock'] as num? ?? 0) == 1,
        stock: _d(m['stock']) ?? 0,
        minStock: _d(m['min_stock']),
        notes: (m['notes'] as String?) ?? '',
        createdAt: _dt(m['created_at']),
        updatedAt: _dt(m['updated_at']),
      );

  Ingredient copy() => Ingredient.fromMap(toMap());
}

/// Registro histórico de precio de un insumo.
class PriceRecord {
  PriceRecord({
    this.id,
    required this.ingredientId,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.date,
    this.supplier = '',
    this.note = '',
  });

  int? id;
  int ingredientId;
  double price;
  double quantity;
  Unit unit;
  DateTime date;
  String supplier;
  String note;

  double get costPerBase => quantity <= 0 ? 0 : price / (quantity * unit.toBase);

  Map<String, Object?> toMap() => {
        'id': id,
        'ingredient_id': ingredientId,
        'price': price,
        'quantity': quantity,
        'unit': unit.key,
        'date': _ms(date),
        'supplier': supplier,
        'note': note,
      };

  factory PriceRecord.fromMap(Map<String, Object?> m) => PriceRecord(
        id: m['id'] as int?,
        ingredientId: (m['ingredient_id'] as num).toInt(),
        price: _d(m['price']) ?? 0,
        quantity: _d(m['quantity']) ?? 0,
        unit: Unit.fromKey(m['unit'] as String?),
        date: _dt(m['date']) ?? DateTime.now(),
        supplier: (m['supplier'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
      );
}

class Recipe {
  Recipe({
    this.id,
    required this.name,
    this.category = 'General',
    this.yieldQty = 1,
    this.yieldUnit = 'unidades',
    this.salePrice,
    this.wastePercent = 0,
    this.includeFixedCosts = false,
    this.notes = '',
    this.parentId,
    List<RecipeItem>? items,
    List<ExtraCost>? extraCosts,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : items = items ?? [],
        extraCosts = extraCosts ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int? id;
  String name;
  String category;

  /// Cantidad producida por preparación (ej. 10 pizzas).
  double yieldQty;

  /// Nombre de lo que se produce: pizzas, bolas de masa, porciones...
  String yieldUnit;

  /// Precio de venta por unidad producida. `null` = sin precio definido.
  double? salePrice;

  /// Desperdicio o merma (%) aplicado sobre el costo de ingredientes.
  double wastePercent;

  /// Si se le asigna una parte de los gastos fijos mensuales.
  bool includeFixedCosts;
  String notes;

  /// Receta de la que es versión (simulación guardada o duplicado).
  int? parentId;
  List<RecipeItem> items;
  List<ExtraCost> extraCosts;
  DateTime createdAt;
  DateTime updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'yield_qty': yieldQty,
        'yield_unit': yieldUnit,
        'sale_price': salePrice,
        'waste_percent': wastePercent,
        'include_fixed': includeFixedCosts ? 1 : 0,
        'notes': notes,
        'parent_id': parentId,
        'created_at': _ms(createdAt),
        'updated_at': _ms(updatedAt),
      };

  factory Recipe.fromMap(Map<String, Object?> m) => Recipe(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        category: (m['category'] as String?) ?? 'General',
        yieldQty: _d(m['yield_qty']) ?? 1,
        yieldUnit: (m['yield_unit'] as String?) ?? 'unidades',
        salePrice: _d(m['sale_price']),
        wastePercent: _d(m['waste_percent']) ?? 0,
        includeFixedCosts: (m['include_fixed'] as num? ?? 0) == 1,
        notes: (m['notes'] as String?) ?? '',
        parentId: m['parent_id'] as int?,
        createdAt: _dt(m['created_at']),
        updatedAt: _dt(m['updated_at']),
      );

  /// Copia profunda (sin ids si [asNew]).
  Recipe clone({bool asNew = false}) {
    final r = Recipe.fromMap(toMap());
    r.items = items.map((i) => i.clone(asNew: asNew)).toList();
    r.extraCosts = extraCosts.map((e) => e.clone(asNew: asNew)).toList();
    if (asNew) {
      r.id = null;
      r.createdAt = DateTime.now();
      r.updatedAt = DateTime.now();
    }
    return r;
  }
}

/// Línea de receta: un insumo o una sub-receta con la cantidad utilizada.
class RecipeItem {
  RecipeItem({
    this.id,
    this.recipeId,
    this.ingredientId,
    this.subRecipeId,
    required this.quantity,
    required this.unit,
    this.sortOrder = 0,
  }) : assert(ingredientId != null || subRecipeId != null);

  int? id;
  int? recipeId;
  int? ingredientId;

  /// Si no es nulo, la línea usa otra receta (receta compuesta). En ese caso
  /// [quantity] se expresa en unidades producidas de la sub-receta.
  int? subRecipeId;
  double quantity;
  Unit unit;
  int sortOrder;

  bool get isSubRecipe => subRecipeId != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'recipe_id': recipeId,
        'ingredient_id': ingredientId,
        'sub_recipe_id': subRecipeId,
        'quantity': quantity,
        'unit': unit.key,
        'sort_order': sortOrder,
      };

  factory RecipeItem.fromMap(Map<String, Object?> m) => RecipeItem(
        id: m['id'] as int?,
        recipeId: m['recipe_id'] as int?,
        ingredientId: m['ingredient_id'] as int?,
        subRecipeId: m['sub_recipe_id'] as int?,
        quantity: _d(m['quantity']) ?? 0,
        unit: Unit.fromKey(m['unit'] as String?),
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      );

  RecipeItem clone({bool asNew = false}) {
    final c = RecipeItem.fromMap(toMap());
    if (asNew) {
      c.id = null;
      c.recipeId = null;
    }
    return c;
  }
}

/// Cómo se aplica un costo adicional.
enum ExtraCostMode {
  /// Monto fijo por cada preparación (ej. gas de un horneado).
  perBatch('Por preparación'),

  /// Monto por cada unidad producida (ej. caja de pizza).
  perUnit('Por unidad'),

  /// Porcentaje del precio de venta (comisiones de apps, impuestos).
  percentOfSale('% del precio de venta');

  const ExtraCostMode(this.label);
  final String label;

  static ExtraCostMode fromKey(String? k) => ExtraCostMode.values
      .firstWhere((e) => e.name == k, orElse: () => ExtraCostMode.perBatch);
}

enum ExtraCostType {
  gas('Gas'),
  electricity('Electricidad'),
  labor('Mano de obra'),
  packaging('Empaques y cajas'),
  transport('Transporte'),
  commission('Comisión de aplicaciones'),
  tax('Impuestos'),
  other('Otros gastos');

  const ExtraCostType(this.label);
  final String label;

  static ExtraCostType fromKey(String? k) => ExtraCostType.values
      .firstWhere((e) => e.name == k, orElse: () => ExtraCostType.other);

  ExtraCostMode get defaultMode {
    switch (this) {
      case ExtraCostType.packaging:
        return ExtraCostMode.perUnit;
      case ExtraCostType.commission:
      case ExtraCostType.tax:
        return ExtraCostMode.percentOfSale;
      default:
        return ExtraCostMode.perBatch;
    }
  }
}

class ExtraCost {
  ExtraCost({
    this.id,
    this.recipeId,
    required this.type,
    this.name = '',
    required this.mode,
    required this.amount,
  });

  int? id;
  int? recipeId;
  ExtraCostType type;
  String name;
  ExtraCostMode mode;

  /// Dólares (perBatch, perUnit) o porcentaje (percentOfSale).
  double amount;

  String get displayName => name.trim().isEmpty ? type.label : name.trim();

  /// Los porcentajes sobre la venta son gastos de venta, no de producción.
  bool get isSaleBased => mode == ExtraCostMode.percentOfSale;

  Map<String, Object?> toMap() => {
        'id': id,
        'recipe_id': recipeId,
        'type': type.name,
        'name': name,
        'mode': mode.name,
        'amount': amount,
      };

  factory ExtraCost.fromMap(Map<String, Object?> m) => ExtraCost(
        id: m['id'] as int?,
        recipeId: m['recipe_id'] as int?,
        type: ExtraCostType.fromKey(m['type'] as String?),
        name: (m['name'] as String?) ?? '',
        mode: ExtraCostMode.fromKey(m['mode'] as String?),
        amount: _d(m['amount']) ?? 0,
      );

  ExtraCost clone({bool asNew = false}) {
    final c = ExtraCost.fromMap(toMap());
    if (asNew) {
      c.id = null;
      c.recipeId = null;
    }
    return c;
  }
}

/// Gasto fijo mensual del negocio (alquiler, internet, sueldos fijos...).
class FixedExpense {
  FixedExpense({this.id, required this.name, required this.monthlyAmount});
  int? id;
  String name;
  double monthlyAmount;

  Map<String, Object?> toMap() =>
      {'id': id, 'name': name, 'monthly_amount': monthlyAmount};
  factory FixedExpense.fromMap(Map<String, Object?> m) => FixedExpense(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        monthlyAmount: _d(m['monthly_amount']) ?? 0,
      );
}

enum MovementType {
  initial('Existencia inicial'),
  purchase('Compra'),
  production('Producción'),
  adjustment('Ajuste');

  const MovementType(this.label);
  final String label;
  static MovementType fromKey(String? k) => MovementType.values
      .firstWhere((e) => e.name == k, orElse: () => MovementType.adjustment);
}

/// Movimiento de inventario. [quantity] con signo, en la unidad del insumo.
class StockMovement {
  StockMovement({
    this.id,
    required this.ingredientId,
    required this.type,
    required this.quantity,
    required this.date,
    this.note = '',
    this.recipeId,
  });
  int? id;
  int ingredientId;
  MovementType type;
  double quantity;
  DateTime date;
  String note;
  int? recipeId;

  Map<String, Object?> toMap() => {
        'id': id,
        'ingredient_id': ingredientId,
        'type': type.name,
        'quantity': quantity,
        'date': _ms(date),
        'note': note,
        'recipe_id': recipeId,
      };
  factory StockMovement.fromMap(Map<String, Object?> m) => StockMovement(
        id: m['id'] as int?,
        ingredientId: (m['ingredient_id'] as num).toInt(),
        type: MovementType.fromKey(m['type'] as String?),
        quantity: _d(m['quantity']) ?? 0,
        date: _dt(m['date']) ?? DateTime.now(),
        note: (m['note'] as String?) ?? '',
        recipeId: m['recipe_id'] as int?,
      );
}

/// Costeo guardado: conserva los precios utilizados en ese momento aunque
/// después cambie el precio de compra del insumo.
class CostingSnapshot {
  CostingSnapshot({
    this.id,
    this.recipeId,
    required this.recipeName,
    required this.date,
    required this.yieldQty,
    required this.yieldUnit,
    this.salePrice,
    required this.ingredientsCost,
    required this.productionCost,
    required this.costPerUnit,
    this.grossProfit,
    this.estimatedProfit,
    this.marginPercent,
    required this.detailJson,
    this.note = '',
  });

  int? id;
  int? recipeId;
  String recipeName;
  DateTime date;
  double yieldQty;
  String yieldUnit;
  double? salePrice;
  double ingredientsCost;
  double productionCost;
  double costPerUnit;
  double? grossProfit;
  double? estimatedProfit;
  double? marginPercent;

  /// Detalle completo (líneas, precios usados, costos adicionales) en JSON.
  String detailJson;
  String note;

  Map<String, Object?> toMap() => {
        'id': id,
        'recipe_id': recipeId,
        'recipe_name': recipeName,
        'date': _ms(date),
        'yield_qty': yieldQty,
        'yield_unit': yieldUnit,
        'sale_price': salePrice,
        'ingredients_cost': ingredientsCost,
        'production_cost': productionCost,
        'cost_per_unit': costPerUnit,
        'gross_profit': grossProfit,
        'estimated_profit': estimatedProfit,
        'margin_percent': marginPercent,
        'detail_json': detailJson,
        'note': note,
      };

  factory CostingSnapshot.fromMap(Map<String, Object?> m) => CostingSnapshot(
        id: m['id'] as int?,
        recipeId: m['recipe_id'] as int?,
        recipeName: (m['recipe_name'] as String?) ?? '',
        date: _dt(m['date']) ?? DateTime.now(),
        yieldQty: _d(m['yield_qty']) ?? 1,
        yieldUnit: (m['yield_unit'] as String?) ?? '',
        salePrice: _d(m['sale_price']),
        ingredientsCost: _d(m['ingredients_cost']) ?? 0,
        productionCost: _d(m['production_cost']) ?? 0,
        costPerUnit: _d(m['cost_per_unit']) ?? 0,
        grossProfit: _d(m['gross_profit']),
        estimatedProfit: _d(m['estimated_profit']),
        marginPercent: _d(m['margin_percent']),
        detailJson: (m['detail_json'] as String?) ?? '{}',
        note: (m['note'] as String?) ?? '',
      );
}

/// Comparación guardada (para "comparaciones recientes").
class ComparisonRecord {
  ComparisonRecord({
    this.id,
    required this.recipeIds,
    required this.title,
    required this.date,
  });
  int? id;
  List<int> recipeIds;
  String title;
  DateTime date;

  Map<String, Object?> toMap() => {
        'id': id,
        'recipe_ids': recipeIds.join(','),
        'title': title,
        'date': _ms(date),
      };
  factory ComparisonRecord.fromMap(Map<String, Object?> m) => ComparisonRecord(
        id: m['id'] as int?,
        recipeIds: ((m['recipe_ids'] as String?) ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .map(int.parse)
            .toList(),
        title: (m['title'] as String?) ?? '',
        date: _dt(m['date']) ?? DateTime.now(),
      );
}
