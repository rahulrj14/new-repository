import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/catalog/nicknames.dart';
import 'package:lock_in/progression/aura.dart';

void main() {
  test('clean 25 min session: 24 min + bonus', () {
    final a = scoreSession(
      locked: const Duration(minutes: 24, seconds: 50),
      cracks: 0,
      completedPlannedLength: true,
      plannedLength: const Duration(minutes: 25),
      earnedTodaySoFar: 0,
    );
    expect(a.base, 24);
    expect(a.bonus, 10);
    expect(a.total, 34);
  });

  test('cracks cost aura and remove the bonus, never below zero', () {
    final a = scoreSession(
      locked: const Duration(minutes: 3),
      cracks: 2,
      completedPlannedLength: true,
      plannedLength: const Duration(minutes: 25),
      earnedTodaySoFar: 0,
    );
    expect(a.bonus, 0);
    expect(a.total, 0);
  });

  test('daily cap trims the excess', () {
    final a = scoreSession(
      locked: const Duration(minutes: 90),
      cracks: 0,
      completedPlannedLength: true,
      plannedLength: const Duration(minutes: 90),
      earnedTodaySoFar: 250,
    );
    expect(a.total, 50);
    expect(a.capTrimmed, 50);
    expect(a.hitCap, isTrue);
  });

  test('levels', () {
    expect(levelFor(0).name, 'NPC');
    expect(levelFor(49).number, 1);
    expect(levelFor(50).name, 'Side Quest');
    expect(levelFor(100).progress(100), closeTo(0.5, 0.001));
    expect(levelFor(99999).next, isNull);
  });

  test('nicknames: every id maps to two words, lists are unique', () {
    expect(adjectives.toSet().length, adjectives.length);
    expect(animals.toSet().length, animals.length);
    expect(nicknameFor(0), 'Calm Otter');
    for (var i = 0; i < adjectives.length * animals.length; i += 97) {
      expect(nicknameFor(i).split(' ').length, 2);
    }
  });
}
