import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Acceso a SQLite. Todas las escrituras se guardan inmediatamente.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const schemaVersion = 1;
  static const backupFormat = 'costeo_pro_backup';

  /// Tablas en orden de dependencia (para respaldo/restauración).
  static const tables = [
    'settings',
    'ingredients',
    'price_history',
    'recipes',
    'recipe_items',
    'extra_costs',
    'fixed_expenses',
    'stock_movements',
    'costings',
    'comparisons',
  ];

  static Future<AppDatabase> open(String path, {DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;
    final db = await f.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, v) => _create(db),
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _create(Database db) async {
    final b = db.batch();
    b.execute('''CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)''');
    b.execute('''CREATE TABLE ingredients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT,
      presentation TEXT,
      quantity REAL NOT NULL,
      unit TEXT NOT NULL,
      price REAL,
      brand TEXT,
      supplier TEXT,
      purchase_date INTEGER,
      photo_path TEXT,
      density REAL,
      track_stock INTEGER DEFAULT 0,
      stock REAL DEFAULT 0,
      min_stock REAL,
      notes TEXT,
      created_at INTEGER,
      updated_at INTEGER)''');
    b.execute('''CREATE TABLE price_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ingredient_id INTEGER NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
      price REAL NOT NULL,
      quantity REAL NOT NULL,
      unit TEXT NOT NULL,
      date INTEGER NOT NULL,
      supplier TEXT,
      note TEXT)''');
    b.execute('''CREATE TABLE recipes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT,
      yield_qty REAL NOT NULL,
      yield_unit TEXT,
      sale_price REAL,
      waste_percent REAL DEFAULT 0,
      include_fixed INTEGER DEFAULT 0,
      notes TEXT,
      parent_id INTEGER,
      created_at INTEGER,
      updated_at INTEGER)''');
    b.execute('''CREATE TABLE recipe_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
      ingredient_id INTEGER REFERENCES ingredients(id),
      sub_recipe_id INTEGER REFERENCES recipes(id),
      quantity REAL NOT NULL,
      unit TEXT NOT NULL,
      sort_order INTEGER DEFAULT 0)''');
    b.execute('''CREATE TABLE extra_costs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      name TEXT,
      mode TEXT NOT NULL,
      amount REAL NOT NULL)''');
    b.execute('''CREATE TABLE fixed_expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      monthly_amount REAL NOT NULL)''');
    b.execute('''CREATE TABLE stock_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ingredient_id INTEGER NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      quantity REAL NOT NULL,
      date INTEGER NOT NULL,
      note TEXT,
      recipe_id INTEGER)''');
    b.execute('''CREATE TABLE costings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER,
      recipe_name TEXT NOT NULL,
      date INTEGER NOT NULL,
      yield_qty REAL,
      yield_unit TEXT,
      sale_price REAL,
      ingredients_cost REAL,
      production_cost REAL,
      cost_per_unit REAL,
      gross_profit REAL,
      estimated_profit REAL,
      margin_percent REAL,
      detail_json TEXT,
      note TEXT)''');
    b.execute('''CREATE TABLE comparisons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_ids TEXT NOT NULL,
      title TEXT,
      date INTEGER NOT NULL)''');
    b.execute('CREATE INDEX idx_items_recipe ON recipe_items(recipe_id)');
    b.execute('CREATE INDEX idx_hist_ing ON price_history(ingredient_id)');
    b.execute('CREATE INDEX idx_mov_ing ON stock_movements(ingredient_id)');
    await b.commit(noResult: true);
  }

  Future<void> close() => db.close();

  // ---------------- Ajustes ----------------
  Future<Map<String, String>> loadSettings() async {
    final rows = await db.query('settings');
    return {for (final r in rows) r['key'] as String: (r['value'] as String?) ?? ''};
  }

  Future<void> setSetting(String key, String value) => db.insert(
      'settings', {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace);

  // ---------------- Insumos ----------------
  Future<List<Ingredient>> ingredients() async {
    final rows = await db.query('ingredients', orderBy: 'name COLLATE NOCASE');
    return rows.map(Ingredient.fromMap).toList();
  }

  /// Guarda un insumo. Si el precio o la presentación cambiaron, se agrega un
  /// registro al historial de precios (el historial nunca se borra al editar).
  Future<int> saveIngredient(Ingredient ing, {String historyNote = ''}) async {
    return db.transaction((txn) async {
      ing.updatedAt = DateTime.now();
      bool addHistory = false;
      if (ing.id == null) {
        final map = ing.toMap()..remove('id');
        ing.id = await txn.insert('ingredients', map);
        addHistory = ing.price != null;
      } else {
        final prev = await txn.query('ingredients',
            where: 'id = ?', whereArgs: [ing.id], limit: 1);
        if (prev.isNotEmpty) {
          final p = Ingredient.fromMap(prev.first);
          addHistory = ing.price != null &&
              (p.price != ing.price ||
                  p.quantity != ing.quantity ||
                  p.unit != ing.unit);
        }
        await txn.update('ingredients', ing.toMap(),
            where: 'id = ?', whereArgs: [ing.id]);
      }
      if (addHistory) {
        await txn.insert(
            'price_history',
            PriceRecord(
              ingredientId: ing.id!,
              price: ing.price!,
              quantity: ing.quantity,
              unit: ing.unit,
              date: ing.purchaseDate ?? DateTime.now(),
              supplier: ing.supplier,
              note: historyNote,
            ).toMap()
              ..remove('id'));
      }
      return ing.id!;
    });
  }

  Future<void> deleteIngredient(int id) =>
      db.delete('ingredients', where: 'id = ?', whereArgs: [id]);

  Future<List<PriceRecord>> priceHistory(int ingredientId) async {
    final rows = await db.query('price_history',
        where: 'ingredient_id = ?',
        whereArgs: [ingredientId],
        orderBy: 'date DESC, id DESC');
    return rows.map(PriceRecord.fromMap).toList();
  }

  // ---------------- Recetas ----------------
  Future<List<Recipe>> recipes() async {
    final rows = await db.query('recipes', orderBy: 'name COLLATE NOCASE');
    final items = await db.query('recipe_items', orderBy: 'sort_order, id');
    final extras = await db.query('extra_costs', orderBy: 'id');
    final byId = <int, Recipe>{};
    for (final r in rows) {
      final rec = Recipe.fromMap(r);
      byId[rec.id!] = rec;
    }
    for (final i in items) {
      final it = RecipeItem.fromMap(i);
      byId[it.recipeId]?.items.add(it);
    }
    for (final e in extras) {
      final ex = ExtraCost.fromMap(e);
      byId[ex.recipeId]?.extraCosts.add(ex);
    }
    return byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Guarda la receta completa (cabecera, líneas y costos adicionales).
  Future<int> saveRecipe(Recipe r) async {
    return db.transaction((txn) async {
      r.updatedAt = DateTime.now();
      if (r.id == null) {
        r.id = await txn.insert('recipes', r.toMap()..remove('id'));
      } else {
        await txn.update('recipes', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
        await txn.delete('recipe_items', where: 'recipe_id = ?', whereArgs: [r.id]);
        await txn.delete('extra_costs', where: 'recipe_id = ?', whereArgs: [r.id]);
      }
      var order = 0;
      for (final it in r.items) {
        it.recipeId = r.id;
        it.sortOrder = order++;
        it.id = await txn.insert('recipe_items', it.toMap()..remove('id'));
      }
      for (final e in r.extraCosts) {
        e.recipeId = r.id;
        e.id = await txn.insert('extra_costs', e.toMap()..remove('id'));
      }
      return r.id!;
    });
  }

  Future<void> deleteRecipe(int id) =>
      db.delete('recipes', where: 'id = ?', whereArgs: [id]);

  // ---------------- Gastos fijos ----------------
  Future<List<FixedExpense>> fixedExpenses() async =>
      (await db.query('fixed_expenses', orderBy: 'id')).map(FixedExpense.fromMap).toList();

  Future<void> saveFixedExpense(FixedExpense f) async {
    if (f.id == null) {
      f.id = await db.insert('fixed_expenses', f.toMap()..remove('id'));
    } else {
      await db.update('fixed_expenses', f.toMap(), where: 'id = ?', whereArgs: [f.id]);
    }
  }

  Future<void> deleteFixedExpense(int id) =>
      db.delete('fixed_expenses', where: 'id = ?', whereArgs: [id]);

  // ---------------- Inventario ----------------
  /// Registra movimientos y actualiza existencias en una sola transacción.
  Future<void> addMovements(List<StockMovement> moves) async {
    await db.transaction((txn) async {
      for (final m in moves) {
        await txn.insert('stock_movements', m.toMap()..remove('id'));
        await txn.rawUpdate(
            'UPDATE ingredients SET stock = stock + ?, track_stock = 1 WHERE id = ?',
            [m.quantity, m.ingredientId]);
      }
    });
  }

  Future<List<StockMovement>> movements({int? ingredientId, int limit = 200}) async {
    final rows = await db.query('stock_movements',
        where: ingredientId == null ? null : 'ingredient_id = ?',
        whereArgs: ingredientId == null ? null : [ingredientId],
        orderBy: 'date DESC, id DESC',
        limit: limit);
    return rows.map(StockMovement.fromMap).toList();
  }

  // ---------------- Costeos guardados ----------------
  Future<int> saveCosting(CostingSnapshot c) =>
      db.insert('costings', c.toMap()..remove('id'));

  Future<List<CostingSnapshot>> costings({int limit = 100}) async =>
      (await db.query('costings', orderBy: 'date DESC, id DESC', limit: limit))
          .map(CostingSnapshot.fromMap)
          .toList();

  Future<void> deleteCosting(int id) =>
      db.delete('costings', where: 'id = ?', whereArgs: [id]);

  // ---------------- Comparaciones ----------------
  Future<void> saveComparison(ComparisonRecord c) =>
      db.insert('comparisons', c.toMap()..remove('id'));

  Future<List<ComparisonRecord>> comparisons({int limit = 20}) async =>
      (await db.query('comparisons', orderBy: 'date DESC, id DESC', limit: limit))
          .map(ComparisonRecord.fromMap)
          .toList();

  // ---------------- Respaldo ----------------
  Future<String> exportBackupJson() async {
    final data = <String, Object?>{};
    for (final t in tables) {
      data[t] = await db.query(t);
    }
    return const JsonEncoder.withIndent(' ').convert({
      'format': backupFormat,
      'schema': schemaVersion,
      'created_at': DateTime.now().toIso8601String(),
      'tables': data,
    });
  }

  /// Reemplaza todos los datos con el respaldo. Si algo falla, no se cambia nada.
  Future<void> restoreBackupJson(String json) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      throw const FormatException('El archivo no es un respaldo válido.');
    }
    if (decoded is! Map || decoded['format'] != backupFormat) {
      throw const FormatException('El archivo no es un respaldo de Costeo Pro.');
    }
    final t = decoded['tables'];
    if (t is! Map) throw const FormatException('Respaldo incompleto.');
    await db.transaction((txn) async {
      for (final name in tables.reversed) {
        await txn.delete(name);
      }
      for (final name in tables) {
        final rows = t[name];
        if (rows is! List) continue;
        for (final row in rows) {
          if (row is Map) {
            await txn.insert(name, Map<String, Object?>.from(row));
          }
        }
      }
    });
  }
}
