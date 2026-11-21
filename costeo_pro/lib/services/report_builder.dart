import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/costing.dart';
import '../core/format.dart';
import '../models/models.dart';

/// Datos de un reporte de costeo (desde un costeo en vivo o uno guardado).
class CostReport {
  CostReport({
    required this.recipeName,
    required this.date,
    required this.detail,
    required this.ingredientsCost,
    required this.productionCost,
    required this.costPerUnit,
    this.salePrice,
    this.revenue,
    this.grossProfit,
    this.estimatedProfit,
    this.grossMargin,
    this.estimatedMargin,
    this.markup,
    this.category = '',
    this.complete = true,
  });

  final String recipeName;
  final String category;
  final DateTime date;
  final Map<String, dynamic> detail;
  final double ingredientsCost;
  final double productionCost;
  final double costPerUnit;
  final double? salePrice;
  final double? revenue;
  final double? grossProfit;
  final double? estimatedProfit;
  final double? grossMargin;
  final double? estimatedMargin;
  final double? markup;
  final bool complete;

  double get yieldQty => (detail['yield_qty'] as num?)?.toDouble() ?? 0;
  String get yieldUnit => (detail['yield_unit'] as String?) ?? '';

  factory CostReport.fromCosting(RecipeCosting c) => CostReport(
        recipeName: c.recipe.name,
        category: c.recipe.category,
        date: DateTime.now(),
        detail: jsonDecode(jsonEncode(c.toDetail())) as Map<String, dynamic>,
        ingredientsCost: c.ingredientsCost,
        productionCost: c.productionCost,
        costPerUnit: c.costPerUnit,
        salePrice: c.hasSalePrice ? c.salePrice : null,
        revenue: c.potentialRevenue,
        grossProfit: c.grossProfit,
        estimatedProfit: c.estimatedProfit,
        grossMargin: c.grossMarginPercent,
        estimatedMargin: c.estimatedMarginPercent,
        markup: c.markupPercent,
        complete: c.isComplete,
      );

  factory CostReport.fromSnapshot(CostingSnapshot s) {
    Map<String, dynamic> d;
    try {
      d = jsonDecode(s.detailJson) as Map<String, dynamic>;
    } catch (_) {
      d = {};
    }
    final price = s.salePrice;
    final hasPrice = price != null && price > 0;
    final revenue = hasPrice ? price * s.yieldQty : null;
    return CostReport(
      recipeName: s.recipeName,
      date: s.date,
      detail: d,
      ingredientsCost: s.ingredientsCost,
      productionCost: s.productionCost,
      costPerUnit: s.costPerUnit,
      salePrice: hasPrice ? price : null,
      revenue: revenue,
      grossProfit: s.grossProfit,
      estimatedProfit: s.estimatedProfit,
      grossMargin: s.marginPercent,
      estimatedMargin: (hasPrice && s.estimatedProfit != null && revenue! > 0)
          ? s.estimatedProfit! / revenue * 100
          : null,
      markup: hasPrice ? ProfitMath.markupPercent(s.costPerUnit, price) : null,
      complete: d['complete'] != false,
    );
  }
}

/// Generador de PDFs con aspecto empresarial.
class PdfBuilder {
  PdfBuilder(this.regular, this.bold);
  final pw.Font regular;
  final pw.Font bold;

  static const _accent = PdfColor.fromInt(0xFF0E9F74);
  static const _dark = PdfColor.fromInt(0xFF111827);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _line = PdfColor.fromInt(0xFFE5E7EB);
  static const _soft = PdfColor.fromInt(0xFFF3F6F8);

  pw.ThemeData get _theme => pw.ThemeData.withFont(base: regular, bold: bold);

  pw.Widget _header(String business, String title, String subtitle) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _accent, width: 2)),
        ),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(business.isEmpty ? 'Mi negocio' : business,
                  style: pw.TextStyle(font: bold, fontSize: 11, color: _accent)),
              pw.SizedBox(height: 4),
              pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 20, color: _dark)),
              if (subtitle.isNotEmpty)
                pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10, color: _muted)),
            ]),
          ),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('REPORTE DE COSTEO', style: pw.TextStyle(font: bold, fontSize: 9, color: _muted)),
            pw.Text(Fmt.dateTime(DateTime.now()), style: const pw.TextStyle(fontSize: 9, color: _muted)),
          ]),
        ]),
      );

  pw.Widget _footer(pw.Context ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text(
          'Generado con Costeo Pro · Valores estimados según precios registrados · Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      );

  pw.Widget _kpi(String label, String value, {PdfColor color = _dark}) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 14, color: color)),
          ]),
        ),
      );

  pw.Widget _section(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
        child: pw.Text(t, style: pw.TextStyle(font: bold, fontSize: 12, color: _dark)),
      );

  pw.Widget _table(List<String> headers, List<List<String>> rows,
      {Map<int, pw.Alignment>? align, List<String>? totalRow, Map<int, pw.TableColumnWidth>? widths}) {
    final al = align ?? {};
    pw.Widget cell(String t, int i, {bool header = false, bool total = false}) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          alignment: al[i] ?? pw.Alignment.centerLeft,
          child: pw.Text(t,
              style: pw.TextStyle(
                font: header || total ? bold : regular,
                fontSize: header ? 8.5 : 9,
                color: header ? PdfColors.white : _dark,
              )),
        );
    return pw.Table(
      columnWidths: widths,
      border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _line, width: 0.5)),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _accent),
          children: [for (var i = 0; i < headers.length; i++) cell(headers[i], i, header: true)],
        ),
        for (var r = 0; r < rows.length; r++)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: r.isOdd ? _soft : PdfColors.white),
            children: [for (var i = 0; i < rows[r].length; i++) cell(rows[r][i], i)],
          ),
        if (totalRow != null)
          pw.TableRow(
            decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE6F6F0),
                border: pw.Border(top: pw.BorderSide(color: _accent, width: 1))),
            children: [for (var i = 0; i < totalRow.length; i++) cell(totalRow[i], i, total: true)],
          ),
      ],
    );
  }

  pw.Widget _row(String l, String v, {bool strong = false, PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(children: [
          pw.Expanded(
              child: pw.Text(l,
                  style: pw.TextStyle(font: strong ? bold : regular, fontSize: 10, color: strong ? _dark : _muted))),
          pw.Text(v, style: pw.TextStyle(font: strong ? bold : regular, fontSize: strong ? 11 : 10, color: color ?? _dark)),
        ]),
      );

  /// Reporte de costeo de una receta.
  Future<Uint8List> recipeReport(CostReport r, {required String business}) async {
    final doc = pw.Document(theme: _theme, title: r.recipeName, author: business);
    final d = r.detail;
    final lines = (d['lines'] as List?) ?? [];
    final prodExtras = (d['production_extras'] as List?) ?? [];
    final saleExtras = (d['sale_extras'] as List?) ?? [];
    final waste = (d['waste_cost'] as num?)?.toDouble() ?? 0;
    final wastePct = (d['waste_percent'] as num?)?.toDouble() ?? 0;
    final fixedTotal = (d['fixed_cost_total'] as num?)?.toDouble() ?? 0;
    final positive = const PdfColor.fromInt(0xFF0E9F74);
    final negative = const PdfColor.fromInt(0xFFDC2626);
    PdfColor sign(double? v) => (v ?? 0) >= 0 ? positive : negative;

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
      header: (_) => pw.SizedBox(),
      footer: _footer,
      build: (ctx) => [
        _header(business, r.recipeName,
            '${r.category.isEmpty ? '' : '${r.category} · '}Costeo del ${Fmt.dateTime(r.date)}'),
        pw.SizedBox(height: 14),
        if (!r.complete)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFFF7E6), borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Text(
              'Costeo incompleto: hay ingredientes sin precio de compra registrado. Los totales no los incluyen.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFFB45309)),
            ),
          ),
        pw.Row(children: [
          _kpi('Costo total de producción', Fmt.money(r.productionCost)),
          _kpi('Cantidad producida', Fmt.units(r.yieldQty, r.yieldUnit)),
          _kpi('Costo por unidad', Fmt.money(r.costPerUnit), color: _accent),
          _kpi('Margen bruto', Fmt.pct(r.grossMargin), color: sign(r.grossMargin)),
        ]),
        _section('Ingredientes'),
        _table(
          ['Ingrediente', 'Cantidad', 'Presentación / precio usado', 'Costo'],
          [
            for (final l in lines)
              [
                '${l['sub_recipe'] == true ? '[Receta] ' : ''}${l['name']}',
                l['sub_recipe'] == true
                    ? Fmt.units((l['quantity'] as num?)?.toDouble() ?? 0, '${l['unit'] ?? ''}')
                    : '${Fmt.num((l['quantity'] as num?)?.toDouble(), maxDecimals: 3)} ${l['unit'] ?? ''}',
                l['sub_recipe'] == true
                    ? (l['sub_cost_per_unit'] != null
                        ? '${Fmt.moneySmart((l['sub_cost_per_unit'] as num).toDouble())} por ${Fmt.units(1, '${l['unit']}').substring(2)}'
                        : '—')
                    : (l['package_price'] != null
                        ? '${Fmt.num((l['package_qty'] as num?)?.toDouble(), maxDecimals: 3)} ${l['package_unit'] ?? ''} a ${Fmt.money((l['package_price'] as num).toDouble())}'
                        : 'Precio pendiente'),
                l['cost'] == null ? 'Pendiente' : Fmt.moneySmart((l['cost'] as num).toDouble()),
              ]
          ],
          align: {3: pw.Alignment.centerRight, 1: pw.Alignment.centerRight},
          widths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.6),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FlexColumnWidth(1.4),
          },
          totalRow: ['Costo de ingredientes', '', '', Fmt.money(r.ingredientsCost)],
        ),
        if (prodExtras.isNotEmpty || saleExtras.isNotEmpty || waste > 0 || fixedTotal > 0) ...[
          _section('Costos adicionales'),
          _table(
            ['Concepto', 'Tipo', 'Valor', 'Total por preparación'],
            [
              if (waste > 0) ['Desperdicio o merma', '% de ingredientes', Fmt.pct(wastePct), Fmt.money(waste)],
              for (final e in prodExtras)
                [
                  '${e['name']}',
                  '${e['mode']}',
                  Fmt.moneySmart((e['amount'] as num).toDouble()),
                  Fmt.money((e['total'] as num).toDouble()),
                ],
              for (final e in saleExtras)
                [
                  '${e['name']}',
                  'Gasto de venta (${e['mode']})',
                  Fmt.pct((e['amount'] as num).toDouble()),
                  Fmt.money((e['total'] as num).toDouble()),
                ],
              if (fixedTotal > 0)
                [
                  'Gastos fijos distribuidos',
                  'Por unidad',
                  Fmt.moneySmart((d['fixed_cost_per_unit'] as num?)?.toDouble()),
                  Fmt.money(fixedTotal),
                ],
            ],
            align: {2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          ),
        ],
        _section('Resumen'),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line), borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(children: [
            _row('Costo de ingredientes', Fmt.money(r.ingredientsCost)),
            _row('Merma y costos de producción', Fmt.money(r.productionCost - r.ingredientsCost)),
            _row('Costo total de producción', Fmt.money(r.productionCost), strong: true),
            _row('Cantidad producida', Fmt.units(r.yieldQty, r.yieldUnit)),
            _row('Costo por unidad', Fmt.money(r.costPerUnit), strong: true),
            pw.Divider(color: _line),
            if (r.salePrice == null)
              _row('Precio de venta', 'No definido')
            else ...[
              _row('Precio de venta por unidad', Fmt.money(r.salePrice)),
              _row('Ingresos potenciales (si se vende todo)', Fmt.money(r.revenue)),
              _row('Ganancia bruta', Fmt.money(r.grossProfit), strong: true, color: sign(r.grossProfit)),
              if (r.estimatedProfit != null && (r.estimatedProfit! - (r.grossProfit ?? 0)).abs() > 1e-9)
                _row('Ganancia estimada después de gastos registrados', Fmt.money(r.estimatedProfit),
                    strong: true, color: sign(r.estimatedProfit)),
              _row('Margen bruto (ganancia ÷ precio)', Fmt.pct(r.grossMargin), strong: true),
              if (r.estimatedMargin != null && r.estimatedProfit != r.grossProfit)
                _row('Margen estimado', Fmt.pct(r.estimatedMargin)),
              _row('Recargo sobre costo (ganancia ÷ costo)', Fmt.pct(r.markup)),
            ],
          ]),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Nota: la ganancia estimada solo descuenta los gastos registrados en la aplicación; '
          'no representa la ganancia neta del negocio ni ventas reales.',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ],
    ));
    return doc.save();
  }

  /// Reporte resumido de todas las recetas.
  Future<Uint8List> recipesSummary(List<RecipeCosting> list, {required String business}) async {
    final doc = pw.Document(theme: _theme, title: 'Resumen de recetas', author: business);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 24),
      footer: _footer,
      build: (_) => [
        _header(business, 'Resumen de recetas', '${list.length} receta(s)'),
        pw.SizedBox(height: 14),
        _table(
          ['Receta', 'Categoría', 'Rinde', 'Costo total', 'Costo c/u', 'Precio', 'Ganancia c/u', 'Margen', 'Estado'],
          [
            for (final c in list)
              [
                c.recipe.name,
                c.recipe.category,
                (Fmt.units(c.yieldQty, c.recipe.yieldUnit)),
                Fmt.money(c.productionCost),
                Fmt.money(c.costPerUnit),
                c.hasSalePrice ? Fmt.money(c.salePrice) : '—',
                c.hasSalePrice ? Fmt.money(c.grossProfitPerUnit) : '—',
                Fmt.pct(c.grossMarginPercent),
                c.isComplete ? 'Completo' : 'Incompleto',
              ]
          ],
          align: {for (var i = 3; i <= 7; i++) i: pw.Alignment.centerRight},
          widths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1.6)},
        ),
      ],
    ));
    return doc.save();
  }
}
