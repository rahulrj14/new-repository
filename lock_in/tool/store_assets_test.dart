// Renders launcher icons and Play Store graphics from the app's own drawing
// code. Run:  flutter test tool/store_assets_test.dart
// Writes android/app/src/main/res/mipmap-*/ and ../docs/play-store/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/ui/theme/tokens.dart';
import 'package:lock_in/ui/widgets/blob_avatar.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _fonts() async {
  final l = FontLoader('Fredoka');
  for (final w in [400, 500, 600, 700]) {
    l.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Fredoka-$w.ttf').readAsBytesSync())));
  }
  await l.load();
}

Future<void> _render(WidgetTester t, Widget w, Size logical, double ratio, String path) async {
  final key = GlobalKey();
  await t.pumpWidget(MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(key: key, child: SizedBox.fromSize(size: logical, child: w)),
      ),
    ),
  ));
  await t.pump();
  await t.runAsync(() async {
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: ratio);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Full-bleed icon: blue rounded square with Blip.
Widget _icon({bool rounded = true}) => Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B7BFF), LockColors.blueDeep],
        ),
        borderRadius: rounded ? BorderRadius.circular(22) : null,
      ),
      alignment: Alignment.center,
      child: const BlobAvatar(avatarId: 0, size: 78, mood: BlobMood.happy, animate: false),
    );

/// Adaptive-icon foreground: 108dp canvas, art inside the 66dp safe zone.
Widget _foreground() => const Center(
      child: BlobAvatar(avatarId: 0, size: 70, mood: BlobMood.happy, animate: false),
    );

Widget _feature() {
  const t = TextStyle(fontFamily: kFont, color: Colors.white, fontWeight: FontWeight.w700, height: 1);
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF3B7BFF), LockColors.blueDeep]),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 48),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('lock in', style: t.copyWith(fontSize: 88)),
              const SizedBox(height: 12),
              Text('phones down. aura up.', style: t.copyWith(fontSize: 34, color: LockColors.sun)),
              const SizedBox(height: 10),
              Text('with friends in the same room', style: t.copyWith(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(
          width: 440,
          height: 500,
          child: Stack(
            children: [
              Positioned(left: 0, top: 210, child: BlobAvatar(avatarId: 1, skinId: 2, size: 165, mood: BlobMood.happy, animate: false)),
              Positioned(left: 270, top: 205, child: BlobAvatar(avatarId: 3, skinId: 3, size: 160, mood: BlobMood.sleepy, animate: false)),
              Positioned(left: 115, top: 25, child: BlobAvatar(avatarId: 0, skinId: 1, size: 210, mood: BlobMood.happy, animate: false)),
              Positioned(left: 160, top: 330, child: BlobAvatar(avatarId: 4, size: 130, mood: BlobMood.shocked, cracked: true, animate: false)),
            ],
          ),
        ),
      ],
    ),
  );
}

void main() {
  setUpAll(_fonts);

  testWidgets('icons + store graphics', (t) async {
    t.view.physicalSize = const Size(3000, 3000);
    t.view.devicePixelRatio = 1;
    const res = 'android/app/src/main/res';
    const dens = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    for (final e in dens.entries) {
      // Legacy launcher icon: 48dp.
      await _render(t, _icon(), const Size(100, 100), 48 * e.value / 100, '$res/mipmap-${e.key}/ic_launcher.png');
      // Adaptive foreground: 108dp.
      await _render(t, _foreground(), const Size(108, 108), e.value, '$res/mipmap-${e.key}/ic_launcher_foreground.png');
    }
    await _render(t, _icon(rounded: false), const Size(100, 100), 5.12, '../docs/play-store/icon-512.png');
    await _render(t, _feature(), const Size(1024, 500), 1, '../docs/play-store/feature-graphic-1024x500.png');
  });
}
