import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'platform/device_bridge.dart';
import 'storage/db.dart';
import 'storage/profile_store.dart';
import 'storage/progress_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();

  // One-off: aura from the first test build lived in prefs.
  final oldAura = prefs.getInt('auraTotal');
  if (oldAura != null) {
    await ProgressRepo(db).migrateAura(oldAura);
    for (final k in ['auraTotal', 'auraDay', 'auraToday', 'sessions']) {
      await prefs.remove(k);
    }
  }

  // If a session was running when the app process died (usually the phone's
  // battery saver), say so honestly instead of pretending it finished.
  final interrupted = prefs.getInt(activeSessionKey) != null;
  if (interrupted) {
    await prefs.remove(activeSessionKey);
    await DeviceBridge().stopSession();
  }

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        interruptedAtLaunchProvider.overrideWithValue(interrupted),
      ],
      child: const LockInApp(),
    ),
  );
}
