import 'package:intl/intl.dart';

import 'units.dart';

/// Formato y lectura de números. Se redondea SOLO al mostrar.
class Fmt {
  Fmt._();

  static String currencySymbol = r'$';

  static final _money2 = NumberFormat('#,##0.00', 'en_US');
  static final _money4 = NumberFormat('#,##0.0000', 'en_US');
  static final _date = DateFormat('dd/MM/yyyy');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  /// $1,234.56 (negativos como -$1.20).
  static String money(double? v, {bool precise = false}) {
    if (v == null || v.isNaN || v.isInfinite) return '—';
    final f = precise ? _money4 : _money2;
    final s = f.format(v.abs());
    return v < 0 && f.format(v.abs()) != f.format(0)
        ? '-$currencySymbol$s'
        : '$currencySymbol$s';
  }

  /// Muestra dinero con 2 decimales y, si es pequeño, con 4.
  static String moneySmart(double? v) {
    if (v == null) return '—';
    if (v != 0 && v.abs() < 0.10) return money(v, precise: true);
    return money(v);
  }

  static String pct(double? v, {int decimals = 1}) {
    if (v == null || v.isNaN || v.isInfinite) return '—';
    return '${num(v, maxDecimals: decimals)} %';
  }

  /// Número con hasta [maxDecimals] decimales, sin ceros sobrantes.
  static String num(double? v, {int maxDecimals = 2}) {
    if (v == null || v.isNaN || v.isInfinite) return '—';
    final pattern = maxDecimals <= 0 ? '#,##0' : '#,##0.${'#' * maxDecimals}';
    return NumberFormat(pattern, 'en_US').format(v);
  }

  static String qty(double v, Unit u) => '${num(v, maxDecimals: 3)} ${u.symbol}';

  /// "10 pizzas", "1 pizza", "1 bola de masa".
  static String units(double qty, String unit) {
    var u = unit.trim();
    if (qty == 1) {
      final parts = u.split(' ');
      final w = parts.first;
      if (w.length > 4 && w.endsWith('ones')) {
        parts[0] = '${w.substring(0, w.length - 4)}ón';
      } else if (w.length > 3 && w.endsWith('es') && !w.endsWith('ces') && w != 'unidades') {
        parts[0] = w.substring(0, w.length - 2);
      } else if (w == 'unidades') {
        parts[0] = 'unidad';
      } else if (w.length > 3 && w.endsWith('s')) {
        parts[0] = w.substring(0, w.length - 1);
      }
      u = parts.join(' ');
    }
    return '${num(qty, maxDecimals: 3)} $u';
  }

  static String date(DateTime? d) => d == null ? '—' : _date.format(d);
  static String dateTime(DateTime? d) => d == null ? '—' : _dateTime.format(d);

  /// Lee un número escrito por el usuario. Acepta coma o punto decimal y
  /// separador de miles. Devuelve null si no es válido.
  static double? parse(String? text) {
    if (text == null) return null;
    var s = text.trim().replaceAll(' ', '').replaceAll(currencySymbol, '').replaceAll('%', '');
    if (s.isEmpty) return null;
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      // El último separador es el decimal.
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }
    final v = double.tryParse(s);
    if (v == null || v.isNaN || v.isInfinite) return null;
    return v;
  }

  /// Valor para precargar un campo de texto.
  static String input(double? v) {
    if (v == null) return '';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    var s = v.toStringAsFixed(6);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }
}
