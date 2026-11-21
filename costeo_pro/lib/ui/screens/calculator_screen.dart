import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/costing.dart';
import '../../core/format.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'costeo_hub_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _cost = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _target = TextEditingController(text: '50');
  String? _source;

  @override
  void dispose() {
    for (final c in [_cost, _price, _qty, _target]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fromRecipe() async {
    final id = await pickRecipe(context, title: 'Usar costo de una receta');
    if (id == null || !mounted) return;
    final s = context.read<AppState>();
    final c = s.costing(s.recipe(id)!);
    setState(() {
      _cost.text = Fmt.input(double.parse(c.costPerUnit.toStringAsFixed(4)));
      if (c.hasSalePrice) _price.text = Fmt.input(c.salePrice);
      _source = c.isComplete ? c.recipe.name : '${c.recipe.name} (costo incompleto)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cost = Fmt.parse(_cost.text);
    final price = Fmt.parse(_price.text);
    final qty = Fmt.parse(_qty.text) ?? 0;
    final target = Fmt.parse(_target.text);
    final hasBoth = cost != null && price != null && cost >= 0 && price > 0;
    final profit = hasBoth ? price - cost : null;
    final margin = hasBoth ? ProfitMath.marginPercent(cost, price) : null;
    final markup = hasBoth ? ProfitMath.markupPercent(cost, price) : null;
    final suggested = cost != null && target != null ? ProfitMath.priceForMargin(cost, target) : null;
    Color sign(double? v) => (v ?? 0) >= 0 ? context.positive : context.negative;

    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de precios')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          OutlinedButton.icon(
            onPressed: context.read<AppState>().recipes.isEmpty ? null : _fromRecipe,
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('Tomar costo de una receta'),
          ),
          if (_source != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Costo tomado de: $_source',
                  style: context.tt.bodySmall!.copyWith(color: context.muted)),
            ),
          const SizedBox(height: 14),
          NumField(
            controller: _cost,
            label: 'Costo de producción por unidad',
            prefix: r'$ ',
            required: false,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          NumField(
            controller: _price,
            label: 'Precio de venta por unidad',
            prefix: r'$ ',
            required: false,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          NumField(
            controller: _qty,
            label: 'Cantidad que venderás',
            required: false,
            onChanged: (_) => setState(() {}),
          ),
          const SectionTitle('Resultado'),
          AppCard(
            child: !hasBoth
                ? Text('Escribe el costo y el precio de venta.', style: TextStyle(color: context.muted))
                : Column(children: [
                    ValueRow('Ingreso por unidad', Fmt.money(price)),
                    ValueRow('Costo por unidad', Fmt.money(cost)),
                    ValueRow('Ganancia por producto', Fmt.money(profit),
                        bold: true, big: true, color: sign(profit), hint: 'Antes de otros gastos'),
                    if (qty > 0) ...[
                      const Divider(height: 22),
                      ValueRow('Ingreso total (${Fmt.num(qty)} u)', Fmt.money(price * qty)),
                      ValueRow('Costo total', Fmt.money(cost * qty)),
                      ValueRow('Ganancia total', Fmt.money(profit! * qty), bold: true, color: sign(profit)),
                    ],
                    const Divider(height: 22),
                    ValueRow('Margen', Fmt.pct(margin),
                        bold: true, color: sign(margin), hint: 'Ganancia ÷ precio de venta'),
                    ValueRow('Recargo sobre costo', Fmt.pct(markup), hint: 'Ganancia ÷ costo'),
                  ]),
          ),
          const SizedBox(height: 10),
          const _MarginVsMarkupHelp(),
          const SectionTitle('Precio recomendado'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              NumField(
                controller: _target,
                label: 'Margen objetivo',
                suffix: '%',
                required: false,
                max: 99.99,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                for (final m in [30, 40, 50, 60, 70])
                  ChoiceChip(
                    label: Text('$m %'),
                    selected: target == m,
                    onSelected: (_) => setState(() => _target.text = '$m'),
                  ),
              ]),
              const SizedBox(height: 14),
              if (cost == null)
                Text('Escribe el costo para calcular el precio.', style: TextStyle(color: context.muted))
              else if (suggested == null)
                Text('El margen debe estar entre 0 % y menos de 100 %.',
                    style: TextStyle(color: context.negative))
              else ...[
                ValueRow('Precio necesario', Fmt.money(suggested), bold: true, big: true, color: AppColors.gold,
                    hint: 'Costo ÷ (1 − ${Fmt.pct(target)})'),
                ValueRow('Ganancia por unidad', Fmt.money(suggested - cost)),
                if (price != null && price > 0)
                  ValueRow(
                    'Diferencia con tu precio actual',
                    '${price >= suggested ? '+' : ''}${Fmt.money(price - suggested)}',
                    color: price >= suggested ? context.positive : context.negative,
                  ),
                const Divider(height: 22),
                Text('Tabla rápida', style: context.tt.labelLarge),
                const SizedBox(height: 6),
                for (final m in [30.0, 40.0, 50.0, 60.0])
                  ValueRow('Margen ${Fmt.pct(m, decimals: 0)}',
                      Fmt.money(ProfitMath.priceForMargin(cost, m))),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _MarginVsMarkupHelp extends StatelessWidget {
  const _MarginVsMarkupHelp();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Margen y recargo no son lo mismo. Ej.: costo \$2.20 y precio \$5.00: '
              'ganancia \$2.80; margen 56 % (sobre el precio) y recargo 127 % (sobre el costo).',
              style: context.tt.bodySmall,
            ),
          ),
        ]),
      );
}
