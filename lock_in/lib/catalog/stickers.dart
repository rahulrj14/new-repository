/// Reaction stickers of your own blob. Earned, then saved/shared as images
/// through the system share sheet (there is no in-app messaging).
library;

/// Lifetime stats used for sticker unlocks.
class StickerStats {
  const StickerStats({
    required this.sessions,
    required this.cleanSessions,
    required this.clutches,
    required this.cracks,
    required this.longestSessionMin,
    required this.groupSessions,
    required this.wins,
    required this.longestStreak,
  });
  final int sessions;
  final int cleanSessions;
  final int clutches;
  final int cracks;
  final int longestSessionMin;
  final int groupSessions;
  final int wins;
  final int longestStreak;

  static const zero = StickerStats(
    sessions: 0,
    cleanSessions: 0,
    clutches: 0,
    cracks: 0,
    longestSessionMin: 0,
    groupSessions: 0,
    wins: 0,
    longestStreak: 0,
  );
}

/// Mood names match BlobMood in the UI.
class Sticker {
  const Sticker(
    this.id,
    this.label,
    this.mood,
    this.requirement,
    this.unlocked, {
    this.cracked = false,
  });
  final int id;
  final String label;
  final String mood;
  final String requirement;
  final bool Function(StickerStats s) unlocked;
  final bool cracked;
}

final stickers = <Sticker>[
  Sticker(0, 'LOCKED IN', 'sleepy', 'finish a session', (s) => s.sessions >= 1),
  Sticker(1, 'CLUTCH', 'shocked', 'land a clutch save', (s) => s.clutches >= 1),
  Sticker(
    2,
    'OOPS 💔',
    'shocked',
    'crack once (it happens)',
    (s) => s.cracks >= 1,
    cracked: true,
  ),
  Sticker(
    3,
    'MAIN CHARACTER',
    'happy',
    '5 clean sessions',
    (s) => s.cleanSessions >= 5,
  ),
  Sticker(
    4,
    'BIG BRAIN',
    'idle',
    'a 90-min session',
    (s) => s.longestSessionMin >= 85,
  ),
  Sticker(
    5,
    'SQUAD',
    'happy',
    'lock in with friends',
    (s) => s.groupSessions >= 1,
  ),
  Sticker(
    6,
    'LAST ONE STANDING',
    'happy',
    'win last-one-standing',
    (s) => s.wins >= 1,
  ),
  Sticker(
    7,
    'TOUCH GRASS',
    'sleepy',
    '7-day streak',
    (s) => s.longestStreak >= 7,
  ),
];
