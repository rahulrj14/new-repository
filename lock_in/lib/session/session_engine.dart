import '../detection/grace_tracker.dart';

export '../detection/grace_tracker.dart'
    show ClutchSave, BreakStarted, BreakEnded, PassStarted, PassEnded;

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

  /// Scheduled break (break mode). Use your phone freely.
  onBreak,

  /// Emergency pass in use. No cracks until you lock again (or it runs out).
  pass,

  /// Planned length reached.
  done,
}

/// Work/break rhythm, e.g. 25 min on, 5 min off.
class BreakPlan {
  const BreakPlan({
    this.work = const Duration(minutes: 25),
    this.rest = const Duration(minutes: 5),
  });
  final Duration work;
  final Duration rest;
}

/// One session (solo or your part of a group). Pure: callers pass signals
/// and times in; it never reads the clock itself.
///
/// Time accounting is incremental: between consecutive inputs the phone is
/// in one known state, so locked time accrues only while it is down, armed,
/// and not on a break.
class SessionEngine {
  SessionEngine({
    required this.startedAt,
    this.plannedLength,
    this.settle = const Duration(seconds: 10),
    this.grace = const Duration(seconds: 10),
    this.breaks,
    this.clutchWindow = const Duration(seconds: 3),
    this.passLength = const Duration(minutes: 5),
  }) {
    _tracker = _newTracker(armedAt);
  }

  final DateTime startedAt;
  final Duration? plannedLength;
  final Duration settle;
  final Duration grace;
  final BreakPlan? breaks;
  final Duration clutchWindow;
  final Duration passLength;

  DateTime get armedAt => startedAt.add(settle);
  DateTime? get endsAt =>
      plannedLength == null ? null : startedAt.add(plannedLength!);

  // Device state, tracked here so it survives tracker rebuilds.
  bool _active = true;
  bool _locked = false;
  bool _covered = false;
  bool get isDown => _locked || (_active && _covered);

  late GraceTracker _tracker;
  int _crackBase = 0;
  int clutches = 0;

  /// The single emergency pass for this session.
  bool passUsed = false;
  DateTime? _passUntil;

  /// True while breaks or a pass suspend crack detection.
  bool _suspended = false;
  bool _armed = false;
  bool _inBreak = false;

  Duration _locked_ = Duration.zero;
  DateTime? _lastAt;
  final List<TrackerEvent> history = [];

  int get cracks => _crackBase + _tracker.crackCount;
  bool get passAvailable => !passUsed;

  GraceTracker _newTracker(DateTime armAt) => GraceTracker(
    armedAt: armAt,
    grace: grace,
    initiallyActive: _active,
    initiallyLocked: _locked,
    initiallyCovered: _covered,
  );

  // ---- breaks -------------------------------------------------------------

  /// Break k runs [armedAt + k*(w+r) + w, + r).
  (DateTime, DateTime)? _breakAt(DateTime t) {
    final b = breaks;
    if (b == null || t.isBefore(armedAt)) return null;
    final cycle = b.work + b.rest;
    final k = t.difference(armedAt).inMilliseconds ~/ cycle.inMilliseconds;
    final start = armedAt.add(cycle * k + b.work);
    final end = start.add(b.rest);
    if (!t.isBefore(start) && t.isBefore(end)) return (start, end);
    return null;
  }

  /// Total break time inside [a, b).
  Duration _breakOverlap(DateTime a, DateTime b) {
    final plan = breaks;
    if (plan == null || !b.isAfter(a)) return Duration.zero;
    final cycle = plan.work + plan.rest;
    var total = Duration.zero;
    final from = a.isBefore(armedAt) ? armedAt : a;
    if (!b.isAfter(from)) return Duration.zero;
    var k = from.difference(armedAt).inMilliseconds ~/ cycle.inMilliseconds;
    while (true) {
      final s = armedAt.add(cycle * k + plan.work);
      final e = s.add(plan.rest);
      if (!s.isBefore(b)) break;
      final lo = s.isAfter(from) ? s : from;
      final hi = e.isBefore(b) ? e : b;
      if (hi.isAfter(lo)) total += hi.difference(lo);
      k++;
    }
    return total;
  }

  /// Next break boundary strictly after [t], up to [limit].
  DateTime? _nextBoundary(DateTime t, DateTime limit) {
    final plan = breaks;
    if (plan == null) return null;
    final cycle = plan.work + plan.rest;
    final base = t.isBefore(armedAt) ? armedAt : t;
    final k = base.difference(armedAt).inMilliseconds ~/ cycle.inMilliseconds;
    for (var i = k; i <= k + 1; i++) {
      for (final c in [
        armedAt.add(cycle * i + plan.work),
        armedAt.add(cycle * i + plan.work + plan.rest),
      ]) {
        if (c.isAfter(t) && !c.isAfter(limit)) return c;
      }
    }
    return null;
  }

  // ---- core ---------------------------------------------------------------

  DateTime _clampToEnd(DateTime t) {
    final end = endsAt;
    return end != null && t.isAfter(end) ? end : t;
  }

  void _accrue(DateTime to) {
    final from = _lastAt;
    _lastAt = to;
    if (from == null || !to.isAfter(from)) return;
    final lo = from.isBefore(armedAt) ? armedAt : from;
    if (!to.isAfter(lo)) return;
    if (isDown) _locked_ += to.difference(lo) - _breakOverlap(lo, to);
  }

  /// Advance time to [t], handling break boundaries and pass expiry on the way.
  List<TrackerEvent> _advance(DateTime t) {
    final out = <TrackerEvent>[];
    var cursor = _lastAt ?? startedAt;
    if (!_armed && !t.isBefore(armedAt)) {
      // Crossing the end of the settle period: start detection.
      _accrue(armedAt);
      _armed = true;
      if (!_suspended) out.addAll(_tracker.arm());
      cursor = armedAt;
    }
    while (true) {
      final passEnd = _passUntil;
      final boundary = _nextBoundary(cursor, t);
      DateTime? next = boundary;
      if (passEnd != null && passEnd.isAfter(cursor) && !passEnd.isAfter(t)) {
        if (next == null || passEnd.isBefore(next)) next = passEnd;
      }
      if (next == null) break;
      out.addAll(_feedTracker(next));
      _accrue(next);
      if (passEnd != null && next == passEnd) {
        _endPass(next, out);
      } else {
        _updateBreakState(next, out);
      }
      cursor = next;
    }
    out.addAll(_feedTracker(t));
    _accrue(t);
    _updateBreakState(t, out);
    return out;
  }

  List<TrackerEvent> _feedTracker(DateTime t) =>
      _suspended ? const [] : _tracker.tick(t);

  void _updateBreakState(DateTime t, List<TrackerEvent> out) {
    final inBreak = _breakAt(t) != null;
    if (inBreak == _inBreak) return;
    _inBreak = inBreak;
    if (inBreak) {
      out.add(BreakStarted(t));
      _suspend();
    } else {
      out.add(BreakEnded(t));
      if (_passUntil == null) _resume(t, out);
    }
  }

  void _suspend() {
    if (_suspended) return;
    _crackBase += _tracker.crackCount;
    _suspended = true;
  }

  void _resume(DateTime t, List<TrackerEvent> out) {
    if (!_suspended || _inBreak) return;
    _suspended = false;
    _tracker = _newTracker(t);
    out.addAll(_tracker.arm());
  }

  void _endPass(DateTime t, List<TrackerEvent> out) {
    if (_passUntil == null) return;
    _passUntil = null;
    out.add(PassEnded(t));
    _resume(t, out);
  }

  List<TrackerEvent> onSignal(DeviceSignal s, DateTime at) {
    final t = _clampToEnd(at);
    final out = _advance(t);
    switch (s) {
      case DeviceSignal.appActive:
        _active = true;
        _locked = false;
      case DeviceSignal.appInactive:
        _active = false;
      case DeviceSignal.proximityCovered:
        _covered = true;
      case DeviceSignal.proximityUncovered:
        _covered = false;
      case DeviceSignal.deviceLocked:
        _locked = true;
      case DeviceSignal.deviceUnlocked:
        _locked = false;
    }
    if (!_suspended) {
      final evs = _tracker.onSignal(s, t);
      for (final e in evs) {
        if (e is GraceCancelled &&
            e.after >= grace - clutchWindow &&
            e.after < grace) {
          clutches++;
          out.add(e);
          out.add(ClutchSave(e.at));
        } else {
          out.add(e);
        }
      }
    } else if (_passUntil != null && isDown && !_inBreak) {
      // Locking again ends the pass early.
      _endPass(t, out);
    }
    history.addAll(out);
    return out;
  }

  List<TrackerEvent> tick(DateTime now) {
    final out = _advance(_clampToEnd(now));
    history.addAll(out);
    return out;
  }

  /// Use the session's single emergency pass. Returns false if already used.
  bool usePass(DateTime now) {
    if (passUsed || isComplete(now)) return false;
    final t = _clampToEnd(now);
    final out = _advance(t);
    passUsed = true;
    _passUntil = t.add(passLength);
    _suspend();
    out.add(PassStarted(t));
    history.addAll(out);
    return true;
  }

  Duration lockedTime(DateTime now) {
    final t = _clampToEnd(now);
    final last = _lastAt;
    var d = _locked_;
    if (last != null && t.isAfter(last) && isDown) {
      final lo = last.isBefore(armedAt) ? armedAt : last;
      if (t.isAfter(lo)) d += t.difference(lo) - _breakOverlap(lo, t);
    }
    return d;
  }

  bool isComplete(DateTime now) {
    final end = endsAt;
    return end != null && !now.isBefore(end);
  }

  /// Seconds left in the current break or pass, if any.
  Duration? suspensionLeft(DateTime now) {
    final p = _passUntil;
    if (p != null) return p.difference(now);
    final b = _breakAt(now);
    if (b != null) return b.$2.difference(now);
    return null;
  }

  /// Time until the next break starts (break mode only).
  Duration? nextBreakIn(DateTime now) {
    final plan = breaks;
    if (plan == null || _breakAt(now) != null || now.isBefore(armedAt)) {
      return null;
    }
    final n = _nextBoundary(now, now.add(plan.work + plan.rest));
    return n?.difference(now);
  }

  SessionPhase phase(DateTime now) {
    if (isComplete(now)) return SessionPhase.done;
    if (now.isBefore(armedAt)) return SessionPhase.settling;
    if (_passUntil != null) return SessionPhase.pass;
    if (_breakAt(now) != null) return SessionPhase.onBreak;
    if (_tracker.isCracked) return SessionPhase.cracked;
    if (_tracker.inGrace) return SessionPhase.grace;
    return isDown ? SessionPhase.locked : SessionPhase.grace;
  }

  /// Seconds left in the current grace window, or null.
  int? graceSecondsLeft(DateTime now) {
    final g = history.whereType<GraceStarted>().lastOrNull;
    if (_suspended || !_tracker.inGrace || g == null) return null;
    final left = grace - now.difference(g.at);
    return left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
  }
}
