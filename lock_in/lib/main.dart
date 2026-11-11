import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'platform/device_bridge.dart';
import 'storage/profile_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // If a session was running when the app process died (usually the phone's
  // battery saver), say so honestly instead of pretending it finished.
  final interrupted = prefs.getInt(activeSessionKey) != null;
  if (interrupted) {
    await prefs.remove(activeSessionKey);
    await DeviceBridge().stopSession();
  }

  runApp(ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      interruptedAtLaunchProvider.overrideWithValue(interrupted),
    ],
    child: const LockInApp(),
  ));
}
