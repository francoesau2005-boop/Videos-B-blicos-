import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/csv_builder.dart';
import '../../services/export_service.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'costing_history_screen.dart';
import 'inventory_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Widget tile(IconData icon, Color color, String title, String sub, VoidCallback onTap) => ListTile(
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        );
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              tile(Icons.inventory_rounded, AppColors.emerald, 'Inventario',
                  '${s.ingredients.where((i) => i.trackStock).length} insumo(s) con existencias'
                  '${s.lowStock.isEmpty ? '' : ' · ${s.lowStock.length} bajo(s)'}',
                  () => go(const InventoryScreen())),
              tile(Icons.account_balance_wallet_rounded, AppColors.gold, 'Gastos fijos',
                  '${Fmt.money(s.totalFixedMonthly)} al mes', () => go(const FixedExpensesScreen())),
              tile(Icons.history_rounded, AppColors.info, 'Historial de costeos',
                  '${s.costings.length} guardado(s)', () => go(const CostingHistoryScreen())),
            ]),
          ),
          const SectionTitle('Datos'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              tile(Icons.ios_share_rounded, AppColors.violet, 'Exportar y reportes',
                  'PDF y CSV de insumos, recetas y costeos', () => go(const ExportScreen())),
              tile(Icons.backup_rounded, AppColors.emerald, 'Copias de seguridad',
                  'Crear, compartir y restaurar', () => go(const BackupScreen())),
            ]),
          ),
          const SectionTitle('Ajustes'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.storefront_rounded),
                title: const Text('Nombre del negocio'),
                subtitle: Text(s.businessName.isEmpty ? 'Aparece en los reportes PDF' : s.businessName),
                trailing: const Icon(Icons.edit_rounded),
                onTap: () async {
                  final ctrl = TextEditingController(text: s.businessName);
                  final v = await showDialog<String>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Nombre del negocio'),
                      content: TextField(
                        controller: ctrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(hintText: 'Ej.: Pizzería Don Luis'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
                        FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
                            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
                            child: const Text('Guardar')),
                      ],
                    ),
                  );
                  if (v != null) await s.setSetting('business_name', v);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tema', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Oscuro')),
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Claro')),
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android_rounded), label: Text('Sistema')),
                      ],
                      selected: {s.themeMode},
                      onSelectionChanged: (v) => s.setTheme(v.first),
                    ),
                  ),
                ]),
              ),
              const ListTile(
                leading: Icon(Icons.attach_money_rounded),
                title: Text('Moneda'),
                subtitle: Text('Dólar estadounidense (USD)'),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('Costeo Pro 1.0 · Funciona sin internet\nTus datos se guardan solo en este teléfono.',
                textAlign: TextAlign.center, style: context.tt.bodySmall!.copyWith(color: context.muted)),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Gastos fijos
// ------------------------------------------------------------------
class FixedExpensesScreen extends StatelessWidget {
  const FixedExpensesScreen({super.key});

  Future<void> _edit(BuildContext context, [FixedExpense? f]) async {
    final s = context.read<AppState>();
    final name = TextEditingController(text: f?.name ?? '');
    final amount = TextEditingController(text: Fmt.input(f?.monthlyAmount));
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(f == null ? 'Nuevo gasto fijo' : 'Editar gasto fijo'),
        content: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Concepto', hintText: 'Alquiler, internet…'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            NumField(controller: amount, label: 'Monto mensual', prefix: r'$ '),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await s.saveFixedExpense(FixedExpense(
        id: f?.id, name: name.text.trim(), monthlyAmount: Fmt.parse(amount.text) ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos fijos')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_fixed',
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar gasto'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Text(
            'Los gastos fijos (alquiler, internet, sueldos fijos…) se reparten entre las unidades que '
            'produces al mes. Actívalos en cada receta con "Incluir gastos fijos distribuidos".',
            style: context.tt.bodySmall!.copyWith(color: context.muted),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: StatTile(label: 'Total mensual', value: Fmt.money(s.totalFixedMonthly), icon: Icons.calendar_month_rounded, color: AppColors.gold)),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Por unidad producida',
                value: s.monthlyUnits > 0 ? Fmt.moneySmart(s.fixedCostPerUnit) : '—',
                icon: Icons.pie_chart_rounded,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.factory_rounded),
              title: const Text('Unidades producidas al mes'),
              subtitle: Text(s.monthlyUnits > 0
                  ? '${Fmt.num(s.monthlyUnits)} unidades (estimado)'
                  : 'Requerido para repartir los gastos'),
              trailing: const Icon(Icons.edit_rounded),
              onTap: () async {
                final v = await askNumber(context,
                    title: 'Unidades producidas al mes',
                    label: 'Unidades',
                    initial: s.monthlyUnits > 0 ? s.monthlyUnits : null,
                    allowZero: false,
                    helper: 'Ej.: si vendes 25 pizzas al día por 26 días: 650.');
                if (v != null) await s.setSetting('monthly_units', Fmt.input(v));
              },
            ),
          ),
          const SectionTitle('Gastos'),
          if (s.fixedExpenses.isEmpty)
            Text('Sin gastos fijos registrados.', style: TextStyle(color: context.muted))
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final f in s.fixedExpenses)
                  ListTile(
                    title: Text(f.name),
                    subtitle: Text('${Fmt.money(f.monthlyAmount)} / mes'),
                    onTap: () => _edit(context, f),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        final ok = await confirmDialog(context,
                            title: '¿Eliminar "${f.name}"?', message: 'Se quitará de los gastos fijos.');
                        if (ok) await s.deleteFixedExpense(f.id!);
                      },
                    ),
                  ),
              ]),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Exportar
// ------------------------------------------------------------------
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  Future<void> _run(BuildContext context, Future<(String, Uint8List, String)> Function() build) async {
    try {
      final (name, bytes, mime) = await build();
      if (!context.mounted) return;
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (c) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Compartir'),
              subtitle: const Text('WhatsApp, correo, Drive…'),
              onTap: () => Navigator.pop(c, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt_rounded),
              title: const Text('Guardar en el teléfono'),
              subtitle: const Text('Elige la carpeta (ej. Descargas)'),
              onTap: () => Navigator.pop(c, 'save'),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      );
      if (choice == null) return;
      final f = await ExportService.writeLocal(name, bytes);
      if (choice == 'share') {
        await ExportService.share(f, mime: mime);
      } else {
        final ok = await ExportService.saveToDevice(name, bytes, mime);
        if (context.mounted) showSnack(context, ok ? 'Archivo guardado' : 'Guardado cancelado');
      }
    } catch (e) {
      if (context.mounted) showSnack(context, 'No se pudo exportar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Widget item(IconData icon, String title, String sub, Future<(String, Uint8List, String)> Function() b) =>
        ListTile(
          leading: Icon(icon, color: context.cs.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.ios_share_rounded),
          onTap: () => _run(context, b),
        );
    final costings = [for (final r in s.recipes) s.costing(r)];
    final stamp = ExportService.stamp();

    return Scaffold(
      appBar: AppBar(title: const Text('Exportar y reportes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const SectionTitle('PDF', padding: EdgeInsets.fromLTRB(4, 4, 4, 10)),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              item(Icons.picture_as_pdf_rounded, 'Resumen de todas las recetas',
                  '${s.recipes.length} receta(s) con costo, precio y margen', () async {
                final b = await ExportService.pdfBuilder();
                final bytes = await b.recipesSummary(costings, business: s.businessName);
                return ('Resumen_recetas_$stamp.pdf', bytes, 'application/pdf');
              }),
              ListTile(
                leading: Icon(Icons.description_rounded, color: context.muted),
                title: const Text('Reporte de una receta'),
                subtitle: const Text('Desde el detalle de la receta, botón "PDF"'),
              ),
            ]),
          ),
          const SectionTitle('CSV (Excel, Hojas de cálculo)'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              item(Icons.inventory_2_rounded, 'Insumos', '${s.ingredients.length} registro(s)', () async =>
                  ('Insumos_$stamp.csv', ExportService.utf8Bytes(CsvBuilder.ingredients(s.ingredients)), 'text/csv')),
              item(Icons.menu_book_rounded, 'Recetas (resumen)', 'Costos, precio, ganancia y margen', () async =>
                  ('Recetas_$stamp.csv', ExportService.utf8Bytes(CsvBuilder.recipes(costings)), 'text/csv')),
              item(Icons.list_alt_rounded, 'Ingredientes por receta', 'Detalle de cantidades y costos', () async =>
                  ('Recetas_detalle_$stamp.csv', ExportService.utf8Bytes(CsvBuilder.recipeLines(costings)), 'text/csv')),
              item(Icons.history_rounded, 'Historial de costeos', '${s.costings.length} costeo(s)', () async =>
                  ('Costeos_$stamp.csv', ExportService.utf8Bytes(CsvBuilder.costings(s.costings)), 'text/csv')),
              item(Icons.show_chart_rounded, 'Historial de precios', 'Todos los cambios de precio', () async {
                final hist = <int, List<PriceRecord>>{};
                for (final i in s.ingredients) {
                  hist[i.id!] = await s.priceHistory(i.id!);
                }
                return ('Historial_precios_$stamp.csv',
                    ExportService.utf8Bytes(CsvBuilder.priceHistory(s.ingredients, hist)), 'text/csv');
              }),
            ]),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Copias de seguridad
// ------------------------------------------------------------------
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  List<File> _local = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final l = await ExportService.localBackups();
    if (mounted) setState(() => _local = l);
  }

  Future<void> _create({required bool share}) async {
    setState(() => _busy = true);
    try {
      final s = context.read<AppState>();
      final json = await s.exportBackup();
      final name = 'CosteoPro_respaldo_${ExportService.stamp()}.json';
      final bytes = ExportService.utf8Bytes(json);
      final f = await ExportService.writeLocal(name, bytes, folder: 'respaldos');
      if (share) {
        await ExportService.share(f, mime: 'application/json');
      } else {
        final ok = await ExportService.saveToDevice(name, bytes, 'application/json');
        if (mounted) showSnack(context, ok ? 'Respaldo guardado' : 'Guardado cancelado (queda copia interna)');
      }
      await _refresh();
    } catch (e) {
      if (mounted) showSnack(context, 'Error al crear respaldo: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(String? json) async {
    if (json == null) return;
    final ok = await confirmDialog(context,
        title: '¿Restaurar respaldo?',
        message: 'Se reemplazarán TODOS los datos actuales (insumos, recetas, historial) por los del respaldo. '
            'Antes se guardará una copia automática de tus datos actuales.',
        confirm: 'Restaurar');
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final s = context.read<AppState>();
    try {
      await ExportService.autoBackup(await s.exportBackup(), keep: 10);
      await s.restoreBackup(json);
      if (mounted) showSnack(context, 'Datos restaurados correctamente');
      await _refresh();
    } catch (e) {
      if (mounted) showSnack(context, 'No se pudo restaurar: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copias de seguridad')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (_busy) const LinearProgressIndicator(),
            Text(
              'El respaldo incluye insumos, historial de precios, recetas, costos adicionales, gastos fijos, '
              'inventario, costeos y ajustes. Las fotos de insumos no se incluyen.',
              style: context.tt.bodySmall!.copyWith(color: context.muted),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _create(share: true),
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('Crear y compartir respaldo'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _create(share: false),
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Guardar respaldo en el teléfono'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final json = await ExportService.pickBackupFile();
                  await _restore(json);
                } catch (e) {
                  if (context.mounted) showSnack(context, 'No se pudo leer el archivo: $e', error: true);
                }
              },
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Restaurar desde archivo'),
            ),
            SectionTitle('Copias en este teléfono (${_local.length})'),
            Text('Se crea una copia automática diaria al abrir la app.',
                style: context.tt.bodySmall!.copyWith(color: context.muted)),
            const SizedBox(height: 8),
            if (_local.isNotEmpty)
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (final f in _local.take(15))
                    ListTile(
                      leading: const Icon(Icons.description_rounded),
                      title: Text(f.uri.pathSegments.last, style: const TextStyle(fontSize: 13)),
                      subtitle: Text('${Fmt.dateTime(f.lastModifiedSync())} · ${(f.lengthSync() / 1024).toStringAsFixed(1)} KB'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'restore') await _restore(await f.readAsString());
                          if (v == 'share') await ExportService.share(f, mime: 'application/json');
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'restore', child: Text('Restaurar')),
                          PopupMenuItem(value: 'share', child: Text('Compartir')),
                        ],
                      ),
                    ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
