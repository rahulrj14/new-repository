/// Skins are accessories drawn on top of your blob. Earned only by keeping
/// your phone down (levels, streaks); nothing to buy in this version.
/// IDs are stable: never reorder, only append.
library;

enum Accessory { none, shades, headphones, beanie, partyHat, flower, crown, halo, cap, starGlasses }

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
        AfterSessions(:final count) => count == 1 ? 'finish 1 session' : 'finish $count sessions',
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
];

Skin skinById(int id) => skins.firstWhere((s) => s.id == id, orElse: () => skins.first);

class UnlockStats {
  const UnlockStats({required this.level, required this.longestStreak, required this.sessions});
  final int level;
  final int longestStreak;
  final int sessions;
}

bool isUnlocked(Skin s, UnlockStats st) => switch (s.unlock) {
      Free() => true,
      AtLevel(:final level) => st.level >= level,
      AtStreak(:final days) => st.longestStreak >= days,
      AfterSessions(:final count) => st.sessions >= count,
    };

/// Skins unlocked by going from [before] to [after].
List<Skin> newlyUnlocked(UnlockStats before, UnlockStats after) =>
    [for (final s in skins) if (!isUnlocked(s, before) && isUnlocked(s, after)) s];
