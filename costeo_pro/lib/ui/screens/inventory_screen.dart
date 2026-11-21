import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'costeo_hub_screen.dart';
import 'ingredient_detail_screen.dart';
import 'recipe_detail_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tracked = s.ingredients.where((i) => i.trackStock).toList()
      ..sort((a, b) => (b.isLowStock ? 1 : 0) - (a.isLowStock ? 1 : 0));
    final untracked = s.ingredients.where((i) => !i.trackStock).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            tooltip: 'Movimientos',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MovementsScreen())),
          ),
        ],
      ),
      floatingActionButton: s.recipes.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_prod',
              onPressed: () async {
                final id = await pickRecipe(context, title: '¿Qué preparaste?');
                if (id != null && context.mounted) {
                  await registerProductionDialog(context, s.recipe(id)!);
                }
              },
              icon: const Icon(Icons.soup_kitchen_rounded),
              label: const Text('Registrar producción'),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Text(
            'El inventario solo se descuenta al registrar una producción real. '
            'Consultar o simular recetas no lo modifica.',
            style: context.tt.bodySmall!.copyWith(color: context.muted),
          ),
          if (tracked.isEmpty) ...[
            const SizedBox(height: 20),
            const EmptyState(
              icon: Icons.inventory_rounded,
              title: 'Inventario opcional',
              message: 'Activa el control de existencias en los insumos que quieras seguir, '
                  'o toca "Iniciar" en la lista de abajo.',
            ),
          ] else ...[
            const SectionTitle('Con control de existencias'),
            for (final i in tracked)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StockTile(ingredient: i),
              ),
          ],
          if (untracked.isNotEmpty) ...[
            const SectionTitle('Sin control'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final i in untracked)
                  ListTile(
                    title: Text(i.name),
                    trailing: TextButton(
                      onPressed: () => showAdjustDialog(context, i, start: true),
                      child: const Text('Iniciar'),
                    ),
                  ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.ingredient});
  final Ingredient ingredient;
  @override
  Widget build(BuildContext context) {
    final i = ingredient;
    final ratio = (i.minStock != null && i.minStock! > 0) ? i.stock / (i.minStock! * 3) : (i.quantity > 0 ? i.stock / (i.quantity * 2) : 0.0);
    final color = i.isLowStock ? AppColors.danger : (i.stock < 0 ? AppColors.danger : context.positive);
    return AppCard(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => IngredientDetailScreen(ingredientId: i.id!))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          Text(Fmt.qty(i.stock, i.unit), style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        ]),
        const SizedBox(height: 8),
        RatioBar(ratio: ratio, color: color),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: Text(
              i.minStock == null ? 'Sin alerta configurada' : 'Alerta en ${Fmt.qty(i.minStock!, i.unit)}',
              style: TextStyle(color: i.isLowStock ? AppColors.danger : context.muted, fontSize: 12),
            ),
          ),
          TextButton(onPressed: () => showAdjustDialog(context, i), child: const Text('Ajustar')),
          TextButton(onPressed: () => showPurchaseDialog(context, i), child: const Text('Compra')),
        ]),
      ]),
    );
  }
}

/// Registrar compra de una o varias presentaciones.
Future<void> showPurchaseDialog(BuildContext context, Ingredient ing) async {
  final qty = TextEditingController(text: '1');
  final price = TextEditingController(text: Fmt.input(ing.price));
  final key = GlobalKey<FormState>();
  final pres = ing.presentation.isEmpty ? 'presentaciones' : ing.presentation.toLowerCase();
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('Compra de ${ing.name}'),
      content: Form(
        key: key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          NumField(
            controller: qty,
            label: 'Cantidad de $pres',
            helper: 'Cada una de ${Fmt.qty(ing.quantity, ing.unit)}',
            allowZero: false,
          ),
          const SizedBox(height: 12),
          NumField(
            controller: price,
            label: 'Precio por ${ing.presentation.isEmpty ? 'presentación' : ing.presentation.toLowerCase()}',
            prefix: r'$ ',
            required: false,
            helper: 'Si cambió, se actualizará y quedará en el historial.',
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
          onPressed: () {
            if (key.currentState!.validate()) Navigator.pop(c, true);
          },
          child: const Text('Registrar'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await context.read<AppState>().registerPurchase(ing,
      packages: Fmt.parse(qty.text)!, newPrice: Fmt.parse(price.text));
  if (context.mounted) showSnack(context, 'Compra registrada');
}

/// Ajustar existencia actual (conteo físico).
Future<void> showAdjustDialog(BuildContext context, Ingredient ing, {bool start = false}) async {
  final v = await askNumber(context,
      title: start ? 'Existencia inicial de ${ing.name}' : 'Existencia real de ${ing.name}',
      label: 'Cantidad actual',
      suffix: ing.unit.symbol,
      initial: start ? null : ing.stock,
      helper: 'Escribe lo que tienes ahora. Se registrará como ajuste.');
  if (v == null || !context.mounted) return;
  final s = context.read<AppState>();
  if (start && !ing.trackStock) {
    await s.saveIngredient(ing.copy()..trackStock = true);
  }
  final fresh = s.ingredient(ing.id)!;
  await s.adjustStock(fresh, v, note: start ? 'Existencia inicial' : 'Conteo físico');
  if (context.mounted) showSnack(context, 'Existencia actualizada');
}

class MovementsScreen extends StatelessWidget {
  const MovementsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: FutureBuilder<List<StockMovement>>(
        future: s.movements(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return const EmptyState(
                icon: Icons.receipt_long_rounded, title: 'Sin movimientos', message: 'Aún no hay compras ni producciones.');
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(indent: 16, endIndent: 16),
            itemBuilder: (_, i) {
              final m = list[i];
              final ing = s.ingredient(m.ingredientId);
              final pos = m.quantity >= 0;
              return ListTile(
                leading: Icon(
                  m.type == MovementType.production
                      ? Icons.soup_kitchen_rounded
                      : m.type == MovementType.purchase
                          ? Icons.add_shopping_cart_rounded
                          : Icons.tune_rounded,
                  color: pos ? context.positive : AppColors.danger,
                ),
                title: Text(ing?.name ?? 'Insumo'),
                subtitle: Text('${m.type.label} · ${Fmt.dateTime(m.date)}${m.note.isEmpty ? '' : '\n${m.note}'}'),
                trailing: Text(
                  '${pos ? '+' : '−'}${ing == null ? Fmt.num(m.quantity.abs()) : Fmt.qty(m.quantity.abs(), ing.unit)}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: pos ? context.positive : AppColors.danger),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
