import 'dart:convert';
import 'dart:io';

import 'package:costeo_pro/core/units.dart';
import 'package:costeo_pro/data/database.dart';
import 'package:costeo_pro/models/models.dart';
import 'package:costeo_pro/services/csv_builder.dart';
import 'package:costeo_pro/services/report_builder.dart';
import 'package:costeo_pro/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory tmp;
  late String path;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('costeo_test');
    path = '${tmp.path}/test.db';
  });
  tearDown(() async => tmp.delete(recursive: true));

  Future<AppState> openState() async {
    final db = await AppDatabase.open(path, factory: databaseFactoryFfi);
    final s = AppState(db);
    await s.load();
    return s;
  }

  Future<(AppState, Recipe)> seedPizza() async {
    final s = await openState();
    final harina = Ingredient(name: 'Harina fuerte', presentation: 'Saco', quantity: 50, unit: Unit.lb, price: 30);
    final aceite = Ingredient(name: 'Aceite Orisol Clásico', presentation: 'Bolsa', quantity: 410, unit: Unit.ml, price: 1.25);
    final sal = Ingredient(name: 'Sal', quantity: 1, unit: Unit.kg); // sin precio
    await s.saveIngredient(harina);
    await s.saveIngredient(aceite);
    await s.saveIngredient(sal);
    final r = Recipe(name: 'Masa de pizza', yieldQty: 10, yieldUnit: 'pizzas', salePrice: 5, items: [
      RecipeItem(ingredientId: harina.id, quantity: 7, unit: Unit.lb),
      RecipeItem(ingredientId: aceite.id, quantity: 140, unit: Unit.ml),
    ]);
    await s.saveRecipe(r);
    return (s, r);
  }

  test('los datos persisten al cerrar y volver a abrir', () async {
    final (s, r) = await seedPizza();
    await s.db.close();

    final s2 = await openState();
    expect(s2.ingredients.length, 3);
    expect(s2.recipes.length, 1);
    final r2 = s2.recipes.single;
    expect(r2.name, 'Masa de pizza');
    expect(r2.items.length, 2);
    final c = s2.costing(r2);
    expect(c.ingredientsCost, closeTo(4.2 + 140 / 410 * 1.25, 1e-12));
    expect(s2.ingredients.firstWhere((i) => i.name == 'Sal').price, isNull);
    await s2.db.close();
  });

  test('editar precio conserva historial y el costeo guardado conserva el precio antiguo', () async {
    final (s, r) = await seedPizza();
    final c1 = s.costing(s.recipe(r.id)!);
    await s.saveCostingSnapshot(c1);

    final harina = s.ingredients.firstWhere((i) => i.name == 'Harina fuerte');
    await s.saveIngredient(harina.copy()..price = 35);

    final hist = await s.priceHistory(harina.id!);
    expect(hist.length, 2);
    expect(hist.map((h) => h.price), containsAll([30.0, 35.0]));

    // El costeo vivo usa el precio nuevo…
    final c2 = s.costing(s.recipe(r.id)!);
    expect(c2.lines.first.cost, closeTo(7 / 50 * 35, 1e-12));
    // …pero el costeo guardado conserva el anterior.
    final snap = s.costings.single;
    expect(snap.ingredientsCost, closeTo(c1.ingredientsCost, 1e-12));
    final detail = jsonDecode(snap.detailJson) as Map;
    expect((detail['lines'] as List).first['package_price'], 30.0);
    await s.db.close();
  });

  test('recetas ilimitadas, duplicar y eliminar', () async {
    final (s, r) = await seedPizza();
    for (var i = 0; i < 150; i++) {
      await s.duplicateRecipe(s.recipe(r.id)!, name: 'Copia $i');
    }
    expect(s.recipes.length, 151);
    final copy = s.recipes.firstWhere((x) => x.name == 'Copia 7');
    expect(copy.items.length, 2);
    expect(copy.parentId, r.id);
    await s.deleteRecipe(copy.id!);
    expect(s.recipes.length, 150);
    await s.db.close();
  });

  test('no se elimina un insumo usado en recetas', () async {
    final (s, _) = await seedPizza();
    final harina = s.ingredients.firstWhere((i) => i.name == 'Harina fuerte');
    expect(() => s.deleteIngredient(harina.id!), throwsStateError);
    final sal = s.ingredients.firstWhere((i) => i.name == 'Sal');
    await s.deleteIngredient(sal.id!);
    expect(s.ingredients.length, 2);
    await s.db.close();
  });

  test('inventario: consultar/simular no descuenta; producción real sí', () async {
    final (s, r) = await seedPizza();
    final harina = s.ingredients.firstWhere((i) => i.name == 'Harina fuerte');
    await s.adjustStock(harina, 50);
    await s.saveIngredient(s.ingredient(harina.id)!.copy()..minStock = 10);
    expect(s.ingredient(harina.id)!.stock, 50);

    // Consultar costeo y simular (copias) no cambia nada.
    s.costing(s.recipe(r.id)!);
    final sim = s.recipe(r.id)!.clone()..items.first.quantity = 1;
    s.costing(sim);
    expect(s.ingredient(harina.id)!.stock, 50);
    expect(s.recipe(r.id)!.items.first.quantity, 7);

    await s.registerProduction(s.recipe(r.id)!, 2);
    expect(s.ingredient(harina.id)!.stock, closeTo(36, 1e-9));
    expect(s.ingredient(harina.id)!.isLowStock, isFalse);

    await s.registerPurchase(s.ingredient(harina.id)!, packages: 1, newPrice: 32);
    expect(s.ingredient(harina.id)!.stock, closeTo(86, 1e-9));
    expect(s.ingredient(harina.id)!.price, 32);

    await s.registerProduction(s.recipe(r.id)!, 11);
    expect(s.ingredient(harina.id)!.stock, closeTo(9, 1e-9));
    expect(s.lowStock.map((i) => i.id), contains(harina.id));
    await s.db.close();
  });

  test('respaldo y restauración completos', () async {
    final (s, r) = await seedPizza();
    await s.saveFixedExpense(FixedExpense(name: 'Alquiler', monthlyAmount: 300));
    await s.setSetting('business_name', 'Pizzería Prueba');
    await s.saveCostingSnapshot(s.costing(s.recipe(r.id)!));
    final json = await s.exportBackup();

    // Borrar todo y restaurar.
    await s.deleteRecipe(r.id!);
    await s.deleteFixedExpense(s.fixedExpenses.single.id!);
    expect(s.recipes, isEmpty);

    await s.restoreBackup(json);
    expect(s.recipes.single.name, 'Masa de pizza');
    expect(s.recipes.single.items.length, 2);
    expect(s.fixedExpenses.single.monthlyAmount, 300);
    expect(s.businessName, 'Pizzería Prueba');
    expect(s.costings.length, 1);
    expect((await s.priceHistory(s.ingredients.first.id!)).isNotEmpty, isTrue);

    // Un archivo inválido no borra nada.
    await expectLater(s.restoreBackup('{"hola":1}'), throwsFormatException);
    expect(s.recipes.length, 1);
    await s.db.close();
  });

  test('gastos fijos distribuidos por unidad', () async {
    final (s, r) = await seedPizza();
    await s.saveFixedExpense(FixedExpense(name: 'Alquiler', monthlyAmount: 300));
    await s.saveFixedExpense(FixedExpense(name: 'Internet', monthlyAmount: 30));
    await s.setSetting('monthly_units', '660');
    expect(s.fixedCostPerUnit, closeTo(0.5, 1e-12));
    final rec = s.recipe(r.id)!.clone()..includeFixedCosts = true;
    final c = s.costing(rec);
    expect(c.fixedCostTotal, closeTo(5, 1e-12));
    expect(c.estimatedProfit, closeTo(c.grossProfit! - 5, 1e-12));
    await s.db.close();
  });

  test('PDF y CSV se generan', () async {
    final (s, r) = await seedPizza();
    final reg = pw.Font.ttf((await File('assets/fonts/Roboto-Regular.ttf').readAsBytes()).buffer.asByteData());
    final bold = pw.Font.ttf((await File('assets/fonts/Roboto-Bold.ttf').readAsBytes()).buffer.asByteData());
    final b = PdfBuilder(reg, bold);
    final rec = s.recipe(r.id)!
      ..extraCosts = [
        ExtraCost(type: ExtraCostType.gas, mode: ExtraCostMode.perBatch, amount: 1),
        ExtraCost(type: ExtraCostType.commission, mode: ExtraCostMode.percentOfSale, amount: 15),
      ]
      ..wastePercent = 5;
    final c = s.costing(rec);
    final pdf = await b.recipeReport(CostReport.fromCosting(c), business: 'Pizzería Ñandú');
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    expect(pdf.length, greaterThan(2000));
    await File('${tmp.path}/r.pdf').writeAsBytes(pdf);

    await s.saveCostingSnapshot(c);
    final pdf2 = await b.recipeReport(CostReport.fromSnapshot(s.costings.first), business: 'X');
    expect(String.fromCharCodes(pdf2.take(5)), '%PDF-');
    final pdf3 = await b.recipesSummary([c], business: 'X');
    expect(String.fromCharCodes(pdf3.take(5)), '%PDF-');

    final csv = CsvBuilder.ingredients(s.ingredients);
    expect(csv.startsWith('﻿'), isTrue);
    expect(csv, contains('Aceite Orisol Clásico'));
    expect(csv.split('\n').where((l) => l.trim().isNotEmpty).length, 4);
    final csvR = CsvBuilder.recipes([c]);
    expect(csvR, contains('Masa de pizza'));
    await s.db.close();
  });
}
