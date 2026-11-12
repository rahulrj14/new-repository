// Play Store phone screenshots (1080x1920, 9:16) rendered from the real app
// with seeded demo data. Run:  flutter test tool/store_screenshots_test.dart
// Writes ../docs/play-store/screenshots/*.png
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/app.dart';
import 'package:lock_in/catalog/vibes.dart';
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

const _out = '../docs/play-store/screenshots';

Future<void> _fonts() async {
  final l = FontLoader('Fredoka');
  for (final w in [400, 500, 600, 700]) {
    l.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Fredoka-$w.ttf').readAsBytesSync())));
  }
  await l.load();
  final e = FontLoader('Noto Color Emoji')
    ..addFont(Future.value(ByteData.sublistView(File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf').readAsBytesSync())));
  await e.load();
  final d = FontLoader('DejaVu Sans')
    ..addFont(Future.value(ByteData.sublistView(File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf').readAsBytesSync())));
  await d.load();
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter';
  final i = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(
        File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
  await i.load();
}

late FakeAir air;

void main() {
  setUpAll(_fonts);

  Future<(ProviderContainer, AppDatabase)> boot(WidgetTester t) async {
    // 1080x1920 at 2.75 → 393x698 logical (a typical phone, 9:16).
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 2.75;
    air = FakeAir();
    final m = t.binding.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('lockin/device_use'), (_) async => null);
    m.setMockStreamHandler(const EventChannel('lockin/device_use/events'), MockStreamHandler.inline(onListen: (_, _) {}));
    SharedPreferences.setMockInitialValues({'avatarId': 1, 'nicknameId': 1234, 'skinId': 4});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    await t.runAsync(() async {
      final repo = ProgressRepo(db);
      final now = DateTime.now();
      for (var i = 9; i >= 1; i--) {
        final end = now.subtract(Duration(days: i, hours: 2));
        await repo.recordSession(
          startedAt: end.subtract(const Duration(minutes: 50)),
          endedAt: end,
          plannedMinutes: 50,
          lockedSeconds: 49 * 60,
          cracks: i == 5 ? 1 : 0,
          completed: true,
          aura: 59,
          vibe: Vibe.values[i % Vibe.values.length],
          clutches: i % 3 == 0 ? 1 : 0,
        );
      }
    });
    final c = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      dbProvider.overrideWithValue(db),
      groupTransportProvider.overrideWithValue((_) => FakeTransport(air, 'host')),
      fakeAirProvider.overrideWithValue(air),
      blePrepareProvider.overrideWithValue(() async => null),
    ]);
    await t.runAsync(() => c.read(progressProvider.future));
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const LockInApp()));
    await t.pump(const Duration(milliseconds: 500));
    return (c, db);
  }

  Future<void> shot(WidgetTester t, String name) async {
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.runAsync(() async {
      final b = t.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
      final img = await b.toImage(pixelRatio: 2.75);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> done(WidgetTester t, AppDatabase db) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 30));
    await t.runAsync(db.close);
  }

  testWidgets('store screenshots', (t) async {
    final (c, db) = await boot(t);
    await shot(t, '1-home');

    // Squad: lobby with friends, then a live crack call-out.
    c.read(routerProvider).push('/squad/host');
    await t.pump(const Duration(milliseconds: 300));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 300));
    final g = c.read(groupProvider.notifier);
    final friends = [for (var i = 0; i < 3; i++) SimFriend(air, 'sim:$i', Random(i + 3))];
    for (final f in friends) {
      await f.join(c.read(groupProvider)!.code);
    }
    await t.pump(const Duration(milliseconds: 300));
    for (final p in [...c.read(groupProvider)!.pending.take(2)]) {
      g.approve(p.peer);
    }
    g.setOptions(lengthMin: 50, stake: 1, lastStanding: false);
    await shot(t, '2-squad-lobby');
    await t.runAsync(() => g.start());
    await t.pump(const Duration(seconds: 1));
    final s = c.read(sessionProvider.notifier);
    s.fake(DeviceSignal.deviceLocked);
    s.warp(const Duration(minutes: 7));
    for (final f in friends.take(2)) {
      f.set(MemberStatus.locked);
    }
    await t.pump(const Duration(milliseconds: 300));
    friends.first.set(MemberStatus.cracked);
    await shot(t, '3-crack-callout');
    await t.runAsync(() async {
      s.warp(const Duration(minutes: 50));
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await t.pump(const Duration(seconds: 1));
    await shot(t, '4-results');
    c.read(routerProvider).push('/share');
    await shot(t, '5-squad-card');
    for (final f in friends) {
      f.dispose();
    }
    c.read(routerProvider).go('/me');
    await shot(t, '6-me-skins');
    c.read(routerProvider).go('/streak');
    await shot(t, '7-streak');
    await done(t, db);
  });
}
