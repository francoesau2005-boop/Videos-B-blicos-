import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calculator_screen.dart';
import 'compare_screen.dart';
import 'costing_history_screen.dart';
import 'simulator_screen.dart';

class CosteoHubScreen extends StatelessWidget {
  const CosteoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Widget tool(IconData icon, Color color, String title, String text, VoidCallback onTap) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: onTap,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(text, style: context.tt.bodySmall!.copyWith(color: context.muted)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: context.muted),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Costeo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          tool(Icons.calculate_rounded, AppColors.gold, 'Calculadora de precios',
              'Ganancia, margen, recargo y precio recomendado según tu margen objetivo.',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen()))),
          tool(Icons.science_rounded, AppColors.violet, 'Simulador de costos',
              '¿Y si sube la harina? ¿Y si saco 12 en vez de 10? Sin alterar tu receta.', () async {
            if (s.recipes.isEmpty) {
              showSnack(context, 'Primero crea una receta');
              return;
            }
            final id = await pickRecipe(context, title: '¿Qué receta quieres simular?');
            if (id != null && context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SimulatorScreen(recipeId: id)));
            }
          }),
          tool(Icons.compare_arrows_rounded, AppColors.info, 'Comparador de recetas',
              'Compara costos, rendimiento y ganancia de dos o más recetas.',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen()))),
          tool(Icons.history_rounded, AppColors.emerald, 'Historial de costeos',
              '${s.costings.length} costeo(s) guardado(s) con los precios de su fecha.',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CostingHistoryScreen()))),
        ],
      ),
    );
  }
}

/// Hoja para elegir una receta. Devuelve su id.
Future<int?> pickRecipe(BuildContext context, {String title = 'Elegir receta', Set<int> exclude = const {}}) {
  final s = context.read<AppState>();
  final list = s.recipes.where((r) => !exclude.contains(r.id)).toList();
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, sc) => ListView(controller: sc, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        if (list.isEmpty)
          const Padding(padding: EdgeInsets.all(20), child: Text('No hay recetas disponibles.')),
        for (final r in list)
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: Text(r.name),
            subtitle: Text(r.category),
            onTap: () => Navigator.pop(c, r.id),
          ),
      ]),
    ),
  );
}
