import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/skins.dart';
import '../../progression/aura.dart';
import '../../session/session_controller.dart';
import '../../storage/profile_store.dart';
import '../../storage/progress_repo.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(lastResultProvider);
    final profile = ref.watch(profileProvider);
    if (r == null || profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/');
      });
      return const Scaffold();
    }
    final text = Theme.of(context).textTheme;
    final level = levelFor(r.auraTotalAfter);
    final a = r.aura;
    final o = r.outcome;
    final bubble = r.leveledUp
        ? 'LEVEL UP! ${level.name} 🎉'
        : r.cracks == 0 && r.completed
            ? 'clean run. no cracks 😎'
            : r.cracks == 0
                ? 'no cracks. respect 🫡'
                : "cracked ${r.cracks}×. next one's cleaner";

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          BlueHeader(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  ChatBubble(text: bubble),
                  BlobAvatar(
                    avatarId: profile.avatarId,
                    skinId: profile.skinId,
                    size: 150,
                    mood: r.cracks == 0 ? BlobMood.happy : BlobMood.idle,
                  ),
                  _PopIn(
                    child: Semantics(
                      label: 'Plus ${a.total} aura',
                      excludeSemantics: true,
                      child: Text('+${a.total}', style: text.displayLarge?.copyWith(color: Colors.white)),
                    ),
                  ),
                  Text('aura farmed ✦', style: text.titleLarge?.copyWith(color: LockColors.sun)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    StatTile(value: '${a.lockedMinutes}m', label: 'locked'),
                    const SizedBox(width: 10),
                    StatTile(
                      value: '${r.cracks}',
                      label: r.cracks == 1 ? 'crack' : 'cracks',
                      color: r.cracks > 0 ? LockColors.coral : LockColors.ink,
                    ),
                    const SizedBox(width: 10),
                    StatTile(value: a.bonus > 0 ? '+${a.bonus}' : '—', label: 'clean bonus', color: LockColors.blue),
                  ],
                ),
                if (a.hitCap) ...[
                  const SizedBox(height: 10),
                  LockCard(
                    color: const Color(0xFFE9FBF3),
                    child: Text("daily cap hit 🌱 that's plenty for today. go touch grass.", style: text.bodyLarge),
                  ),
                ],
                const SizedBox(height: 12),
                _StreakUpdate(o: o),
                for (final s in o.newSkins) ...[
                  const SizedBox(height: 12),
                  _NewSkin(
                    skin: s,
                    avatarId: profile.avatarId,
                    wearing: profile.skinId == s.id,
                    onWear: () => ref.read(profileProvider.notifier).setSkin(s.id),
                  ),
                ],
                const SizedBox(height: 12),
                LockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('LV ${level.number} · ${level.name}', style: text.titleLarge)),
                          Text(level.next == null ? 'max' : '${level.next! - r.auraTotalAfter} to go',
                              style: text.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FatBar(value: level.progress(r.auraTotalAfter)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/share'),
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('share'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                        onPressed: () => context.go('/'),
                        child: const Text('done'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakUpdate extends StatelessWidget {
  const _StreakUpdate({required this.o});
  final SessionOutcome o;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lines = <String>[];
    String title;
    if (o.dayJustQualified) {
      title = o.streakAfter == 1 ? 'streak started! 🔥 1 day' : '🔥 ${o.streakAfter}-day streak!';
      if (o.freezesUsed > 0) lines.add('❄️ a freeze covered the day you missed');
      if (o.earnedFreeze) lines.add('❄️ +1 freeze earned for a 7-day run');
      if (lines.isEmpty) lines.add("today's locked in. see you tomorrow ✌️");
    } else if (o.minutesToQualify == 0) {
      title = '🔥 ${o.streakAfter}-day streak';
      lines.add('today already counted ✅');
    } else {
      title = '🔥 ${o.minutesToQualify} more min today';
      lines.add('sessions add up — hit 25 min to ${o.streakBefore > 0 ? 'keep' : 'start'} your streak');
    }
    return LockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleLarge),
          for (final l in lines) Text(l, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _NewSkin extends StatelessWidget {
  const _NewSkin({required this.skin, required this.avatarId, required this.wearing, required this.onWear});
  final Skin skin;
  final int avatarId;
  final bool wearing;
  final VoidCallback onWear;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LockCard(
      color: const Color(0xFFFFF7DD),
      child: Row(
        children: [
          BlobAvatar(avatarId: avatarId, skinId: skin.id, size: 72, mood: BlobMood.happy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('new skin unlocked!', style: text.bodyMedium),
                Text(skin.name, style: text.titleLarge),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: wearing ? null : onWear,
            child: Text(wearing ? 'wearing' : 'wear'),
          ),
        ],
      ),
    );
  }
}

class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (_, v, c) => Transform.scale(scale: v, child: c),
      child: child,
    );
  }
}
