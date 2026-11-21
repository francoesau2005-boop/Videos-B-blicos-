import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/units.dart';
import 'theme.dart';

/// Campo numérico con teclado decimal, validación y aceptación de coma o punto.
class NumField extends StatelessWidget {
  const NumField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.required = true,
    this.allowZero = true,
    this.max,
    this.onChanged,
    this.helper,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefix;
  final String? suffix;
  final bool required;
  final bool allowZero;
  final double? max;
  final ValueChanged<double?>? onChanged;
  final String? helper;
  final bool autofocus;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixText: prefix,
        suffixText: suffix,
      ),
      onChanged: onChanged == null ? null : (t) => onChanged!(Fmt.parse(t)),
      validator: (t) {
        final empty = t == null || t.trim().isEmpty;
        if (empty) return required ? 'Requerido' : null;
        final v = Fmt.parse(t);
        if (v == null) return 'Número no válido';
        if (v < 0) return 'No puede ser negativo';
        if (!allowZero && v == 0) return 'Debe ser mayor que cero';
        if (max != null && v > max!) return 'Máximo ${Fmt.num(max)}';
        return null;
      },
    );
  }
}

class UnitDropdown extends StatelessWidget {
  const UnitDropdown({
    super.key,
    required this.value,
    required this.units,
    required this.onChanged,
    this.label = 'Unidad',
    this.compact = false,
  });
  final Unit value;
  final List<Unit> units;
  final ValueChanged<Unit> onChanged;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final list = units.contains(value) ? units : [value, ...units];
    return DropdownButtonFormField<Unit>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final u in list)
          DropdownMenuItem(
            value: u,
            child: Text(compact ? u.label : '${u.label} (${u.symbol})',
                overflow: TextOverflow.ellipsis),
          )
      ],
      onChanged: (u) {
        if (u != null) onChanged(u);
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.padding});
  final String text;
  final Widget? trailing;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Row(children: [
          Expanded(
            child: Text(text,
                style: context.tt.titleMedium!
                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2)),
          ),
          ?trailing,
        ]),
      );
}

/// Tarjeta con relleno estándar.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color});
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ),
      );
}

/// Indicador grande (KPI).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.sub,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.cs.primary;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: c),
          ),
        if (icon != null) const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: context.tt.headlineSmall!
                  .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.tt.bodySmall!.copyWith(color: context.muted)),
        if (sub != null)
          Text(sub!, style: context.tt.labelSmall!.copyWith(color: c)),
      ]),
    );
  }
}

/// Fila etiqueta — valor para resúmenes de costos.
class ValueRow extends StatelessWidget {
  const ValueRow(this.label, this.value,
      {super.key, this.bold = false, this.color, this.hint, this.big = false});
  final String label;
  final String value;
  final bool bold;
  final bool big;
  final Color? color;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final style = (big ? context.tt.titleLarge : context.tt.bodyLarge)!.copyWith(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: context.tt.bodyMedium!.copyWith(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: bold ? null : context.muted)),
            if (hint != null)
              Text(hint!, style: context.tt.bodySmall!.copyWith(color: context.muted)),
          ]),
        ),
        const SizedBox(width: 12),
        Text(value, style: style),
      ]),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color, this.icon});
  final String text;
  final Color? color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: c), const SizedBox(width: 4)],
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: context.cs.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: context.cs.primary),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: context.tt.titleLarge!.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: context.tt.bodyMedium!.copyWith(color: context.muted)),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}

class WarningBanner extends StatelessWidget {
  const WarningBanner(this.text, {super.key, this.icon = Icons.warning_amber_rounded, this.color, this.onTap});
  final String text;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.warning;
    return Material(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(icon, color: c),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w600))),
            if (onTap != null) Icon(Icons.chevron_right, color: c),
          ]),
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context,
    {required String title,
    required String message,
    String confirm = 'Eliminar',
    bool destructive = true}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, minimumSize: const Size(48, 44))
              : FilledButton.styleFrom(minimumSize: const Size(48, 44)),
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}

void showSnack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.danger : null,
    ));
}

/// Diálogo con un campo numérico. Devuelve el valor o null si se cancela.
Future<double?> askNumber(BuildContext context,
    {required String title,
    String label = 'Valor',
    double? initial,
    String? prefix,
    String? suffix,
    String? helper,
    bool allowZero = true}) async {
  final ctrl = TextEditingController(text: Fmt.input(initial));
  final key = GlobalKey<FormState>();
  final r = await showDialog<double>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Form(
        key: key,
        child: NumField(
          controller: ctrl,
          label: label,
          prefix: prefix,
          suffix: suffix,
          helper: helper,
          allowZero: allowZero,
          autofocus: true,
          textInputAction: TextInputAction.done,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
          onPressed: () {
            if (key.currentState!.validate()) Navigator.pop(c, Fmt.parse(ctrl.text));
          },
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
  return r;
}

/// Gráfico de dona simple para desglose de costos.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.values, required this.colors, this.size = 140, this.center});
  final List<double> values;
  final List<Color> colors;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => CustomPaint(
            painter: _DonutPainter(values, colors, t, context.cs.surfaceContainerHighest),
            child: child,
          ),
          child: Center(child: center),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.values, this.colors, this.t, this.track);
  final List<double> values;
  final List<Color> colors;
  final double t;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.14;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    final total = values.fold<double>(0, (s, v) => s + (v > 0 ? v : 0));
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * math.pi * 2 * t;
      canvas.drawArc(r, start, math.max(0, sweep - 0.02), false, p..color = colors[i % colors.length]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.t != t || old.values != values;
}

/// Barra horizontal proporcional (para rankings y comparaciones).
class RatioBar extends StatelessWidget {
  const RatioBar({super.key, required this.ratio, this.color, this.height = 8});
  final double ratio;
  final Color? color;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Stack(children: [
            Container(color: context.cs.surfaceContainerHighest),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio.clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(color: color ?? context.cs.primary),
              ),
            ),
          ]),
        ),
      );
}

/// Selector horizontal de categorías.
class CategoryFilter extends StatelessWidget {
  const CategoryFilter({super.key, required this.categories, required this.selected, required this.onSelected});
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('Todas'),
                selected: selected == null,
                onSelected: (_) => onSelected(null),
              ),
            ),
            for (final c in categories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: selected == c,
                  onSelected: (_) => onSelected(selected == c ? null : c),
                ),
              ),
          ],
        ),
      );
}

/// Campo de texto con autocompletado de categorías existentes.
class CategoryField extends StatelessWidget {
  const CategoryField({super.key, required this.controller, required this.options, this.label = 'Categoría'});
  final TextEditingController controller;
  final List<String> options;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final o in options.take(8))
          ActionChip(
            label: Text(o, style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            onPressed: () => controller.text = o,
          ),
      ]),
    ]);
  }
}
