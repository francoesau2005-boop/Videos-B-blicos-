import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ingredient_detail_screen.dart';
import 'ingredient_form_screen.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});
  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  String _q = '';
  String? _cat;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cats = s.ingredients.map((i) => i.category).toSet().toList()..sort();
    final list = s.ingredients.where((i) {
      if (_cat != null && i.category != _cat) return false;
      if (_q.isEmpty) return true;
      final q = _q.toLowerCase();
      return i.name.toLowerCase().contains(q) ||
          i.brand.toLowerCase().contains(q) ||
          i.supplier.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Insumos')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_ing',
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const IngredientFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo insumo'),
      ),
      body: s.ingredients.isEmpty
          ? EmptyState(
              icon: Icons.inventory_2_rounded,
              title: 'Sin insumos todavía',
              message:
                  'Registra lo que compras: un saco, bolsa, bote o paquete, con su contenido y precio.',
              action: FilledButton.icon(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const IngredientFormScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Registrar insumo'),
              ),
            )
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar insumo, marca o proveedor',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _q = v.trim()),
                ),
              ),
              if (cats.length > 1)
                CategoryFilter(
                    categories: cats, selected: _cat, onSelected: (c) => setState(() => _cat = c)),
              const SizedBox(height: 6),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Sin resultados'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => IngredientTile(ingredient: list[i]),
                      ),
              ),
            ]),
    );
  }
}

class IngredientTile extends StatelessWidget {
  const IngredientTile({super.key, required this.ingredient, this.onTap});
  final Ingredient ingredient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i = ingredient;
    final pres = i.presentation.isEmpty ? '' : '${i.presentation} · ';
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap ??
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => IngredientDetailScreen(ingredientId: i.id!))),
      child: Row(children: [
        IngredientAvatar(ingredient: i),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 2),
            Text('$pres${Fmt.qty(i.quantity, i.unit)}',
                style: context.tt.bodySmall!.copyWith(color: context.muted)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              Pill(i.category, color: context.muted),
              if (i.isLowStock) const Pill('Existencia baja', color: AppColors.danger, icon: Icons.warning_rounded),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (i.price == null)
            Pill('Precio pendiente', color: context.warning)
          else ...[
            Text(Fmt.money(i.price),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('${Fmt.moneySmart(i.price! / i.quantity)}/${i.unit.symbol}',
                style: context.tt.bodySmall!.copyWith(color: context.muted)),
          ],
        ]),
      ]),
    );
  }
}

class IngredientAvatar extends StatelessWidget {
  const IngredientAvatar({super.key, required this.ingredient, this.size = 48});
  final Ingredient ingredient;
  final double size;
  @override
  Widget build(BuildContext context) {
    final path = ingredient.photoPath;
    final hasPhoto = path != null && File(path).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: context.cs.primary.withValues(alpha: 0.12),
        child: hasPhoto
            ? Image.file(File(path), fit: BoxFit.cover, cacheWidth: (size * 3).toInt())
            : Center(
                child: Text(
                  ingredient.name.isEmpty ? '?' : ingredient.name.characters.first.toUpperCase(),
                  style: TextStyle(
                      fontSize: size * 0.42, fontWeight: FontWeight.w800, color: context.cs.primary),
                ),
              ),
      ),
    );
  }
}
