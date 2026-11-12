import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db.dart';
import 'progress_repo.dart';

/// Set while a session runs; still present at launch = the app was killed.
const activeSessionKey = 'activeSessionStart';

/// True if the previous session was cut off by the system.
final interruptedAtLaunchProvider = Provider<bool>((ref) => false);

/// Overridden in main() with the loaded instances.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final dbProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());
final repoProvider = Provider<ProgressRepo>(
  (ref) => ProgressRepo(ref.watch(dbProvider)),
);

/// Who I am: catalog IDs only, never free text. Small, so it lives in prefs.
class Profile {
  const Profile({
    required this.avatarId,
    required this.nicknameId,
    required this.skinId,
  });
  final int avatarId;
  final int nicknameId;
  final int skinId;
}

class ProfileNotifier extends Notifier<Profile?> {
  SharedPreferences get _p => ref.read(prefsProvider);

  @override
  Profile? build() {
    final avatar = _p.getInt('avatarId');
    final nick = _p.getInt('nicknameId');
    if (avatar == null || nick == null) return null;
    return Profile(
      avatarId: avatar,
      nicknameId: nick,
      skinId: _p.getInt('skinId') ?? 0,
    );
  }

  Future<void> create({required int avatarId, required int nicknameId}) async {
    await _p.setInt('avatarId', avatarId);
    await _p.setInt('nicknameId', nicknameId);
    state = build();
  }

  Future<void> setAvatar(int id) async {
    await _p.setInt('avatarId', id);
    state = build();
  }

  Future<void> setSkin(int id) async {
    await _p.setInt('skinId', id);
    state = build();
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile?>(
  ProfileNotifier.new,
);

/// Aura, streak, skins and history from the database.
class ProgressNotifier extends AsyncNotifier<ProgressSnapshot> {
  @override
  Future<ProgressSnapshot> build() =>
      ref.read(repoProvider).load(DateTime.now());

  Future<void> refresh() async {
    state = AsyncData(await ref.read(repoProvider).load(DateTime.now()));
  }

  Future<void> markSkinsSeen() async {
    await ref.read(repoProvider).markSkinsSeen();
    await refresh();
  }
}

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, ProgressSnapshot>(
      ProgressNotifier.new,
    );

/// Convenience: latest snapshot, or empty while loading.
final progressValueProvider = Provider<ProgressSnapshot>(
  (ref) => ref.watch(progressProvider).value ?? ProgressSnapshot.empty,
);

/// App settings (shared preferences).
class Settings {
  const Settings({required this.haptics, required this.reduceMotion});
  final bool haptics;
  final bool reduceMotion;
}

class SettingsNotifier extends Notifier<Settings> {
  SharedPreferences get _p => ref.read(prefsProvider);

  @override
  Settings build() => Settings(
    haptics: _p.getBool('haptics') ?? true,
    reduceMotion: _p.getBool('reduceMotion') ?? false,
  );

  Future<void> setHaptics(bool v) async {
    await _p.setBool('haptics', v);
    state = build();
  }

  Future<void> setReduceMotion(bool v) async {
    await _p.setBool('reduceMotion', v);
    state = build();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
