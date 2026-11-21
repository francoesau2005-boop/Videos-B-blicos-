import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/costing.dart';
import '../../core/format.dart';
import '../../core/units.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'costeo_hub_screen.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, this.initialIds = const []});
  final List<int> initialIds;
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late List<int> _ids = [...widget.initialIds];
  String _recorded = '';

  Future<void> _add() async {
    final id = await pickRecipe(context, title: 'Agregar receta a la comparación', exclude: _ids.toSet());
    if (id != null) setState(() => _ids = [..._ids, id]);
  }

  void _record() {
    final key = _ids.join(',');
    if (_ids.length >= 2 && key != _recorded) {
      _recorded = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppState>().recordComparison(_ids);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    _ids = _ids.where((i) => s.recipe(i) != null).toList();
    final costings = [for (final id in _ids) s.engine.cost(s.recipe(id)!)];
    _record();

    return Scaffold(
      appBar: AppBar(title: const Text('Comparador')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < costings.length; i++)
              InputChip(
                avatar: CircleAvatar(
                  backgroundColor: AppColors.chart[i % AppColors.chart.length],
                  child: Text(String.fromCharCode(65 + i),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
                label: Text(costings[i].recipe.name),
                onDeleted: () => setState(() => _ids = [..._ids]..removeAt(i)),
              ),
            ActionChip(
              avatar: const Icon(Icons.add_rounded),
              label: const Text('Agregar receta'),
              onPressed: s.recipes.length > _ids.length ? _add : null,
            ),
          ]),
          const SizedBox(height: 14),
          if (costings.length < 2)
            const EmptyState(
              icon: Icons.compare_arrows_rounded,
              title: 'Elige al menos dos recetas',
              message: 'Ej.: "Masa original" contra "Masa premium". Verás diferencias de ingredientes, '
                  'costos, rendimiento y ganancia.',
            )
          else ...[
            _Verdict(costings: costings),
            const SectionTitle('Resumen'),
            _SummaryTable(costings: costings),
            const SectionTitle('Ingredientes'),
            _IngredientsTable(costings: costings, state: s),
            const SizedBox(height: 14),
            Text(
              'La comparación usa el costo y la ganancia POR UNIDAD producida, con los precios '
              'registrados hoy. Que una receta sea más económica no significa que tenga mejor sabor o calidad.',
              style: context.tt.bodySmall!.copyWith(color: context.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.costings});
  final List<RecipeCosting> costings;

  @override
  Widget build(BuildContext context) {
    final incomplete = costings.where((c) => !c.isComplete).toList();
    final cheapest = [...costings]..sort((a, b) => a.costPerUnit.compareTo(b.costPerUnit));
    final withPrice = costings.where((c) => c.hasSalePrice).toList()
      ..sort((a, b) => b.grossProfitPerUnit!.compareTo(a.grossProfitPerUnit!));
    final ch = cheapest.first;
    final exp = cheapest.last;
    final saving = exp.costPerUnit - ch.costPerUnit;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (incomplete.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WarningBanner('Costo incompleto en: ${incomplete.map((c) => c.recipe.name).join(', ')}. '
                'La comparación puede no ser exacta.'),
          ),
        _line(context, Icons.savings_rounded, context.positive, 'Cuesta menos por unidad',
            saving.abs() < 1e-9
                ? 'Todas cuestan lo mismo por unidad (${Fmt.money(ch.costPerUnit)})'
                : '${ch.recipe.name}: ${Fmt.money(ch.costPerUnit)} — '
                    '${Fmt.money(saving)} menos que ${exp.recipe.name}'),
        const SizedBox(height: 12),
        if (withPrice.isEmpty)
          _line(context, Icons.trending_up_rounded, context.muted, 'Más ganancia por unidad',
              'Define precios de venta para comparar ganancias.')
        else if (withPrice.length > 1 &&
            (withPrice.first.grossProfitPerUnit! - withPrice[1].grossProfitPerUnit!).abs() < 1e-9)
          _line(context, Icons.trending_up_rounded, AppColors.gold, 'Más ganancia por unidad',
              'Empate: ${Fmt.money(withPrice.first.grossProfitPerUnit)} por unidad')
        else
          _line(context, Icons.trending_up_rounded, AppColors.gold, 'Deja más ganancia por unidad',
              '${withPrice.first.recipe.name}: ${Fmt.money(withPrice.first.grossProfitPerUnit)} '
              '(margen ${Fmt.pct(withPrice.first.grossMarginPercent)})'),
        if (withPrice.length < costings.length && withPrice.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Algunas recetas no tienen precio de venta y no entran en esta comparación.',
                style: TextStyle(color: context.muted, fontSize: 12)),
          ),
      ]),
    );
  }

  Widget _line(BuildContext context, IconData icon, Color color, String title, String text) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            Text(text),
          ]),
        ),
      ]);
}

Widget _scrollTable(BuildContext context, List<String> headers, List<List<Widget>> rows) {
  final head = context.tt.labelSmall!.copyWith(color: context.muted, fontWeight: FontWeight.w800);
  return AppCard(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(children: [
            for (var i = 0; i < headers.length; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 10, 8),
                child: Text(headers[i], textAlign: i == 0 ? TextAlign.left : TextAlign.right, style: head),
              ),
          ]),
          for (final r in rows)
            TableRow(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: context.cs.outlineVariant))),
              children: [
                for (final w in r) Padding(padding: const EdgeInsets.fromLTRB(6, 9, 10, 9), child: w),
              ],
            ),
        ],
      ),
    ),
  );
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.costings});
  final List<RecipeCosting> costings;

  @override
  Widget build(BuildContext context) {
    final base = costings.first;
    final headers = ['', for (var i = 0; i < costings.length; i++) String.fromCharCode(65 + i)];
    Widget l(String t) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 118),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));
    Widget v(String t, {Color? color, bool bold = false}) => Text(t,
        textAlign: TextAlign.right,
        style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: color));
    final minCpu = costings.map((c) => c.costPerUnit).reduce((a, b) => a < b ? a : b);
    final profits = costings.where((c) => c.hasSalePrice).map((c) => c.grossProfitPerUnit!);
    final maxProfit = profits.isEmpty ? null : profits.reduce((a, b) => a > b ? a : b);

    String diff(double x) {
      if (x.abs() < 1e-9) return '=';
      return x > 0 ? '+${Fmt.money(x)}' : '−${Fmt.money(-x)}';
    }

    return _scrollTable(context, headers, [
      [l('Costo total'), for (final c in costings) v(Fmt.money(c.productionCost))],
      [
        l('Diferencia vs A'),
        for (final c in costings)
          v(c == base ? '—' : diff(c.productionCost - base.productionCost),
              color: c == base
                  ? null
                  : (c.productionCost - base.productionCost) > 0
                      ? context.negative
                      : context.positive)
      ],
      [l('Rendimiento'), for (final c in costings) v(Fmt.num(c.yieldQty, maxDecimals: 3))],
      [
        l('Costo por unidad'),
        for (final c in costings)
          v(Fmt.money(c.costPerUnit), bold: true, color: (c.costPerUnit - minCpu).abs() < 1e-9 ? context.positive : null)
      ],
      [l('Precio de venta'), for (final c in costings) v(c.hasSalePrice ? Fmt.money(c.salePrice) : '—')],
      [
        l('Ganancia por unidad'),
        for (final c in costings)
          v(c.hasSalePrice ? Fmt.money(c.grossProfitPerUnit) : '—',
              bold: true,
              color: maxProfit != null && c.hasSalePrice && (c.grossProfitPerUnit! - maxProfit).abs() < 1e-9
                  ? AppColors.gold
                  : null)
      ],
      [l('Ganancia por lote'), for (final c in costings) v(c.hasSalePrice ? Fmt.money(c.estimatedProfit) : '—')],
      [l('Margen bruto'), for (final c in costings) v(Fmt.pct(c.grossMarginPercent))],
    ]);
  }
}

class _IngredientsTable extends StatelessWidget {
  const _IngredientsTable({required this.costings, required this.state});
  final List<RecipeCosting> costings;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    // Unión de ingredientes por clave (insumo o sub-receta).
    final keys = <String>[];
    final names = <String, String>{};
    final unitOf = <String, Unit?>{};
    for (final c in costings) {
      for (final l in c.lines) {
        final k = l.item.isSubRecipe ? 'r${l.item.subRecipeId}' : 'i${l.item.ingredientId}';
        if (!names.containsKey(k)) {
          keys.add(k);
          names[k] = l.name;
          unitOf[k] = l.item.isSubRecipe ? null : l.item.unit;
        }
      }
    }
    final headers = ['Ingrediente', for (var i = 0; i < costings.length; i++) String.fromCharCode(65 + i)];
    if (costings.length == 2) headers.add('Dif. B − A');

    List<Widget> rowFor(String k) {
      final qtys = <double?>[];
      final costs = <double?>[];
      for (final c in costings) {
        double? q;
        double? cost;
        for (final l in c.lines) {
          final lk = l.item.isSubRecipe ? 'r${l.item.subRecipeId}' : 'i${l.item.ingredientId}';
          if (lk != k) continue;
          var qq = l.item.quantity;
          final u = unitOf[k];
          if (u != null && l.item.unit != u) {
            final ing = state.ingredient(l.item.ingredientId);
            try {
              qq = ing == null ? convert(qq, l.item.unit, u) : toPurchaseUnit(ing, qq, l.item.unit) * convert(1, ing.unit, u, density: ing.density);
            } catch (_) {}
          }
          q = (q ?? 0) + qq;
          cost = l.cost == null ? cost : (cost ?? 0) + l.cost!;
        }
        qtys.add(q);
        costs.add(cost);
      }
      final unitLabel = unitOf[k]?.symbol ?? 'u';
      Widget cell(double? q, double? c) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(q == null ? '—' : '${Fmt.num(q, maxDecimals: 3)} $unitLabel',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (q != null)
              Text(c == null ? 'sin precio' : Fmt.moneySmart(c),
                  style: TextStyle(fontSize: 12, color: context.muted)),
          ]);
      final row = <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(names[k]!, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        for (var i = 0; i < costings.length; i++) cell(qtys[i], costs[i]),
      ];
      if (costings.length == 2) {
        final dq = (qtys[1] ?? 0) - (qtys[0] ?? 0);
        final dc = (costs[1] ?? 0) - (costs[0] ?? 0);
        row.add(Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(dq.abs() < 1e-9 ? '=' : '${dq > 0 ? '+' : '−'}${Fmt.num(dq.abs(), maxDecimals: 3)} $unitLabel',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(dc.abs() < 1e-9 ? '=' : '${dc > 0 ? '+' : '−'}${Fmt.moneySmart(dc.abs())}',
              style: TextStyle(fontSize: 12, color: dc > 0 ? context.negative : context.positive)),
        ]));
      }
      return row;
    }

    return _scrollTable(context, headers, [for (final k in keys) rowFor(k)]);
  }
}
