import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
      return const Scaffold(backgroundColor: LockColors.blue);
    }
    final text = Theme.of(context).textTheme;
    final phase = s.phase;
    final alarm = phase == SessionPhase.grace || phase == SessionPhase.cracked;
    final bg = alarm ? LockColors.coral : LockColors.blue;
    final today = ref.watch(progressValueProvider).auraToday;
    final liveAura = scoreSession(
      locked: s.locked,
      cracks: s.cracks,
      completedPlannedLength: false,
      earnedTodaySoFar: today,
    ).total;

    final (bubble, sub) = switch (phase) {
      SessionPhase.settling => ('lock your phone 👇', 'starts in ${s.settleLeft.inSeconds.clamp(0, 99) + 1}s'),
      SessionPhase.grace => ('LOCK IT!! 😱', 'press power within ${s.graceLeft ?? 0}s or I crack'),
      SessionPhase.cracked => ('ouch. I cracked 💔', 'lock your phone to keep farming'),
      SessionPhase.locked => ('zzz… locked in 😴', 'phone down. aura up.'),
      SessionPhase.done => ('we did it ✨', ''),
    };
    final mood = switch (phase) {
      SessionPhase.locked => BlobMood.sleepy,
      SessionPhase.grace || SessionPhase.cracked => BlobMood.shocked,
      _ => BlobMood.idle,
    };

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(systemNavigationBarColor: bg),
        child: Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg, Color.lerp(bg, Colors.black, 0.2)!],
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
                          label: s.engine.endsAt == null ? 'Elapsed ${fmtClock(s.clock)}' : '${fmtClock(s.clock)} left',
                          excludeSemantics: true,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(LockRadius.pill),
                            ),
                            child: Text(
                              fmtClock(s.clock),
                              style: text.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        AuraPill(aura: liveAura, onBlue: true),
                      ],
                    ),
                    if (s.cracks > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('💔 × ${s.cracks}', style: text.titleMedium?.copyWith(color: Colors.white)),
                      ),
                    const Spacer(),
                    Semantics(
                      liveRegion: true,
                      child: Center(child: ChatBubble(text: bubble, textColor: alarm ? LockColors.coral : LockColors.ink)),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: BlobAvatar(
                        avatarId: profile.avatarId,
                        skinId: profile.skinId,
                        size: 210,
                        mood: mood,
                        cracked: phase == SessionPhase.cracked,
                      ),
                    ),
                    if (phase == SessionPhase.grace)
                      Text('${s.graceLeft ?? 0}',
                          textAlign: TextAlign.center, style: text.displayLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(sub,
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
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
