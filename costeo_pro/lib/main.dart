import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'data/database.dart';
import 'services/export_service.dart';
import 'state/app_state.dart';
import 'ui/screens/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final dir = await getDatabasesPath();
  final db = await AppDatabase.open(p.join(dir, 'costeo_pro.db'));
  final state = AppState(db);
  await state.load();
  runApp(CosteoProApp(state: state));
  _dailyBackup(state);
}

/// Copia de seguridad automática local, una vez al día.
Future<void> _dailyBackup(AppState state) async {
  try {
    final last = int.tryParse(state.settings['last_auto_backup'] ?? '') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < const Duration(hours: 20).inMilliseconds) return;
    if (state.ingredients.isEmpty && state.recipes.isEmpty) return;
    await ExportService.autoBackup(await state.exportBackup());
    await state.setSetting('last_auto_backup', '$now');
  } catch (_) {
    // Un fallo del respaldo automático nunca debe impedir usar la app.
  }
}

class CosteoProApp extends StatelessWidget {
  const CosteoProApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: Selector<AppState, ThemeMode>(
        selector: (_, s) => s.themeMode,
        builder: (_, mode, _) => MaterialApp(
          title: 'Costeo Pro',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: mode,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeShell(),
        ),
      ),
    );
  }
}
