import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/costing.dart';
import '../../core/format.dart';
import '../../core/units.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ingredient_form_screen.dart';

class _ItemRow {
  _ItemRow(this.item) : ctrl = TextEditingController(text: Fmt.input(item.quantity == 0 ? null : item.quantity));
  final RecipeItem item;
  final TextEditingController ctrl;
}

class _ExtraRow {
  _ExtraRow(this.extra)
      : amount = TextEditingController(text: Fmt.input(extra.amount == 0 ? null : extra.amount)),
        name = TextEditingController(text: extra.name);
  final ExtraCost extra;
  final TextEditingController amount;
  final TextEditingController name;
}

/// Crear o editar una receta con costeo en vivo.
class RecipeEditorScreen extends StatefulWidget {
  const RecipeEditorScreen({super.key, this.recipe});
  final Recipe? recipe;
  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _form = GlobalKey<FormState>();
  late Recipe _r;
  late final TextEditingController _name, _category, _yield, _yieldUnit, _price, _waste, _notes;
  final List<_ItemRow> _items = [];
  final List<_ExtraRow> _extras = [];
  bool _dirty = false;
  bool _saving = false;

  bool get _isNew => widget.recipe?.id == null;

  @override
  void initState() {
    super.initState();
    _r = widget.recipe?.clone() ?? Recipe(name: '', yieldQty: 10, yieldUnit: 'unidades');
    _name = TextEditingController(text: _r.name);
    _category = TextEditingController(text: _r.category);
    _yield = TextEditingController(text: Fmt.input(_r.yieldQty));
    _yieldUnit = TextEditingController(text: _r.yieldUnit);
    _price = TextEditingController(text: Fmt.input(_r.salePrice));
    _waste = TextEditingController(text: _r.wastePercent == 0 ? '' : Fmt.input(_r.wastePercent));
    _notes = TextEditingController(text: _r.notes);
    _items.addAll(_r.items.map(_ItemRow.new));
    _extras.addAll(_r.extraCosts.map(_ExtraRow.new));
    if (widget.recipe != null && widget.recipe!.id == null) _dirty = true;
  }

  @override
  void dispose() {
    for (final c in [_name, _category, _yield, _yieldUnit, _price, _waste, _notes]) {
      c.dispose();
    }
    for (final i in _items) {
      i.ctrl.dispose();
    }
    for (final e in _extras) {
      e.amount.dispose();
      e.name.dispose();
    }
    super.dispose();
  }

  /// Construye la receta a partir del formulario (para el costeo en vivo).
  Recipe _current() {
    final r = _r.clone()
      ..name = _name.text.trim()
      ..category = _category.text.trim().isEmpty ? 'General' : _category.text.trim()
      ..yieldQty = Fmt.parse(_yield.text) ?? 0
      ..yieldUnit = _yieldUnit.text.trim().isEmpty ? 'unidades' : _yieldUnit.text.trim()
      ..salePrice = Fmt.parse(_price.text)
      ..wastePercent = (Fmt.parse(_waste.text) ?? 0).clamp(0, 100).toDouble()
      ..notes = _notes.text.trim();
    r.items = [
      for (final row in _items)
        row.item.clone()..quantity = Fmt.parse(row.ctrl.text) ?? 0,
    ];
    r.extraCosts = [
      for (final row in _extras)
        row.extra.clone()
          ..amount = Fmt.parse(row.amount.text) ?? 0
          ..name = row.name.text.trim(),
    ];
    return r;
  }

  void _changed() {
    if (!_dirty) _dirty = true;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      showSnack(context, 'Revisa los campos marcados', error: true);
      return;
    }
    if (_items.isEmpty) {
      showSnack(context, 'Agrega al menos un ingrediente', error: true);
      return;
    }
    setState(() => _saving = true);
    final r = _current();
    try {
      await context.read<AppState>().saveRecipe(r);
      _dirty = false;
      if (!mounted) return;
      showSnack(context, 'Receta guardada');
      Navigator.pop(context, r.id);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) showSnack(context, 'Error al guardar: $e', error: true);
    }
  }

  Future<void> _addIngredient() async {
    final s = context.read<AppState>();
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _IngredientPicker(state: s),
    );
    if (id == null || !mounted) return;
    final ing = context.read<AppState>().ingredient(id);
    if (ing == null) return;
    setState(() {
      _items.add(_ItemRow(RecipeItem(ingredientId: id, quantity: 0, unit: ing.unit)));
      _dirty = true;
    });
  }

  Future<void> _addSubRecipe() async {
    final s = context.read<AppState>();
    final forbidden = s.engine.forbiddenSubRecipes(_r.id);
    final options = s.recipes.where((r) => !forbidden.contains(r.id)).toList();
    if (options.isEmpty) {
      showSnack(context, 'No hay otras recetas disponibles para usar como base.');
      return;
    }
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, sc) => ListView(controller: sc, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('Usar otra receta como ingrediente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text('Ej.: una pizza usa 1 bola de "Masa de pizza". El costo se toma del costo por unidad de esa receta.',
                style: TextStyle(color: c.muted)),
          ),
          for (final r in options)
            ListTile(
              leading: const Icon(Icons.layers_rounded),
              title: Text(r.name),
              subtitle: Text('Rinde ${Fmt.units(r.yieldQty, r.yieldUnit)}'),
              onTap: () => Navigator.pop(c, r.id),
            ),
        ]),
      ),
    );
    if (id == null) return;
    setState(() {
      _items.add(_ItemRow(RecipeItem(subRecipeId: id, quantity: 1, unit: Unit.unit)));
      _dirty = true;
    });
  }

  void _addExtra(ExtraCostType t) {
    setState(() {
      _extras.add(_ExtraRow(ExtraCost(type: t, mode: t.defaultMode, amount: 0)));
      _dirty = true;
    });
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final r = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Guardar cambios?'),
        content: const Text('Tienes cambios sin guardar en esta receta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'discard'), child: const Text('Descartar')),
          TextButton(onPressed: () => Navigator.pop(c, 'cancel'), child: const Text('Seguir editando')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
              onPressed: () => Navigator.pop(c, 'save'),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (r == 'save') {
      await _save();
      return false;
    }
    return r == 'discard';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final current = _current();
    final costing = s.engine.cost(current);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          _dirty = false;
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Nueva receta' : 'Editar receta'),
          actions: [
            TextButton(onPressed: _saving ? null : _save, child: const Text('Guardar')),
          ],
        ),
        bottomNavigationBar: _SummaryBar(costing: costing, onSave: _saving ? null : _save),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Nombre de la receta *', hintText: 'Ej.: Masa de pizza original'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Escribe un nombre' : null,
                onChanged: (_) => _changed(),
              ),
              const SizedBox(height: 14),
              CategoryField(controller: _category, options: s.recipeCategories),
              SectionTitle('Ingredientes (${_items.length})'),
              const _HowItWorks(),
              const SizedBox(height: 12),
              for (var i = 0; i < _items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _itemCard(context, s, i, i < costing.lines.length ? costing.lines[i] : null),
                ),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Insumo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addSubRecipe,
                    icon: const Icon(Icons.layers_rounded),
                    label: const Text('Sub-receta'),
                  ),
                ),
              ]),
              const SectionTitle('Producción y venta'),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: NumField(
                    controller: _yield,
                    label: 'Cantidad producida *',
                    allowZero: false,
                    onChanged: (_) => _changed(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _yieldUnit,
                    decoration: const InputDecoration(labelText: '¿Qué produce?', hintText: 'pizzas'),
                    onChanged: (_) => _changed(),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                for (final u in ['pizzas', 'porciones', 'unidades', 'panes', 'bolas de masa', 'donas'])
                  ActionChip(
                    label: Text(u, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _yieldUnit.text = u;
                      _changed();
                    },
                  ),
              ]),
              const SizedBox(height: 14),
              NumField(
                controller: _price,
                label: 'Precio de venta por unidad',
                prefix: r'$ ',
                required: false,
                helper: 'Déjalo vacío si esta receta es una base (ej. masa) que no vendes sola.',
                onChanged: (_) => _changed(),
              ),
              const SectionTitle('Costos adicionales (opcional)'),
              NumField(
                controller: _waste,
                label: 'Desperdicio o merma',
                suffix: '%',
                required: false,
                max: 100,
                helper: 'Porcentaje que se suma al costo de ingredientes.',
                onChanged: (_) => _changed(),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _extras.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _extraCard(context, i),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: PopupMenuButton<ExtraCostType>(
                  onSelected: _addExtra,
                  itemBuilder: (_) => [
                    for (final t in ExtraCostType.values)
                      PopupMenuItem(value: t, child: Text(t.label)),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.cs.outlineVariant),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, color: context.cs.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Agregar gasto (gas, luz, empaque…)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.cs.primary, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                value: _r.includeFixedCosts,
                title: const Text('Incluir gastos fijos distribuidos'),
                subtitle: Text(s.monthlyUnits > 0
                    ? '${Fmt.moneySmart(s.fixedCostPerUnit)} por unidad '
                        '(${Fmt.money(s.totalFixedMonthly)}/mes ÷ ${Fmt.num(s.monthlyUnits)} unidades)'
                    : 'Configura tus gastos fijos en Más → Gastos fijos'),
                onChanged: (v) => setState(() {
                  _r.includeFixedCosts = v;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notes,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Notas / preparación'),
                onChanged: (_) => _changed(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemCard(BuildContext context, AppState s, int index, LineCost? line) {
    final row = _items[index];
    final item = row.item;
    final isSub = item.isSubRecipe;
    final ing = isSub ? null : s.ingredient(item.ingredientId);
    final sub = isSub ? s.recipe(item.subRecipeId) : null;
    final name = isSub ? (sub?.name ?? 'Receta eliminada') : (ing?.name ?? 'Insumo eliminado');
    final units = ing == null ? [item.unit] : s.unitsFor(ing);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isSub ? Icons.layers_rounded : Icons.egg_alt_outlined, size: 20, color: context.cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          if (line?.cost != null)
            Text(Fmt.moneySmart(line!.cost),
                style: TextStyle(fontWeight: FontWeight.w800, color: context.positive)),
          IconButton(
            tooltip: 'Quitar',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => setState(() {
              _items.removeAt(index).ctrl.dispose();
              _dirty = true;
            }),
          ),
        ]),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 5,
              child: NumField(
                controller: row.ctrl,
                label: 'Cantidad usada',
                allowZero: false,
                onChanged: (_) => _changed(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: isSub
                  ? InputDecorator(
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      child: Text(sub?.yieldUnit ?? 'u', maxLines: 1, overflow: TextOverflow.ellipsis),
                    )
                  : UnitDropdown(
                      value: item.unit,
                      units: units,
                      compact: true,
                      onChanged: (u) => setState(() {
                        item.unit = u;
                        _dirty = true;
                      }),
                    ),
            ),
          ]),
        ),
        if (ing != null && ing.price != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: _UsageExplanation(ing: ing, qty: Fmt.parse(row.ctrl.text) ?? 0, unit: item.unit, cost: line?.cost),
          ),
        if (isSub && line?.subCostPerUnit != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('${Fmt.moneySmart(line!.subCostPerUnit)} por ${Fmt.units(1, sub?.yieldUnit ?? 'unidad').substring(2)}',
                style: context.tt.bodySmall!.copyWith(color: context.muted)),
          ),
        if (line != null && !line.ok)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: line.missingPrice && ing != null
                ? WarningBanner('Falta el precio de compra de ${ing.name}. Toca para registrarlo.',
                    onTap: () => _setPrice(ing))
                : WarningBanner(line.error ?? 'Error', color: AppColors.danger),
          ),
      ]),
    );
  }

  Future<void> _setPrice(Ingredient ing) async {
    final v = await askNumber(context,
        title: 'Precio de ${ing.name}',
        label: 'Precio de ${Fmt.qty(ing.quantity, ing.unit)}',
        prefix: r'$ ');
    if (v == null || !mounted) return;
    await context.read<AppState>().saveIngredient(ing.copy()..price = v);
  }

  Widget _extraCard(BuildContext context, int index) {
    final row = _extras[index];
    final e = row.extra;
    final isPct = e.mode == ExtraCostMode.percentOfSale;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      child: Column(children: [
        Row(children: [
          Icon(_extraIcon(e.type), size: 20, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(e.type.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => setState(() {
              final r = _extras.removeAt(index);
              r.amount.dispose();
              r.name.dispose();
              _dirty = true;
            }),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(children: [
            TextFormField(
              controller: row.name,
              decoration: InputDecoration(labelText: 'Descripción (opcional)', hintText: e.type.label),
              onChanged: (_) => _changed(),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ExtraCostMode>(
              initialValue: e.mode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Se aplica'),
              items: [
                for (final m in ExtraCostMode.values) DropdownMenuItem(value: m, child: Text(m.label)),
              ],
              onChanged: (m) => setState(() {
                if (m != null) e.mode = m;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 10),
            NumField(
              controller: row.amount,
              label: isPct ? 'Porcentaje' : 'Monto',
              prefix: isPct ? null : r'$ ',
              suffix: isPct ? '%' : (e.mode == ExtraCostMode.perUnit ? 'c/u' : 'por preparación'),
              max: isPct ? 100 : null,
              onChanged: (_) => _changed(),
            ),
          ]),
        ),
      ]),
    );
  }
}

IconData _extraIcon(ExtraCostType t) {
  switch (t) {
    case ExtraCostType.gas:
      return Icons.local_fire_department_rounded;
    case ExtraCostType.electricity:
      return Icons.bolt_rounded;
    case ExtraCostType.labor:
      return Icons.person_rounded;
    case ExtraCostType.packaging:
      return Icons.inventory_rounded;
    case ExtraCostType.transport:
      return Icons.local_shipping_rounded;
    case ExtraCostType.commission:
      return Icons.phone_android_rounded;
    case ExtraCostType.tax:
      return Icons.account_balance_rounded;
    case ExtraCostType.other:
      return Icons.more_horiz_rounded;
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.costing, required this.onSave});
  final RecipeCosting costing;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final c = costing;
    return Material(
      color: context.cs.surface,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              _mini(context, 'Cuesta toda la receta', Fmt.money(c.productionCost)),
              _mini(context, 'Cuesta cada ${_one(c.recipe.yieldUnit)}', Fmt.money(c.costPerUnit)),
              _mini(
                context,
                'Ganas por ${_one(c.recipe.yieldUnit)}',
                c.hasSalePrice ? Fmt.money(c.grossProfitPerUnit) : '—',
                color: (c.grossProfitPerUnit ?? 0) >= 0 ? context.positive : context.negative,
              ),
            ]),
            if (!c.isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Costo incompleto: faltan precios o hay líneas con error',
                    style: TextStyle(color: context.warning, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Guardar receta'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _mini(BuildContext context, String label, String value, {Color? color}) => Expanded(
        child: Column(children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: color)),
          ),
          Text(label, style: context.tt.labelSmall!.copyWith(color: context.muted)),
        ]),
      );
}

/// Selector de insumos con búsqueda y opción de crear uno nuevo.
class _IngredientPicker extends StatefulWidget {
  const _IngredientPicker({required this.state});
  final AppState state;
  @override
  State<_IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends State<_IngredientPicker> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.state.ingredients
        .where((i) => _q.isEmpty || i.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, sc) => Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + MediaQuery.of(context).viewInsets.bottom * 0),
          child: TextField(
            autofocus: false,
            decoration: const InputDecoration(hintText: 'Buscar insumo', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: context.cs.primary,
            child: Icon(Icons.add, color: context.cs.onPrimary),
          ),
          title: Text(_q.isEmpty ? 'Crear nuevo insumo' : 'Crear "$_q"',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Se te pedirá su contenido y precio de compra'),
          onTap: () async {
            final nav = Navigator.of(context);
            final id = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                    builder: (_) => IngredientFormScreen(initialName: _q.isEmpty ? null : _q)));
            if (id != null) nav.pop(id);
          },
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            controller: sc,
            itemCount: list.length,
            itemBuilder: (_, i) {
              final ing = list[i];
              return ListTile(
                title: Text(ing.name),
                subtitle: Text('${ing.presentation.isEmpty ? '' : '${ing.presentation} · '}'
                    '${Fmt.qty(ing.quantity, ing.unit)}'),
                trailing: ing.price == null
                    ? Pill('Sin precio', color: context.warning)
                    : Text(Fmt.money(ing.price), style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(context, ing.id),
              );
            },
          ),
        ),
      ]),
    );
  }
}


String _one(String u) {
  final t = Fmt.units(1, u.trim().isEmpty ? 'unidades' : u.trim());
  return t.substring(2);
}

/// Ayuda breve de cómo llenar la receta.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Escribe lo que gastas para preparar TODA la tanda (ej. 7 lb de harina). '
              'Abajo indica cuántas unidades salen de esa tanda y a cuánto vendes CADA una.',
              style: context.tt.bodySmall,
            ),
          ),
        ]),
      );
}

/// Explica en palabras simples cómo se calculó el costo de un ingrediente.
class _UsageExplanation extends StatelessWidget {
  const _UsageExplanation({required this.ing, required this.qty, required this.unit, required this.cost});
  final Ingredient ing;
  final double qty;
  final Unit unit;
  final double? cost;

  @override
  Widget build(BuildContext context) {
    final pres = ing.presentation.isEmpty ? 'presentación' : ing.presentation.toLowerCase();
    final presText = '$pres de ${Fmt.qty(ing.quantity, ing.unit)}'
        '${ing.hasPieces ? ' (${Fmt.num(ing.pieces)} piezas)' : ''}';
    double? packs;
    try {
      packs = qty <= 0 || ing.quantity <= 0 ? null : toPurchaseUnit(ing, qty, unit) / ing.quantity;
    } catch (_) {}
    final unitName = unit == Unit.unit ? Fmt.units(qty, 'unidades') : Fmt.qty(qty, unit);
    final lines = <String>['Compras: $presText a ${Fmt.money(ing.price)}'];
    if (packs != null && cost != null) {
      lines.add('Usas $unitName = ${Fmt.num(packs, maxDecimals: 2)} '
          '${_plural(packs, pres)}, cuesta ${Fmt.money(cost)}');
    }
    final many = packs != null && packs > 1.0001;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final l in lines)
        Text(l, style: context.tt.bodySmall!.copyWith(color: context.muted)),
      if (many)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '¿Seguro? Eso equivale a ${Fmt.num(packs, maxDecimals: 2)} ${_plural(packs, pres)} completos. '
            '${ing.unit.dimension != Dimension.count && !ing.hasPieces ? 'Si querías contar piezas (ej. 12 tortas), '
                'edita el insumo y escribe cuántas piezas trae; luego elige "Unidades".' : 'Revisa la cantidad y la unidad.'}',
            style: TextStyle(color: context.warning, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
    ]);
  }
}

String _plural(double n, String w) {
  if ((n - 1).abs() < 1e-9) return w;
  if (w.endsWith('ón')) return '${w.substring(0, w.length - 2)}ones';
  return RegExp(r'[aeiou]$').hasMatch(w) ? '${w}s' : '${w}es';
}
