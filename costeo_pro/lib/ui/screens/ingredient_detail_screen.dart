import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/units.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ingredient_form_screen.dart';
import 'ingredients_screen.dart';
import 'inventory_screen.dart';
import 'recipe_detail_screen.dart';

class IngredientDetailScreen extends StatelessWidget {
  const IngredientDetailScreen({super.key, required this.ingredientId});
  final int ingredientId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ing = s.ingredient(ingredientId);
    if (ing == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Insumo eliminado')));
    }
    final used = s.recipesUsingIngredient(ing.id!);
    return Scaffold(
      appBar: AppBar(
        title: Text(ing.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => IngredientFormScreen(ingredient: ing))),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') await _delete(context, ing, used);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Eliminar insumo')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (ing.photoPath != null && File(ing.photoPath!).existsSync())
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.file(File(ing.photoPath!), fit: BoxFit.cover),
                ),
              ),
            ),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IngredientAvatar(ingredient: ing, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                        '${ing.presentation.isEmpty ? 'Presentación' : ing.presentation} de '
                        '${Fmt.qty(ing.quantity, ing.unit)}'
                        '${ing.hasPieces ? ' · ${Fmt.num(ing.pieces)} piezas' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Pill(ing.category, color: context.muted),
                  ]),
                ),
              ]),
              const Divider(height: 28),
              if (ing.price == null)
                WarningBanner('Precio de compra pendiente. Toca para registrarlo.',
                    onTap: () => _quickPrice(context, ing))
              else ...[
                ValueRow('Precio de compra', Fmt.money(ing.price), bold: true, big: true),
                const SizedBox(height: 6),
                Wrap(spacing: 14, runSpacing: 6, children: [
                  for (final u in compatibleUnits(ing.unit, density: ing.density))
                    Text(
                      '${Fmt.moneySmart(ing.price! / convert(ing.quantity, ing.unit, u, density: ing.density))} / ${u.symbol}',
                      style: TextStyle(color: context.muted, fontWeight: FontWeight.w600),
                    ),
                  if (ing.hasPieces)
                    Text('${Fmt.moneySmart(ing.price! / ing.pieces!)} / pieza',
                        style: TextStyle(color: context.muted, fontWeight: FontWeight.w600)),
                ]),
              ],
              const SizedBox(height: 10),
              if (ing.brand.isNotEmpty) ValueRow('Marca', ing.brand),
              if (ing.supplier.isNotEmpty) ValueRow('Proveedor', ing.supplier),
              if (ing.purchaseDate != null) ValueRow('Fecha de compra', Fmt.date(ing.purchaseDate)),
              if (ing.density != null) ValueRow('Densidad', '${Fmt.num(ing.density, maxDecimals: 4)} g/ml'),
              if (ing.notes.isNotEmpty) ValueRow('Notas', ing.notes),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _quickPrice(context, ing),
                icon: const Icon(Icons.price_change_rounded),
                label: const Text('Nuevo precio'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showPurchaseDialog(context, ing),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Compra'),
              ),
            ),
          ]),
          if (ing.trackStock) ...[
            const SectionTitle('Existencias'),
            AppCard(
              child: Column(children: [
                ValueRow('Existencia actual', Fmt.qty(ing.stock, ing.unit),
                    bold: true, color: ing.isLowStock ? AppColors.danger : null),
                if (ing.minStock != null) ValueRow('Alerta en', Fmt.qty(ing.minStock!, ing.unit)),
                if (ing.quantity > 0)
                  ValueRow('Equivale a',
                      '${Fmt.num(ing.stock / ing.quantity)} ${ing.presentation.isEmpty ? 'presentaciones' : ing.presentation.toLowerCase()}'),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => showAdjustDialog(context, ing),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Ajustar existencia'),
                  ),
                ),
              ]),
            ),
          ],
          SectionTitle('Usado en ${used.length} receta(s)'),
          if (used.isEmpty)
            Text('Todavía no se usa en recetas.', style: TextStyle(color: context.muted))
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final r in used)
                  ListTile(
                    leading: const Icon(Icons.menu_book_rounded),
                    title: Text(r.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id!))),
                  ),
              ]),
            ),
          const SectionTitle('Historial de precios'),
          _PriceHistory(ingredient: ing, key: ValueKey(ing.updatedAt)),
        ],
      ),
    );
  }

  Future<void> _quickPrice(BuildContext context, Ingredient ing) async {
    final v = await askNumber(context,
        title: 'Precio de ${ing.presentation.isEmpty ? 'la presentación' : ing.presentation.toLowerCase()} '
            'de ${Fmt.qty(ing.quantity, ing.unit)}',
        label: 'Precio total',
        prefix: r'$ ',
        initial: ing.price,
        helper: 'El precio anterior se conserva en el historial.');
    if (v == null || !context.mounted) return;
    final upd = ing.copy()
      ..price = v
      ..purchaseDate = DateTime.now();
    await context.read<AppState>().saveIngredient(upd, note: 'Actualización de precio');
    if (context.mounted) showSnack(context, 'Precio actualizado');
  }

  Future<void> _delete(BuildContext context, Ingredient ing, List<Recipe> used) async {
    if (used.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('No se puede eliminar'),
          content: Text('Este insumo se usa en: ${used.map((r) => r.name).join(', ')}.\n\n'
              'Quítalo de esas recetas primero.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Entendido'))],
        ),
      );
      return;
    }
    final ok = await confirmDialog(context,
        title: '¿Eliminar "${ing.name}"?',
        message: 'Se eliminará el insumo junto con su historial de precios y movimientos. '
            'Esta acción no se puede deshacer.');
    if (!ok || !context.mounted) return;
    await context.read<AppState>().deleteIngredient(ing.id!);
    if (context.mounted) {
      Navigator.pop(context);
      showSnack(context, 'Insumo eliminado');
    }
  }
}

class _PriceHistory extends StatelessWidget {
  const _PriceHistory({super.key, required this.ingredient});
  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PriceRecord>>(
      future: context.read<AppState>().priceHistory(ingredient.id!),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
              padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return Text('Sin registros de precio.', style: TextStyle(color: context.muted));
        }
        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < list.length; i++)
              _historyTile(context, list[i], i + 1 < list.length ? list[i + 1] : null),
          ]),
        );
      },
    );
  }

  Widget _historyTile(BuildContext context, PriceRecord r, PriceRecord? prev) {
    double? changePct;
    if (prev != null && prev.costPerBase > 0) {
      changePct = (r.costPerBase - prev.costPerBase) / prev.costPerBase * 100;
    }
    return ListTile(
      title: Text('${Fmt.money(r.price)} · ${Fmt.qty(r.quantity, r.unit)}',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text([
        Fmt.date(r.date),
        if (r.supplier.isNotEmpty) r.supplier,
        if (r.note.isNotEmpty) r.note,
      ].join(' · ')),
      trailing: changePct == null || changePct.abs() < 0.05
          ? null
          : Pill('${changePct > 0 ? '+' : ''}${Fmt.pct(changePct)}',
              color: changePct > 0 ? AppColors.danger : context.positive,
              icon: changePct > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded),
    );
  }
}
