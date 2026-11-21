import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/costing.dart';
import '../../core/format.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'recipe_detail_screen.dart';
import 'recipe_editor_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _q = '';
  String? _cat;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final engine = s.engine;
    final cats = s.recipes.map((r) => r.category).toSet().toList()..sort();
    final list = s.recipes.where((r) {
      if (_cat != null && r.category != _cat) return false;
      return _q.isEmpty || r.name.toLowerCase().contains(_q.toLowerCase());
    }).toList();

    // Agrupar por categoría.
    final groups = <String, List<RecipeCosting>>{};
    for (final r in list) {
      groups.putIfAbsent(r.category, () => []).add(engine.cost(r));
    }
    final keys = groups.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Recetas')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_rec',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const RecipeEditorScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nueva receta'),
      ),
      body: s.recipes.isEmpty
          ? EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'Crea tu primera receta',
              message: s.ingredients.isEmpty
                  ? 'Primero registra algunos insumos (harina, aceite, levadura…) y luego arma tu receta.'
                  : 'Selecciona insumos, indica cuánto usas y cuántas unidades produces.',
              action: FilledButton.icon(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const RecipeEditorScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Nueva receta'),
              ),
            )
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: TextField(
                  decoration: const InputDecoration(
                      hintText: 'Buscar receta', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => _q = v.trim()),
                ),
              ),
              if (cats.length > 1)
                CategoryFilter(
                    categories: cats, selected: _cat, onSelected: (c) => setState(() => _cat = c)),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Sin resultados'))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        children: [
                          for (final k in keys) ...[
                            SectionTitle(k, padding: const EdgeInsets.fromLTRB(4, 14, 4, 8)),
                            for (final c in groups[k]!)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: RecipeTile(costing: c),
                              ),
                          ]
                        ],
                      ),
              ),
            ]),
    );
  }
}

class RecipeTile extends StatelessWidget {
  const RecipeTile({super.key, required this.costing, this.onTap, this.trailing});
  final RecipeCosting costing;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = costing;
    final r = c.recipe;
    final margin = c.grossMarginPercent;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap ??
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id!))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              '${r.items.length} ingrediente(s) · rinde ${Fmt.units(r.yieldQty, r.yieldUnit)}',
              style: context.tt.bodySmall!.copyWith(color: context.muted),
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (!c.isComplete)
                Pill('Costo incompleto', color: context.warning, icon: Icons.warning_amber_rounded),
              if (margin != null && c.isComplete)
                Pill('Margen ${Fmt.pct(margin)}',
                    color: margin >= 0 ? context.positive : context.negative),
              if (!c.hasSalePrice) Pill('Sin precio de venta', color: context.muted),
            ]),
          ]),
        ),
        const SizedBox(width: 10),
        trailing ??
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Fmt.money(c.costPerUnit),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text('costo c/u', style: context.tt.labelSmall!.copyWith(color: context.muted)),
              if (c.hasSalePrice) ...[
                const SizedBox(height: 4),
                Text('Venta ${Fmt.money(c.salePrice)}',
                    style: context.tt.labelMedium!.copyWith(color: AppColors.gold)),
              ],
            ]),
      ]),
    );
  }
}
