import 'package:drift/drift.dart';

import '../catalog/skins.dart';
import '../catalog/stickers.dart';
import '../catalog/vibes.dart';
import '../progression/aura.dart';
import '../progression/quests.dart';
import '../progression/stages.dart';
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
    required this.lifetimeMinutes,
    required this.stickerStats,
    required this.todayQuest,
    required this.questDoneToday,
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
  final int lifetimeMinutes;
  final StickerStats stickerStats;
  final Quest todayQuest;
  final bool questDoneToday;

  Level get level => levelFor(auraTotal);
  BlobStage get stage => stageFor(lifetimeMinutes);
  UnlockStats get unlockStats => UnlockStats(
    level: level.number,
    longestStreak: streakState.longest,
    sessions: sessions,
  );
  Set<int> get unlockedStickers => {
    for (final s in stickers)
      if (s.unlocked(stickerStats)) s.id,
  };

  static final empty = ProgressSnapshot(
    auraTotal: 0,
    auraToday: 0,
    lockedSecondsToday: 0,
    sessions: 0,
    streakState: const StreakState(),
    streak: const StreakView(
      days: 0,
      freezes: 0,
      doneToday: false,
      frozenDays: 0,
      longest: 0,
    ),
    unlockedSkins: const {0},
    unseenSkins: const {},
    recent: const [],
    days: const {},
    lifetimeMinutes: 0,
    stickerStats: StickerStats.zero,
    todayQuest: quests.first,
    questDoneToday: false,
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
    this.questCompleted,
    this.questAura = 0,
    this.newStickers = const [],
    this.stageBefore,
    this.stageAfter,
  });
  final int streakBefore;
  final int streakAfter;
  final bool dayJustQualified;
  final int freezesUsed;
  final bool earnedFreeze;
  final List<Skin> newSkins;

  /// Locked minutes still needed today for the streak (0 if done).
  final int minutesToQualify;
  final Quest? questCompleted;

  /// Aura actually granted for the quest (after the daily cap).
  final int questAura;
  final List<Sticker> newStickers;
  final BlobStage? stageBefore;
  final BlobStage? stageAfter;

  bool get grew =>
      stageBefore != null &&
      stageAfter != null &&
      stageAfter!.index > stageBefore!.index;
}

/// Year-so-far numbers for Lock In Wrapped.
class WrappedStats {
  const WrappedStats({
    required this.year,
    required this.minutes,
    required this.sessions,
    required this.longestStreak,
    required this.topVibe,
    required this.clutches,
    required this.squadSessions,
    required this.longestSessionMin,
    required this.timeOfDay,
    required this.cleanSessions,
  });
  final int year;
  final int minutes;
  final int sessions;
  final int longestStreak;
  final Vibe? topVibe;
  final int clutches;
  final int squadSessions;
  final int longestSessionMin;

  /// morning | afternoon | evening | night
  final String timeOfDay;
  final int cleanSessions;
}

class ProgressRepo {
  ProgressRepo(this.db);
  final AppDatabase db;

  Future<StreakState> _streak() async {
    final row = await (db.select(
      db.streakStates,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return const StreakState();
    return StreakState(
      current: row.current,
      longest: row.longest,
      freezes: row.freezes,
      lastDay: row.lastDay,
    );
  }

  Expression<bool> get _real => db.sessions.mode.equals('migrated').not();

  Future<ProgressSnapshot> load(DateTime now) async {
    final today = dayNumber(now);
    final s = db.sessions;
    final total = s.aura.sum();
    final count = s.id.count();
    final secs = s.lockedSeconds.sum();
    final clutch = s.clutches.sum();
    final crack = s.cracks.sum();
    final longest = s.lockedSeconds.max();
    final agg = await (db.selectOnly(s)..addColumns([total])).getSingle();
    final real =
        await (db.selectOnly(s)
              ..addColumns([count, secs, clutch, crack, longest])
              ..where(_real))
            .getSingle();
    final clean =
        await (db.selectOnly(s)
              ..addColumns([count])
              ..where(
                _real &
                    s.cracks.equals(0) &
                    s.lockedSeconds.isBiggerOrEqualValue(15 * 60),
              ))
            .getSingle();
    final group =
        await (db.selectOnly(s)
              ..addColumns([count])
              ..where(s.mode.equals('group')))
            .getSingle();
    final wins =
        await (db.selectOnly(s)
              ..addColumns([count])
              ..where(s.won.equals(true)))
            .getSingle();
    final dayRows = await (db.select(
      db.dailyActivity,
    )..where((t) => t.day.isBiggerOrEqualValue(today - 27))).get();
    final days = {for (final d in dayRows) d.day: d};
    final skinsRows = await db.select(db.unlockedSkins).get();
    final recent =
        await (db.select(s)
              ..where((t) => t.mode.equals('migrated').not())
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
              ..limit(20))
            .get();
    final st = await _streak();
    return ProgressSnapshot(
      auraTotal: agg.read(total) ?? 0,
      auraToday: days[today]?.aura ?? 0,
      lockedSecondsToday: days[today]?.lockedSeconds ?? 0,
      sessions: real.read(count) ?? 0,
      streakState: st,
      streak: viewStreak(st, today),
      unlockedSkins: {0, ...skinsRows.map((r) => r.skinId)},
      unseenSkins: {
        for (final r in skinsRows)
          if (!r.seen) r.skinId,
      },
      recent: recent,
      days: days,
      lifetimeMinutes: (real.read(secs) ?? 0) ~/ 60,
      stickerStats: StickerStats(
        sessions: real.read(count) ?? 0,
        cleanSessions: clean.read(count) ?? 0,
        clutches: real.read(clutch) ?? 0,
        cracks: real.read(crack) ?? 0,
        longestSessionMin: (real.read(longest) ?? 0) ~/ 60,
        groupSessions: group.read(count) ?? 0,
        wins: wins.read(count) ?? 0,
        longestStreak: st.longest,
      ),
      todayQuest: questForDay(today, weekend: now.weekday >= DateTime.saturday),
      questDoneToday: days[today]?.questDone ?? false,
    );
  }

  /// Saves a finished session and updates daily totals, quest, streak,
  /// skins and stickers, all in one transaction. [aura] is the session's own
  /// aura (already capped); a quest reward is added here within the cap.
  Future<SessionOutcome> recordSession({
    required DateTime startedAt,
    required DateTime endedAt,
    required int? plannedMinutes,
    required int lockedSeconds,
    required int cracks,
    required bool completed,
    required int aura,
    Vibe vibe = Vibe.study,
    int clutches = 0,
    bool passUsed = false,
    int groupSize = 1,
    bool squadClean = false,
    bool won = false,
  }) {
    return db.transaction(() async {
      final before = await load(endedAt);
      final today = dayNumber(endedAt);
      final prevDay = before.days[today];
      final secondsToday = (prevDay?.lockedSeconds ?? 0) + lockedSeconds;

      // Daily quest.
      Quest? questDone;
      var questAura = 0;
      if (!before.questDoneToday) {
        final ctx = QuestContext(
          startedAt: startedAt,
          plannedMinutes: plannedMinutes,
          lockedMinutes: lockedSeconds ~/ 60,
          cracks: cracks,
          completed: completed,
          passUsed: passUsed,
          vibe: vibe,
          sessionsToday: _sessionsOn(before, today) + 1,
          lockedMinutesToday: secondsToday ~/ 60,
          group: groupSize > 1,
        );
        if (before.todayQuest.check(ctx)) {
          questDone = before.todayQuest;
          final room = AuraRules.dailyCap - before.auraToday - aura;
          questAura = room <= 0 ? 0 : (room < questReward ? room : questReward);
        }
      }

      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              startedAt: startedAt,
              endedAt: endedAt,
              plannedMinutes: Value(plannedMinutes),
              lockedSeconds: lockedSeconds,
              cracks: cracks,
              completed: completed,
              aura: aura + questAura,
              mode: Value(groupSize > 1 ? 'group' : 'solo'),
              vibe: Value(vibe.name),
              clutches: Value(clutches),
              passUsed: Value(passUsed),
              groupSize: Value(groupSize),
              squadClean: Value(squadClean),
              won: Value(won),
              questAura: Value(questAura),
            ),
          );
      final wasQualified = prevDay?.qualified ?? false;
      final nowQualified = secondsToday >= qualifyingSeconds;
      await db
          .into(db.dailyActivity)
          .insertOnConflictUpdate(
            DailyActivityCompanion.insert(
              day: Value(today),
              lockedSeconds: Value(secondsToday),
              aura: Value((prevDay?.aura ?? 0) + aura + questAura),
              qualified: Value(nowQualified),
              frozen: Value(prevDay?.frozen ?? false),
              questDone: Value(before.questDoneToday || questDone != null),
            ),
          );

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
          await db
              .into(db.dailyActivity)
              .insertOnConflictUpdate(
                DailyActivityCompanion.insert(
                  day: Value(today - i),
                  frozen: const Value(true),
                ),
              );
        }
        await db
            .into(db.streakStates)
            .insertOnConflictUpdate(
              StreakStatesCompanion.insert(
                id: const Value(1),
                current: Value(st.current),
                longest: Value(st.longest),
                freezes: Value(st.freezes),
                lastDay: Value(st.lastDay),
              ),
            );
      }

      final after = UnlockStats(
        level: levelFor(before.auraTotal + aura + questAura).number,
        longestStreak: st.longest,
        sessions: before.sessions + 1,
      );
      final fresh = <Skin>[
        ...newlyUnlocked(before.unlockStats, after),
        if (lockedSeconds >= 10 * 60) ...seasonalActive(endedAt),
      ].where((s) => !before.unlockedSkins.contains(s.id)).toList();
      for (final s in fresh) {
        await db
            .into(db.unlockedSkins)
            .insertOnConflictUpdate(
              UnlockedSkinsCompanion.insert(
                skinId: Value(s.id),
                unlockedAt: endedAt,
              ),
            );
      }

      final b = before.stickerStats;
      final stickerAfter = StickerStats(
        sessions: b.sessions + 1,
        cleanSessions:
            b.cleanSessions + (cracks == 0 && lockedSeconds >= 15 * 60 ? 1 : 0),
        clutches: b.clutches + clutches,
        cracks: b.cracks + cracks,
        longestSessionMin: lockedSeconds ~/ 60 > b.longestSessionMin
            ? lockedSeconds ~/ 60
            : b.longestSessionMin,
        groupSessions: b.groupSessions + (groupSize > 1 ? 1 : 0),
        wins: b.wins + (won ? 1 : 0),
        longestStreak: st.longest,
      );
      final newStickers = [
        for (final s in stickers)
          if (!s.unlocked(b) && s.unlocked(stickerAfter)) s,
      ];

      return SessionOutcome(
        streakBefore: before.streak.days,
        streakAfter: viewStreak(st, today).days,
        dayJustQualified: justQualified,
        freezesUsed: freezesUsed,
        earnedFreeze: earned,
        newSkins: fresh,
        minutesToQualify: nowQualified
            ? 0
            : ((qualifyingSeconds - secondsToday) / 60).ceil(),
        questCompleted: questDone,
        questAura: questAura,
        newStickers: newStickers,
        stageBefore: before.stage,
        stageAfter: stageFor(before.lifetimeMinutes + lockedSeconds ~/ 60),
      );
    });
  }

  int _sessionsOn(ProgressSnapshot p, int day) =>
      p.recent.where((r) => dayNumber(r.startedAt) == day).length;

  Future<void> markSkinsSeen() =>
      (db.update(db.unlockedSkins)..where((t) => t.seen.equals(false))).write(
        const UnlockedSkinsCompanion(seen: Value(true)),
      );

  Future<WrappedStats> wrapped(DateTime now) async {
    final from = DateTime(now.year);
    final rows =
        await (db.select(db.sessions)..where(
              (t) =>
                  t.mode.equals('migrated').not() &
                  t.startedAt.isBiggerOrEqualValue(from),
            ))
            .get();
    final vibes = <String, int>{};
    final tod = <String, int>{};
    var minutes = 0, clutches = 0, squad = 0, longest = 0, clean = 0;
    for (final r in rows) {
      final m = r.lockedSeconds ~/ 60;
      minutes += m;
      clutches += r.clutches;
      if (r.groupSize > 1) squad++;
      if (m > longest) longest = m;
      if (r.cracks == 0 && m >= 15) clean++;
      vibes[r.vibe] = (vibes[r.vibe] ?? 0) + m;
      final h = r.startedAt.hour;
      final k = h < 5
          ? 'night'
          : h < 12
          ? 'morning'
          : h < 17
          ? 'afternoon'
          : h < 21
          ? 'evening'
          : 'night';
      tod[k] = (tod[k] ?? 0) + 1;
    }
    String? top(Map<String, int> m) => m.isEmpty
        ? null
        : (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
    return WrappedStats(
      year: now.year,
      minutes: minutes,
      sessions: rows.length,
      longestStreak: (await _streak()).longest,
      topVibe: top(vibes) == null ? null : Vibe.byName(top(vibes)),
      clutches: clutches,
      squadSessions: squad,
      longestSessionMin: longest,
      timeOfDay: top(tod) ?? 'evening',
      cleanSessions: clean,
    );
  }

  /// One-off: carry aura over from the first test build (stored in prefs).
  Future<void> migrateAura(int aura) async {
    if (aura <= 0) return;
    final any = await (db.select(db.sessions)..limit(1)).getSingleOrNull();
    if (any != null) return;
    final now = DateTime.now();
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            startedAt: now,
            endedAt: now,
            lockedSeconds: 0,
            cracks: 0,
            completed: false,
            aura: aura,
            mode: const Value('migrated'),
          ),
        );
  }
}
