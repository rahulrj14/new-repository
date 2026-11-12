import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/detection/grace_tracker.dart';
import 'package:lock_in/session/session_engine.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 12, 9);
  DateTime at(int s) => t0.add(Duration(seconds: s));

  SessionEngine engine({int minutes = 25}) => SessionEngine(
    startedAt: t0,
    plannedLength: Duration(minutes: minutes),
  );

  test('lock during settle, never touch: full time counted, no cracks', () {
    final e = engine();
    e.onSignal(DeviceSignal.appInactive, at(4));
    e.onSignal(DeviceSignal.deviceLocked, at(4));
    expect(e.phase(at(5)), SessionPhase.settling);
    e.tick(at(1500));
    expect(e.cracks, 0);
    // 25 min minus the 10 s settle period.
    expect(
      e.lockedTime(at(1500)),
      const Duration(minutes: 25) - const Duration(seconds: 10),
    );
    expect(e.phase(at(1500)), SessionPhase.done);
  });

  test('still holding the phone when settle ends: grace then crack', () {
    final e = engine();
    expect(e.tick(at(10)).single, isA<GraceStarted>());
    expect(e.phase(at(12)), SessionPhase.grace);
    expect(e.graceSecondsLeft(at(12)), 8);
    expect(e.tick(at(20)).single, isA<Cracked>());
    expect(e.phase(at(21)), SessionPhase.cracked);
    expect(e.lockedTime(at(30)), Duration.zero);
  });

  test(
    'unlock mid-session for 2 minutes: crack, and that time is not counted',
    () {
      final e = engine();
      e.onSignal(DeviceSignal.appInactive, at(3));
      e.onSignal(DeviceSignal.deviceLocked, at(3));
      e.onSignal(DeviceSignal.deviceUnlocked, at(600));
      e.tick(at(615));
      expect(e.cracks, 1);
      e.onSignal(DeviceSignal.deviceLocked, at(720));
      expect(e.phase(at(721)), SessionPhase.locked);
      // (1000 - 10) total since arm, minus 120 s up.
      expect(e.lockedTime(at(1000)), const Duration(seconds: 990 - 120));
    },
  );

  test('quick glance inside grace: no crack, glance time not counted', () {
    final e = engine();
    e.onSignal(DeviceSignal.deviceLocked, at(2));
    e.onSignal(DeviceSignal.deviceUnlocked, at(100));
    e.onSignal(DeviceSignal.deviceLocked, at(104));
    e.tick(at(200));
    expect(e.cracks, 0);
    expect(e.lockedTime(at(200)), const Duration(seconds: 190 - 4));
  });

  test('time after the planned end is ignored', () {
    final e = engine(minutes: 1);
    e.onSignal(DeviceSignal.deviceLocked, at(1));
    e.onSignal(DeviceSignal.deviceUnlocked, at(500));
    e.tick(at(520));
    expect(e.cracks, 0);
    expect(e.lockedTime(at(520)), const Duration(seconds: 50));
  });

  test('open-ended session never completes', () {
    final e = SessionEngine(startedAt: t0);
    e.onSignal(DeviceSignal.deviceLocked, at(1));
    expect(e.isComplete(at(100000)), isFalse);
    expect(e.lockedTime(at(70)), const Duration(seconds: 60));
  });

  group('clutch, pass, breaks', () {
    test('relock in the last 3 s of grace is a clutch save', () {
      final e = engine();
      e.onSignal(DeviceSignal.deviceLocked, at(2));
      e.onSignal(DeviceSignal.deviceUnlocked, at(100));
      final out = e.onSignal(DeviceSignal.deviceLocked, at(108));
      expect(out.whereType<ClutchSave>(), hasLength(1));
      expect(e.clutches, 1);
      expect(e.cracks, 0);
    });

    test('relocking early is not a clutch', () {
      final e = engine();
      e.onSignal(DeviceSignal.deviceLocked, at(2));
      e.onSignal(DeviceSignal.deviceUnlocked, at(100));
      e.onSignal(DeviceSignal.deviceLocked, at(103));
      expect(e.clutches, 0);
    });

    test('emergency pass: no crack while used, ends when locked again', () {
      final e = engine();
      e.onSignal(DeviceSignal.deviceLocked, at(2));
      e.onSignal(DeviceSignal.deviceUnlocked, at(100));
      expect(e.usePass(at(104)), isTrue);
      expect(e.phase(at(105)), SessionPhase.pass);
      e.tick(at(200));
      expect(e.cracks, 0);
      final out = e.onSignal(DeviceSignal.deviceLocked, at(220));
      expect(out.whereType<PassEnded>(), hasLength(1));
      expect(e.phase(at(221)), SessionPhase.locked);
      // Phone-up time (100..220) is not counted as locked.
      expect(e.lockedTime(at(300)), const Duration(seconds: 290 - 120));
      expect(e.usePass(at(301)), isFalse, reason: 'one pass per session');
    });

    test('pass that runs out while still unlocked: grace then crack', () {
      final e = engine();
      e.onSignal(DeviceSignal.deviceLocked, at(2));
      e.onSignal(DeviceSignal.deviceUnlocked, at(100));
      e.usePass(at(101));
      final out = e.tick(at(101 + 300 + 11));
      expect(out.whereType<PassEnded>(), hasLength(1));
      expect(out.whereType<Cracked>(), hasLength(1));
    });

    test('break mode: unlocking during a break never cracks, break time not counted', () {
      final e = SessionEngine(
        startedAt: t0,
        plannedLength: const Duration(minutes: 60),
        breaks: const BreakPlan(
          work: Duration(minutes: 25),
          rest: Duration(minutes: 5),
        ),
      );
      e.onSignal(DeviceSignal.deviceLocked, at(2));
      final breakStart = 10 + 25 * 60;
      final s = e.tick(at(breakStart + 1));
      expect(s.whereType<BreakStarted>(), hasLength(1));
      expect(e.phase(at(breakStart + 1)), SessionPhase.onBreak);
      e.onSignal(DeviceSignal.deviceUnlocked, at(breakStart + 30));
      e.tick(at(breakStart + 200));
      expect(e.cracks, 0);
      e.onSignal(DeviceSignal.deviceLocked, at(breakStart + 280));
      final end = e.tick(at(breakStart + 301));
      expect(end.whereType<BreakEnded>(), hasLength(1));
      expect(e.phase(at(breakStart + 302)), SessionPhase.locked);
      // Locked: 25 min before the break + 1 s after it.
      expect(
        e.lockedTime(at(breakStart + 301)),
        const Duration(minutes: 25, seconds: 1),
      );
    });

    test(
      'still on the phone when the break ends: grace starts at break end',
      () {
        final e = SessionEngine(
          startedAt: t0,
          plannedLength: const Duration(minutes: 60),
          breaks: const BreakPlan(
            work: Duration(minutes: 1),
            rest: Duration(minutes: 1),
          ),
        );
        e.onSignal(DeviceSignal.deviceLocked, at(2));
        e.onSignal(DeviceSignal.deviceUnlocked, at(80));
        final out = e.tick(at(10 + 120 + 11));
        expect(out.whereType<BreakEnded>(), hasLength(1));
        expect(out.whereType<GraceStarted>(), hasLength(1));
        expect(out.whereType<Cracked>(), hasLength(1));
      },
    );
  });
}
