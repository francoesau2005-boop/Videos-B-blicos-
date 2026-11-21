import 'package:costeo_pro/core/costing.dart';
import 'package:costeo_pro/core/format.dart';
import 'package:costeo_pro/core/units.dart';
import 'package:costeo_pro/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Conversiones de unidades', () {
    test('libras a gramos y kilos', () {
      expect(convert(1, Unit.lb, Unit.g), closeTo(453.59237, 1e-9));
      expect(convert(50, Unit.lb, Unit.kg), closeTo(22.6796185, 1e-9));
      expect(convert(1, Unit.kg, Unit.lb), closeTo(2.2046226218, 1e-9));
    });

    test('onzas de peso', () {
      expect(convert(16, Unit.oz, Unit.lb), closeTo(1, 1e-12));
      expect(convert(4, Unit.oz, Unit.g), closeTo(113.3980925, 1e-9));
    });

    test('onzas líquidas y litros', () {
      expect(convert(1, Unit.floz, Unit.ml), closeTo(29.5735295625, 1e-9));
      expect(convert(1, Unit.l, Unit.ml), 1000);
      expect(convert(1, Unit.gal, Unit.floz), closeTo(128, 1e-9));
    });

    test('oz de peso y fl oz NO son intercambiables sin densidad', () {
      expect(() => convert(1, Unit.oz, Unit.floz), throwsA(isA<UnitConversionException>()));
      expect(canConvert(Unit.oz, Unit.floz), isFalse);
    });

    test('gramos a mililitros requiere densidad', () {
      expect(() => convert(100, Unit.g, Unit.ml), throwsA(isA<UnitConversionException>()));
      // Aceite con densidad 0.92 g/ml: 92 g = 100 ml.
      expect(convert(92, Unit.g, Unit.ml, density: 0.92), closeTo(100, 1e-9));
      expect(convert(100, Unit.ml, Unit.g, density: 0.92), closeTo(92, 1e-9));
    });

    test('unidades no se convierten a peso', () {
      expect(() => convert(1, Unit.unit, Unit.g), throwsA(isA<UnitConversionException>()));
    });

    test('ida y vuelta conserva precisión', () {
      final v = convert(convert(7, Unit.lb, Unit.g), Unit.g, Unit.lb);
      expect(v, closeTo(7, 1e-12));
    });
  });

  group('Costo de la cantidad utilizada', () {
    test('Aceite: 140 ml de bolsa de 410 ml a \$1.25', () {
      final c = ProfitMath.usageCost(
          usedQty: 140, usedUnit: Unit.ml, purchaseQty: 410,
          purchaseUnit: Unit.ml, purchasePrice: 1.25);
      expect(c, closeTo(0.426829268, 1e-9));
      expect(Fmt.money(c), r'$0.43');
    });

    test('Harina: 7 lb de un saco de 50 lb', () {
      final c = ProfitMath.usageCost(
          usedQty: 7, usedUnit: Unit.lb, purchaseQty: 50,
          purchaseUnit: Unit.lb, purchasePrice: 30);
      expect(c, closeTo(4.2, 1e-12));
    });

    test('Queso: 300 g de un paquete de 5 lb', () {
      final c = ProfitMath.usageCost(
          usedQty: 300, usedUnit: Unit.g, purchaseQty: 5,
          purchaseUnit: Unit.lb, purchasePrice: 10);
      // 300 g = 0.661387 lb ; /5 × 10 = 1.322774
      expect(c, closeTo(300 / 453.59237 / 5 * 10, 1e-12));
    });

    test('Azúcar: 4 oz de bolsa de 2 lb', () {
      final c = ProfitMath.usageCost(
          usedQty: 4, usedUnit: Unit.oz, purchaseQty: 2,
          purchaseUnit: Unit.lb, purchasePrice: 1);
      expect(c, closeTo(0.125, 1e-12));
    });

    test('Levadura, consomé y huevos', () {
      expect(ProfitMath.usageCost(usedQty: 14, usedUnit: Unit.g, purchaseQty: 500,
          purchaseUnit: Unit.g, purchasePrice: 5), closeTo(0.14, 1e-12));
      expect(ProfitMath.usageCost(usedQty: 3, usedUnit: Unit.g, purchaseQty: 10,
          purchaseUnit: Unit.g, purchasePrice: 0.25), closeTo(0.075, 1e-12));
      expect(ProfitMath.usageCost(usedQty: 4, usedUnit: Unit.unit, purchaseQty: 30,
          purchaseUnit: Unit.unit, purchasePrice: 4.5), closeTo(0.6, 1e-12));
    });

    test('cantidad comprada cero lanza error (sin división entre cero)', () {
      expect(() => ProfitMath.usageCost(usedQty: 1, usedUnit: Unit.g, purchaseQty: 0,
          purchaseUnit: Unit.g, purchasePrice: 1), throwsA(isA<UnitConversionException>()));
    });
  });

  group('Margen y recargo', () {
    test('pizza: costo 2.20, precio 5.00', () {
      expect(5 - 2.20, closeTo(2.80, 1e-12));
      expect(ProfitMath.marginPercent(2.20, 5), closeTo(56, 1e-9));
      expect(ProfitMath.markupPercent(2.20, 5), closeTo(127.2727, 1e-4));
    });

    test('precio para margen objetivo', () {
      expect(ProfitMath.priceForMargin(2.20, 30), closeTo(3.142857, 1e-6));
      expect(ProfitMath.priceForMargin(2.20, 40), closeTo(3.666667, 1e-6));
      expect(ProfitMath.priceForMargin(2.20, 50), closeTo(4.40, 1e-9));
      expect(ProfitMath.priceForMargin(2.20, 100), isNull);
      expect(ProfitMath.priceForMargin(2.20, -5), isNull);
    });

    test('precio con recargo', () {
      expect(ProfitMath.priceForMarkup(2, 50), closeTo(3, 1e-12));
    });

    test('valores inválidos devuelven null', () {
      expect(ProfitMath.marginPercent(1, 0), isNull);
      expect(ProfitMath.markupPercent(0, 5), isNull);
    });
  });

  group('Receta: masa de pizza', () {
    late Map<int, Ingredient> ings;
    late Recipe masa;

    setUp(() {
      ings = {
        1: Ingredient(id: 1, name: 'Harina fuerte', quantity: 50, unit: Unit.lb, price: 30),
        2: Ingredient(id: 2, name: 'Aceite', quantity: 410, unit: Unit.ml, price: 1.25),
        3: Ingredient(id: 3, name: 'Levadura', quantity: 500, unit: Unit.g, price: 5),
        4: Ingredient(id: 4, name: 'Sal', quantity: 1, unit: Unit.kg, price: null),
      };
      masa = Recipe(id: 10, name: 'Masa', yieldQty: 10, yieldUnit: 'pizzas', salePrice: 5, items: [
        RecipeItem(ingredientId: 1, quantity: 7, unit: Unit.lb),
        RecipeItem(ingredientId: 2, quantity: 140, unit: Unit.ml),
        RecipeItem(ingredientId: 3, quantity: 14, unit: Unit.g),
      ]);
    });

    test('costo total, por pizza, ingresos, ganancia y margen', () {
      final e = CostingEngine(CostingContext(ingredients: ings, recipes: {10: masa}));
      final c = e.cost(masa);
      final expected = 4.2 + 140 / 410 * 1.25 + 0.14;
      expect(c.isComplete, isTrue);
      expect(c.ingredientsCost, closeTo(expected, 1e-12));
      expect(c.productionCost, closeTo(expected, 1e-12));
      expect(c.costPerUnit, closeTo(expected / 10, 1e-12));
      expect(c.potentialRevenue, 50);
      expect(c.grossProfit, closeTo(50 - expected, 1e-12));
      expect(c.grossMarginPercent, closeTo((50 - expected) / 50 * 100, 1e-9));
    });

    test('cambiar el rendimiento a 12 pizzas recalcula al instante', () {
      final e = CostingEngine(CostingContext(ingredients: ings, recipes: {10: masa}));
      final c10 = e.cost(masa);
      masa.yieldQty = 12;
      final c12 = e.cost(masa);
      expect(c12.ingredientsCost, closeTo(c10.ingredientsCost, 1e-12));
      expect(c12.costPerUnit, closeTo(c10.ingredientsCost / 12, 1e-12));
      expect(c12.potentialRevenue, 60);
    });

    test('precio pendiente: no se inventa, costo marcado incompleto', () {
      masa.items.add(RecipeItem(ingredientId: 4, quantity: 30, unit: Unit.g));
      final c = CostingEngine(CostingContext(ingredients: ings, recipes: {10: masa})).cost(masa);
      expect(c.isComplete, isFalse);
      expect(c.problemLines.single.name, 'Sal');
      expect(c.problemLines.single.missingPrice, isTrue);
    });

    test('unidad incompatible se reporta como error', () {
      masa.items.add(RecipeItem(ingredientId: 3, quantity: 1, unit: Unit.ml));
      final c = CostingEngine(CostingContext(ingredients: ings, recipes: {10: masa})).cost(masa);
      expect(c.isComplete, isFalse);
      expect(c.problemLines.single.error, contains('densidad'));
    });

    test('rendimiento cero no divide entre cero', () {
      masa.yieldQty = 0;
      final c = CostingEngine(CostingContext(ingredients: ings, recipes: {10: masa})).cost(masa);
      expect(c.costPerUnit, 0);
      expect(c.costPerUnit.isFinite, isTrue);
    });
  });

  group('Costos adicionales', () {
    test('por preparación, por unidad, % de venta, merma y gastos fijos', () {
      final ings = {1: Ingredient(id: 1, name: 'X', quantity: 1, unit: Unit.unit, price: 10)};
      final r = Recipe(
        id: 1, name: 'R', yieldQty: 10, salePrice: 5, wastePercent: 10,
        includeFixedCosts: true,
        items: [RecipeItem(ingredientId: 1, quantity: 1, unit: Unit.unit)],
        extraCosts: [
          ExtraCost(type: ExtraCostType.gas, mode: ExtraCostMode.perBatch, amount: 2),
          ExtraCost(type: ExtraCostType.packaging, mode: ExtraCostMode.perUnit, amount: 0.30),
          ExtraCost(type: ExtraCostType.commission, mode: ExtraCostMode.percentOfSale, amount: 20),
        ],
      );
      final c = CostingEngine(CostingContext(
              ingredients: ings, recipes: {1: r}, fixedCostPerUnit: 0.25))
          .cost(r);
      expect(c.ingredientsCost, 10);
      expect(c.wasteCost, closeTo(1, 1e-12));
      expect(c.productionExtrasTotal, closeTo(2 + 3, 1e-12));
      expect(c.productionCost, closeTo(16, 1e-12));
      expect(c.costPerUnit, closeTo(1.6, 1e-12));
      expect(c.grossProfit, closeTo(50 - 16, 1e-12));
      expect(c.saleExtrasTotal, closeTo(10, 1e-12)); // 20 % de 50
      expect(c.fixedCostTotal, closeTo(2.5, 1e-12));
      expect(c.estimatedProfit, closeTo(34 - 10 - 2.5, 1e-12));
      expect(c.estimatedMarginPercent, closeTo(21.5 / 50 * 100, 1e-9));
    });

    test('sin precio de venta no se muestra ganancia', () {
      final r = Recipe(id: 1, name: 'R', yieldQty: 5);
      final c = CostingEngine(CostingContext(ingredients: {}, recipes: {1: r})).cost(r);
      expect(c.grossProfit, isNull);
      expect(c.estimatedProfit, isNull);
    });
  });

  group('Recetas compuestas', () {
    test('pizza usa 1 bola de masa + queso', () {
      final ings = {
        1: Ingredient(id: 1, name: 'Harina', quantity: 50, unit: Unit.lb, price: 30),
        2: Ingredient(id: 2, name: 'Queso', quantity: 5, unit: Unit.lb, price: 10),
      };
      final masa = Recipe(id: 1, name: 'Masa', yieldQty: 10, yieldUnit: 'bolas', items: [
        RecipeItem(ingredientId: 1, quantity: 7, unit: Unit.lb),
      ]);
      final pizza = Recipe(id: 2, name: 'Pizza', yieldQty: 1, salePrice: 5, items: [
        RecipeItem(subRecipeId: 1, quantity: 1, unit: Unit.unit),
        RecipeItem(ingredientId: 2, quantity: 300, unit: Unit.g),
      ]);
      final e = CostingEngine(CostingContext(ingredients: ings, recipes: {1: masa, 2: pizza}));
      final c = e.cost(pizza);
      expect(c.lines.first.cost, closeTo(0.42, 1e-12));
      expect(c.ingredientsCost, closeTo(0.42 + 300 / 453.59237 / 5 * 10, 1e-12));

      // Requerimientos de inventario expanden la sub-receta.
      final req = e.requirements(pizza, 2);
      expect(req[1], closeTo(1.4, 1e-12)); // 2 × 0.7 lb
      expect(req[2], closeTo(2 * 300 / 453.59237, 1e-12));
    });

    test('referencia circular no entra en bucle', () {
      final a = Recipe(id: 1, name: 'A', yieldQty: 1, items: [RecipeItem(subRecipeId: 2, quantity: 1, unit: Unit.unit)]);
      final b = Recipe(id: 2, name: 'B', yieldQty: 1, items: [RecipeItem(subRecipeId: 1, quantity: 1, unit: Unit.unit)]);
      final e = CostingEngine(CostingContext(ingredients: {}, recipes: {1: a, 2: b}));
      final c = e.cost(a);
      expect(c.isComplete, isFalse);
      expect(e.forbiddenSubRecipes(1), containsAll([1, 2]));
    });
  });

  group('Formato y lectura de números', () {
    test('acepta coma o punto decimal', () {
      expect(Fmt.parse('1,25'), 1.25);
      expect(Fmt.parse('1.25'), 1.25);
      expect(Fmt.parse('1,234.5'), 1234.5);
      expect(Fmt.parse('1.234,5'), 1234.5);
      expect(Fmt.parse(r'$5'), 5);
      expect(Fmt.parse('abc'), isNull);
      expect(Fmt.parse(''), isNull);
    });

    test('moneda redondea solo al mostrar', () {
      expect(Fmt.money(0.4268292), r'$0.43');
      expect(Fmt.money(-1.2), r'-$1.20');
      expect(Fmt.money(1234.5), r'$1,234.50');
      expect(Fmt.pct(56), '56 %');
    });
  });

  group('Piezas por presentación', () {
    test('paquete de 4 lb con 12 tortas: usar 12 tortas cuesta el paquete', () {
      final tortas = Ingredient(id: 1, name: 'Tortas', quantity: 4, unit: Unit.lb, price: 1, pieces: 12);
      expect(unitsForIngredient(tortas), contains(Unit.unit));
      final r = Recipe(id: 1, name: 'Hamburguesas', yieldQty: 12, items: [
        RecipeItem(ingredientId: 1, quantity: 12, unit: Unit.unit),
      ]);
      final e = CostingEngine(CostingContext(ingredients: {1: tortas}, recipes: {1: r}));
      expect(e.cost(r).ingredientsCost, closeTo(1.0, 1e-12));
      expect(e.requirements(r, 1)[1], closeTo(4, 1e-12)); // 4 lb
      // Usar 12 lb son 3 paquetes.
      r.items.first.unit = Unit.lb;
      expect(e.cost(r).ingredientsCost, closeTo(3.0, 1e-12));
    });

    test('sin piezas registradas no se puede usar "unidades" con un insumo por peso', () {
      final x = Ingredient(id: 1, name: 'X', quantity: 4, unit: Unit.lb, price: 1);
      expect(unitsForIngredient(x), isNot(contains(Unit.unit)));
      expect(() => toPurchaseUnit(x, 1, Unit.unit), throwsA(isA<UnitConversionException>()));
    });
  });
}
