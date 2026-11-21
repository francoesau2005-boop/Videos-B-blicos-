import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/export_service.dart';
import '../../services/report_builder.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class CostingHistoryScreen extends StatelessWidget {
  const CostingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de costeos')),
      body: s.costings.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: 'Sin costeos guardados',
              message: 'En el detalle de una receta toca "Guardar costeo". Se conservarán los precios '
                  'usados ese día aunque después cambien.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: s.costings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = s.costings[i];
                return AppCard(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => CostingSnapshotScreen(snapshot: c))),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.recipeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(Fmt.dateTime(c.date), style: TextStyle(color: context.muted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Total ${Fmt.money(c.productionCost)} · ${Fmt.units(c.yieldQty, c.yieldUnit)}',
                            style: context.tt.bodySmall),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(Fmt.money(c.costPerUnit),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('costo c/u', style: TextStyle(color: context.muted, fontSize: 11)),
                      if (c.marginPercent != null)
                        Text('Margen ${Fmt.pct(c.marginPercent)}',
                            style: TextStyle(color: context.positive, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ]),
                );
              },
            ),
    );
  }
}

/// Detalle de un costeo guardado (precios históricos congelados).
class CostingSnapshotScreen extends StatelessWidget {
  const CostingSnapshotScreen({super.key, required this.snapshot});
  final CostingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final r = CostReport.fromSnapshot(snapshot);
    final lines = (r.detail['lines'] as List?) ?? [];
    final s = context.read<AppState>();
    final current = snapshot.recipeId == null ? null : s.recipe(snapshot.recipeId);
    final nowCpu = current == null ? null : s.costing(current).costPerUnit;

    return Scaffold(
      appBar: AppBar(
        title: Text(snapshot.recipeName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () async {
              try {
                await ExportService.shareSnapshotPdf(snapshot, businessName: s.businessName);
              } catch (e) {
                if (context.mounted) showSnack(context, 'Error: $e', error: true);
              }
            },
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: '¿Eliminar este costeo?', message: 'Se borrará del historial.');
              if (!ok || !context.mounted) return;
              await s.deleteCosting(snapshot.id!);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Pill('Precios del ${Fmt.dateTime(snapshot.date)}', icon: Icons.lock_clock_rounded),
          if (nowCpu != null && (nowCpu - snapshot.costPerUnit).abs() > 0.0005) ...[
            const SizedBox(height: 12),
            WarningBanner(
              'Con los precios actuales el costo por unidad es ${Fmt.money(nowCpu)} '
              '(${nowCpu > snapshot.costPerUnit ? '+' : '−'}${Fmt.money((nowCpu - snapshot.costPerUnit).abs())}).',
              icon: Icons.compare_arrows_rounded,
              color: AppColors.info,
            ),
          ],
          const SectionTitle('Ingredientes y precios usados'),
          AppCard(
            child: Column(children: [
              for (final l in lines)
                ValueRow(
                  '${l['name']}',
                  l['cost'] == null ? 'Pendiente' : Fmt.moneySmart((l['cost'] as num).toDouble()),
                  hint: '${Fmt.num((l['quantity'] as num?)?.toDouble(), maxDecimals: 3)} ${l['unit'] ?? ''}'
                      '${l['package_price'] != null ? ' · de ${Fmt.num((l['package_qty'] as num?)?.toDouble(), maxDecimals: 3)} ${l['package_unit']} a ${Fmt.money((l['package_price'] as num).toDouble())}' : ''}',
                ),
            ]),
          ),
          const SectionTitle('Resultados'),
          AppCard(
            child: Column(children: [
              ValueRow('Costo de ingredientes', Fmt.money(r.ingredientsCost)),
              ValueRow('Costo total de producción', Fmt.money(r.productionCost), bold: true),
              ValueRow('Cantidad producida', Fmt.units(r.yieldQty, r.yieldUnit)),
              ValueRow('Costo por unidad', Fmt.money(r.costPerUnit), bold: true, big: true),
              if (r.salePrice != null) ...[
                const Divider(height: 22),
                ValueRow('Precio de venta', Fmt.money(r.salePrice)),
                ValueRow('Ingresos potenciales', Fmt.money(r.revenue)),
                ValueRow('Ganancia bruta', Fmt.money(r.grossProfit), bold: true),
                if (r.estimatedProfit != null && r.estimatedProfit != r.grossProfit)
                  ValueRow('Ganancia estimada después de gastos registrados', Fmt.money(r.estimatedProfit)),
                ValueRow('Margen bruto', Fmt.pct(r.grossMargin), bold: true),
                ValueRow('Recargo sobre costo', Fmt.pct(r.markup)),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
