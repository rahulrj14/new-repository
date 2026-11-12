/// One optional quest per day, picked from a fixed list by the date, so it is
/// the same all day and needs no server. No notifications, ever.
library;

import '../catalog/vibes.dart';

const questReward = 15;

/// Facts about a just-finished session plus today's totals (including it).
class QuestContext {
  const QuestContext({
    required this.startedAt,
    required this.plannedMinutes,
    required this.lockedMinutes,
    required this.cracks,
    required this.completed,
    required this.passUsed,
    required this.vibe,
    required this.sessionsToday,
    required this.lockedMinutesToday,
    required this.group,
  });
  final DateTime startedAt;
  final int? plannedMinutes;
  final int lockedMinutes;
  final int cracks;
  final bool completed;
  final bool passUsed;
  final Vibe vibe;
  final int sessionsToday;
  final int lockedMinutesToday;
  final bool group;
}

class Quest {
  const Quest(this.id, this.emoji, this.title, this.detail, this.check);
  final int id;
  final String emoji;
  final String title;
  final String detail;
  final bool Function(QuestContext c) check;
}

final quests = <Quest>[
  Quest(
    0,
    '🌅',
    'early bird',
    'start a session before 10am',
    (c) => c.startedAt.hour < 10 && c.lockedMinutes >= 10,
  ),
  Quest(
    1,
    '🏔️',
    'long haul',
    'finish a 50+ min session',
    (c) => c.completed && (c.plannedMinutes ?? 0) >= 50,
  ),
  Quest(
    2,
    '💎',
    'spotless',
    '0 cracks, 15+ min locked',
    (c) => c.cracks == 0 && c.lockedMinutes >= 15,
  ),
  Quest(
    3,
    '✌️',
    'double up',
    'do 2 sessions today',
    (c) => c.sessionsToday >= 2,
  ),
  Quest(
    4,
    '🧠',
    'deep work',
    'lock in 45 min today',
    (c) => c.lockedMinutesToday >= 45,
  ),
  Quest(
    5,
    '🍜',
    'dinner diplomat',
    'a dinner-vibe session (15+ min)',
    (c) => c.vibe == Vibe.dinner && c.lockedMinutes >= 15,
  ),
  Quest(
    6,
    '🌙',
    'wind down',
    'a session after 9pm',
    (c) => c.startedAt.hour >= 21 && c.lockedMinutes >= 10,
  ),
  Quest(
    7,
    '🫡',
    'no pass needed',
    'finish 25+ min without your pass',
    (c) => c.completed && !c.passUsed && (c.plannedMinutes ?? 0) >= 25,
  ),
  Quest(
    8,
    '🫶',
    'squad up',
    'lock in with a friend',
    (c) => c.group && c.lockedMinutes >= 10,
  ),
];

/// Today's quest. "squad up" only shows on weekends (friends are around).
Quest questForDay(int dayNumber, {required bool weekend}) {
  final pool = weekend ? quests : quests.where((q) => q.id != 8).toList();
  return pool[(dayNumber * 7 + 3) % pool.length];
}
