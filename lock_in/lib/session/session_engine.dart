import '../detection/grace_tracker.dart';

/// What the session screen shows.
enum SessionPhase {
  /// First few seconds: time to put the phone down. Nothing counts yet.
  settling,

  /// Phone is down. Aura is ticking.
  locked,

  /// Phone is up; the 10 s grace window is running.
  grace,

  /// Grace ran out. Not earning until the phone goes down again.
  cracked,

  /// Planned length reached.
  done,
}

/// One solo session. Pure: callers pass signals and times in; it never
/// reads the clock itself. Wraps [GraceTracker] and adds time accounting.
class SessionEngine {
  SessionEngine({
    required this.startedAt,
    this.plannedLength,
    this.settle = const Duration(seconds: 10),
    Duration grace = const Duration(seconds: 10),
  }) : tracker = GraceTracker(
          armedAt: startedAt.add(settle),
          grace: grace,
          initiallyActive: true,
        );

  final DateTime startedAt;

  /// Null for open-ended sessions.
  final Duration? plannedLength;
  final Duration settle;
  final GraceTracker tracker;

  DateTime get armedAt => tracker.armedAt;
  DateTime? get endsAt => plannedLength == null ? null : startedAt.add(plannedLength!);

  /// Phone-up time since [armedAt] that has finished (closed intervals).
  Duration _upTotal = Duration.zero;

  /// Start of the current phone-up interval, if the phone is up now.
  DateTime? _upSince;
  bool _armed = false;
  final List<TrackerEvent> history = [];

  int get cracks => tracker.crackCount;

  /// Call when [now] passes [armedAt] (or on any later tick; it is idempotent).
  List<TrackerEvent> _armIfDue(DateTime now) {
    if (_armed || now.isBefore(armedAt)) return const [];
    _armed = true;
    if (!tracker.isDown) _upSince = armedAt;
    return tracker.arm();
  }

  List<TrackerEvent> onSignal(DeviceSignal s, DateTime at) {
    final at2 = _clampToEnd(at);
    final out = <TrackerEvent>[..._armIfDue(at2)];
    final wasDown = tracker.isDown;
    out.addAll(tracker.onSignal(s, at2));
    final isDown = tracker.isDown;
    if (_armed) {
      if (wasDown && !isDown) _upSince = at2;
      if (!wasDown && isDown) _closeUp(at2);
    }
    history.addAll(out);
    return out;
  }

  List<TrackerEvent> tick(DateTime now) {
    final out = <TrackerEvent>[..._armIfDue(now), ...tracker.tick(_clampToEnd(now))];
    history.addAll(out);
    return out;
  }

  void _closeUp(DateTime at) {
    final since = _upSince;
    if (since != null) {
      _upTotal += at.difference(since);
      _upSince = null;
    }
  }

  DateTime _clampToEnd(DateTime t) {
    final end = endsAt;
    return end != null && t.isAfter(end) ? end : t;
  }

  /// Time with the phone down since arming, up to [now] (or the end).
  Duration lockedTime(DateTime now) {
    final t = _clampToEnd(now);
    if (t.isBefore(armedAt)) return Duration.zero;
    var up = _upTotal;
    final since = _upSince ?? (!_armed && !tracker.isDown ? armedAt : null);
    if (since != null) up += t.difference(since);
    final d = t.difference(armedAt) - up;
    return d.isNegative ? Duration.zero : d;
  }

  bool isComplete(DateTime now) {
    final end = endsAt;
    return end != null && !now.isBefore(end);
  }

  SessionPhase phase(DateTime now) {
    if (isComplete(now)) return SessionPhase.done;
    if (now.isBefore(armedAt)) return SessionPhase.settling;
    if (tracker.isCracked) return SessionPhase.cracked;
    if (tracker.inGrace) return SessionPhase.grace;
    return tracker.isDown ? SessionPhase.locked : SessionPhase.grace;
  }

  /// Seconds left in the current grace window, or null.
  int? graceSecondsLeft(DateTime now) {
    final g = history.whereType<GraceStarted>().lastOrNull;
    if (!tracker.inGrace || g == null) return null;
    final left = tracker.grace - now.difference(g.at);
    return left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
  }
}
