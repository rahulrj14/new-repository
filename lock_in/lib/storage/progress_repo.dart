import 'package:drift/drift.dart';

import '../catalog/skins.dart';
import '../progression/aura.dart';
import '../progression/streaks.dart';
import 'db.dart';

/// Everything progress-related, read in one go for the UI.
class ProgressSnapshot {
  const ProgressSnapshot({
    required this.auraTotal,
    required this.auraToday,
    required this.lockedSecondsToday,
    required this.sessions,
    required this.streakState,
    required this.streak,
    required this.unlockedSkins,
    required this.unseenSkins,
    required this.recent,
    required this.days,
  });

  final int auraTotal;
  final int auraToday;
  final int lockedSecondsToday;
  final int sessions;
  final StreakState streakState;
  final StreakView streak;
  final Set<int> unlockedSkins;
  final Set<int> unseenSkins;
  final List<SessionRow> recent;

  /// Last 28 days of activity, keyed by dayNumber.
  final Map<int, DayRow> days;

  Level get level => levelFor(auraTotal);
  UnlockStats get unlockStats =>
      UnlockStats(level: level.number, longestStreak: streakState.longest, sessions: sessions);

  static const empty = ProgressSnapshot(
    auraTotal: 0,
    auraToday: 0,
    lockedSecondsToday: 0,
    sessions: 0,
    streakState: StreakState(),
    streak: StreakView(days: 0, freezes: 0, doneToday: false, frozenDays: 0, longest: 0),
    unlockedSkins: {0},
    unseenSkins: {},
    recent: [],
    days: {},
  );
}

/// What changed because of one session, for the results screen.
class SessionOutcome {
  const SessionOutcome({
    required this.streakBefore,
    required this.streakAfter,
    required this.dayJustQualified,
    required this.freezesUsed,
    required this.earnedFreeze,
    required this.newSkins,
    required this.minutesToQualify,
  });
  final int streakBefore;
  final int streakAfter;
  final bool dayJustQualified;
  final int freezesUsed;
  final bool earnedFreeze;
  final List<Skin> newSkins;

  /// Locked minutes still needed today for the streak (0 if done).
  final int minutesToQualify;
}

class ProgressRepo {
  ProgressRepo(this.db);
  final AppDatabase db;

  Future<StreakState> _streak() async {
    final row = await (db.select(db.streakStates)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return const StreakState();
    return StreakState(current: row.current, longest: row.longest, freezes: row.freezes, lastDay: row.lastDay);
  }

  Future<ProgressSnapshot> load(DateTime now) async {
    final today = dayNumber(now);
    final totalExpr = db.sessions.aura.sum();
    final countExpr = db.sessions.id.count();
    final agg = await (db.selectOnly(db.sessions)..addColumns([totalExpr])).getSingle();
    final cnt = await (db.selectOnly(db.sessions)
          ..addColumns([countExpr])
          ..where(db.sessions.mode.equals('migrated').not()))
        .getSingle();
    final dayRows = await (db.select(db.dailyActivity)..where((t) => t.day.isBiggerOrEqualValue(today - 27))).get();
    final days = {for (final d in dayRows) d.day: d};
    final skinsRows = await db.select(db.unlockedSkins).get();
    final recent = await (db.select(db.sessions)
          ..where((t) => t.mode.equals('migrated').not())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(20))
        .get();
    final st = await _streak();
    return ProgressSnapshot(
      auraTotal: agg.read(totalExpr) ?? 0,
      auraToday: days[today]?.aura ?? 0,
      lockedSecondsToday: days[today]?.lockedSeconds ?? 0,
      sessions: cnt.read(countExpr) ?? 0,
      streakState: st,
      streak: viewStreak(st, today),
      unlockedSkins: {0, ...skinsRows.map((r) => r.skinId)},
      unseenSkins: {for (final r in skinsRows) if (!r.seen) r.skinId},
      recent: recent,
      days: days,
    );
  }

  /// Saves a finished session and updates daily totals, streak and skins,
  /// all in one transaction.
  Future<SessionOutcome> recordSession({
    required DateTime startedAt,
    required DateTime endedAt,
    required int? plannedMinutes,
    required int lockedSeconds,
    required int cracks,
    required bool completed,
    required int aura,
  }) {
    return db.transaction(() async {
      final before = await load(endedAt);
      final today = dayNumber(endedAt);
      await db.into(db.sessions).insert(SessionsCompanion.insert(
            startedAt: startedAt,
            endedAt: endedAt,
            plannedMinutes: Value(plannedMinutes),
            lockedSeconds: lockedSeconds,
            cracks: cracks,
            completed: completed,
            aura: aura,
          ));
      final prevDay = before.days[today];
      final secondsToday = (prevDay?.lockedSeconds ?? 0) + lockedSeconds;
      final wasQualified = prevDay?.qualified ?? false;
      final nowQualified = secondsToday >= qualifyingSeconds;
      await db.into(db.dailyActivity).insertOnConflictUpdate(DailyActivityCompanion.insert(
            day: Value(today),
            lockedSeconds: Value(secondsToday),
            aura: Value((prevDay?.aura ?? 0) + aura),
            qualified: Value(nowQualified),
          ));

      var st = before.streakState;
      var freezesUsed = 0;
      var earned = false;
      final justQualified = nowQualified && !wasQualified;
      if (justQualified) {
        final u = recordQualifiedDay(st, today);
        st = u.state;
        freezesUsed = u.freezesUsed;
        earned = u.earnedFreeze;
        for (var i = 1; i <= freezesUsed; i++) {
          await db.into(db.dailyActivity).insertOnConflictUpdate(DailyActivityCompanion.insert(
                day: Value(today - i),
                frozen: const Value(true),
              ));
        }
        await db.into(db.streakStates).insertOnConflictUpdate(StreakStatesCompanion.insert(
              id: const Value(1),
              current: Value(st.current),
              longest: Value(st.longest),
              freezes: Value(st.freezes),
              lastDay: Value(st.lastDay),
            ));
      }

      final after = UnlockStats(
        level: levelFor(before.auraTotal + aura).number,
        longestStreak: st.longest,
        sessions: before.sessions + 1,
      );
      final fresh = newlyUnlocked(before.unlockStats, after)
          .where((s) => !before.unlockedSkins.contains(s.id))
          .toList();
      for (final s in fresh) {
        await db.into(db.unlockedSkins).insertOnConflictUpdate(
              UnlockedSkinsCompanion.insert(skinId: Value(s.id), unlockedAt: endedAt),
            );
      }
      return SessionOutcome(
        streakBefore: before.streak.days,
        streakAfter: viewStreak(st, today).days,
        dayJustQualified: justQualified,
        freezesUsed: freezesUsed,
        earnedFreeze: earned,
        newSkins: fresh,
        minutesToQualify: nowQualified ? 0 : ((qualifyingSeconds - secondsToday) / 60).ceil(),
      );
    });
  }

  Future<void> markSkinsSeen() =>
      (db.update(db.unlockedSkins)..where((t) => t.seen.equals(false))).write(const UnlockedSkinsCompanion(seen: Value(true)));

  /// One-off: carry aura over from the first test build (stored in prefs).
  Future<void> migrateAura(int aura) async {
    if (aura <= 0) return;
    final any = await (db.select(db.sessions)..limit(1)).getSingleOrNull();
    if (any != null) return;
    final now = DateTime.now();
    await db.into(db.sessions).insert(SessionsCompanion.insert(
          startedAt: now,
          endedAt: now,
          lockedSeconds: 0,
          cracks: 0,
          completed: false,
          aura: aura,
          mode: const Value('migrated'),
        ));
  }
}
