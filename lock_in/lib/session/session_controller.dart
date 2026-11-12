import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/vibes.dart';
import '../detection/grace_tracker.dart';
import '../group/group_controller.dart';
import '../group/protocol.dart';
import '../platform/device_bridge.dart';
import '../progression/aura.dart';
import '../storage/profile_store.dart';
import '../storage/progress_repo.dart';
import 'session_engine.dart';

/// A snapshot of the running session for the UI. A new object every tick.
class ActiveSession {
  const ActiveSession(
    this.engine,
    this.now, {
    required this.vibe,
    required this.group,
  });
  final SessionEngine engine;
  final DateTime now;
  final Vibe vibe;
  final bool group;

  SessionPhase get phase => engine.phase(now);
  Duration get locked => engine.lockedTime(now);
  int get cracks => engine.cracks;
  int? get graceLeft => engine.graceSecondsLeft(now);
  Duration? get suspensionLeft => engine.suspensionLeft(now);
  Duration? get nextBreakIn => engine.nextBreakIn(now);
  bool get passAvailable => engine.passAvailable;

  /// Remaining (planned) or elapsed (open-ended).
  Duration get clock {
    final end = engine.endsAt;
    if (end == null) return now.difference(engine.startedAt);
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  Duration get settleLeft => engine.armedAt.difference(now);

  MemberStatus get memberStatus => switch (phase) {
    SessionPhase.settling => MemberStatus.settling,
    SessionPhase.locked => MemberStatus.locked,
    SessionPhase.grace => MemberStatus.up,
    SessionPhase.cracked => MemberStatus.cracked,
    SessionPhase.onBreak => MemberStatus.onBreak,
    SessionPhase.pass => MemberStatus.pass,
    SessionPhase.done => MemberStatus.finished,
  };
}

/// One squad member as they finished, for results and the group card.
class SquadMemberResult {
  const SquadMemberResult(
    this.index,
    this.avatar,
    this.nickname,
    this.skin,
    this.cracks,
    this.lockedMin, {
    this.me = false,
  });
  final int index;
  final int avatar;
  final int nickname;
  final int skin;
  final int cracks;
  final int lockedMin;
  final bool me;
}

class SquadResult {
  const SquadResult({
    required this.members,
    required this.clean,
    required this.stake,
    this.firstCrack,
    this.winner,
    required this.lastStanding,
    required this.iWon,
  });
  final List<SquadMemberResult> members;
  final bool clean;
  final int stake;
  final int? firstCrack;
  final int? winner;
  final bool lastStanding;
  final bool iWon;
}

class SessionResult {
  const SessionResult({
    required this.aura,
    required this.cracks,
    required this.completed,
    required this.plannedLength,
    required this.levelBefore,
    required this.auraTotalAfter,
    required this.outcome,
    required this.endedAt,
    required this.vibe,
    required this.clutches,
    required this.passUsed,
    this.squad,
  });
  final AuraBreakdown aura;
  final int cracks;
  final bool completed;
  final Duration? plannedLength;
  final Level levelBefore;
  final int auraTotalAfter;
  final SessionOutcome outcome;
  final DateTime endedAt;
  final Vibe vibe;
  final int clutches;
  final bool passUsed;
  final SquadResult? squad;

  int get totalAura => aura.total + outcome.questAura;
  bool get leveledUp => levelFor(auraTotalAfter).number > levelBefore.number;
}

class SessionController extends Notifier<ActiveSession?> {
  SessionEngine? _engine;
  Vibe _vibe = Vibe.study;
  bool _group = false;
  StreamSubscription<DeviceEvent>? _sub;
  Timer? _ticker;
  Timer? _heartbeat;
  SessionPhase? _lastPhase;
  bool _finishing = false;

  DeviceBridge get _bridge => ref.read(deviceBridgeProvider);
  late AppClock _clock;

  @override
  ActiveSession? build() {
    _clock = ref.read(clockProvider);
    ref.onDispose(_teardown);
    return null;
  }

  Future<void> start(
    Duration? length, {
    Vibe vibe = Vibe.study,
    bool breaks = false,
    DateTime? startAt,
    bool group = false,
  }) async {
    final now = startAt ?? _clock.now();
    final engine = SessionEngine(
      startedAt: now,
      plannedLength: length,
      breaks: breaks ? const BreakPlan() : null,
    );
    _engine = engine;
    _vibe = vibe;
    _group = group;
    _finishing = false;
    _lastPhase = null;
    ref.read(lastResultProvider.notifier).clear();
    _sub = _bridge.events.listen(_onDevice);
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    if (group) {
      _heartbeat = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _report(force: true),
      );
    }
    state = ActiveSession(engine, _clock.now(), vibe: vibe, group: group);
    await ref
        .read(prefsProvider)
        .setInt(activeSessionKey, now.millisecondsSinceEpoch);
    await _bridge.startSession(
      startAt: engine.startedAt.subtract(_clock.offset),
      endAt: engine.endsAt?.subtract(_clock.offset),
      group: group,
    );
  }

  void _onDevice(DeviceEvent e) {
    final engine = _engine;
    if (engine == null) return;
    if (e.name == 'emergencyPass') {
      usePass();
      return;
    }
    final s = e.signal;
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

  /// "I genuinely need my phone." Once per session.
  bool usePass() {
    final engine = _engine;
    if (engine == null) return false;
    final ok = engine.usePass(_clock.now());
    if (ok) {
      _bridge.updateNotification(
        'Emergency pass 🆘',
        "No cracks for 5 min. Lock your phone when you're done.",
      );
      _tick();
    }
    return ok;
  }

  void _tick() {
    final engine = _engine;
    if (engine == null || _finishing) return;
    final now = _clock.now();
    _handle(engine.tick(now));
    if (engine.isComplete(now)) {
      finish();
      return;
    }
    state = ActiveSession(engine, now, vibe: _vibe, group: _group);
    final phase = engine.phase(now);
    if (phase != _lastPhase) {
      _lastPhase = phase;
      _report();
    }
  }

  void _report({bool force = false}) {
    final s = state;
    if (!_group || s == null) return;
    ref
        .read(groupProvider.notifier)
        .reportMine(
          status: s.memberStatus,
          cracks: s.cracks,
          lockedSec: s.locked.inSeconds,
          clutches: s.engine.clutches,
          force: force,
        );
  }

  void _handle(List<TrackerEvent> events) {
    final haptics = ref.read(settingsProvider).haptics;
    for (final e in events) {
      switch (e) {
        case GraceStarted():
          if (haptics) HapticFeedback.mediumImpact();
        case Cracked():
          if (haptics) HapticFeedback.heavyImpact();
          _bridge.updateNotification(
            'Cracked 💔',
            'Lock your phone to keep farming aura.',
          );
        case Rearmed():
          _bridge.updateNotification('Locked in 🔒', 'Back on track. Aura up.');
        case ClutchSave():
          if (haptics) HapticFeedback.heavyImpact();
          _bridge.updateNotification(
            'CLUTCH 😮‍💨',
            'Saved it with seconds to spare. +2 aura.',
          );
        case BreakStarted():
          if (haptics) HapticFeedback.lightImpact();
          _bridge.updateNotification(
            'Break time ☕',
            '5 minutes. Use your phone guilt-free.',
          );
        case BreakEnded():
          if (haptics) HapticFeedback.heavyImpact();
          _bridge.updateNotification(
            'Break over 🔒',
            'Lock your phone to keep going.',
          );
        case PassStarted() || PassEnded() || GraceCancelled():
          break;
      }
    }
  }

  /// Ends the session (on time, early, or because the squad ended) and
  /// banks the aura.
  Future<void> finish() async {
    final engine = _engine;
    if (engine == null || _finishing) return;
    _finishing = true;
    final now = _clock.now();
    final completed = engine.isComplete(now);
    final group = _group ? ref.read(groupProvider) : null;
    _teardown();

    SquadResult? squad;
    if (group != null) {
      final me = group.myIndex;
      final members = group.sorted
          .where((m) => !m.gone || m.index == me)
          .toList();
      final iWon =
          group.config.lastStanding &&
          group.config.winner != null &&
          group.config.winner == me;
      squad = SquadResult(
        members: [
          for (final m in members)
            SquadMemberResult(
              m.index,
              m.avatar,
              m.nickname,
              m.skin,
              m.index == me ? engine.cracks : m.cracks,
              m.index == me
                  ? engine.lockedTime(now).inMinutes
                  : m.lockedSec ~/ 60,
              me: m.index == me,
            ),
        ],
        clean:
            members.length >= 2 &&
            engine.cracks == 0 &&
            members.every((m) => m.index == me || m.cracks == 0),
        stake: group.config.stake,
        firstCrack: group.config.firstCrack,
        winner: group.config.winner,
        lastStanding: group.config.lastStanding,
        iWon: iWon,
      );
      await ref
          .read(groupProvider.notifier)
          .mySessionFinished(
            early: !completed && group.config.phase != GroupPhase.ended,
          );
    }

    final repo = ref.read(repoProvider);
    final before = await repo.load(now);
    final locked = engine.lockedTime(now);
    final aura = scoreSession(
      locked: locked,
      cracks: engine.cracks,
      completedPlannedLength: completed,
      plannedLength: engine.plannedLength,
      earnedTodaySoFar: before.auraToday,
      clutches: engine.clutches,
      squadClean: squad?.clean ?? false,
    );
    final outcome = await repo.recordSession(
      startedAt: engine.startedAt,
      endedAt: now,
      plannedMinutes: engine.plannedLength?.inMinutes,
      lockedSeconds: locked.inSeconds,
      cracks: engine.cracks,
      completed: completed,
      aura: aura.total,
      vibe: _vibe,
      clutches: engine.clutches,
      passUsed: engine.passUsed,
      groupSize: squad?.members.length ?? 1,
      squadClean: squad?.clean ?? false,
      won: squad?.iWon ?? false,
    );
    await ref.read(progressProvider.notifier).refresh();
    ref
        .read(lastResultProvider.notifier)
        .set(
          SessionResult(
            aura: aura,
            cracks: engine.cracks,
            completed: completed,
            plannedLength: engine.plannedLength,
            levelBefore: before.level,
            auraTotalAfter: before.auraTotal + aura.total + outcome.questAura,
            outcome: outcome,
            endedAt: now,
            vibe: _vibe,
            clutches: engine.clutches,
            passUsed: engine.passUsed,
            squad: squad,
          ),
        );
    state = null;
    await ref.read(prefsProvider).remove(activeSessionKey);
    final total = aura.total + outcome.questAura;
    await _bridge.stopSession(
      doneTitle: completed || squad != null
          ? 'Session done ✦ +$total aura'
          : null,
      doneText: engine.cracks == 0
          ? 'Clean run. No cracks.'
          : "Cracked ${engine.cracks}×. Next one's cleaner.",
    );
  }

  void _teardown() {
    _engine = null;
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _clock.offset = Duration.zero;
  }
}

final sessionProvider = NotifierProvider<SessionController, ActiveSession?>(
  SessionController.new,
);

class LastResultNotifier extends Notifier<SessionResult?> {
  @override
  SessionResult? build() => null;
  void set(SessionResult r) => state = r;
  void clear() => state = null;
}

final lastResultProvider = NotifierProvider<LastResultNotifier, SessionResult?>(
  LastResultNotifier.new,
);
