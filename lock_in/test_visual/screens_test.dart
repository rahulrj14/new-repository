// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders every screen at phone size with real fonts and seeded data, and
// writes PNGs for design review. Not part of the normal test run:
//   flutter test test_visual --update-goldens
// Output: test_visual/goldens/*.png  (emoji render as boxes here; fine on phones)
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/app.dart';
import 'package:lock_in/detection/grace_tracker.dart';
import 'package:lock_in/group/group_controller.dart';
import 'package:lock_in/group/protocol.dart';
import 'package:lock_in/group/transport.dart';
import 'package:lock_in/session/session_controller.dart';
import 'package:lock_in/storage/db.dart';
import 'package:lock_in/storage/profile_store.dart';
import 'package:lock_in/storage/progress_repo.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('Fredoka');
  for (final w in [400, 500, 600, 700]) {
    loader.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/Fredoka-$w.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await loader.load();
  final icons = FontLoader('MaterialIcons');
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter';
  icons.addFont(
    Future.value(
      ByteData.sublistView(
        File(
          '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytesSync(),
      ),
    ),
  );
  await icons.load();
}

late FakeAir air;

void main() {
  setUpAll(_loadFonts);
  setUp(() => air = FakeAir());

  Future<(ProviderContainer, AppDatabase)> boot(
    WidgetTester tester, {
    bool onboarded = true,
  }) async {
    tester.view.physicalSize = const Size(786, 1704);
    tester.view.devicePixelRatio = 2;
    final m = tester.binding.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
      const MethodChannel('lockin/device_use'),
      (call) async => null,
    );
    m.setMockStreamHandler(
      const EventChannel('lockin/device_use/events'),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );
    SharedPreferences.setMockInitialValues(
      onboarded
          ? {'avatarId': 1, 'nicknameId': 1234, 'skinId': 2}
          : <String, Object>{},
    );
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    if (onboarded) {
      await tester.runAsync(() async {
        final repo = ProgressRepo(db);
        final now = DateTime.now();
        for (var i = 4; i >= 1; i--) {
          if (i == 3) {
            continue; // a missed day, covered later only if a freeze exists
          }
          final end = now.subtract(Duration(days: i));
          await repo.recordSession(
            startedAt: end.subtract(const Duration(minutes: 50)),
            endedAt: end,
            plannedMinutes: 50,
            lockedSeconds: 50 * 60,
            cracks: i == 2 ? 1 : 0,
            completed: true,
            aura: i == 2 ? 44 : 60,
          );
        }
      });
    }
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        dbProvider.overrideWithValue(db),
        groupTransportProvider.overrideWithValue((_) => FakeTransport(air, 'host')),
        fakeAirProvider.overrideWithValue(air),
        blePrepareProvider.overrideWithValue(() async => null),
      ],
    );
    await tester.runAsync(() => container.read(progressProvider.future));
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const LockInApp()),
    );
    await tester.pump(const Duration(milliseconds: 500));
    return (container, db);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    // Several frames so implicit animations (colours, page slides) finish.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  Future<void> teardown(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30)); // let squad hang-up timers fire
    await tester.runAsync(db.close);
  }

  testWidgets('onboarding', (tester) async {
    final (_, db) = await boot(tester, onboarded: false);
    await shot(tester, '01-onboarding-pick');
    await tester.tap(find.text('Mochi'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('next'));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '02-onboarding-name');
    await teardown(tester, db);
  });

  testWidgets('tabs', (tester) async {
    final (c, db) = await boot(tester);
    await shot(tester, '03-home');
    c.read(routerProvider).go('/streak');
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '04-streak');
    c.read(routerProvider).go('/me');
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '05-me');
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '06-me-scrolled');
    await teardown(tester, db);
  });

  testWidgets('session + results + share', (tester) async {
    final (c, db) = await boot(tester);
    await tester.runAsync(
      () => c.read(sessionProvider.notifier).start(const Duration(minutes: 25)),
    );
    c.read(routerProvider).go('/session');
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '07-session-settling');
    c.read(sessionProvider.notifier).fake(DeviceSignal.deviceLocked);
    c.read(sessionProvider.notifier).warp(const Duration(minutes: 3));
    await shot(tester, '08-session-locked');
    c.read(sessionProvider.notifier).fake(DeviceSignal.deviceUnlocked);
    await shot(tester, '09-session-grace');
    c.read(sessionProvider.notifier).warp(const Duration(seconds: 11));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '10-session-cracked');
    c.read(sessionProvider.notifier).fake(DeviceSignal.deviceLocked);
    await tester.runAsync(() async {
      c.read(sessionProvider.notifier).warp(const Duration(minutes: 30));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump(const Duration(milliseconds: 800));
    await shot(tester, '11-results');
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '12-results-scrolled');
    c.read(routerProvider).push('/share');
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, '13-share');
    await teardown(tester, db);
  });

  testWidgets('breaks + emergency pass', (tester) async {
    final (c, db) = await boot(tester);
    await tester.runAsync(
      () => c.read(sessionProvider.notifier).start(const Duration(minutes: 50), breaks: true),
    );
    c.read(routerProvider).go('/session');
    await tester.pump(const Duration(milliseconds: 400));
    final s = c.read(sessionProvider.notifier);
    s.fake(DeviceSignal.deviceLocked);
    s.warp(const Duration(minutes: 25, seconds: 20));
    await shot(tester, '14-session-break');
    s.warp(const Duration(minutes: 5));
    s.fake(DeviceSignal.deviceUnlocked);
    s.warp(const Duration(seconds: 8));
    await shot(tester, '15-session-grace-with-pass');
    s.usePass();
    await shot(tester, '16-session-pass');
    await tester.runAsync(() => s.finish());
    await tester.pump(const Duration(seconds: 1));
    await teardown(tester, db);
  });

  testWidgets('squad: lobby, session, results, card', (tester) async {
    final (c, db) = await boot(tester);
    c.read(routerProvider).push('/squad/host');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 300));
    final g = c.read(groupProvider.notifier);
    final code = c.read(groupProvider)!.code;
    final friends = [for (var i = 0; i < 3; i++) SimFriend(air, 'sim:$i', Random(i + 3))];
    for (final f in friends) {
      await f.join(code);
    }
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, '17-lobby-requests');
    for (final p in [...c.read(groupProvider)!.pending.take(2)]) {
      g.approve(p.peer);
    }
    g.setOptions(lengthMin: 50, stake: 1);
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, '18-lobby');
    await tester.runAsync(() => g.start());
    await tester.pump(const Duration(seconds: 1));
    final s = c.read(sessionProvider.notifier);
    s.fake(DeviceSignal.deviceLocked);
    s.warp(const Duration(minutes: 5));
    for (final f in friends.take(2)) {
      f.set(MemberStatus.locked);
    }
    await tester.pump(const Duration(milliseconds: 300));
    s.fake(DeviceSignal.deviceUnlocked);
    await tester.pump(const Duration(milliseconds: 300));
    s.fake(DeviceSignal.deviceLocked);
    await tester.pump(const Duration(milliseconds: 100));
    friends.first.set(MemberStatus.cracked);
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, '19-squad-session-callout');
    await tester.runAsync(() async {
      s.warp(const Duration(minutes: 50));
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '20-squad-results');
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '21-squad-results-scrolled');
    c.read(routerProvider).push('/share');
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, '22-squad-card');
    for (final f in friends) {
      f.dispose();
    }
    await teardown(tester, db);
  });

  testWidgets('me: stickers + wrapped', (tester) async {
    final (c, db) = await boot(tester);
    c.read(routerProvider).go('/me');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '23-me-stickers');
    c.read(routerProvider).push('/wrapped');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '24-wrapped-1');
    await tester.tap(find.byType(PageView));
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, '25-wrapped-2');
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byType(PageView));
      for (var j = 0; j < 5; j++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await shot(tester, '26-wrapped-card');
    await teardown(tester, db);
  });
}
