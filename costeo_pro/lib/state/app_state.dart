import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/costing.dart';
import '../core/format.dart';
import '../core/units.dart';
import '../data/database.dart';
import '../models/models.dart';

/// Estado global de la app. Mantiene en memoria los datos de SQLite y
/// guarda cada cambio en la base de datos de inmediato.
class AppState extends ChangeNotifier {
  AppState(this.db);

  final AppDatabase db;

  List<Ingredient> ingredients = [];
  List<Recipe> recipes = [];
  List<FixedExpense> fixedExpenses = [];
  List<CostingSnapshot> costings = [];
  List<ComparisonRecord> comparisons = [];
  Map<String, String> settings = {};
  bool loaded = false;

  Map<int, Ingredient> _ingById = {};
  Map<int, Recipe> _recById = {};

  Future<void> load() async {
    ingredients = await db.ingredients();
    recipes = await db.recipes();
    fixedExpenses = await db.fixedExpenses();
    costings = await db.costings();
    comparisons = await db.comparisons();
    settings = await db.loadSettings();
    _index();
    loaded = true;
    notifyListeners();
  }

  void _index() {
    _ingById = {for (final i in ingredients) i.id!: i};
    _recById = {for (final r in recipes) r.id!: r};
  }

  Ingredient? ingredient(int? id) => id == null ? null : _ingById[id];
  Recipe? recipe(int? id) => id == null ? null : _recById[id];

  // ---------------- Ajustes ----------------
  String get businessName => settings['business_name'] ?? '';
  ThemeMode get themeMode {
    switch (settings['theme']) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  /// Unidades producidas al mes (para repartir los gastos fijos).
  double get monthlyUnits => Fmt.parse(settings['monthly_units']) ?? 0;
  double get totalFixedMonthly =>
      fixedExpenses.fold(0.0, (s, f) => s + f.monthlyAmount);
  double get fixedCostPerUnit =>
      monthlyUnits > 0 ? totalFixedMonthly / monthlyUnits : 0;

  Future<void> setSetting(String key, String value) async {
    await db.setSetting(key, value);
    settings = {...settings, key: value};
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode m) => setSetting(
      'theme',
      m == ThemeMode.light
          ? 'light'
          : m == ThemeMode.system
              ? 'system'
              : 'dark');

  // ---------------- Costeo ----------------
  CostingContext get context => CostingContext(
        ingredients: _ingById,
        recipes: _recById,
        fixedCostPerUnit: fixedCostPerUnit,
      );
  CostingEngine get engine => CostingEngine(context);
  RecipeCosting costing(Recipe r) => engine.cost(r);

  List<String> get ingredientCategories {
    final s = <String>{'General', 'Harinas', 'Lácteos', 'Carnes', 'Aceites y grasas',
      'Condimentos', 'Verduras', 'Bebidas', 'Empaques'};
    s.addAll(ingredients.map((i) => i.category).where((c) => c.trim().isNotEmpty));
    return s.toList()..sort();
  }

  List<String> get recipeCategories {
    final s = <String>{'General', 'Masas', 'Pizzas', 'Salsas', 'Panadería',
      'Postres', 'Frituras', 'Hamburguesas'};
    s.addAll(recipes.map((r) => r.category).where((c) => c.trim().isNotEmpty));
    return s.toList()..sort();
  }

  List<Ingredient> get lowStock => ingredients.where((i) => i.isLowStock).toList();
  List<Ingredient> get missingPrice => ingredients.where((i) => i.price == null).toList();

  // ---------------- Insumos ----------------
  Future<void> saveIngredient(Ingredient ing, {String note = ''}) async {
    final isNew = ing.id == null;
    final initialStock = ing.stock;
    if (isNew) ing.stock = 0;
    await db.saveIngredient(ing, historyNote: note);
    if (isNew && ing.trackStock && initialStock > 0) {
      await db.addMovements([
        StockMovement(
            ingredientId: ing.id!,
            type: MovementType.initial,
            quantity: initialStock,
            date: DateTime.now())
      ]);
    }
    await _reloadIngredients();
  }

  Future<void> _reloadIngredients() async {
    ingredients = await db.ingredients();
    _index();
    notifyListeners();
  }

  /// Recetas que usan el insumo (para impedir borrarlo por accidente).
  List<Recipe> recipesUsingIngredient(int id) =>
      recipes.where((r) => r.items.any((i) => i.ingredientId == id)).toList();
  List<Recipe> recipesUsingRecipe(int id) =>
      recipes.where((r) => r.items.any((i) => i.subRecipeId == id)).toList();

  Future<void> deleteIngredient(int id) async {
    if (recipesUsingIngredient(id).isNotEmpty) {
      throw StateError('El insumo se usa en recetas.');
    }
    await db.deleteIngredient(id);
    await _reloadIngredients();
  }

  Future<List<PriceRecord>> priceHistory(int id) => db.priceHistory(id);

  // ---------------- Recetas ----------------
  Future<int> saveRecipe(Recipe r) async {
    final id = await db.saveRecipe(r);
    recipes = await db.recipes();
    _index();
    notifyListeners();
    return id;
  }

  Future<void> deleteRecipe(int id) async {
    if (recipesUsingRecipe(id).isNotEmpty) {
      throw StateError('La receta se usa dentro de otras recetas.');
    }
    await db.deleteRecipe(id);
    recipes = await db.recipes();
    _index();
    notifyListeners();
  }

  Future<int> duplicateRecipe(Recipe r, {String? name}) async {
    final c = r.clone(asNew: true)
      ..name = name ?? '${r.name} (copia)'
      ..parentId = r.id;
    return saveRecipe(c);
  }

  // ---------------- Costeos guardados ----------------
  Future<void> saveCostingSnapshot(RecipeCosting c, {String note = ''}) async {
    await db.saveCosting(snapshotFrom(c, note: note));
    costings = await db.costings();
    notifyListeners();
  }

  static CostingSnapshot snapshotFrom(RecipeCosting c, {String note = ''}) =>
      CostingSnapshot(
        recipeId: c.recipe.id,
        recipeName: c.recipe.name,
        date: DateTime.now(),
        yieldQty: c.yieldQty,
        yieldUnit: c.recipe.yieldUnit,
        salePrice: c.salePrice,
        ingredientsCost: c.ingredientsCost,
        productionCost: c.productionCost,
        costPerUnit: c.costPerUnit,
        grossProfit: c.grossProfit,
        estimatedProfit: c.estimatedProfit,
        marginPercent: c.grossMarginPercent,
        detailJson: jsonEncode(c.toDetail()),
        note: note,
      );

  Future<void> deleteCosting(int id) async {
    await db.deleteCosting(id);
    costings = await db.costings();
    notifyListeners();
  }

  // ---------------- Comparaciones ----------------
  Future<void> recordComparison(List<int> ids) async {
    final names = ids.map((i) => recipe(i)?.name ?? '?').join(' vs ');
    if (comparisons.isNotEmpty &&
        comparisons.first.recipeIds.join(',') == ids.join(',')) {
      return; // evitar duplicados consecutivos
    }
    await db.saveComparison(
        ComparisonRecord(recipeIds: ids, title: names, date: DateTime.now()));
    comparisons = await db.comparisons();
    notifyListeners();
  }

  // ---------------- Gastos fijos ----------------
  Future<void> saveFixedExpense(FixedExpense f) async {
    await db.saveFixedExpense(f);
    fixedExpenses = await db.fixedExpenses();
    notifyListeners();
  }

  Future<void> deleteFixedExpense(int id) async {
    await db.deleteFixedExpense(id);
    fixedExpenses = await db.fixedExpenses();
    notifyListeners();
  }

  // ---------------- Inventario ----------------
  /// Registra una compra: suma existencias y, si se indica, actualiza el
  /// precio del insumo (se guarda en el historial).
  Future<void> registerPurchase(Ingredient ing,
      {required double packages, double? newPrice, String note = ''}) async {
    if (packages <= 0) throw ArgumentError('Cantidad inválida');
    if (newPrice != null && newPrice >= 0 && newPrice != ing.price) {
      final upd = ing.copy()
        ..price = newPrice
        ..purchaseDate = DateTime.now();
      await db.saveIngredient(upd, historyNote: 'Compra');
    }
    await db.addMovements([
      StockMovement(
        ingredientId: ing.id!,
        type: MovementType.purchase,
        quantity: packages * ing.quantity,
        date: DateTime.now(),
        note: note.isEmpty ? '${Fmt.num(packages)} × ${ing.presentation.isEmpty ? 'presentación' : ing.presentation}' : note,
      )
    ]);
    await _reloadIngredients();
  }

  Future<void> adjustStock(Ingredient ing, double newStock, {String note = ''}) async {
    final delta = newStock - ing.stock;
    if (delta == 0) return;
    await db.addMovements([
      StockMovement(
        ingredientId: ing.id!,
        type: ing.stock == 0 && !ing.trackStock
            ? MovementType.initial
            : MovementType.adjustment,
        quantity: delta,
        date: DateTime.now(),
        note: note,
      )
    ]);
    await _reloadIngredients();
  }

  /// Descuenta del inventario los insumos de una producción REAL.
  /// (Consultar o simular una receta nunca descuenta inventario.)
  Future<Map<int, double>> registerProduction(Recipe r, double batches) async {
    if (batches <= 0) throw ArgumentError('Cantidad inválida');
    final req = engine.requirements(r, batches);
    final now = DateTime.now();
    await db.addMovements([
      for (final e in req.entries)
        StockMovement(
          ingredientId: e.key,
          type: MovementType.production,
          quantity: -e.value,
          date: now,
          note: '${r.name} × ${Fmt.num(batches)}',
          recipeId: r.id,
        )
    ]);
    await _reloadIngredients();
    return req;
  }

  Future<List<StockMovement>> movements({int? ingredientId}) =>
      db.movements(ingredientId: ingredientId);

  // ---------------- Respaldo ----------------
  Future<String> exportBackup() => db.exportBackupJson();
  Future<void> restoreBackup(String json) async {
    await db.restoreBackupJson(json);
    await load();
  }

  /// Unidades en que puede expresarse un insumo en una receta.
  List<Unit> unitsFor(Ingredient ing) => unitsForIngredient(ing);
}
