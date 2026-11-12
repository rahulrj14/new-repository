import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../catalog/nicknames.dart';
import '../../session/session_controller.dart';
import '../../storage/profile_store.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';

/// Story-sized (1080×1920) share card, rendered on the phone.
/// Only what's on the card is shared: your blob, nickname and session stats.
class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // Card is laid out at 360×640 logical px; ×3 = 1080×1920.
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lock-in-card.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'image/png')]));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("couldn't make the card. try again?")));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(lastResultProvider);
    final profile = ref.watch(profileProvider);
    final p = ref.watch(progressValueProvider);
    if (r == null || profile == null) return const Scaffold();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: LockColors.bg,
        title: Text('share your run', style: text.titleLarge),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    child: RepaintBoundary(
                      key: _key,
                      child: ShareCard(
                        avatarId: profile.avatarId,
                        skinId: profile.skinId,
                        nickname: nicknameFor(profile.nicknameId),
                        aura: r.aura.total,
                        minutes: r.aura.lockedMinutes,
                        cracks: r.cracks,
                        streak: p.streak.days,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _share,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(_busy ? 'making it…' : 'share to story'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.avatarId,
    required this.skinId,
    required this.nickname,
    required this.aura,
    required this.minutes,
    required this.cracks,
    required this.streak,
  });

  final int avatarId;
  final int skinId;
  final String nickname;
  final int aura;
  final int minutes;
  final int cracks;
  final int streak;

  @override
  Widget build(BuildContext context) {
    TextStyle t(double size, {Color color = Colors.white, FontWeight w = FontWeight.w700}) =>
        TextStyle(fontFamily: kFont, fontSize: size, fontWeight: w, color: color, height: 1.05);
    Widget chip(String s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(LockRadius.pill),
          ),
          child: Text(s, style: t(16, w: FontWeight.w600)),
        );
    return MediaQuery(
      // The card always renders the same, whatever the phone's text size.
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
      child: Container(
        width: 360,
        height: 640,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B7BFF), LockColors.blueDeep],
          ),
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        child: Stack(
          children: [
            // Confetti dots.
            for (final (x, y, r, c) in const [
              (30.0, 90.0, 7.0, LockColors.sun),
              (310.0, 70.0, 5.0, Colors.white),
              (290.0, 250.0, 9.0, LockColors.coral),
              (40.0, 330.0, 6.0, Colors.white),
              (320.0, 420.0, 6.0, LockColors.sun),
              (300.0, 560.0, 8.0, LockColors.mint),
            ])
              Positioned(
                left: x,
                top: y,
                child: Container(width: r * 2, height: r * 2, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  Text('🔒 lock in', style: t(22)),
                  const Spacer(),
                  ChatBubble(text: cracks == 0 ? 'zero cracks. built different.' : 'locked in (mostly) 😅'),
                  BlobAvatar(
                    avatarId: avatarId,
                    skinId: skinId,
                    size: 200,
                    mood: cracks == 0 ? BlobMood.happy : BlobMood.idle,
                    animate: false,
                  ),
                  Text('+$aura', style: t(84)),
                  Text('aura ✦', style: t(24, color: LockColors.sun)),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip('⏱️ $minutes min'),
                      chip(cracks == 0 ? '💎 0 cracks' : '💔 $cracks'),
                      if (streak > 0) chip('🔥 $streak-day streak'),
                    ],
                  ),
                  const Spacer(),
                  Text(nickname, style: t(20)),
                  const SizedBox(height: 4),
                  Text('phone down. aura up.', style: t(15, color: Colors.white70, w: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
