/// Aura rules. Pure functions, no I/O. All numbers live here so they are
/// easy to tune. The only way to earn is to keep the phone down.
library;

class AuraRules {
  static const perLockedMinute = 1;
  static const crackPenalty = 5;
  static const cleanFinishBonus = 10;

  /// Clean-finish bonus only for planned sessions at least this long.
  static const minBonusLength = Duration(minutes: 25);

  /// Healthy cap: no reason to grind past this in a day.
  static const dailyCap = 300;
}

class AuraBreakdown {
  const AuraBreakdown({
    required this.lockedMinutes,
    required this.base,
    required this.penalty,
    required this.bonus,
    required this.capTrimmed,
    required this.total,
  });

  final int lockedMinutes;
  final int base;
  final int penalty;
  final int bonus;

  /// Aura that would have been earned but was over today's cap.
  final int capTrimmed;
  final int total;

  bool get hitCap => capTrimmed > 0;
}

AuraBreakdown scoreSession({
  required Duration locked,
  required int cracks,
  required bool completedPlannedLength,
  Duration? plannedLength,
  required int earnedTodaySoFar,
}) {
  final minutes = locked.inMinutes;
  final base = minutes * AuraRules.perLockedMinute;
  final penalty = cracks * AuraRules.crackPenalty;
  final bonus = completedPlannedLength &&
          cracks == 0 &&
          plannedLength != null &&
          plannedLength >= AuraRules.minBonusLength
      ? AuraRules.cleanFinishBonus
      : 0;
  final raw = (base - penalty + bonus).clamp(0, 1 << 30);
  final room = (AuraRules.dailyCap - earnedTodaySoFar).clamp(0, AuraRules.dailyCap);
  final total = raw < room ? raw : room;
  return AuraBreakdown(
    lockedMinutes: minutes,
    base: base,
    penalty: penalty > base + bonus ? base + bonus : penalty,
    bonus: bonus,
    capTrimmed: raw - total,
    total: total,
  );
}

class Level {
  const Level(this.number, this.name, this.floor, this.next);
  final int number;
  final String name;
  final int floor;

  /// Aura needed for the next level, or null at max level.
  final int? next;

  double progress(int aura) {
    final n = next;
    if (n == null) return 1;
    return ((aura - floor) / (n - floor)).clamp(0.0, 1.0);
  }
}

const _levels = <(int, String)>[
  (0, 'NPC'),
  (50, 'Side Quest'),
  (150, 'Locked In'),
  (300, 'Aura Farmer'),
  (500, 'Main Character'),
  (800, 'Untouchable'),
  (1200, 'Monk Mode'),
  (1800, 'Final Boss'),
];

Level levelFor(int aura) {
  var i = 0;
  while (i + 1 < _levels.length && aura >= _levels[i + 1].$1) {
    i++;
  }
  final next = i + 1 < _levels.length ? _levels[i + 1].$1 : null;
  return Level(i + 1, _levels[i].$2, _levels[i].$1, next);
}
