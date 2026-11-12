import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/catalog/skins.dart';
import 'package:lock_in/progression/streaks.dart';
import 'package:lock_in/storage/db.dart';
import 'package:lock_in/storage/progress_repo.dart';

void main() {
  group('streak rules', () {
    test('consecutive days grow the streak', () {
      var s = const StreakState();
      for (var d = 100; d < 105; d++) {
        s = recordQualifiedDay(s, d).state;
      }
      expect(s.current, 5);
      expect(s.longest, 5);
    });

    test('same day twice does nothing', () {
      final s = recordQualifiedDay(const StreakState(), 10).state;
      expect(recordQualifiedDay(s, 10).state, s);
    });

    test('7-day milestone earns a freeze, capped at 2', () {
      var s = const StreakState();
      for (var d = 0; d < 21; d++) {
        s = recordQualifiedDay(s, d).state;
      }
      expect(s.freezes, 2);
    });

    test('a freeze covers a missed day', () {
      const s = StreakState(current: 9, longest: 9, freezes: 1, lastDay: 50);
      final u = recordQualifiedDay(s, 52);
      expect(u.freezesUsed, 1);
      expect(u.state.current, 10);
      expect(u.state.freezes, 0);
    });

    test('too many missed days resets to 1, longest kept', () {
      const s = StreakState(current: 9, longest: 12, freezes: 1, lastDay: 50);
      final u = recordQualifiedDay(s, 54);
      expect(u.reset, isTrue);
      expect(u.state.current, 1);
      expect(u.state.longest, 12);
    });

    test('view: broken streak shows 0, protected gap shows frozen days', () {
      const s = StreakState(current: 5, longest: 5, freezes: 1, lastDay: 10);
      expect(viewStreak(s, 10).doneToday, isTrue);
      expect(viewStreak(s, 11).days, 5);
      expect(viewStreak(s, 12).frozenDays, 1);
      expect(viewStreak(s, 13).days, 0);
    });

    test('dayNumber is stable across a DST change', () {
      expect(
        dayNumber(DateTime(2026, 3, 30, 0, 30)) -
            dayNumber(DateTime(2026, 3, 29, 23, 30)),
        1,
      );
    });
  });

  group('skins', () {
    test('unlock rules', () {
      const fresh = UnlockStats(level: 1, longestStreak: 0, sessions: 0);
      const after = UnlockStats(level: 2, longestStreak: 3, sessions: 1);
      final names = newlyUnlocked(fresh, after).map((s) => s.name);
      expect(names, containsAll(['Party', 'Shades', 'Beanie']));
      expect(names, isNot(contains('Classic')));
    });

    test('ids are unique', () {
      expect(skins.map((s) => s.id).toSet().length, skins.length);
    });
  });

  group('repo', () {
    late AppDatabase db;
    late ProgressRepo repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ProgressRepo(db);
    });
    tearDown(() => db.close());

    Future<SessionOutcome> session(
      DateTime end, {
      int minutes = 25,
      int aura = 30,
    }) => repo.recordSession(
      startedAt: end.subtract(Duration(minutes: minutes)),
      endedAt: end,
      plannedMinutes: minutes,
      lockedSeconds: minutes * 60,
      cracks: 0,
      completed: true,
      aura: aura,
    );

    test(
      'first qualifying session starts a streak and unlocks Party',
      () async {
        final o = await session(DateTime(2026, 11, 12, 10));
        expect(o.dayJustQualified, isTrue);
        expect(o.streakAfter, 1);
        expect(o.newSkins.map((s) => s.name), contains('Party'));
        final p = await repo.load(DateTime(2026, 11, 12, 11));
        expect(
          p.auraTotal,
          30 + o.questAura,
          reason: 'session aura + any daily-quest reward',
        );
        expect(p.sessions, 1);
        expect(p.streak.doneToday, isTrue);
        expect(p.unlockedSkins, containsAll([0, 1]));
      },
    );

    test('two short sessions add up to qualify the day', () async {
      final a = await session(DateTime(2026, 11, 12, 10), minutes: 15);
      expect(a.dayJustQualified, isFalse);
      expect(a.minutesToQualify, 9); // 24-min threshold (1-min allowance)
      final b = await session(DateTime(2026, 11, 12, 12), minutes: 15);
      expect(b.dayJustQualified, isTrue);
    });

    test('streak across days', () async {
      await session(DateTime(2026, 11, 10, 10));
      await session(DateTime(2026, 11, 11, 10));
      final o = await session(DateTime(2026, 11, 12, 10));
      expect(o.streakBefore, 2);
      expect(o.streakAfter, 3);
      expect(o.newSkins.map((s) => s.name), contains('Beanie'));
    });

    test('migrated aura counts toward total but not sessions', () async {
      await repo.migrateAura(40);
      final p = await repo.load(DateTime.now());
      expect(p.auraTotal, 40);
      expect(p.sessions, 0);
      expect(p.recent, isEmpty);
    });
  });
}
