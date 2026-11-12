import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/nicknames.dart';
import '../../catalog/skins.dart';
import '../../catalog/stickers.dart';
import '../../group/stakes.dart';
import '../../progression/aura.dart';
import '../../progression/quests.dart';
import '../../session/session_controller.dart';
import '../../storage/profile_store.dart';
import '../../storage/progress_repo.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';
import '../widgets/sticker.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(lastResultProvider);
    final profile = ref.watch(profileProvider);
    final p = ref.watch(progressValueProvider);
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
    final sq = r.squad;
    final bubble = sq != null && sq.iWon
        ? 'LAST ONE STANDING 👑'
        : r.leveledUp
        ? 'LEVEL UP! ${level.name} 🎉'
        : sq != null && sq.clean
        ? 'squad stayed clean 🫶 ×1.5'
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
            color: r.vibe.color,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  ChatBubble(text: bubble),
                  BlobAvatar(
                    avatarId: profile.avatarId,
                    skinId: sq != null && sq.iWon ? 7 : profile.skinId,
                    stage: p.stage.index,
                    size: 150,
                    mood: r.cracks == 0 ? BlobMood.happy : BlobMood.idle,
                  ),
                  _PopIn(
                    child: Semantics(
                      label: 'Plus ${r.totalAura} aura',
                      excludeSemantics: true,
                      child: Text(
                        '+${r.totalAura}',
                        style: text.displayLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  Text(
                    'aura farmed ✦',
                    style: text.titleLarge?.copyWith(color: LockColors.sun),
                  ),
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
                    const SizedBox(width: 8),
                    StatTile(
                      value: '${r.cracks}',
                      label: r.cracks == 1 ? 'crack' : 'cracks',
                      color: r.cracks > 0 ? LockColors.coral : LockColors.ink,
                    ),
                    const SizedBox(width: 8),
                    StatTile(
                      value: '${r.clutches}',
                      label: 'clutch',
                      color: LockColors.sun,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Breakdown(r: r),
                if (sq != null) ...[
                  const SizedBox(height: 12),
                  _SquadCard(sq: sq),
                ],
                if (a.hitCap) ...[
                  const SizedBox(height: 10),
                  LockCard(
                    color: const Color(0xFFE9FBF3),
                    child: Text(
                      "daily cap hit 🌱 that's plenty for today. go touch grass.",
                      style: text.bodyLarge,
                    ),
                  ),
                ],
                if (o.questCompleted != null) ...[
                  const SizedBox(height: 12),
                  _QuestDone(q: o.questCompleted!, aura: o.questAura),
                ],
                const SizedBox(height: 12),
                _StreakUpdate(o: o),
                if (o.grew) ...[
                  const SizedBox(height: 12),
                  LockCard(
                    color: const Color(0xFFF1ECFF),
                    child: Row(
                      children: [
                        BlobAvatar(
                          avatarId: profile.avatarId,
                          skinId: profile.skinId,
                          stage: o.stageAfter!.index,
                          size: 72,
                          mood: BlobMood.happy,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'your blob grew! 🌱',
                                style: text.bodyMedium,
                              ),
                              Text(
                                '${o.stageAfter!.name} stage',
                                style: text.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                for (final s in o.newSkins) ...[
                  const SizedBox(height: 12),
                  _NewSkin(
                    skin: s,
                    avatarId: profile.avatarId,
                    wearing: profile.skinId == s.id,
                    onWear: () =>
                        ref.read(profileProvider.notifier).setSkin(s.id),
                  ),
                ],
                for (final st in o.newStickers) ...[
                  const SizedBox(height: 12),
                  _NewSticker(
                    sticker: st,
                    avatarId: profile.avatarId,
                    skinId: profile.skinId,
                  ),
                ],
                const SizedBox(height: 12),
                LockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'LV ${level.number} · ${level.name}',
                              style: text.titleLarge,
                            ),
                          ),
                          Text(
                            level.next == null
                                ? 'max'
                                : '${level.next! - r.auraTotalAfter} to go',
                            style: text.bodyMedium,
                          ),
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
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
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

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.r});
  final SessionResult r;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = r.aura;
    final rows = <(String, int)>[
      ('locked minutes', a.base),
      if (a.squad > 0) ('squad clean ×1.5', a.squad),
      if (a.clutch > 0) ('clutch saves', a.clutch),
      if (a.bonus > 0) ('clean finish', a.bonus),
      if (a.penalty > 0) ('cracks', -a.penalty),
      if (r.outcome.questAura > 0) ('daily quest', r.outcome.questAura),
      if (a.capTrimmed > 0) ('over daily cap', -a.capTrimmed),
    ];
    return LockCard(
      child: Column(
        children: [
          for (final (label, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: text.bodyLarge)),
                  Text(
                    v >= 0 ? '+$v' : '$v',
                    style: text.titleMedium?.copyWith(
                      color: v >= 0 ? LockColors.blue : LockColors.coral,
                    ),
                  ),
                ],
              ),
            ),
          if (r.passUsed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '🆘 you used your emergency pass. no shame in that.',
                style: text.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _SquadCard extends StatelessWidget {
  const _SquadCard({required this.sq});
  final SquadResult sq;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final first = sq.members.where((m) => m.index == sq.firstCrack).firstOrNull;
    final winner = sq.members.where((m) => m.index == sq.winner).firstOrNull;
    String who(SquadMemberResult m) => m.me ? 'you' : nicknameFor(m.nickname);
    final stake = stakeText(sq.stake);
    String? stakeLine;
    if (sq.stake != 0) {
      if (stake.startsWith('last one standing') && winner != null) {
        stakeLine =
            '🎬 ${who(winner)} ${winner.me ? 'pick' : 'picks'} the movie';
      } else if (first != null) {
        stakeLine =
            '🎲 ${who(first)}: ${stake.replaceFirst('first crack ', '')}';
      } else {
        stakeLine = '🎲 nobody cracked — stakes off!';
      }
    }
    return LockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sq.clean ? 'squad: zero cracks 🫶' : 'the squad',
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final m in sq.members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  BlobAvatar(
                    avatarId: m.avatar,
                    skinId: m.skin,
                    size: 40,
                    animate: false,
                    cracked: m.cracks > 0,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.me ? 'you' : nicknameFor(m.nickname),
                      style: text.titleMedium,
                    ),
                  ),
                  if (m.index == sq.winner) const Text('👑 '),
                  Text(
                    '${m.lockedMin}m · ${m.cracks == 0 ? '💎' : '💔 ${m.cracks}'}',
                    style: text.bodyLarge,
                  ),
                ],
              ),
            ),
          if (stakeLine != null) ...[
            const Divider(height: 20),
            Text(stakeLine, style: text.titleMedium),
          ],
        ],
      ),
    );
  }
}

class _QuestDone extends StatelessWidget {
  const _QuestDone({required this.q, required this.aura});
  final Quest q;
  final int aura;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LockCard(
      color: const Color(0xFFE9FBF3),
      child: Row(
        children: [
          Text(q.emoji, style: text.headlineMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('quest complete ✅', style: text.bodyMedium),
                Text(q.title, style: text.titleLarge),
              ],
            ),
          ),
          Text(
            aura > 0 ? '+$aura ✦' : 'capped',
            style: text.titleMedium?.copyWith(color: LockColors.mint),
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
      title = o.streakAfter == 1
          ? 'streak started! 🔥 1 day'
          : '🔥 ${o.streakAfter}-day streak!';
      if (o.freezesUsed > 0) {
        lines.add('❄️ a freeze covered the day you missed');
      }
      if (o.earnedFreeze) lines.add('❄️ +1 freeze earned for a 7-day run');
      if (lines.isEmpty) lines.add("today's locked in. see you tomorrow ✌️");
    } else if (o.minutesToQualify == 0) {
      title = '🔥 ${o.streakAfter}-day streak';
      lines.add('today already counted ✅');
    } else {
      title = '🔥 ${o.minutesToQualify} more min today';
      lines.add(
        'sessions add up — hit 25 min to ${o.streakBefore > 0 ? 'keep' : 'start'} your streak',
      );
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
  const _NewSkin({
    required this.skin,
    required this.avatarId,
    required this.wearing,
    required this.onWear,
  });
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
          BlobAvatar(
            avatarId: avatarId,
            skinId: skin.id,
            size: 72,
            mood: BlobMood.happy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skin.unlock is Seasonal
                      ? 'seasonal skin unlocked!'
                      : 'new skin unlocked!',
                  style: text.bodyMedium,
                ),
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

class _NewSticker extends StatelessWidget {
  const _NewSticker({
    required this.sticker,
    required this.avatarId,
    required this.skinId,
  });
  final Sticker sticker;
  final int avatarId;
  final int skinId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LockCard(
      color: const Color(0xFFFFEFF5),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: BlobSticker(
              sticker: sticker,
              avatarId: avatarId,
              skinId: skinId,
              size: 80,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('new sticker!', style: text.bodyMedium),
                Text(sticker.label, style: text.titleLarge),
                Text('find it in Me → stickers', style: text.bodyMedium),
              ],
            ),
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
