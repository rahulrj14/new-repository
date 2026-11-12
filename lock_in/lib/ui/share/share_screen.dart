import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/nicknames.dart';
import '../../session/session_controller.dart';
import '../../share/share_util.dart';
import '../../storage/profile_store.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';

/// Story-sized (1080×1920) share card, rendered on the phone.
/// Only what's on the card is shared: blobs, nicknames and session stats.
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
    // Card is laid out at 360×640 logical px; ×3 = 1080×1920.
    final ok = await sharePng(_key, pixelRatio: 3, name: 'lock-in-card');
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("couldn't make the card. try again?")),
      );
    }
    if (mounted) setState(() => _busy = false);
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
        title: Text(
          r.squad != null ? 'share the squad' : 'share your run',
          style: text.titleLarge,
        ),
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
                      child: r.squad != null
                          ? SquadCard(result: r)
                          : ShareCard(
                              avatarId: profile.avatarId,
                              skinId: profile.skinId,
                              stage: p.stage.index,
                              nickname: nicknameFor(profile.nicknameId),
                              aura: r.totalAura,
                              minutes: r.aura.lockedMinutes,
                              cracks: r.cracks,
                              clutches: r.clutches,
                              streak: p.streak.days,
                              vibeEmoji: r.vibe.emoji,
                              color: r.vibe.color,
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

/// Shared frame for 360×640 story cards.
class StoryFrame extends StatelessWidget {
  const StoryFrame({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      // Cards always render the same, whatever the phone's text size.
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
      child: Container(
        width: 360,
        height: 640,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.1)!,
              Color.lerp(color, Colors.black, 0.3)!,
            ],
          ),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
        ),
        child: Stack(
          children: [
            for (final (x, y, r, c) in const [
              (30.0, 90.0, 7.0, LockColors.sun),
              (310.0, 70.0, 5.0, Colors.white),
              (300.0, 250.0, 9.0, LockColors.coral),
              (30.0, 330.0, 6.0, Colors.white),
              (320.0, 430.0, 6.0, LockColors.sun),
              (305.0, 565.0, 8.0, LockColors.mint),
            ])
              Positioned(
                left: x,
                top: y,
                child: Container(
                  width: r * 2,
                  height: r * 2,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _t(
  double size, {
  Color color = Colors.white,
  FontWeight w = FontWeight.w700,
}) => TextStyle(
  fontFamily: kFont,
  fontSize: size,
  fontWeight: w,
  color: color,
  height: 1.05,
);

Widget _chip(String s) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.18),
    borderRadius: BorderRadius.circular(LockRadius.pill),
  ),
  child: Text(s, style: _t(16, w: FontWeight.w600)),
);

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
    this.stage = 1,
    this.clutches = 0,
    this.vibeEmoji = '🔒',
    this.color = LockColors.blue,
  });

  final int avatarId;
  final int skinId;
  final int stage;
  final String nickname;
  final int aura;
  final int minutes;
  final int cracks;
  final int clutches;
  final int streak;
  final String vibeEmoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return StoryFrame(
      color: color,
      child: Column(
        children: [
          Text('🔒 lock in', style: _t(22)),
          const Spacer(),
          ChatBubble(
            text: cracks == 0
                ? 'zero cracks. built different.'
                : 'locked in (mostly) 😅',
          ),
          BlobAvatar(
            avatarId: avatarId,
            skinId: skinId,
            stage: stage,
            size: 200,
            mood: cracks == 0 ? BlobMood.happy : BlobMood.idle,
            animate: false,
          ),
          Text('+$aura', style: _t(84)),
          Text('aura ✦', style: _t(24, color: LockColors.sun)),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('$vibeEmoji $minutes min'),
              _chip(cracks == 0 ? '💎 0 cracks' : '💔 $cracks'),
              if (clutches > 0) _chip('😮‍💨 $clutches clutch'),
              if (streak > 0) _chip('🔥 $streak-day streak'),
            ],
          ),
          const Spacer(),
          Text(nickname, style: _t(20)),
          const SizedBox(height: 4),
          Text(
            'phone down. aura up. · free on Google Play',
            style: _t(15, color: Colors.white70, w: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Everyone's blobs in one frame: the word-of-mouth card.
class SquadCard extends StatelessWidget {
  const SquadCard({super.key, required this.result});
  final SessionResult result;

  @override
  Widget build(BuildContext context) {
    final sq = result.squad!;
    final n = sq.members.length;
    final size = n <= 2
        ? 130.0
        : n <= 4
        ? 110.0
        : 84.0;
    final cracks = sq.members.fold<int>(0, (a, m) => a + m.cracks);
    final mins = sq.members
        .map((m) => m.lockedMin)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return StoryFrame(
      color: result.vibe.color,
      child: Column(
        children: [
          Text('🔒 lock in · squad', style: _t(22)),
          const Spacer(),
          ChatBubble(
            text: sq.clean
                ? 'nobody cracked. elite squad 🫶'
                : sq.winner != null
                ? 'last one standing: ${sq.members.firstWhere((m) => m.index == sq.winner).me ? 'me' : nicknameFor(sq.members.firstWhere((m) => m.index == sq.winner).nickname)} 👑'
                : 'we locked in (mostly) 😅',
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final m in sq.members)
                SizedBox(
                  width: size + 10,
                  child: Column(
                    children: [
                      BlobAvatar(
                        avatarId: m.avatar,
                        skinId: m.index == sq.winner ? 7 : m.skin,
                        size: size,
                        animate: false,
                        cracked: m.cracks > 0,
                        mood: m.cracks == 0 ? BlobMood.happy : BlobMood.shocked,
                      ),
                      Text(
                        nicknameFor(m.nickname).split(' ').last,
                        style: _t(14, w: FontWeight.w600),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            sq.clean ? '×1.5 squad aura' : '+${result.totalAura} aura',
            style: _t(40, color: LockColors.sun),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('👥 $n of us'),
              _chip('${result.vibe.emoji} $mins min'),
              _chip(cracks == 0 ? '💎 0 cracks' : '💔 $cracks total'),
            ],
          ),
          const Spacer(),
          Text(
            'phone down. aura up. · free on Google Play',
            style: _t(15, color: Colors.white70, w: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
