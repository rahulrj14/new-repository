import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../progression/aura.dart';

/// Set while a session runs; still present at launch = the app was killed.
const activeSessionKey = 'activeSessionStart';

/// True if the previous session was cut off by the system.
final interruptedAtLaunchProvider = Provider<bool>((ref) => false);

/// Overridden in main() with the loaded instance.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

/// Everything about "me", on this phone only. Catalog IDs and numbers,
/// never free text. (Moves to drift/SQLite with streaks and skins.)
class Profile {
  const Profile({
    required this.avatarId,
    required this.nicknameId,
    required this.auraTotal,
    required this.auraToday,
    required this.sessions,
  });

  final int avatarId;
  final int nicknameId;
  final int auraTotal;
  final int auraToday;
  final int sessions;

  Level get level => levelFor(auraTotal);
}

class ProfileNotifier extends Notifier<Profile?> {
  static const _avatar = 'avatarId';
  static const _nickname = 'nicknameId';
  static const _total = 'auraTotal';
  static const _day = 'auraDay';
  static const _today = 'auraToday';
  static const _sessions = 'sessions';

  SharedPreferences get _p => ref.read(prefsProvider);

  static String _dayKey(DateTime t) => '${t.year}-${t.month}-${t.day}';

  @override
  Profile? build() => _load(DateTime.now());

  Profile? _load(DateTime now) {
    final avatar = _p.getInt(_avatar);
    final nick = _p.getInt(_nickname);
    if (avatar == null || nick == null) return null;
    final sameDay = _p.getString(_day) == _dayKey(now);
    return Profile(
      avatarId: avatar,
      nicknameId: nick,
      auraTotal: _p.getInt(_total) ?? 0,
      auraToday: sameDay ? (_p.getInt(_today) ?? 0) : 0,
      sessions: _p.getInt(_sessions) ?? 0,
    );
  }

  Future<void> create({required int avatarId, required int nicknameId}) async {
    await _p.setInt(_avatar, avatarId);
    await _p.setInt(_nickname, nicknameId);
    state = _load(DateTime.now());
  }

  Future<void> setAvatar(int id) async {
    await _p.setInt(_avatar, id);
    state = _load(DateTime.now());
  }

  /// Aura earned today so far (resets at local midnight).
  int earnedToday(DateTime now) => _load(now)?.auraToday ?? 0;

  Future<void> addSession({required int aura, required DateTime at}) async {
    final today = earnedToday(at);
    await _p.setInt(_total, (_p.getInt(_total) ?? 0) + aura);
    await _p.setString(_day, _dayKey(at));
    await _p.setInt(_today, today + aura);
    await _p.setInt(_sessions, (_p.getInt(_sessions) ?? 0) + 1);
    state = _load(at);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);

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

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
