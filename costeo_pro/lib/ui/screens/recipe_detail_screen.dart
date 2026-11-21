import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/costing.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/export_service.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'compare_screen.dart';
import 'recipe_editor_screen.dart';
import 'simulator_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});
  final int recipeId;
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  /// Rendimiento temporal para ver resultados al instante (no se guarda solo).
  double? _yieldOverride;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final saved = s.recipe(widget.recipeId);
    if (saved == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Receta eliminada')));
    }
    final view = saved.clone();
    if (_yieldOverride != null) view.yieldQty = _yieldOverride!;
    final c = s.engine.cost(view);
    final yieldChanged = _yieldOverride != null && _yieldOverride != saved.yieldQty;

    return Scaffold(
      appBar: AppBar(
        title: Text(saved.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => RecipeEditorScreen(recipe: saved))),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _menu(context, v, saved, c),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'dup', child: ListTile(leading: Icon(Icons.copy_rounded), title: Text('Duplicar'))),
              PopupMenuItem(value: 'sim', child: ListTile(leading: Icon(Icons.science_rounded), title: Text('Simular cambios'))),
              PopupMenuItem(value: 'cmp', child: ListTile(leading: Icon(Icons.compare_arrows_rounded), title: Text('Comparar'))),
              PopupMenuItem(value: 'prod', child: ListTile(leading: Icon(Icons.inventory_rounded), title: Text('Registrar producción'))),
              PopupMenuItem(value: 'del', child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Eliminar'))),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            Pill(saved.category, color: context.muted),
            if (saved.parentId != null && s.recipe(saved.parentId) != null)
              Pill('Versión de ${s.recipe(saved.parentId)!.name}', color: AppColors.violet),
          ]),
          if (!c.isComplete) ...[
            const SizedBox(height: 12),
            WarningBanner(
              'Costo incompleto: ${c.problemLines.map((l) => l.name).join(', ')}. '
              'No se inventan precios: regístralos para obtener el costo real.',
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => RecipeEditorScreen(recipe: saved))),
            ),
          ],
          const SizedBox(height: 12),
          _YieldCard(
            value: view.yieldQty,
            unit: view.yieldUnit,
            changed: yieldChanged,
            onChanged: (v) => setState(() => _yieldOverride = v),
            onReset: () => setState(() => _yieldOverride = null),
            onSave: () async {
              final r = saved.clone()..yieldQty = _yieldOverride!;
              await context.read<AppState>().saveRecipe(r);
              if (!context.mounted) return;
              setState(() => _yieldOverride = null);
              showSnack(context, 'Rendimiento guardado');
            },
          ),
          const SizedBox(height: 12),
          _HeroResults(c: c),
          const SizedBox(height: 12),
          CostBreakdownCard(c: c),
          const SectionTitle('Ingredientes'),
          IngredientLinesCard(c: c),
          if (c.productionExtras.isNotEmpty || c.saleExtras.isNotEmpty || c.recipe.wastePercent > 0 || c.recipe.includeFixedCosts) ...[
            const SectionTitle('Costos adicionales'),
            ExtrasCard(c: c),
          ],
          const SectionTitle('Resultados'),
          ResultsCard(c: c),
          if (saved.notes.isNotEmpty) ...[
            const SectionTitle('Notas'),
            AppCard(child: Text(saved.notes)),
          ],
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AppState>().saveCostingSnapshot(c);
                  if (context.mounted) {
                    showSnack(context, 'Costeo guardado con los precios de hoy');
                  }
                },
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('Guardar costeo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _pdf(context, c),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('PDF'),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => SimulatorScreen(recipeId: saved.id!))),
            icon: const Icon(Icons.science_rounded),
            label: const Text('Simular cambios (sin modificar la receta)'),
          ),
        ],
      ),
    );
  }

  Future<void> _pdf(BuildContext context, RecipeCosting c) async {
    final s = context.read<AppState>();
    try {
      await ExportService.shareRecipePdf(c, businessName: s.businessName);
    } catch (e) {
      if (context.mounted) showSnack(context, 'No se pudo generar el PDF: $e', error: true);
    }
  }

  Future<void> _menu(BuildContext context, String v, Recipe r, RecipeCosting c) async {
    final s = context.read<AppState>();
    switch (v) {
      case 'dup':
        final id = await s.duplicateRecipe(r);
        if (!context.mounted) return;
        showSnack(context, 'Receta duplicada');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: id)));
        break;
      case 'sim':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SimulatorScreen(recipeId: r.id!)));
        break;
      case 'cmp':
        Navigator.push(context, MaterialPageRoute(builder: (_) => CompareScreen(initialIds: [r.id!])));
        break;
      case 'prod':
        await registerProductionDialog(context, r);
        break;
      case 'del':
        final users = s.recipesUsingRecipe(r.id!);
        if (users.isNotEmpty) {
          showSnack(context, 'Se usa en: ${users.map((e) => e.name).join(', ')}. Quítala primero.',
              error: true);
          return;
        }
        final ok = await confirmDialog(context,
            title: '¿Eliminar "${r.name}"?',
            message: 'La receta se eliminará. Los costeos guardados se conservan en el historial.');
        if (!ok || !context.mounted) return;
        await s.deleteRecipe(r.id!);
        if (context.mounted) {
          Navigator.pop(context);
          showSnack(context, 'Receta eliminada');
        }
        break;
    }
  }
}

/// Diálogo para registrar una producción real (descuenta inventario).
Future<void> registerProductionDialog(BuildContext context, Recipe r) async {
  final s = context.read<AppState>();
  final batches = await askNumber(context,
      title: 'Registrar producción real',
      label: 'Número de preparaciones',
      initial: 1,
      allowZero: false,
      helper: 'Cada preparación rinde ${Fmt.units(r.yieldQty, r.yieldUnit)}. '
          'Se descontarán los insumos del inventario.');
  if (batches == null || !context.mounted) return;
  final req = s.engine.requirements(r, batches);
  final lines = req.entries.map((e) {
    final ing = s.ingredient(e.key)!;
    final after = ing.stock - e.value;
    return '• ${ing.name}: −${Fmt.qty(e.value, ing.unit)}'
        '${ing.trackStock ? ' (quedan ${Fmt.qty(after, ing.unit)})' : ''}';
  }).join('\n');
  final ok = await confirmDialog(context,
      title: 'Confirmar producción',
      message: '${Fmt.num(batches)} × ${r.name}\n\n$lines',
      confirm: 'Registrar',
      destructive: false);
  if (!ok || !context.mounted) return;
  await s.registerProduction(r, batches);
  if (context.mounted) showSnack(context, 'Producción registrada e inventario actualizado');
}

class _YieldCard extends StatelessWidget {
  const _YieldCard({
    required this.value,
    required this.unit,
    required this.changed,
    required this.onChanged,
    required this.onReset,
    required this.onSave,
  });
  final double value;
  final String unit;
  final bool changed;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Rendimiento', style: context.tt.bodySmall!.copyWith(color: context.muted)),
              Text(Fmt.units(value, unit),
                  style: context.tt.titleLarge!.copyWith(fontWeight: FontWeight.w800)),
            ]),
          ),
          IconButton.filledTonal(
            iconSize: 28,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            iconSize: 28,
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: 'Escribir cantidad',
            icon: const Icon(Icons.keyboard_rounded),
            onPressed: () async {
              final v = await askNumber(context,
                  title: 'Cantidad producida', initial: value, allowZero: false, suffix: unit);
              if (v != null) onChanged(v);
            },
          ),
        ]),
        if (changed)
          Row(children: [
            Expanded(
              child: Text('Vista temporal. La receta no ha cambiado.',
                  style: TextStyle(color: context.warning, fontSize: 12)),
            ),
            TextButton(onPressed: onReset, child: const Text('Restablecer')),
            TextButton(onPressed: onSave, child: const Text('Guardar')),
          ]),
      ]),
    );
  }
}

class _HeroResults extends StatelessWidget {
  const _HeroResults({required this.c});
  final RecipeCosting c;
  @override
  Widget build(BuildContext context) {
    final profit = c.grossProfitPerUnit;
    return Row(children: [
      Expanded(
        child: StatTile(
          label: 'Costo por ${_one(c.recipe.yieldUnit)}',
          value: Fmt.money(c.costPerUnit),
          icon: Icons.payments_rounded,
          color: AppColors.info,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: StatTile(
          label: 'Ganancia bruta c/u',
          value: c.hasSalePrice ? Fmt.money(profit) : '—',
          icon: Icons.trending_up_rounded,
          color: (profit ?? 0) >= 0 ? context.positive : context.negative,
          sub: c.hasSalePrice ? 'Margen ${Fmt.pct(c.grossMarginPercent)}' : 'Sin precio de venta',
        ),
      ),
    ]);
  }
}

String _one(String u) {
  final t = u.trim();
  if (t.isEmpty) return 'unidad';
  if (t.endsWith('s') && t.length > 3 && !t.contains(' ')) return t.substring(0, t.length - 1);
  return 'unidad';
}

class CostBreakdownCard extends StatelessWidget {
  const CostBreakdownCard({super.key, required this.c});
  final RecipeCosting c;
  @override
  Widget build(BuildContext context) {
    final parts = <(String, double)>[
      ('Ingredientes', c.ingredientsCost),
      if (c.wasteCost > 0) ('Merma', c.wasteCost),
      for (final e in c.productionExtras) (e.extra.displayName, e.batchAmount),
      if (c.saleExtrasTotal > 0) ('Comisiones / impuestos', c.saleExtrasTotal),
      if (c.fixedCostTotal > 0) ('Gastos fijos', c.fixedCostTotal),
    ].where((p) => p.$2 > 0).toList();
    final total = parts.fold<double>(0, (s, p) => s + p.$2);
    if (total <= 0) return const SizedBox.shrink();
    return AppCard(
      child: Row(children: [
        DonutChart(
          size: 120,
          values: parts.map((p) => p.$2).toList(),
          colors: AppColors.chart,
          center: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(Fmt.money(total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text('por lote', style: context.tt.labelSmall!.copyWith(color: context.muted)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < parts.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: AppColors.chart[i % AppColors.chart.length],
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(parts[i].$1,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  Text(Fmt.pct(parts[i].$2 / total * 100, decimals: 0),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

class IngredientLinesCard extends StatelessWidget {
  const IngredientLinesCard({super.key, required this.c});
  final RecipeCosting c;
  @override
  Widget build(BuildContext context) {
    final total = c.ingredientsCost;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: [
        for (final l in c.lines)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (l.item.isSubRecipe)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.layers_rounded, size: 16, color: context.cs.primary),
                  ),
                Expanded(
                  child: Text(l.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(
                  l.item.isSubRecipe
                      ? Fmt.units(l.item.quantity, l.subYieldUnit ?? '')
                      : Fmt.qty(l.item.quantity, l.item.unit),
                  style: TextStyle(color: context.muted),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 76,
                  child: Text(
                    l.ok ? Fmt.moneySmart(l.cost) : 'Pendiente',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: l.ok ? null : context.warning),
                  ),
                ),
              ]),
              if (l.ok && total > 0) ...[
                const SizedBox(height: 6),
                RatioBar(ratio: l.cost! / total, height: 5),
              ],
              if (!l.ok && l.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l.error!, style: TextStyle(color: context.warning, fontSize: 12)),
                ),
            ]),
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: ValueRow('Costo de ingredientes', Fmt.money(c.ingredientsCost), bold: true),
        ),
      ]),
    );
  }
}

class ExtrasCard extends StatelessWidget {
  const ExtrasCard({super.key, required this.c});
  final RecipeCosting c;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        if (c.recipe.wastePercent > 0)
          ValueRow('Merma (${Fmt.pct(c.recipe.wastePercent)} de ingredientes)', Fmt.money(c.wasteCost)),
        for (final e in c.productionExtras)
          ValueRow(e.extra.displayName, Fmt.money(e.batchAmount),
              hint: e.extra.mode == ExtraCostMode.perUnit
                  ? '${Fmt.money(e.extra.amount)} × ${Fmt.units(c.yieldQty, 'unidades')}'
                  : 'Por preparación'),
        if (c.saleExtras.isNotEmpty) const Divider(height: 20),
        for (final e in c.saleExtras)
          ValueRow(e.extra.displayName, Fmt.money(e.batchAmount),
              hint: '${Fmt.pct(e.extra.amount)} del precio de venta (gasto de venta)'),
        if (c.recipe.includeFixedCosts)
          ValueRow('Gastos fijos distribuidos', Fmt.money(c.fixedCostTotal),
              hint: c.fixedCostPerUnit > 0
                  ? '${Fmt.moneySmart(c.fixedCostPerUnit)} por unidad'
                  : 'Configura gastos fijos y producción mensual en Más'),
      ]),
    );
  }
}

class ResultsCard extends StatelessWidget {
  const ResultsCard({super.key, required this.c});
  final RecipeCosting c;
  @override
  Widget build(BuildContext context) {
    final pos = context.positive;
    final neg = context.negative;
    Color sign(double? v) => (v ?? 0) >= 0 ? pos : neg;
    return AppCard(
      child: Column(children: [
        ValueRow('Costo de ingredientes', Fmt.money(c.ingredientsCost)),
        if (c.wasteCost > 0 || c.productionExtrasTotal > 0)
          ValueRow('Merma y costos de producción', Fmt.money(c.wasteCost + c.productionExtrasTotal)),
        ValueRow('Costo total de producción', Fmt.money(c.productionCost), bold: true),
        ValueRow('Cantidad producida', Fmt.units(c.yieldQty, c.recipe.yieldUnit)),
        ValueRow('Costo por unidad', Fmt.money(c.costPerUnit), bold: true, big: true),
        const Divider(height: 24),
        if (!c.hasSalePrice)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Define un precio de venta para ver ingresos, ganancia y margen.',
              style: TextStyle(color: context.muted),
            ),
          )
        else ...[
          ValueRow('Precio de venta', Fmt.money(c.salePrice)),
          ValueRow('Ingresos potenciales', Fmt.money(c.potentialRevenue),
              hint: 'Si se vende todo lo producido'),
          ValueRow('Ganancia bruta', Fmt.money(c.grossProfit),
              bold: true, color: sign(c.grossProfit),
              hint: '${Fmt.money(c.grossProfitPerUnit)} por unidad · antes de otros gastos'),
          if (c.saleExtrasTotal > 0)
            ValueRow('Comisiones e impuestos', '−${Fmt.money(c.saleExtrasTotal)}'),
          if (c.fixedCostTotal > 0)
            ValueRow('Gastos fijos asignados', '−${Fmt.money(c.fixedCostTotal)}'),
          if (c.saleExtrasTotal > 0 || c.fixedCostTotal > 0)
            ValueRow('Ganancia estimada después de gastos registrados', Fmt.money(c.estimatedProfit),
                bold: true, color: sign(c.estimatedProfit),
                hint: '${Fmt.money(c.estimatedProfitPerUnit)} por unidad'),
          const Divider(height: 24),
          ValueRow('Margen bruto', Fmt.pct(c.grossMarginPercent),
              bold: true, color: sign(c.grossMarginPercent), hint: 'Ganancia ÷ precio de venta'),
          if (c.saleExtrasTotal > 0 || c.fixedCostTotal > 0)
            ValueRow('Margen estimado', Fmt.pct(c.estimatedMarginPercent), color: sign(c.estimatedMarginPercent)),
          ValueRow('Recargo sobre costo', Fmt.pct(c.markupPercent), hint: 'Ganancia ÷ costo'),
        ],
      ]),
    );
  }
}
