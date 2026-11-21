import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/costing.dart';
import '../../core/format.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calculator_screen.dart';
import 'compare_screen.dart';
import 'costing_history_screen.dart';
import 'home_shell.dart';
import 'ingredient_detail_screen.dart';
import 'ingredient_form_screen.dart';
import 'inventory_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_editor_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final engine = s.engine;
    final costed = <RecipeCosting>[
      for (final r in s.recipes) engine.cost(r),
    ];
    final ranked = costed
        .where((c) => c.isComplete && c.hasSalePrice && c.grossMarginPercent != null)
        .toList()
      ..sort((a, b) => b.grossMarginPercent!.compareTo(a.grossMarginPercent!));
    final top = ranked.take(5).toList();
    final hello = s.businessName.isEmpty ? 'Costeo Pro' : s.businessName;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.emerald, Color(0xFF1B8F70)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.insights_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(hello,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.tt.titleLarge!.copyWith(fontWeight: FontWeight.w800)),
                    Text('Costos y ganancias de tu negocio',
                        style: context.tt.bodySmall!.copyWith(color: context.muted)),
                  ]),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList.list(children: [
              Row(children: [
                Expanded(
                  child: StatTile(
                    label: 'Recetas registradas',
                    value: '${s.recipes.length}',
                    icon: Icons.menu_book_rounded,
                    onTap: () => currentTab.value = 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    label: 'Insumos registrados',
                    value: '${s.ingredients.length}',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.info,
                    onTap: () => currentTab.value = 1,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_rounded,
                    label: 'Nueva receta',
                    color: context.cs.primary,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RecipeEditorScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.calculate_rounded,
                    label: 'Calcular ganancia',
                    color: AppColors.gold,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CalculatorScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_shopping_cart_rounded,
                    label: 'Nuevo insumo',
                    color: AppColors.info,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const IngredientFormScreen())),
                  ),
                ),
              ]),
              ),
              if (s.missingPrice.isNotEmpty) ...[
                const SizedBox(height: 12),
                WarningBanner(
                  '${s.missingPrice.length} insumo(s) sin precio de compra. '
                  'Regístralo para completar los costeos.',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => IngredientDetailScreen(
                              ingredientId: s.missingPrice.first.id!))),
                ),
              ],
              if (s.lowStock.isNotEmpty) ...[
                const SizedBox(height: 12),
                WarningBanner(
                  'Existencias bajas: ${s.lowStock.map((i) => i.name).take(3).join(', ')}'
                  '${s.lowStock.length > 3 ? '…' : ''}',
                  icon: Icons.inventory_rounded,
                  color: AppColors.danger,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                ),
              ],
              if (s.recipes.isEmpty && s.ingredients.isEmpty) ...[
                const SizedBox(height: 20),
                _Onboarding(),
              ],
              SectionTitle('Mayor margen estimado',
                  trailing: Text('margen bruto', style: context.tt.bodySmall!.copyWith(color: context.muted))),
              if (top.isEmpty)
                AppCard(
                  child: Text(
                    'Aquí verás tus productos con mayor margen cuando tengas recetas '
                    'con precio de venta y todos sus precios de insumos registrados.',
                    style: context.tt.bodyMedium!.copyWith(color: context.muted),
                  ),
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    for (final c in top)
                      InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RecipeDetailScreen(recipeId: c.recipe.id!))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(
                                child: Text(c.recipe.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              Text(Fmt.pct(c.grossMarginPercent),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: (c.grossMarginPercent ?? 0) >= 0
                                          ? context.positive
                                          : context.negative)),
                            ]),
                            const SizedBox(height: 6),
                            RatioBar(
                                ratio: (c.grossMarginPercent ?? 0) / 100,
                                color: (c.grossMarginPercent ?? 0) >= 0
                                    ? context.positive
                                    : context.negative),
                            const SizedBox(height: 4),
                            Text(
                              'Costo ${Fmt.money(c.costPerUnit)} · Venta ${Fmt.money(c.salePrice)} '
                              '· Ganancia ${Fmt.money(c.grossProfitPerUnit)} por ${_singular(c.recipe.yieldUnit)}',
                              style: context.tt.bodySmall!.copyWith(color: context.muted),
                            ),
                          ]),
                        ),
                      ),
                  ]),
                ),
              SectionTitle('Últimos costeos',
                  trailing: s.costings.isEmpty
                      ? null
                      : TextButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const CostingHistoryScreen())),
                          child: const Text('Ver todos'))),
              if (s.costings.isEmpty)
                AppCard(
                  child: Text(
                    'Guarda un costeo desde el detalle de una receta para conservar '
                    'los precios usados en esa fecha.',
                    style: context.tt.bodyMedium!.copyWith(color: context.muted),
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (final c in s.costings.take(4))
                      ListTile(
                        leading: const Icon(Icons.receipt_long_rounded),
                        title: Text(c.recipeName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(Fmt.dateTime(c.date)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(Fmt.money(c.costPerUnit),
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text('por unidad',
                                style: context.tt.labelSmall!.copyWith(color: context.muted)),
                          ],
                        ),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CostingSnapshotScreen(snapshot: c))),
                      ),
                  ]),
                ),
              SectionTitle('Comparaciones recientes',
                  trailing: TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CompareScreen())),
                      child: const Text('Comparar'))),
              if (s.comparisons.isEmpty)
                AppCard(
                  child: Text(
                    'Compara dos o más recetas para ver cuál cuesta menos y cuál deja más ganancia.',
                    style: context.tt.bodyMedium!.copyWith(color: context.muted),
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (final c in s.comparisons.take(4))
                      ListTile(
                        leading: const Icon(Icons.compare_arrows_rounded),
                        title: Text(
                          c.recipeIds.map((i) => s.recipe(i)?.name ?? '(eliminada)').join(' vs '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(Fmt.dateTime(c.date)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final ids = c.recipeIds.where((i) => s.recipe(i) != null).toList();
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => CompareScreen(initialIds: ids)));
                        },
                      ),
                  ]),
                ),
              const SizedBox(height: 12),
              Text(
                'Los valores mostrados son estimaciones basadas en tus recetas y precios '
                'registrados. No representan ventas reales.',
                textAlign: TextAlign.center,
                style: context.tt.bodySmall!.copyWith(color: context.muted),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  static String _singular(String u) {
    final t = u.trim();
    if (t.endsWith('s') && t.length > 3) return t.substring(0, t.length - 1);
    return t.isEmpty ? 'unidad' : t;
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );
}

class _Onboarding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget step(String n, String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: context.cs.primary,
              child: Text(n, style: TextStyle(color: context.cs.onPrimary, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(text, style: context.tt.bodySmall!.copyWith(color: context.muted)),
              ]),
            ),
          ]),
        );
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Empieza en 3 pasos',
            style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        step('1', 'Registra tus insumos',
            'Ej.: saco de harina de 50 lb y lo que pagaste por él.'),
        step('2', 'Crea una receta',
            'Elige los insumos y escribe cuánto usas (ej. 7 lb de harina).'),
        step('3', 'Indica rendimiento y precio',
            'Ej.: 10 pizzas a \$5. La app calcula costo, ganancia y margen.'),
      ]),
    );
  }
}
