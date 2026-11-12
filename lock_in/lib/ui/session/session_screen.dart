import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../config.dart';
import '../../detection/grace_tracker.dart';
import '../../group/group_controller.dart';
import '../../group/protocol.dart';
import '../../progression/aura.dart';
import '../../session/session_controller.dart';
import '../../session/session_engine.dart';
import '../../storage/profile_store.dart';
import '../squad/squad_widgets.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';
import 'hold_button.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  DateTime? _clutchAt;

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (prev, next) {
      if (prev != null && next == null) {
        context.go(ref.read(lastResultProvider) != null ? '/results' : '/');
      }
      if (prev != null &&
          next != null &&
          next.engine.clutches > prev.engine.clutches) {
        setState(() => _clutchAt = DateTime.now());
      }
    });
    final s = ref.watch(sessionProvider);
    final profile = ref.watch(profileProvider);
    if (s == null || profile == null) {
      final hasResult = ref.read(lastResultProvider) != null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(hasResult ? '/results' : '/');
      });
      return const Scaffold(backgroundColor: LockColors.blue);
    }
    final group = s.group ? ref.watch(groupProvider) : null;
    final callouts = ref.watch(calloutsProvider);
    final latest = callouts.isEmpty ? null : callouts.last;
    final showCallout =
        latest != null && s.now.difference(latest.at).inSeconds.abs() < 4;
    final showClutch =
        _clutchAt != null &&
        DateTime.now().difference(_clutchAt!).inMilliseconds < 2200;

    final text = Theme.of(context).textTheme;
    final phase = s.phase;
    final alarm = phase == SessionPhase.grace || phase == SessionPhase.cracked;
    final bg = switch (phase) {
      SessionPhase.grace || SessionPhase.cracked => LockColors.coral,
      SessionPhase.onBreak => LockColors.mint,
      SessionPhase.pass => const Color(0xFFFF9F1C),
      _ => s.vibe.color,
    };
    final p = ref.watch(progressValueProvider);
    final liveAura = scoreSession(
      locked: s.locked,
      cracks: s.cracks,
      completedPlannedLength: false,
      earnedTodaySoFar: p.auraToday,
      clutches: s.engine.clutches,
    ).total;
    final susp = s.suspensionLeft;

    final (bubble, sub) = switch (phase) {
      SessionPhase.settling => (
        s.vibe.startLine,
        'starts in ${s.settleLeft.inSeconds.clamp(0, 99) + 1}s',
      ),
      SessionPhase.grace => (
        'LOCK IT!! 😱',
        'press power within ${s.graceLeft ?? 0}s or I crack',
      ),
      SessionPhase.cracked => (
        'ouch. I cracked 💔',
        'lock your phone to keep farming',
      ),
      SessionPhase.locked => (s.vibe.lockedLine, 'phone down. aura up.'),
      SessionPhase.onBreak => (
        'break time ☕ stretch!',
        'back in ${fmtClock(susp ?? Duration.zero)}',
      ),
      SessionPhase.pass => (
        'emergency pass 🆘',
        "no cracks for ${fmtClock(susp ?? Duration.zero)}. lock when you're done",
      ),
      SessionPhase.done => ('we did it ✨', ''),
    };
    final mood = switch (phase) {
      SessionPhase.locked => BlobMood.sleepy,
      SessionPhase.grace || SessionPhase.cracked => BlobMood.shocked,
      SessionPhase.onBreak => BlobMood.happy,
      _ => BlobMood.idle,
    };
    final isHost = group?.isHost ?? false;
    final holdLabel = group == null
        ? 'hold to end'
        : isHost
        ? 'hold to end for everyone'
        : 'hold to leave the squad';

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarColor: bg,
        ),
        child: Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg, Color.lerp(bg, Colors.black, 0.22)!],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Semantics(
                              label: s.engine.endsAt == null
                                  ? 'Elapsed ${fmtClock(s.clock)}'
                                  : '${fmtClock(s.clock)} left',
                              excludeSemantics: true,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(
                                    LockRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  fmtClock(s.clock),
                                  style: text.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.vibe.emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                            const Spacer(),
                            AuraPill(aura: liveAura, onBlue: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (s.cracks > 0)
                              Text(
                                '💔 × ${s.cracks}   ',
                                style: text.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            if (s.engine.clutches > 0)
                              Text(
                                '😮‍💨 × ${s.engine.clutches}   ',
                                style: text.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            if (s.nextBreakIn != null)
                              Text(
                                '☕ in ${fmtClock(s.nextBreakIn!)}',
                                style: text.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                          ],
                        ),
                        if (group != null) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 92,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final m in group.others)
                                  MemberChip(
                                    m: m,
                                    now: s.now,
                                    size: 52,
                                    onDark: true,
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Semantics(
                          liveRegion: true,
                          child: Center(
                            child: ChatBubble(
                              text: bubble,
                              textColor: alarm
                                  ? LockColors.coral
                                  : LockColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: BlobAvatar(
                            avatarId: profile.avatarId,
                            skinId: profile.skinId,
                            stage: p.stage.index,
                            size: group == null ? 210 : 180,
                            mood: mood,
                            cracked: phase == SessionPhase.cracked,
                          ),
                        ),
                        if (phase == SessionPhase.grace)
                          Text(
                            '${s.graceLeft ?? 0}',
                            textAlign: TextAlign.center,
                            style: text.displayLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          sub,
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        if (alarm && s.passAvailable) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                ref.read(sessionProvider.notifier).usePass();
                              },
                              icon: const Text(
                                '🆘',
                                style: TextStyle(fontSize: 18),
                              ),
                              label: const Text('I genuinely need my phone'),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (kDebugTools)
                          _DebugBar(group: group != null && isHost),
                        HoldButton(
                          label: holdLabel,
                          onConfirmed: () =>
                              ref.read(sessionProvider.notifier).finish(),
                        ),
                      ],
                    ),
                  ),
                  if (showCallout)
                    Positioned(
                      top: group == null ? 120 : 196,
                      left: 20,
                      right: 20,
                      child: _Toast(
                        text: latest.text,
                        avatar: latest.avatar,
                        color: latest.good ? LockColors.mint : LockColors.ink,
                      ),
                    ),
                  if (showClutch)
                    const Positioned.fill(
                      child: IgnorePointer(child: _ClutchBurst()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.text, required this.avatar, required this.color});
  final String text;
  final int avatar;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (_, v, c) => Transform.scale(scale: v, child: c),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(LockRadius.pill),
            boxShadow: kCardShadow,
          ),
          child: Row(
            children: [
              BlobAvatar(
                avatarId: avatar,
                size: 44,
                animate: false,
                mood: BlobMood.shocked,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClutchBurst extends StatelessWidget {
  const _ClutchBurst();

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: reduce ? 1 : 900),
      curve: Curves.easeOutBack,
      builder: (_, v, _) => Center(
        child: Transform.rotate(
          angle: reduce ? 0 : (1 - v) * -0.4,
          child: Transform.scale(
            scale: 0.5 + v * 0.7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: LockColors.sun,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: kCardShadow,
              ),
              child: Text(
                'CLUTCH 😮‍💨 +2',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(color: LockColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Test tools for trying every state on one phone. Not in store builds.
class _DebugBar extends ConsumerWidget {
  const _DebugBar({required this.group});
  final bool group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.read(sessionProvider.notifier);
    final sims = ref.read(groupProvider.notifier).sims;
    Widget chip(String label, VoidCallback onTap) => ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide.none,
      shape: const StadiumBorder(),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 2,
        children: [
          chip('🧪 lock', () => c.fake(DeviceSignal.deviceLocked)),
          chip('🧪 unlock', () => c.fake(DeviceSignal.deviceUnlocked)),
          chip('⏩ +1m', () => c.warp(const Duration(minutes: 1))),
          chip('⏩ +10m', () => c.warp(const Duration(minutes: 10))),
          if (group && sims.isNotEmpty) ...[
            chip('🧪 friend cracks', () {
              final live = sims
                  .where((f) => f.status != MemberStatus.cracked)
                  .toList();
              if (live.isNotEmpty) {
                live[Random().nextInt(live.length)].set(MemberStatus.cracked);
              }
            }),
            chip('🧪 friends relock', () {
              for (final f in sims) {
                f.set(MemberStatus.locked);
              }
            }),
          ],
        ],
      ),
    );
  }
}
