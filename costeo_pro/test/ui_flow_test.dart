import 'package:costeo_pro/data/database.dart';
import 'package:costeo_pro/main.dart';
import 'package:costeo_pro/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Recorre la app real: registrar insumos, crear receta, ver costeo,
/// cambiar rendimiento, calculadora, simulador y comparador.
void main() {
  sqfliteFfiInit();

  Future<AppState> boot(WidgetTester tester, {Size size = const Size(412, 915)}) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final db = await AppDatabase.open(inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
    final s = AppState(db);
    await s.load();
    await tester.pumpWidget(CosteoProApp(state: s));
    await tester.pumpAndSettle();
    return s;
  }

  Future<void> enter(WidgetTester tester, String label, String text) async {
    final f = find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(f.first);
    await tester.enterText(f.first, text);
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
    }
    await tester.ensureVisible(f.last);
    await tester.pumpAndSettle();
    await tester.tap(f.last);
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
  }

  Future<void> setLastQty(WidgetTester tester, String v) async {
    final f = find.widgetWithText(TextFormField, '¿Cuánto usas?').last;
    await tester.ensureVisible(f);
    await tester.enterText(f, v);
    await tester.pumpAndSettle();
  }

  Future<void> addIngredient(WidgetTester tester, String name, String qty, String unitLabel, String? price) async {
    await enter(tester, 'Nombre del producto', name);
    await enter(tester, 'Cantidad', qty);
    if (unitLabel != 'Libras (lb)') {
      await tester.ensureVisible(find.text('Libras (lb)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Libras (lb)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(unitLabel).last);
      await tester.pumpAndSettle();
    }
    if (price != null) await enter(tester, 'Precio que pagaste', price);
    await tapText(tester, 'Guardar insumo');
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Guardar insumo'), findsNothing);
  }

  testWidgets('flujo completo de costeo de pizza', (tester) async {
    final s = await boot(tester);
    expect(find.text('Empieza en 3 pasos'), findsOneWidget);

    // --- Insumos ---
    await tester.tap(find.text('Insumos').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Registrar insumo');
    await addIngredient(tester, 'Harina fuerte', '50', 'Libras (lb)', '30');
    expect(s.ingredients.single.price, 30);
    expect(find.text('Harina fuerte'), findsOneWidget);

    await tapText(tester, 'Nuevo insumo');
    await addIngredient(tester, 'Aceite Orisol', '410', 'Mililitros (ml)', '1.25');
    await tapText(tester, 'Nuevo insumo');
    await addIngredient(tester, 'Levadura', '500', 'Gramos (g)', null); // precio pendiente
    expect(s.ingredients.length, 3);
    expect(find.text('Precio pendiente'), findsOneWidget);

    // --- Receta ---
    await tester.tap(find.text('Recetas').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Nueva receta');
    await enter(tester, 'Nombre', 'Masa de pizza');

    await tapText(tester, 'Agregar ingrediente');
    await tapText(tester, 'Harina fuerte');
    await setLastQty(tester, '7');
    await tapText(tester, 'Agregar otro ingrediente');
    await tapText(tester, 'Aceite Orisol');
    await setLastQty(tester, '140');
    await tapText(tester, 'Agregar otro ingrediente');
    await tapText(tester, 'Levadura');
    await setLastQty(tester, '14');

    await enter(tester, 'Cantidad', '10');
    await tapText(tester, 'pizzas');
    await enter(tester, 'Precio de venta', '5');
    await tester.pumpAndSettle();
    // Precio pendiente visible y no inventado.
    await tester.scrollUntilVisible(find.textContaining('Falta el precio de compra de Levadura'), -150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Falta el precio de compra de Levadura'), findsOneWidget);

    // Registrar el precio desde la receta.
    await tapText(tester, 'Falta el precio de compra de Levadura. Toca para registrarlo.');
    await tester.enterText(find.byType(TextFormField).last, '5');
    await tapText(tester, 'Aceptar');
    expect(find.textContaining('Falta el precio'), findsNothing);

    await tapText(tester, 'Guardar receta');
    expect(s.recipes.single.items.length, 3);

    // --- Detalle ---
    await tapText(tester, 'Masa de pizza');
    const total = 4.2 + 140 / 410 * 1.25 + 0.14; // 4.766829…
    expect(s.costing(s.recipes.single).productionCost, closeTo(total, 1e-12));
    expect(find.text(r'$4.77'), findsWidgets); // costo total
    expect(find.text(r'$0.48'), findsWidgets); // costo por pizza
    expect(find.text('10 pizzas'), findsWidgets);

    // Cambiar rendimiento a 12 al instante (sin guardar).
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('12 pizzas'), findsWidgets);
    expect(find.text(r'$0.40'), findsWidgets); // 4.7668/12
    expect(s.recipes.single.yieldQty, 10); // la receta guardada no cambió

    // Guardar costeo.
    await tapText(tester, 'Guardar costeo');
    expect(s.costings.length, 1);

    // Duplicar como "premium" desde el menú.
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tapText(tester, 'Duplicar');
    expect(s.recipes.length, 2);

    // Volver al inicio.
    await back(tester);
    await tester.pumpAndSettle();

    // --- Calculadora ---
    await tester.tap(find.text('Costeo').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Calculadora de precios');
    await enter(tester, 'Costo de producción por unidad', '2.20');
    await enter(tester, 'Precio de venta por unidad', '5');
    await tester.pumpAndSettle();
    expect(find.text(r'$2.80'), findsWidgets);
    expect(find.text('56 %'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Precio necesario'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text(r'$4.40'), findsWidgets); // 50 % objetivo
    await back(tester);
    await tester.pumpAndSettle();

    // --- Comparador ---
    await tapText(tester, 'Comparador de recetas');
    await tapText(tester, 'Agregar receta');
    await tapText(tester, 'Masa de pizza');
    await tapText(tester, 'Agregar receta');
    await tapText(tester, 'Masa de pizza (copia)');
    expect(find.text('Cuesta menos por unidad'), findsOneWidget);
    expect(find.textContaining('Todas cuestan lo mismo'), findsOneWidget);
    expect(s.comparisons.length, 1);
    await back(tester);
    await tester.pumpAndSettle();

    // --- Simulador: no modifica datos reales ---
    final before = s.recipes.map((r) => '${r.yieldQty}|${r.salePrice}|${r.items.map((i) => i.quantity).join(',')}').toList();
    final pricesBefore = s.ingredients.map((i) => i.price).toList();
    await tapText(tester, 'Simulador de costos');
    await tapText(tester, 'Masa de pizza');
    await enter(tester, 'Rendimiento', '12');
    await enter(tester, 'Precio de venta', '5.50');
    await tester.pumpAndSettle();
    expect(find.text('SIMULADO'), findsOneWidget);
    await back(tester);
    await tester.pumpAndSettle();
    expect(s.recipes.map((r) => '${r.yieldQty}|${r.salePrice}|${r.items.map((i) => i.quantity).join(',')}').toList(), before);
    expect(s.ingredients.map((i) => i.price).toList(), pricesBefore);
    expect(s.ingredients.every((i) => i.stock == 0), isTrue);

    // --- Dashboard ---
    await tester.tap(find.text('Inicio').last);
    await tester.pumpAndSettle();
    expect(find.text('Mayor margen estimado'), findsOneWidget);
    expect(find.text('Masa de pizza'), findsWidgets);
    await s.db.close();
  });

  for (final size in const [Size(320, 568), Size(360, 640), Size(480, 1000)]) {
    testWidgets('sin desbordes en pantalla ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      final s = await boot(tester, size: size);
      for (final tab in ['Insumos', 'Recetas', 'Costeo', 'Más', 'Inicio']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Pestaña $tab');
      }
      await tester.tap(find.text('Recetas').last);
      await tester.pumpAndSettle();
      await tapText(tester, 'Nueva receta');
      expect(tester.takeException(), isNull);
      await s.db.close();
    });
  }
}
