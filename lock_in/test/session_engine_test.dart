import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/detection/grace_tracker.dart';
import 'package:lock_in/session/session_engine.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 12, 9);
  DateTime at(int s) => t0.add(Duration(seconds: s));

  SessionEngine engine({int minutes = 25}) =>
      SessionEngine(startedAt: t0, plannedLength: Duration(minutes: minutes));

  test('lock during settle, never touch: full time counted, no cracks', () {
    final e = engine();
    e.onSignal(DeviceSignal.appInactive, at(4));
    e.onSignal(DeviceSignal.deviceLocked, at(4));
    expect(e.phase(at(5)), SessionPhase.settling);
    e.tick(at(1500));
    expect(e.cracks, 0);
    // 25 min minus the 10 s settle period.
    expect(e.lockedTime(at(1500)), const Duration(minutes: 25) - const Duration(seconds: 10));
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

  test('unlock mid-session for 2 minutes: crack, and that time is not counted', () {
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
  });

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
}
