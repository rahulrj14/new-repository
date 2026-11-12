import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/nicknames.dart';
import '../../share/share_util.dart';
import '../../storage/profile_store.dart';
import '../../storage/progress_repo.dart';
import '../share/share_screen.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';

final wrappedProvider = FutureProvider.autoDispose<WrappedStats>(
  (ref) => ref.read(repoProvider).wrapped(DateTime.now()),
);

/// Year-so-far story, computed on the phone from local history. Tap to go on.
class WrappedScreen extends ConsumerStatefulWidget {
  const WrappedScreen({super.key});

  @override
  ConsumerState<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<WrappedScreen> {
  final _pages = PageController();
  final _cardKey = GlobalKey();
  int _page = 0;

  static const _colors = [
    Color(0xFF2C6BFF),
    Color(0xFF5B4BDB),
    Color(0xFFE5489C),
    Color(0xFFFF8A2C),
    Color(0xFF14B87C),
    Color(0xFF1C1F3B),
  ];

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(wrappedProvider).value;
    final profile = ref.watch(profileProvider);
    final p = ref.watch(progressValueProvider);
    if (w == null || profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final text = Theme.of(context).textTheme;
    final hours = w.minutes / 60;
    final pages = <(String, String, String)>[
      ('your ${w.year}', 'in lock in ✨', 'tap to see it'),
      (
        hours >= 10 ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1),
        'hours with your phone down',
        hours >= 1
            ? "that's ${(w.minutes / 25).floor()} focus sessions' worth 🧠"
            : 'every minute counts',
      ),
      (
        '${w.sessions}',
        'sessions',
        '${w.cleanSessions} of them with zero cracks 💎',
      ),
      (
        '${w.longestStreak}',
        'day best streak 🔥',
        'longest single session: ${w.longestSessionMin} min',
      ),
      (
        w.topVibe?.emoji ?? '🔒',
        'top vibe: ${w.topVibe?.label ?? 'study'}',
        'you lock in most in the ${w.timeOfDay}',
      ),
      (
        '${w.clutches}',
        'clutch saves 😮‍💨',
        w.squadSessions > 0
            ? '${w.squadSessions} squad sessions 🫶'
            : 'squad up next time 🫶',
      ),
    ];
    final last = _page == pages.length;

    return Scaffold(
      backgroundColor: last ? LockColors.bg : _colors[_page % _colors.length],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  for (var i = 0; i <= pages.length; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: (last ? LockColors.ink : Colors.white)
                              .withValues(alpha: i <= _page ? 0.9 : 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: last ? LockColors.ink : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (var i = 0; i < pages.length; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _pages.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      child: Semantics(
                        label: '${pages[i].$1} ${pages[i].$2}. ${pages[i].$3}',
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BlobAvatar(
                                avatarId: profile.avatarId,
                                skinId: profile.skinId,
                                stage: p.stage.index,
                                size: 150,
                                mood: i.isEven ? BlobMood.happy : BlobMood.idle,
                              ),
                              const SizedBox(height: 24),
                              FittedBox(
                                child: Text(
                                  pages[i].$1,
                                  style: text.displayLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Text(
                                pages[i].$2,
                                textAlign: TextAlign.center,
                                style: text.headlineMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                pages[i].$3,
                                textAlign: TextAlign.center,
                                style: text.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Expanded(
                          child: FittedBox(
                            child: RepaintBoundary(
                              key: _cardKey,
                              child: _WrappedCard(
                                w: w,
                                profileAvatar: profile.avatarId,
                                skin: profile.skinId,
                                stage: p.stage.index,
                                nickname: nicknameFor(profile.nicknameId),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => sharePng(
                            _cardKey,
                            pixelRatio: 3,
                            name: 'lock-in-wrapped',
                          ),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('share my wrapped'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrappedCard extends StatelessWidget {
  const _WrappedCard({
    required this.w,
    required this.profileAvatar,
    required this.skin,
    required this.stage,
    required this.nickname,
  });
  final WrappedStats w;
  final int profileAvatar;
  final int skin;
  final int stage;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    TextStyle t(
      double s, {
      Color c = Colors.white,
      FontWeight wt = FontWeight.w700,
    }) => TextStyle(
      fontFamily: kFont,
      fontSize: s,
      fontWeight: wt,
      color: c,
      height: 1.05,
    );
    Widget stat(String v, String l) => Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(v, style: t(30)),
            Text(
              l,
              style: t(13, c: Colors.white70, wt: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    return StoryFrame(
      color: const Color(0xFF3B2BC4),
      child: Column(
        children: [
          Text('🔒 lock in wrapped ${w.year}', style: t(20)),
          const Spacer(),
          ChatBubble(
            text:
                '${(w.minutes / 60).toStringAsFixed(1)} hours. phone down. 😌',
          ),
          BlobAvatar(
            avatarId: profileAvatar,
            skinId: skin,
            stage: stage,
            size: 170,
            mood: BlobMood.happy,
            animate: false,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              stat('${w.sessions}', 'sessions'),
              stat('${w.longestStreak}🔥', 'best streak'),
            ],
          ),
          Row(
            children: [
              stat(w.topVibe?.emoji ?? '🔒', 'top vibe'),
              stat('${w.clutches}', 'clutch saves'),
            ],
          ),
          Row(
            children: [
              stat('${w.cleanSessions}💎', 'clean runs'),
              stat('${w.squadSessions}🫶', 'squad sessions'),
            ],
          ),
          const Spacer(),
          Text(nickname, style: t(20)),
          Text(
            'phone down. aura up. · free on Google Play',
            style: t(14, c: Colors.white70, wt: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
