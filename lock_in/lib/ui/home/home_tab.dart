import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/nicknames.dart';
import '../../platform/device_bridge.dart';
import '../../progression/aura.dart';
import '../../progression/streaks.dart';
import '../../session/session_controller.dart';
import '../../storage/profile_store.dart';
import '../../storage/progress_repo.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';

/// null = open-ended.
const _lengths = <Duration?>[Duration(minutes: 25), Duration(minutes: 50), Duration(minutes: 90), null];

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  Duration? _length = const Duration(minutes: 25);
  bool _dismissedWarning = false;

  String _greeting(ProgressSnapshot p) {
    if (p.sessions == 0) return 'hiii! ready to lock in? 👋';
    if (p.streak.doneToday) return "today's done. proud of us 😌";
    if (p.streak.frozenDays > 0) return 'a freeze saved our streak ❄️';
    if (p.streak.days > 0) return "don't break our 🔥 ${p.streak.days}";
    return "let's get that aura ✨";
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (profile == null) return const SizedBox.shrink();
    final p = ref.watch(progressValueProvider);
    final text = Theme.of(context).textTheme;
    final level = p.level;
    final interrupted = ref.watch(interruptedAtLaunchProvider);
    final info = ref.watch(deviceInfoProvider).value ?? const {};
    final batteryRisk = info['batteryOptimized'] == true;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        BlueHeader(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('lock in', style: text.headlineMedium?.copyWith(color: Colors.white)),
                    const Spacer(),
                    AuraPill(aura: p.auraTotal, onBlue: true),
                  ],
                ),
                const SizedBox(height: 16),
                ChatBubble(text: _greeting(p)),
                const SizedBox(height: 4),
                BlobAvatar(
                  avatarId: profile.avatarId,
                  skinId: profile.skinId,
                  size: 170,
                  mood: p.streak.doneToday ? BlobMood.happy : BlobMood.idle,
                  semanticLabel: 'Your blob',
                ),
                Text(nicknameFor(profile.nicknameId), style: text.headlineMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 10),
                Semantics(
                  label: 'Level ${level.number}, ${level.name}',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('LV ${level.number} · ${level.name}',
                            style: text.titleMedium?.copyWith(color: Colors.white)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 160,
                          child: FatBar(
                            value: level.progress(p.auraTotal),
                            track: Colors.white.withValues(alpha: 0.25),
                            height: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_dismissedWarning && (interrupted || batteryRisk)) ...[
                _Warning(
                  interrupted: interrupted,
                  onFix: () => ref.read(deviceBridgeProvider).openAppSettings(),
                  onClose: () => setState(() => _dismissedWarning = true),
                ),
                const SizedBox(height: 12),
              ],
              _StreakCard(p: p, onTap: () => context.go('/streak')),
              const SizedBox(height: 20),
              Text('how long?', style: text.titleLarge),
              const SizedBox(height: 10),
              _LengthPicker(
                value: _length,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _length = v);
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(sessionProvider.notifier).start(_length);
                  if (context.mounted) context.go('/session');
                },
                child: const Text('Lock in 🔒'),
              ),
              const SizedBox(height: 10),
              Text(
                p.auraToday >= AuraRules.dailyCap
                    ? 'daily cap hit. go touch grass 🌱'
                    : 'today ✦ ${p.auraToday} / ${AuraRules.dailyCap} aura',
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.p, required this.onTap});
  final ProgressSnapshot p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = p.streak;
    final left = ((qualifyingSeconds - p.lockedSecondsToday) / 60).ceil().clamp(0, qualifyingMinutes);
    final sub = s.doneToday
        ? "today's done. see you tomorrow ✌️"
        : s.days > 0
            ? '$left more min today keeps it alive'
            : 'lock in $left min today to start one';
    return LockCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🔥', style: text.headlineMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.days == 1 ? '1-day streak' : '${s.days}-day streak', style: text.titleLarge),
              ),
              Semantics(
                label: '${s.freezes} streak freezes',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LockColors.ice.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(LockRadius.pill),
                  ),
                  child: Text('❄️ ${s.freezes}', style: text.titleMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(sub, style: text.bodyMedium),
          const SizedBox(height: 14),
          WeekStrip(days: p.days, today: DateTime.now()),
        ],
      ),
    );
  }
}

class _LengthPicker extends StatelessWidget {
  const _LengthPicker({required this.value, required this.onChanged});
  final Duration? value;
  final ValueChanged<Duration?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final l in _lengths) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: value == l,
              label: l == null ? 'Open-ended' : '${l.inMinutes} minutes',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == l ? LockColors.blueSoft : Colors.white,
                    borderRadius: BorderRadius.circular(LockRadius.button),
                    border: Border.all(color: value == l ? LockColors.blue : LockColors.line, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l == null ? '∞' : '${l.inMinutes}',
                          style: text.titleLarge?.copyWith(color: value == l ? LockColors.blue : LockColors.ink)),
                      Text(l == null ? 'open' : 'min', style: text.bodyMedium?.copyWith(height: 1)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (l != _lengths.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.interrupted, required this.onFix, required this.onClose});
  final bool interrupted;
  final VoidCallback onFix;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LockCard(
      color: const Color(0xFFFFF4D6),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      onTap: onFix,
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(interrupted ? 'your phone killed the last session' : 'your phone might kill sessions',
                    style: text.titleMedium),
                Text('tap → battery saver → no restrictions',
                    style: text.bodyMedium?.copyWith(color: LockColors.blue)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: LockColors.muted),
          ),
        ],
      ),
    );
  }
}
