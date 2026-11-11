import 'package:flutter_test/flutter_test.dart';
import 'package:lockin_spike/detection/grace_tracker.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 11, 12);
  DateTime at(int s) => t0.add(Duration(seconds: s));

  GraceTracker faceDown() => GraceTracker(
        armedAt: t0,
        initiallyActive: true,
        initiallyCovered: true,
      );

  test('face down and untouched: no events', () {
    final g = faceDown();
    expect(g.arm(), isEmpty);
    expect(g.tick(at(1800)), isEmpty);
    expect(g.crackCount, 0);
  });

  test('picked up and put back within grace: cancelled, no crack', () {
    final g = faceDown()..arm();
    expect(g.onSignal(DeviceSignal.proximityUncovered, at(60)).single,
        isA<GraceStarted>());
    final ev = g.onSignal(DeviceSignal.proximityCovered, at(65)).single;
    expect(ev, isA<GraceCancelled>());
    expect((ev as GraceCancelled).after, const Duration(seconds: 5));
    expect(g.tick(at(100)), isEmpty);
    expect(g.crackCount, 0);
  });

  test('picked up for longer than grace: one crack, timestamped at deadline', () {
    final g = faceDown()..arm();
    g.onSignal(DeviceSignal.proximityUncovered, at(60));
    expect(g.tick(at(69)), isEmpty);
    final ev = g.tick(at(70)).single as Cracked;
    expect(ev.at, at(70));
    expect(ev.noticedLate, isFalse);
    // Staying up does not crack again.
    expect(g.tick(at(200)), isEmpty);
    expect(g.crackCount, 1);
  });

  test('after a crack, putting it down re-arms; a second pickup cracks again', () {
    final g = faceDown()..arm();
    g.onSignal(DeviceSignal.proximityUncovered, at(10));
    g.tick(at(20));
    expect(g.onSignal(DeviceSignal.proximityCovered, at(30)).single,
        isA<Rearmed>());
    g.onSignal(DeviceSignal.proximityUncovered, at(40));
    g.tick(at(50));
    expect(g.crackCount, 2);
  });

  test('pressing the side button (inactive then locked) is not a crack', () {
    final g = faceDown()..arm();
    g.onSignal(DeviceSignal.proximityUncovered, at(10)); // picked up
    g.onSignal(DeviceSignal.appInactive, at(12));
    final ev = g.onSignal(DeviceSignal.deviceLocked, at(12));
    expect(ev.single, isA<GraceCancelled>());
    expect(g.tick(at(100)), isEmpty);
    expect(g.crackCount, 0);
  });

  test('switching to another app cracks after grace', () {
    final g = faceDown()..arm();
    g.onSignal(DeviceSignal.proximityUncovered, at(10));
    g.onSignal(DeviceSignal.appInactive, at(11));
    expect(g.tick(at(20)).single, isA<Cracked>());
  });

  test('crack noticed late (app was suspended) keeps the true time', () {
    final g = GraceTracker(armedAt: t0, initiallyActive: false, initiallyLocked: true)
      ..arm();
    // Unlock is only delivered when the app wakes much later.
    g.onSignal(DeviceSignal.deviceUnlocked, at(300));
    final out = g.onSignal(DeviceSignal.appActive, at(400));
    final crack = out.whereType<Cracked>().single;
    expect(crack.at, at(310));
    expect(crack.noticedLate, isTrue);
  });

  test('not down at arm time opens grace immediately', () {
    final g = GraceTracker(armedAt: at(15), initiallyCovered: false);
    expect(g.arm().single.at, at(15));
    expect(g.tick(at(25)).single, isA<Cracked>());
  });

  test('signals during setup period are timed from arm moment', () {
    final g = GraceTracker(armedAt: at(15), initiallyCovered: true);
    final ev = g.onSignal(DeviceSignal.proximityUncovered, at(3)).single;
    expect(ev.at, at(15));
  });
}
