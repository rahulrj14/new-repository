/// Streak rules. Pure, no I/O, no clock.
///
/// A day "qualifies" once you have [qualifyingMinutes] locked minutes that day.
/// Every 7-day milestone earns a freeze (hold at most [maxFreezes]). Freezes
/// are spent automatically to cover missed days, so one off day never wipes
/// a streak. No notifications, no guilt trips.
library;

const qualifyingMinutes = 25;

/// Seconds that actually qualify: a 1-minute allowance so a 25-minute
/// session (which loses ~10 s to the "lock your phone" start) still counts.
const qualifyingSeconds = qualifyingMinutes * 60 - 60;
const maxFreezes = 2;
const freezeEvery = 7;

/// Day number in local calendar terms, immune to DST shifts.
int dayNumber(DateTime local) => DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/ 86400000;

DateTime dayFromNumber(int n) {
  final u = DateTime.fromMillisecondsSinceEpoch(n * 86400000, isUtc: true);
  return DateTime(u.year, u.month, u.day);
}

class StreakState {
  const StreakState({this.current = 0, this.longest = 0, this.freezes = 0, this.lastDay});
  final int current;
  final int longest;
  final int freezes;

  /// [dayNumber] of the last qualifying (or frozen) day.
  final int? lastDay;

  StreakState copyWith({int? current, int? longest, int? freezes, int? lastDay}) => StreakState(
        current: current ?? this.current,
        longest: longest ?? this.longest,
        freezes: freezes ?? this.freezes,
        lastDay: lastDay ?? this.lastDay,
      );

  @override
  bool operator ==(Object other) =>
      other is StreakState &&
      other.current == current &&
      other.longest == longest &&
      other.freezes == freezes &&
      other.lastDay == lastDay;

  @override
  int get hashCode => Object.hash(current, longest, freezes, lastDay);
}

class StreakUpdate {
  const StreakUpdate(this.state, {this.freezesUsed = 0, this.earnedFreeze = false, this.reset = false});
  final StreakState state;
  final int freezesUsed;
  final bool earnedFreeze;

  /// The old streak had already broken; this day starts a new one.
  final bool reset;
}

/// Record that [day] qualified.
StreakUpdate recordQualifiedDay(StreakState s, int day) {
  final last = s.lastDay;
  if (last != null && day <= last) return StreakUpdate(s);
  var current = s.current;
  var freezes = s.freezes;
  var used = 0;
  var reset = false;
  if (last == null) {
    current = 1;
  } else {
    final missed = day - last - 1;
    if (missed == 0) {
      current += 1;
    } else if (missed <= freezes) {
      freezes -= missed;
      used = missed;
      current += 1;
    } else {
      current = 1;
      reset = true;
    }
  }
  var earned = false;
  if (current % freezeEvery == 0 && freezes < maxFreezes) {
    freezes += 1;
    earned = true;
  }
  return StreakUpdate(
    StreakState(
      current: current,
      longest: current > s.longest ? current : s.longest,
      freezes: freezes,
      lastDay: day,
    ),
    freezesUsed: used,
    earnedFreeze: earned,
    reset: reset,
  );
}

/// What to show for [today].
class StreakView {
  const StreakView({
    required this.days,
    required this.freezes,
    required this.doneToday,
    required this.frozenDays,
    required this.longest,
  });

  /// Current streak as shown (0 if broken).
  final int days;
  final int freezes;
  final bool doneToday;

  /// Missed days that will be covered by freezes if you qualify today.
  final int frozenDays;
  final int longest;

  bool get alive => days > 0;
}

StreakView viewStreak(StreakState s, int today) {
  final last = s.lastDay;
  if (last == null) {
    return StreakView(days: 0, freezes: s.freezes, doneToday: false, frozenDays: 0, longest: s.longest);
  }
  final gap = today - last;
  if (gap <= 0) {
    return StreakView(days: s.current, freezes: s.freezes, doneToday: true, frozenDays: 0, longest: s.longest);
  }
  final missed = gap - 1;
  if (missed <= s.freezes) {
    return StreakView(days: s.current, freezes: s.freezes, doneToday: false, frozenDays: missed, longest: s.longest);
  }
  return StreakView(days: 0, freezes: s.freezes, doneToday: false, frozenDays: 0, longest: s.longest);
}
