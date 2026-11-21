import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/costing.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'recipe_detail_screen.dart';

/// Simulador: cambia cantidades, precios, rendimiento y precio de venta en
/// memoria. Nada se guarda en la base de datos salvo que el usuario guarde
/// la simulación como una NUEVA versión de receta.
class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key, required this.recipeId});
  final int recipeId;
  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  Recipe? _sim;
  final Map<int, double> _priceOverrides = {};
  final List<TextEditingController> _qty = [];
  late final TextEditingController _yield, _price;

  @override
  void initState() {
    super.initState();
    final r = context.read<AppState>().recipe(widget.recipeId);
    if (r != null) {
      _sim = r.clone();
      for (final i in _sim!.items) {
        _qty.add(TextEditingController(text: Fmt.input(i.quantity)));
      }
    }
    _yield = TextEditingController(text: Fmt.input(_sim?.yieldQty));
    _price = TextEditingController(text: Fmt.input(_sim?.salePrice));
  }

  @override
  void dispose() {
    for (final c in _qty) {
      c.dispose();
    }
    _yield.dispose();
    _price.dispose();
    super.dispose();
  }

  Recipe _current() {
    final r = _sim!.clone();
    for (var i = 0; i < r.items.length; i++) {
      r.items[i].quantity = Fmt.parse(_qty[i].text) ?? 0;
    }
    r.yieldQty = Fmt.parse(_yield.text) ?? 0;
    r.salePrice = Fmt.parse(_price.text);
    return r;
  }

  CostingContext _simContext(AppState s) {
    if (_priceOverrides.isEmpty) return s.context;
    final ings = Map<int, Ingredient>.from(s.context.ingredients);
    _priceOverrides.forEach((id, price) {
      final base = ings[id];
      if (base != null) ings[id] = base.copy()..price = price;
    });
    return s.context.copyWith(ingredients: ings);
  }

  void _reset() {
    final r = context.read<AppState>().recipe(widget.recipeId)!;
    setState(() {
      _priceOverrides.clear();
      for (var i = 0; i < r.items.length && i < _qty.length; i++) {
        _qty[i].text = Fmt.input(r.items[i].quantity);
      }
      _yield.text = Fmt.input(r.yieldQty);
      _price.text = Fmt.input(r.salePrice);
    });
  }

  Future<void> _saveAsVersion(Recipe original) async {
    final s = context.read<AppState>();
    final versions = s.recipes.where((r) => r.parentId == original.id).length;
    final nameCtrl = TextEditingController(text: '${original.name} (versión ${versions + 2})');
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Guardar como nueva versión'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
          if (_priceOverrides.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Los precios de insumos simulados no se guardan en tu catálogo: la nueva '
              'receta usará los precios reales registrados.',
              style: TextStyle(color: c.warning, fontSize: 13),
            ),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
            onPressed: () => Navigator.pop(c, nameCtrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final cur = _current();
    if (cur.yieldQty <= 0) {
      showSnack(context, 'El rendimiento debe ser mayor que cero', error: true);
      return;
    }
    final nr = cur.clone(asNew: true)
      ..name = name
      ..parentId = original.id;
    nr.items.removeWhere((i) => i.quantity <= 0);
    final id = await s.saveRecipe(nr);
    if (!mounted) return;
    showSnack(context, 'Nueva versión guardada. La receta original no cambió.');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final original = s.recipe(widget.recipeId);
    if (original == null || _sim == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Receta no encontrada')));
    }
    final a = s.engine.cost(original);
    final b = CostingEngine(_simContext(s)).cost(_current());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador'),
        actions: [
          TextButton(onPressed: _reset, child: const Text('Restablecer')),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => _saveAsVersion(original),
            icon: const Icon(Icons.save_as_rounded),
            label: const Text('Guardar como nueva versión'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(original.name, style: context.tt.titleLarge!.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Pill('Modo simulación · tu receta no se modifica', color: AppColors.violet, icon: Icons.science_rounded),
          const SizedBox(height: 14),
          _ComparisonTable(a: a, b: b),
          const SectionTitle('Producción y venta'),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: NumField(
                controller: _yield,
                label: 'Rendimiento',
                suffix: original.yieldUnit,
                required: false,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumField(
                controller: _price,
                label: 'Precio de venta',
                prefix: r'$ ',
                required: false,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ActionChip(
              label: const Text('+1 rendimiento'),
              onPressed: () => setState(() => _yield.text = Fmt.input((Fmt.parse(_yield.text) ?? 0) + 1)),
            ),
            ActionChip(
              label: const Text(r'+$0.50 precio'),
              onPressed: () => setState(() => _price.text = Fmt.input((Fmt.parse(_price.text) ?? 0) + 0.5)),
            ),
          ]),
          const SectionTitle('Ingredientes'),
          for (var i = 0; i < _sim!.items.length; i++) _itemRow(context, s, i, b),
        ],
      ),
    );
  }

  Widget _itemRow(BuildContext context, AppState s, int i, RecipeCosting b) {
    final item = _sim!.items[i];
    final ing = item.isSubRecipe ? null : s.ingredient(item.ingredientId);
    final sub = item.isSubRecipe ? s.recipe(item.subRecipeId) : null;
    final override = ing == null ? null : _priceOverrides[ing.id];
    final line = i < b.lines.length ? b.lines[i] : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(ing?.name ?? sub?.name ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Text(line?.ok == true ? Fmt.moneySmart(line!.cost) : 'Pendiente',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: NumField(
                controller: _qty[i],
                label: 'Cantidad',
                suffix: item.isSubRecipe ? (sub?.yieldUnit ?? 'u') : item.unit.symbol,
                required: false,
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (ing != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: override != null ? AppColors.violet : null,
                    side: override != null ? const BorderSide(color: AppColors.violet) : null,
                  ),
                  onPressed: () async {
                    final v = await askNumber(context,
                        title: 'Precio simulado de ${ing.name}',
                        label: 'Precio de ${Fmt.qty(ing.quantity, ing.unit)}',
                        prefix: r'$ ',
                        initial: override ?? ing.price,
                        helper: 'Solo para esta simulación. Tu catálogo no cambia.');
                    if (v != null) setState(() => _priceOverrides[ing.id!] = v);
                  },
                  child: FittedBox(
                    child: Text(override != null
                        ? 'Precio ${Fmt.money(override)}'
                        : (ing.price == null ? 'Simular precio' : 'Precio ${Fmt.money(ing.price)}')),
                  ),
                ),
              ),
            ],
          ]),
          if (override != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _priceOverrides.remove(ing.id)),
                child: Text('Volver al precio real (${Fmt.money(ing!.price)})'),
              ),
            ),
        ]),
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.a, required this.b});
  final RecipeCosting a;
  final RecipeCosting b;

  @override
  Widget build(BuildContext context) {
    TableRow row(String label, double? x, double? y, {bool money = true, bool higherIsBetter = false, bool bold = false}) {
      final diff = (x != null && y != null) ? y - x : null;
      Color? dc;
      if (diff != null && diff.abs() > 1e-9) {
        final good = higherIsBetter ? diff > 0 : diff < 0;
        dc = good ? context.positive : context.negative;
      }
      String f(double? v) => money ? Fmt.money(v) : Fmt.pct(v);
      String fd(double? v) {
        if (v == null) return '—';
        if (v.abs() < 1e-9) return '=';
        final sgn = v > 0 ? '+' : '−';
        return money ? '$sgn${Fmt.money(v.abs())}' : '$sgn${Fmt.num(v.abs(), maxDecimals: 1)} pts';
      }

      final st = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: 13.5);
      return TableRow(children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(label, style: st)),
        Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(f(x), textAlign: TextAlign.right, style: st)),
        Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(f(y), textAlign: TextAlign.right, style: st.copyWith(color: AppColors.violet))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(fd(diff), textAlign: TextAlign.right, style: st.copyWith(color: dc, fontWeight: FontWeight.w700))),
      ]);
    }

    final head = context.tt.labelSmall!.copyWith(color: context.muted, fontWeight: FontWeight.w700);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(1.7), 1: FlexColumnWidth(1.1), 2: FlexColumnWidth(1.1), 3: FlexColumnWidth(1.1)},
          children: [
            TableRow(children: [
              Text('', style: head),
              Text('ACTUAL', textAlign: TextAlign.right, style: head),
              Text('SIMULADO', textAlign: TextAlign.right, style: head),
              Text('DIFERENCIA', textAlign: TextAlign.right, style: head),
            ]),
            row('Costo total', a.productionCost, b.productionCost),
            row('Costo c/u', a.costPerUnit, b.costPerUnit, bold: true),
            row('Precio venta', a.salePrice, b.salePrice, higherIsBetter: true),
            row('Ganancia c/u', a.grossProfitPerUnit, b.grossProfitPerUnit, higherIsBetter: true, bold: true),
            row('Ganancia lote', a.grossProfit, b.grossProfit, higherIsBetter: true),
            row('Margen', a.grossMarginPercent, b.grossMarginPercent, money: false, higherIsBetter: true),
          ],
        ),
        if (!b.isComplete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Hay ingredientes sin precio: el resultado está incompleto.',
                style: TextStyle(color: context.warning, fontSize: 12)),
          ),
      ]),
    );
  }
}
