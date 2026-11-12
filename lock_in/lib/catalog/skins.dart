/// Skins are accessories drawn on top of your blob. Earned only by keeping
/// your phone down (levels, streaks); nothing to buy in this version.
/// IDs are stable: never reorder, only append.
library;

enum Accessory {
  none,
  shades,
  headphones,
  beanie,
  partyHat,
  flower,
  crown,
  halo,
  cap,
  starGlasses,
  diya,
  pumpkin,
  sparkleSpecs,
  nerd,
}

sealed class Unlock {
  const Unlock();
}

class Free extends Unlock {
  const Free();
}

class AtLevel extends Unlock {
  const AtLevel(this.level);
  final int level;
}

class AtStreak extends Unlock {
  const AtStreak(this.days);
  final int days;
}

class AfterSessions extends Unlock {
  const AfterSessions(this.count);
  final int count;
}

/// Earned by finishing any session inside a date window. Free, never sold.
class Seasonal extends Unlock {
  const Seasonal(this.event, this.windows);
  final String event;

  /// (start, end) inclusive local dates as (year, month, day).
  /// Year 0 = every year (the window may wrap over New Year).
  final List<((int, int, int), (int, int, int))> windows;

  bool activeOn(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    for (final (a, b) in windows) {
      if (a.$1 == 0) {
        final s = DateTime(day.year, a.$2, a.$3);
        final e = DateTime(day.year, b.$2, b.$3);
        final inside = e.isBefore(s)
            ? !day.isBefore(s) || !day.isAfter(e)
            : !day.isBefore(s) && !day.isAfter(e);
        if (inside) return true;
      } else {
        final s = DateTime(a.$1, a.$2, a.$3);
        final e = DateTime(b.$1, b.$2, b.$3);
        if (!day.isBefore(s) && !day.isAfter(e)) return true;
      }
    }
    return false;
  }
}

class Skin {
  const Skin(this.id, this.name, this.accessory, this.unlock);
  final int id;
  final String name;
  final Accessory accessory;
  final Unlock unlock;

  String get requirement => switch (unlock) {
    Free() => 'free',
    AtLevel(:final level) => 'reach LV $level',
    AtStreak(:final days) => '$days-day streak',
    AfterSessions(:final count) =>
      count == 1 ? 'finish 1 session' : 'finish $count sessions',
    Seasonal(:final event) => 'lock in during $event',
  };
}

const skins = <Skin>[
  Skin(0, 'Classic', Accessory.none, Free()),
  Skin(1, 'Party', Accessory.partyHat, AfterSessions(1)),
  Skin(2, 'Shades', Accessory.shades, AtLevel(2)),
  Skin(3, 'Beanie', Accessory.beanie, AtStreak(3)),
  Skin(4, 'Headphones', Accessory.headphones, AtLevel(3)),
  Skin(5, 'Flower', Accessory.flower, AfterSessions(10)),
  Skin(6, 'Halo', Accessory.halo, AtStreak(7)),
  Skin(7, 'Crown', Accessory.crown, AtLevel(5)),
  Skin(8, 'Cap', Accessory.cap, AtStreak(14)),
  Skin(9, 'Star Specs', Accessory.starGlasses, AtLevel(7)),
  // Seasonal: earned by finishing a session during the window.
  Skin(
    10,
    'Diya',
    Accessory.diya,
    Seasonal('Diwali', [
      ((2026, 11, 3), (2026, 11, 13)),
      ((2027, 10, 24), (2027, 11, 3)),
      ((2028, 10, 12), (2028, 10, 22)),
    ]),
  ),
  Skin(
    11,
    'Pumpkin',
    Accessory.pumpkin,
    Seasonal('Halloween week', [((0, 10, 24), (0, 10, 31))]),
  ),
  Skin(
    12,
    'New Year Specs',
    Accessory.sparkleSpecs,
    Seasonal('New Year', [((0, 12, 28), (0, 1, 4))]),
  ),
  Skin(
    13,
    'Exam Mode',
    Accessory.nerd,
    Seasonal('exam season', [((0, 4, 15), (0, 6, 15))]),
  ),
];

/// Seasonal skins whose window includes [d].
List<Skin> seasonalActive(DateTime d) => [
  for (final s in skins)
    if (s.unlock case final Seasonal se when se.activeOn(d)) s,
];

Skin skinById(int id) =>
    skins.firstWhere((s) => s.id == id, orElse: () => skins.first);

class UnlockStats {
  const UnlockStats({
    required this.level,
    required this.longestStreak,
    required this.sessions,
  });
  final int level;
  final int longestStreak;
  final int sessions;
}

bool isUnlocked(Skin s, UnlockStats st) => switch (s.unlock) {
  Free() => true,
  AtLevel(:final level) => st.level >= level,
  AtStreak(:final days) => st.longestStreak >= days,
  AfterSessions(:final count) => st.sessions >= count,
  // Recorded in the database when earned; not derivable from stats.
  Seasonal() => false,
};

/// Skins unlocked by going from [before] to [after].
List<Skin> newlyUnlocked(UnlockStats before, UnlockStats after) => [
  for (final s in skins)
    if (!isUnlocked(s, before) && isUnlocked(s, after)) s,
];
