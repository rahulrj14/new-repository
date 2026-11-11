import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../detection/grace_tracker.dart';
import '../platform/device_bridge.dart';
import '../progression/aura.dart';
import '../storage/profile_store.dart';
import 'session_engine.dart';

/// A snapshot of the running session for the UI. A new object every tick.
class ActiveSession {
  const ActiveSession(this.engine, this.now);
  final SessionEngine engine;
  final DateTime now;

  SessionPhase get phase => engine.phase(now);
  Duration get locked => engine.lockedTime(now);
  int get cracks => engine.cracks;
  int? get graceLeft => engine.graceSecondsLeft(now);

  /// Remaining (planned) or elapsed (open-ended).
  Duration get clock {
    final end = engine.endsAt;
    if (end == null) return now.difference(engine.startedAt);
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  Duration get settleLeft => engine.armedAt.difference(now);
}

class SessionResult {
  const SessionResult({
    required this.aura,
    required this.cracks,
    required this.completed,
    required this.plannedLength,
    required this.levelBefore,
    required this.auraTotalAfter,
  });
  final AuraBreakdown aura;
  final int cracks;
  final bool completed;
  final Duration? plannedLength;
  final Level levelBefore;
  final int auraTotalAfter;

  bool get leveledUp => levelFor(auraTotalAfter).number > levelBefore.number;
}

class SessionController extends Notifier<ActiveSession?> {
  SessionEngine? _engine;
  StreamSubscription<DeviceEvent>? _sub;
  Timer? _ticker;

  DeviceBridge get _bridge => ref.read(deviceBridgeProvider);
  AppClock get _clock => ref.read(clockProvider);

  @override
  ActiveSession? build() {
    ref.onDispose(_teardown);
    return null;
  }

  Future<void> start(Duration? length) async {
    final now = _clock.now();
    final engine = SessionEngine(startedAt: now, plannedLength: length);
    _engine = engine;
    ref.read(lastResultProvider.notifier).clear();
    _sub = _bridge.events.listen(_onDevice);
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    state = ActiveSession(engine, now);
    await ref.read(prefsProvider).setInt(activeSessionKey, now.millisecondsSinceEpoch);
    await _bridge.startSession(startAt: engine.startedAt.subtract(_clock.offset), endAt: engine.endsAt?.subtract(_clock.offset));
  }

  void _onDevice(DeviceEvent e) {
    final s = e.signal;
    final engine = _engine;
    if (engine == null) return;
    if (s != null) _handle(engine.onSignal(s, e.at.add(_clock.offset)));
    _tick();
  }

  /// Debug tools: inject a fake signal now.
  void fake(DeviceSignal s) {
    final engine = _engine;
    if (engine == null) return;
    _handle(engine.onSignal(s, _clock.now()));
    _tick();
  }

  /// Debug tools: jump forward in time.
  void warp(Duration d) {
    _clock.offset += d;
    _tick();
  }

  void _tick() {
    final engine = _engine;
    if (engine == null) return;
    final now = _clock.now();
    _handle(engine.tick(now));
    if (engine.isComplete(now)) {
      finish();
      return;
    }
    state = ActiveSession(engine, now);
  }

  void _handle(List<TrackerEvent> events) {
    final haptics = ref.read(settingsProvider).haptics;
    for (final e in events) {
      switch (e) {
        case GraceStarted():
          if (haptics) HapticFeedback.mediumImpact();
        case Cracked():
          if (haptics) HapticFeedback.heavyImpact();
          _bridge.updateNotification('Cracked 💔', 'Lock your phone to keep farming aura.');
        case Rearmed():
          _bridge.updateNotification('Locked in 🔒', 'Back on track. Aura up.');
        case GraceCancelled():
          break;
      }
    }
  }

  /// Ends the session (on time or early) and banks the aura.
  Future<void> finish() async {
    final engine = _engine;
    if (engine == null) return;
    final now = _clock.now();
    _teardown();
    final profiles = ref.read(profileProvider.notifier);
    final before = ref.read(profileProvider);
    final aura = scoreSession(
      locked: engine.lockedTime(now),
      cracks: engine.cracks,
      completedPlannedLength: engine.isComplete(now),
      plannedLength: engine.plannedLength,
      earnedTodaySoFar: profiles.earnedToday(now),
    );
    await profiles.addSession(aura: aura.total, at: now);
    ref.read(lastResultProvider.notifier).set(SessionResult(
          aura: aura,
          cracks: engine.cracks,
          completed: engine.isComplete(now),
          plannedLength: engine.plannedLength,
          levelBefore: levelFor(before?.auraTotal ?? 0),
          auraTotalAfter: ref.read(profileProvider)?.auraTotal ?? aura.total,
        ));
    state = null;
    await ref.read(prefsProvider).remove(activeSessionKey);
    final completed = engine.isComplete(now);
    await _bridge.stopSession(
      doneTitle: completed ? 'Session done ✦ +${aura.total} aura' : null,
      doneText: engine.cracks == 0 ? 'Clean run. No cracks.' : 'Cracked ${engine.cracks}×. Next one\'s cleaner.',
    );
  }

  void _teardown() {
    _engine = null;
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
    _clock.offset = Duration.zero;
  }
}

final sessionProvider = NotifierProvider<SessionController, ActiveSession?>(SessionController.new);

class LastResultNotifier extends Notifier<SessionResult?> {
  @override
  SessionResult? build() => null;
  void set(SessionResult r) => state = r;
  void clear() => state = null;
}

final lastResultProvider = NotifierProvider<LastResultNotifier, SessionResult?>(LastResultNotifier.new);
