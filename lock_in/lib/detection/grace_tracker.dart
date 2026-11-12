/// Pure crack-detection state machine. No platform code, no timers:
/// callers feed it signals with timestamps and call [tick] with the
/// current time. That keeps it testable and lets it judge retroactively
/// when the app was suspended (iOS) and only sees events late.
library;

/// Raw device signals, already normalised from iOS or Android.
enum DeviceSignal {
  /// App is in the foreground and receiving touches.
  appActive,

  /// App lost the foreground (another app, Control Centre, side button, ...).
  appInactive,

  /// Proximity sensor covered (phone face down or in a pocket). iOS face-down mode.
  proximityCovered,

  /// Proximity sensor uncovered.
  proximityUncovered,

  /// Device is locking (iOS: protectedDataWillBecomeUnavailable, Android: SCREEN_OFF).
  deviceLocked,

  /// Device was unlocked (iOS: protectedDataDidBecomeAvailable, Android: USER_PRESENT).
  deviceUnlocked,
}

/// What happened, as decided by the tracker.
sealed class TrackerEvent {
  const TrackerEvent(this.at);
  final DateTime at;
}

/// The phone stopped being "down"; the grace window started.
class GraceStarted extends TrackerEvent {
  const GraceStarted(super.at);
}

/// The phone went back down inside the grace window. No crack.
class GraceCancelled extends TrackerEvent {
  const GraceCancelled(super.at, this.after);
  final Duration after;
}

/// The grace window ran out. [at] is when the crack *happened*
/// (grace start + grace length), even if we noticed later.
class Cracked extends TrackerEvent {
  const Cracked(super.at, {required this.noticedLate});

  /// True when the crack was only evaluated after the fact (app was asleep).
  final bool noticedLate;
}

/// The phone is down again after a crack; detection re-armed.
class Rearmed extends TrackerEvent {
  const Rearmed(super.at);
}

// Session-level events (emitted by SessionEngine, not by GraceTracker).
// They live here because TrackerEvent is sealed.

/// Emitted when you relock in the last few seconds of the grace window.
class ClutchSave extends TrackerEvent {
  const ClutchSave(super.at);
}

/// Emitted at break boundaries and when a pass starts/ends.
class BreakStarted extends TrackerEvent {
  const BreakStarted(super.at);
}

class BreakEnded extends TrackerEvent {
  const BreakEnded(super.at);
}

class PassStarted extends TrackerEvent {
  const PassStarted(super.at);
}

class PassEnded extends TrackerEvent {
  const PassEnded(super.at);
}

class GraceTracker {
  GraceTracker({
    this.grace = const Duration(seconds: 10),
    required this.armedAt,
    bool initiallyActive = true,
    bool initiallyLocked = false,
    bool initiallyCovered = false,
  }) : _active = initiallyActive,
       _locked = initiallyLocked,
       _covered = initiallyCovered;

  final Duration grace;

  /// Detection only counts from this moment (gives the user time to put
  /// the phone down after tapping Start).
  final DateTime armedAt;

  bool _active;
  bool _locked;
  bool _covered;

  DateTime? _graceSince;
  bool _cracked = false;
  int crackCount = 0;

  /// The phone counts as "down" if it is locked, or Lock In is in the
  /// foreground with the proximity sensor covered (face-down mode).
  bool get isDown => _locked || (_active && _covered);
  bool get inGrace => _graceSince != null;
  bool get isCracked => _cracked;

  /// Feed one signal observed at [at]. Returns any decisions it caused.
  List<TrackerEvent> onSignal(DeviceSignal s, DateTime at) {
    // Before applying the new signal, settle any grace window that
    // would already have expired by [at].
    final out = tick(at);
    switch (s) {
      case DeviceSignal.appActive:
        _active = true;
        // Being in the foreground means the device is unlocked.
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
    out.addAll(_evaluate(at));
    return out;
  }

  /// Advance time. [lateBy] lets the caller mark that this tick happened
  /// long after the previous one (the app was suspended).
  List<TrackerEvent> tick(DateTime now, {bool noticedLate = false}) {
    final since = _graceSince;
    if (since == null) return [];
    final deadline = since.add(grace);
    if (!now.isBefore(deadline)) {
      _graceSince = null;
      _cracked = true;
      crackCount++;
      final late =
          noticedLate || now.difference(deadline) > const Duration(seconds: 2);
      return [Cracked(deadline, noticedLate: late)];
    }
    return [];
  }

  List<TrackerEvent> _evaluate(DateTime at) {
    final effective = at.isBefore(armedAt) ? armedAt : at;
    if (isDown) {
      if (_graceSince != null) {
        final after = effective.difference(_graceSince!);
        _graceSince = null;
        return [GraceCancelled(effective, after)];
      }
      if (_cracked) {
        _cracked = false;
        return [Rearmed(effective)];
      }
      return [];
    }
    // Not down.
    if (_graceSince == null && !_cracked) {
      _graceSince = effective;
      return [GraceStarted(effective)];
    }
    return [];
  }

  /// Call once when the run starts, after the setup period, to open a grace
  /// window if the phone is not down at that moment.
  List<TrackerEvent> arm() => _evaluate(armedAt);
}
