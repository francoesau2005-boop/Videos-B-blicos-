import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/units.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Crear o editar un insumo. Devuelve el id guardado con Navigator.pop.
class IngredientFormScreen extends StatefulWidget {
  const IngredientFormScreen({super.key, this.ingredient, this.initialName});
  final Ingredient? ingredient;
  final String? initialName;

  @override
  State<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Ingredient _ing;
  late final TextEditingController _name, _category, _presentation, _qty, _price,
      _brand, _supplier, _density, _stock, _minStock, _notes, _pieces;
  bool _saving = false;

  static const _presentations = [
    'Saco', 'Bolsa', 'Bote', 'Paquete', 'Cartón', 'Botella', 'Caja', 'Sobre', 'Lata', 'Galón', 'Unidad'
  ];

  bool get _isNew => widget.ingredient == null;

  @override
  void initState() {
    super.initState();
    _ing = widget.ingredient?.copy() ??
        Ingredient(name: widget.initialName ?? '', quantity: 0, unit: Unit.lb);
    _name = TextEditingController(text: _ing.name);
    _category = TextEditingController(text: _ing.category);
    _presentation = TextEditingController(text: _ing.presentation);
    _qty = TextEditingController(text: _isNew ? '' : Fmt.input(_ing.quantity));
    _price = TextEditingController(text: Fmt.input(_ing.price));
    _brand = TextEditingController(text: _ing.brand);
    _supplier = TextEditingController(text: _ing.supplier);
    _density = TextEditingController(text: Fmt.input(_ing.density));
    _stock = TextEditingController(text: _isNew ? '' : Fmt.input(_ing.stock));
    _minStock = TextEditingController(text: Fmt.input(_ing.minStock));
    _notes = TextEditingController(text: _ing.notes);
    _pieces = TextEditingController(text: Fmt.input(_ing.pieces));
  }

  @override
  void dispose() {
    for (final c in [_name, _category, _presentation, _qty, _price, _brand, _supplier,
      _density, _stock, _minStock, _notes, _pieces]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1200, imageQuality: 80);
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final photos = Directory(p.join(dir.path, 'photos'));
      await photos.create(recursive: true);
      final dest = p.join(photos.path, 'ing_${DateTime.now().millisecondsSinceEpoch}${p.extension(x.path)}');
      await File(x.path).copy(dest);
      setState(() => _ing.photoPath = dest);
    } catch (e) {
      if (mounted) showSnack(context, 'No se pudo obtener la foto: $e', error: true);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final s = context.read<AppState>();
    _ing
      ..name = _name.text.trim()
      ..category = _category.text.trim().isEmpty ? 'General' : _category.text.trim()
      ..presentation = _presentation.text.trim()
      ..quantity = Fmt.parse(_qty.text)!
      ..price = Fmt.parse(_price.text)
      ..brand = _brand.text.trim()
      ..supplier = _supplier.text.trim()
      ..density = Fmt.parse(_density.text)
      ..pieces = _ing.unit == Unit.unit ? null : Fmt.parse(_pieces.text)
      ..minStock = Fmt.parse(_minStock.text)
      ..notes = _notes.text.trim();
    if (_ing.density == 0) _ing.density = null;
    if (_isNew) _ing.stock = Fmt.parse(_stock.text) ?? 0;
    if (_ing.trackStock == false && (_ing.minStock != null)) _ing.trackStock = true;
    try {
      await s.saveIngredient(_ing);
      if (!mounted) return;
      showSnack(context, 'Insumo guardado');
      Navigator.pop(context, _ing.id);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) showSnack(context, 'Error al guardar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final qty = Fmt.parse(_qty.text);
    final price = Fmt.parse(_price.text);
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Nuevo insumo' : 'Editar insumo')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(_saving ? 'Guardando…' : 'Guardar insumo'),
          ),
        ),
      ),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _photoSheet(),
                child: Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 96,
                      height: 96,
                      color: context.cs.surfaceContainerHigh,
                      child: _ing.photoPath != null && File(_ing.photoPath!).existsSync()
                          ? Image.file(File(_ing.photoPath!), fit: BoxFit.cover)
                          : Icon(Icons.add_a_photo_rounded, size: 34, color: context.muted),
                    ),
                  ),
                ]),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _photoSheet,
                child: Text(_ing.photoPath == null ? 'Agregar foto (opcional)' : 'Cambiar foto'),
              ),
            ),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre del producto *', hintText: 'Ej.: Harina fuerte'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Escribe el nombre' : null,
            ),
            const SizedBox(height: 14),
            CategoryField(controller: _category, options: s.ingredientCategories),
            const SizedBox(height: 18),
            const SectionTitle('¿Cómo lo compras?', padding: EdgeInsets.fromLTRB(4, 4, 4, 8)),
            TextFormField(
              controller: _presentation,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Presentación', hintText: 'Saco, bolsa, bote…'),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final pr in _presentations)
                ChoiceChip(
                  label: Text(pr),
                  selected: _presentation.text == pr,
                  onSelected: (_) => setState(() => _presentation.text = pr),
                ),
            ]),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 5,
                child: NumField(
                  controller: _qty,
                  label: 'Contenido *',
                  hint: 'Ej.: 50',
                  allowZero: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: UnitDropdown(
                  value: _ing.unit,
                  units: Unit.values,
                  onChanged: (u) => setState(() => _ing.unit = u),
                ),
              ),
            ]),
            if (_ing.unit != Unit.unit) ...[
              const SizedBox(height: 14),
              NumField(
                controller: _pieces,
                label: '¿Cuántas piezas trae? (opcional)',
                suffix: 'piezas',
                required: false,
                helper: 'Ej.: paquete de 4 lb con 12 tortas → escribe 12. Así en tus recetas '
                    'podrás usar "Unidades" (ej. 1 torta) en lugar de libras.',
              ),
            ],
            const SizedBox(height: 14),
            NumField(
              controller: _price,
              label: 'Precio total de compra',
              prefix: r'$ ',
              required: false,
              helper: 'Lo que pagas por la presentación completa. Déjalo vacío si aún no '
                  'lo sabes: quedará como "precio pendiente".',
            ),
            if (qty != null && qty > 0 && price != null) ...[
              const SizedBox(height: 12),
              _UnitCostPreview(qty: qty, unit: _ing.unit, price: price, density: Fmt.parse(_density.text)),
            ],
            const SizedBox(height: 18),
            const SectionTitle('Detalles opcionales', padding: EdgeInsets.fromLTRB(4, 4, 4, 8)),
            TextFormField(
              controller: _brand,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Marca'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _supplier,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Proveedor'),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _ing.purchaseDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (d != null) setState(() => _ing.purchaseDate = d);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de compra',
                  suffixIcon: _ing.purchaseDate == null
                      ? const Icon(Icons.calendar_today_rounded)
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _ing.purchaseDate = null)),
                ),
                child: Text(_ing.purchaseDate == null ? 'Sin fecha' : Fmt.date(_ing.purchaseDate)),
              ),
            ),
            const SizedBox(height: 14),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text('Densidad (avanzado)', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Solo si necesitas convertir peso ↔ volumen'),
              children: [
                NumField(
                  controller: _density,
                  label: 'Densidad',
                  suffix: 'g/ml',
                  required: false,
                  helper: 'Ej.: aceite ≈ 0.92 g/ml. Sin densidad, la app NO convierte '
                      'gramos a mililitros.',
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 6),
            const SectionTitle('Inventario (opcional)', padding: EdgeInsets.fromLTRB(4, 4, 4, 0)),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              value: _ing.trackStock,
              title: const Text('Controlar existencias'),
              subtitle: const Text('Descuenta solo al registrar producciones reales'),
              onChanged: (v) => setState(() => _ing.trackStock = v),
            ),
            if (_ing.trackStock) ...[
              const SizedBox(height: 8),
              if (_isNew) ...[
                NumField(
                  controller: _stock,
                  label: 'Existencia inicial',
                  suffix: _ing.unit.symbol,
                  required: false,
                ),
                const SizedBox(height: 14),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Text('Existencia actual: ${Fmt.qty(_ing.stock, _ing.unit)} '
                      '(ajústala desde Inventario)',
                      style: context.tt.bodySmall!.copyWith(color: context.muted)),
                ),
              NumField(
                controller: _minStock,
                label: 'Alerta de existencia baja',
                suffix: _ing.unit.symbol,
                required: false,
                helper: 'Te avisaremos cuando la existencia sea igual o menor.',
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notas'),
            ),
          ],
        ),
      ),
    );
  }

  void _photoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: const Text('Tomar foto'),
            onTap: () {
              Navigator.pop(c);
              _pickPhoto(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Elegir de la galería'),
            onTap: () {
              Navigator.pop(c);
              _pickPhoto(ImageSource.gallery);
            },
          ),
          if (_ing.photoPath != null)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Quitar foto'),
              onTap: () {
                Navigator.pop(c);
                setState(() => _ing.photoPath = null);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

/// Vista previa del costo por unidad en unidades compatibles.
class _UnitCostPreview extends StatelessWidget {
  const _UnitCostPreview({required this.qty, required this.unit, required this.price, this.density});
  final double qty;
  final Unit unit;
  final double price;
  final double? density;

  @override
  Widget build(BuildContext context) {
    final units = Unit.ofDimension(unit.dimension);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Costo equivalente', style: TextStyle(fontWeight: FontWeight.w700, color: context.cs.primary)),
        const SizedBox(height: 6),
        Wrap(spacing: 14, runSpacing: 6, children: [
          for (final u in units)
            Text('${Fmt.moneySmart(price / convert(qty, unit, u))} / ${u.symbol}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}
