import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

/// Local SQLite database. Lives only on this phone; nothing syncs anywhere.

@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();

  /// Null for open-ended sessions.
  IntColumn get plannedMinutes => integer().nullable()();
  IntColumn get lockedSeconds => integer()();
  IntColumn get cracks => integer()();
  BoolColumn get completed => boolean()();
  IntColumn get aura => integer()();

  /// solo | group | migrated
  TextColumn get mode => text().withDefault(const Constant('solo'))();

  // v2
  TextColumn get vibe => text().withDefault(const Constant('study'))();
  IntColumn get clutches => integer().withDefault(const Constant(0))();
  BoolColumn get passUsed => boolean().withDefault(const Constant(false))();
  IntColumn get groupSize => integer().withDefault(const Constant(1))();
  BoolColumn get squadClean => boolean().withDefault(const Constant(false))();
  BoolColumn get won => boolean().withDefault(const Constant(false))();
  IntColumn get questAura => integer().withDefault(const Constant(0))();
}

@DataClassName('DayRow')
class DailyActivity extends Table {
  /// dayNumber (local calendar day).
  IntColumn get day => integer()();
  IntColumn get lockedSeconds => integer().withDefault(const Constant(0))();
  IntColumn get aura => integer().withDefault(const Constant(0))();
  BoolColumn get qualified => boolean().withDefault(const Constant(false))();

  /// Missed day covered by a streak freeze.
  BoolColumn get frozen => boolean().withDefault(const Constant(false))();

  // v2
  BoolColumn get questDone => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {day};
}

@DataClassName('StreakRow')
class StreakStates extends Table {
  IntColumn get id => integer()();
  IntColumn get current => integer().withDefault(const Constant(0))();
  IntColumn get longest => integer().withDefault(const Constant(0))();
  IntColumn get freezes => integer().withDefault(const Constant(0))();
  IntColumn get lastDay => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SkinRow')
class UnlockedSkins extends Table {
  IntColumn get skinId => integer()();
  DateTimeColumn get unlockedAt => dateTime()();
  BoolColumn get seen => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {skinId};
}

@DriftDatabase(tables: [Sessions, DailyActivity, StreakStates, UnlockedSkins])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'lockin'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        for (final c in [
          sessions.vibe,
          sessions.clutches,
          sessions.passUsed,
          sessions.groupSize,
          sessions.squadClean,
          sessions.won,
          sessions.questAura,
        ]) {
          await m.addColumn(sessions, c);
        }
        await m.addColumn(dailyActivity, dailyActivity.questDone);
      }
    },
  );
}
