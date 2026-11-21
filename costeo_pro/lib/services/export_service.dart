import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/costing.dart';
import '../models/models.dart';
import 'report_builder.dart';

/// Guardar, compartir e importar archivos en Android.
class ExportService {
  ExportService._();

  static PdfBuilder? _pdf;

  static Future<PdfBuilder> pdfBuilder() async {
    if (_pdf != null) return _pdf!;
    final reg = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    return _pdf = PdfBuilder(pw.Font.ttf(reg), pw.Font.ttf(bold));
  }

  static String stamp() {
    final d = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}';
  }

  static String safeName(String s) {
    final t = s.trim().replaceAll(RegExp(r'[^\w\-áéíóúñÁÉÍÓÚÑ ]'), '').replaceAll(' ', '_');
    return t.isEmpty ? 'reporte' : t;
  }

  /// Escribe el archivo en la carpeta de documentos de la app (copia local).
  static Future<File> writeLocal(String fileName, Uint8List bytes, {String folder = 'exportaciones'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(dir.path, folder));
    await d.create(recursive: true);
    final f = File(p.join(d.path, fileName));
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  /// Abre el menú de Android para compartir (WhatsApp, Drive, correo, Archivos…).
  static Future<void> share(File f, {String? mime, String? text}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(f.path, mimeType: mime)],
      text: text,
      subject: p.basename(f.path),
    ));
  }

  /// Permite al usuario elegir dónde guardar el archivo en el dispositivo.
  static Future<bool> saveToDevice(String fileName, Uint8List bytes, String mime) async {
    final uri = await FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: mime);
    return uri != null;
  }

  static Future<(String, Uint8List)> recipePdf(RecipeCosting c, {required String businessName}) async {
    final b = await pdfBuilder();
    final bytes = await b.recipeReport(CostReport.fromCosting(c), business: businessName);
    return ('Costeo_${safeName(c.recipe.name)}_${stamp()}.pdf', bytes);
  }

  static Future<void> shareRecipePdf(RecipeCosting c, {required String businessName}) async {
    final (name, bytes) = await recipePdf(c, businessName: businessName);
    final f = await writeLocal(name, bytes);
    await share(f, mime: 'application/pdf');
  }

  static Future<void> shareSnapshotPdf(CostingSnapshot s, {required String businessName}) async {
    final b = await pdfBuilder();
    final bytes = await b.recipeReport(CostReport.fromSnapshot(s), business: businessName);
    final f = await writeLocal('Costeo_${safeName(s.recipeName)}_${stamp()}.pdf', bytes);
    await share(f, mime: 'application/pdf');
  }

  static Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

  /// Lee un archivo de respaldo elegido por el usuario.
  static Future<String?> pickBackupFile() async {
    final f = await FilePicker.pickFile(type: FileType.any);
    if (f == null) return null;
    final bytes = await f.readAsBytes();
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Respaldos automáticos locales (se conservan los últimos [keep]).
  static Future<File> autoBackup(String json, {int keep = 7}) async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(dir.path, 'respaldos'));
    await d.create(recursive: true);
    final f = File(p.join(d.path, 'auto_${stamp()}.json'));
    await f.writeAsString(json, flush: true);
    final files = d.listSync().whereType<File>().where((e) => p.basename(e.path).startsWith('auto_')).toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    for (final old in files.skip(keep)) {
      try {
        await old.delete();
      } catch (_) {}
    }
    return f;
  }

  static Future<List<File>> localBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(dir.path, 'respaldos'));
    if (!await d.exists()) return [];
    return d.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => b.path.compareTo(a.path));
  }
}
