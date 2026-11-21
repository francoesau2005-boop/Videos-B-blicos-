// Genera capturas de pantalla reales de la app (con fuentes reales) para
// revisar el diseño. Ejecutar con:
//   flutter test test_screens/screenshots_test.dart --update-goldens
// Los datos de ejemplo aquí son SOLO para la captura, no se incluyen en la app.
import 'dart:io';

import 'package:costeo_pro/core/units.dart';
import 'package:costeo_pro/data/database.dart';
import 'package:costeo_pro/main.dart';
import 'package:costeo_pro/models/models.dart';
import 'package:costeo_pro/services/report_builder.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:costeo_pro/state/app_state.dart';
import 'package:costeo_pro/ui/screens/calculator_screen.dart';
import 'package:costeo_pro/ui/screens/compare_screen.dart';
import 'package:costeo_pro/ui/screens/home_shell.dart';
import 'package:costeo_pro/ui/screens/recipe_detail_screen.dart';
import 'package:costeo_pro/ui/screens/recipe_editor_screen.dart';
import 'package:costeo_pro/ui/screens/simulator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.view(File(f).readAsBytesSync().buffer)));
  }
  await l.load();
}

void main() {
  sqfliteFfiInit();
  const mf = '/opt/sdk/flutter/bin/cache/artifacts/material_fonts';

  setUpAll(() async {
    await _font('Roboto', ['$mf/Roboto-Regular.ttf', '$mf/Roboto-Medium.ttf', '$mf/Roboto-Bold.ttf', '$mf/Roboto-Black.ttf']);
    await _font('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
  });

  Future<AppState> seed() async {
    final db = await AppDatabase.open(inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
    final s = AppState(db);
    await s.load();
    await s.setSetting('business_name', 'Pizzería Demo');
    final ing = <String, Ingredient>{};
    Future<void> add(String n, String cat, String pres, double q, Unit u, double? p) async {
      final i = Ingredient(name: n, category: cat, presentation: pres, quantity: q, unit: u, price: p);
      await s.saveIngredient(i);
      ing[n] = i;
    }

    await add('Harina fuerte', 'Harinas', 'Saco', 50, Unit.lb, 32);
    await add('Aceite Orisol Clásico', 'Aceites y grasas', 'Bolsa', 410, Unit.ml, 1.25);
    await add('Levadura', 'Panadería', 'Bolsa', 500, Unit.g, 4.5);
    await add('Azúcar', 'Condimentos', 'Bolsa', 2, Unit.lb, 1.1);
    await add('Sal', 'Condimentos', 'Bolsa', 1, Unit.kg, 0.6);
    await add('Queso mozzarella', 'Lácteos', 'Paquete', 5, Unit.lb, 14);
    await add('Pepperoni', 'Carnes', 'Paquete', 1, Unit.lb, 5.5);
    await add('Huevos', 'Lácteos', 'Cartón', 30, Unit.unit, 4.5);
    await add('Salsa de tomate', 'Salsas', 'Bote', 3, Unit.l, null);

    final masa = Recipe(name: 'Masa de pizza original', category: 'Masas', yieldQty: 10, yieldUnit: 'bolas de masa', items: [
      RecipeItem(ingredientId: ing['Harina fuerte']!.id, quantity: 7, unit: Unit.lb),
      RecipeItem(ingredientId: ing['Aceite Orisol Clásico']!.id, quantity: 140, unit: Unit.ml),
      RecipeItem(ingredientId: ing['Levadura']!.id, quantity: 14, unit: Unit.g),
      RecipeItem(ingredientId: ing['Azúcar']!.id, quantity: 4, unit: Unit.oz),
      RecipeItem(ingredientId: ing['Sal']!.id, quantity: 30, unit: Unit.g),
    ]);
    await s.saveRecipe(masa);
    final premium = masa.clone(asNew: true)
      ..name = 'Masa de pizza premium'
      ..yieldQty = 12;
    premium.items[1].quantity = 200;
    premium.items.add(RecipeItem(ingredientId: ing['Huevos']!.id, quantity: 4, unit: Unit.unit));
    await s.saveRecipe(premium);
    final pep = Recipe(name: 'Pizza de pepperoni', category: 'Pizzas', yieldQty: 1, yieldUnit: 'pizzas', salePrice: 5, items: [
      RecipeItem(subRecipeId: masa.id, quantity: 1, unit: Unit.unit),
      RecipeItem(ingredientId: ing['Queso mozzarella']!.id, quantity: 150, unit: Unit.g),
      RecipeItem(ingredientId: ing['Pepperoni']!.id, quantity: 60, unit: Unit.g),
    ], extraCosts: [
      ExtraCost(type: ExtraCostType.packaging, mode: ExtraCostMode.perUnit, amount: 0.35),
      ExtraCost(type: ExtraCostType.gas, mode: ExtraCostMode.perBatch, amount: 0.15),
    ]);
    await s.saveRecipe(pep);
    final queso = Recipe(name: 'Pizza de queso', category: 'Pizzas', yieldQty: 1, yieldUnit: 'pizzas', salePrice: 4.5, items: [
      RecipeItem(subRecipeId: masa.id, quantity: 1, unit: Unit.unit),
      RecipeItem(ingredientId: ing['Queso mozzarella']!.id, quantity: 200, unit: Unit.g),
    ]);
    await s.saveRecipe(queso);
    await s.saveCostingSnapshot(s.costing(s.recipe(pep.id)!));
    await s.recordComparison([masa.id!, premium.id!]);
    // PDF de ejemplo.
    final b = PdfBuilder(pw.Font.ttf(File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync().buffer.asByteData()),
        pw.Font.ttf(File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync().buffer.asByteData()));
    final pepC = s.costing(s.recipe(pep.id)!..wastePercent = 3..includeFixedCosts = false);
    File('test_screens/shots/reporte_ejemplo.pdf')
        .writeAsBytesSync(await b.recipeReport(CostReport.fromCosting(pepC), business: 'Pizzería Demo'));
    return s;
  }

  Future<void> shot(WidgetTester tester, String name, {bool dark = true}) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
  }

  testWidgets('capturas', (tester) async {
    tester.view.physicalSize = const Size(412, 892) * 2.0;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final s = await seed();
    await tester.pumpWidget(CosteoProApp(state: s));
    await tester.pumpAndSettle();
    await shot(tester, '01_inicio');

    currentTab.value = 1;
    await shot(tester, '02_insumos');
    currentTab.value = 2;
    await shot(tester, '03_recetas');
    currentTab.value = 3;
    await shot(tester, '04_costeo');
    currentTab.value = 4;
    await shot(tester, '05_mas');
    currentTab.value = 0;

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    final pep = s.recipes.firstWhere((r) => r.name == 'Pizza de pepperoni');
    nav.push(MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: pep.id!)));
    await shot(tester, '06_detalle_receta');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -700));
    await shot(tester, '07_detalle_receta_2');
    nav.pop();
    await tester.pumpAndSettle();

    final masa = s.recipes.firstWhere((r) => r.name == 'Masa de pizza original');
    nav.push(MaterialPageRoute(builder: (_) => RecipeEditorScreen(recipe: masa)));
    await shot(tester, '08_editor');
    nav.pop();
    await tester.pumpAndSettle();

    nav.push(MaterialPageRoute(builder: (_) => const CalculatorScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '2.20');
    await tester.enterText(find.byType(TextFormField).at(1), '5');
    await tester.enterText(find.byType(TextFormField).at(2), '100');
    await shot(tester, '09_calculadora');
    nav.pop();
    await tester.pumpAndSettle();

    final prem = s.recipes.firstWhere((r) => r.name == 'Masa de pizza premium');
    nav.push(MaterialPageRoute(builder: (_) => CompareScreen(initialIds: [masa.id!, prem.id!])));
    await shot(tester, '10_comparador');
    nav.pop();
    await tester.pumpAndSettle();

    nav.push(MaterialPageRoute(builder: (_) => SimulatorScreen(recipeId: pep.id!)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '5.50');
    await shot(tester, '11_simulador');
    nav.pop();
    await tester.pumpAndSettle();

    await s.setSetting('theme', 'light');
    await tester.pumpAndSettle();
    await shot(tester, '12_inicio_claro');
    nav.push(MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: pep.id!)));
    await shot(tester, '13_detalle_claro');
    await s.db.close();
  });
}
