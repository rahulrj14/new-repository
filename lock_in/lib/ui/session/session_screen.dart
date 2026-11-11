import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/avatars.dart';
import '../../config.dart';
import '../../detection/grace_tracker.dart';
import '../../progression/aura.dart';
import '../../session/session_controller.dart';
import '../../session/session_engine.dart';
import '../../storage/profile_store.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';
import 'hold_button.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionProvider, (prev, next) {
      if (prev != null && next == null) {
        context.go(ref.read(lastResultProvider) != null ? '/results' : '/');
      }
    });
    final s = ref.watch(sessionProvider);
    final profile = ref.watch(profileProvider);
    if (s == null || profile == null) {
      // Session ended: the listener above routes to results. Only fall back
      // to home if there is nothing to show (e.g. opened without a session).
      final hasResult = ref.read(lastResultProvider) != null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(hasResult ? '/results' : '/');
      });
      return const Scaffold();
    }
    final text = Theme.of(context).textTheme;
    final avatar = avatarById(profile.avatarId);
    final phase = s.phase;
    final alarm = phase == SessionPhase.grace || phase == SessionPhase.cracked;
    final accent = alarm ? LockColors.crack : avatar.color;
    final liveAura = scoreSession(
      locked: s.locked,
      cracks: s.cracks,
      completedPlannedLength: false,
      earnedTodaySoFar: profile.auraToday,
    ).total;

    final (headline, sub) = switch (phase) {
      SessionPhase.settling => ('lock your\nphone 👇', 'starts in ${s.settleLeft.inSeconds.clamp(0, 99) + 1}s'),
      SessionPhase.grace => ('lock it!', 'press power within ${s.graceLeft ?? 0}s or it cracks'),
      SessionPhase.cracked => ('cracked 💔', 'lock your phone to keep farming'),
      SessionPhase.locked => ('locked in', 'phone down. aura up.'),
      SessionPhase.done => ('done ✦', ''),
    };
    final mood = switch (phase) {
      SessionPhase.locked => BlobMood.sleepy,
      SessionPhase.grace => BlobMood.shocked,
      SessionPhase.cracked => BlobMood.shocked,
      _ => BlobMood.idle,
    };

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.1,
              colors: [accent.withValues(alpha: alarm ? 0.22 : 0.10), LockColors.bg],
            ),
          ),
          child: SafeArea(
            child: Padding(
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
                        child: Text(fmtClock(s.clock),
                            style: text.headlineMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                      const Spacer(),
                      AuraPill(aura: liveAura),
                    ],
                  ),
                  if (s.cracks > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('💔 × ${s.cracks}', style: text.titleMedium?.copyWith(color: LockColors.crack)),
                    ),
                  const Spacer(),
                  Center(
                    child: Glow(
                      color: accent,
                      size: 300,
                      child: BlobAvatar(
                        avatarId: avatar.id,
                        size: 200,
                        mood: mood,
                        cracked: phase == SessionPhase.cracked,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    liveRegion: true,
                    child: Column(
                      children: [
                        if (phase == SessionPhase.grace)
                          Text('${s.graceLeft ?? 0}',
                              style: text.displayLarge?.copyWith(color: LockColors.crack)),
                        Text(headline,
                            textAlign: TextAlign.center,
                            style: text.headlineLarge?.copyWith(color: alarm ? LockColors.crack : LockColors.text)),
                        const SizedBox(height: 8),
                        Text(sub, textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: LockColors.muted)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (kDebugTools) const _DebugBar(),
                  HoldButton(
                    label: 'hold to end',
                    onConfirmed: () => ref.read(sessionProvider.notifier).finish(),
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

/// Test tools for trying every state on one phone. Not in store builds.
class _DebugBar extends ConsumerWidget {
  const _DebugBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.read(sessionProvider.notifier);
    Widget chip(String label, VoidCallback onTap) => ActionChip(label: Text(label), onPressed: onTap);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          chip('🧪 fake lock', () => c.fake(DeviceSignal.deviceLocked)),
          chip('🧪 fake unlock', () => c.fake(DeviceSignal.deviceUnlocked)),
          chip('⏩ +1 min', () => c.warp(const Duration(minutes: 1))),
          chip('⏩ +10 min', () => c.warp(const Duration(minutes: 10))),
        ],
      ),
    );
  }
}
