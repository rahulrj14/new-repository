import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/nicknames.dart';
import '../../catalog/vibes.dart';
import '../../platform/device_bridge.dart';
import '../../progression/aura.dart';
import '../../progression/quests.dart';
import '../../progression/streaks.dart';
import '../../session/session_controller.dart';
import '../../storage/profile_store.dart';
import '../../storage/progress_repo.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';

/// null = open-ended.
const _lengths = <Duration?>[
  Duration(minutes: 25),
  Duration(minutes: 50),
  Duration(minutes: 90),
  null,
];

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  Duration? _length = const Duration(minutes: 25);
  Vibe _vibe = Vibe.study;
  bool _breaks = false;
  bool _dismissedWarning = false;

  String _greeting(ProgressSnapshot p) {
    if (p.sessions == 0) return 'hiii! ready to lock in? 👋';
    if (p.streak.doneToday) return "today's done. proud of us 😌";
    if (p.streak.frozenDays > 0) return 'a freeze saved our streak ❄️';
    if (p.streak.days > 0) return "don't break our 🔥 ${p.streak.days}";
    return "let's get that aura ✨";
  }

  bool get _breaksAllowed =>
      _length == null || _length! > const Duration(minutes: 25);

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
                    Text(
                      'lock in',
                      style: text.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    AuraPill(aura: p.auraTotal, onBlue: true),
                  ],
                ),
                const SizedBox(height: 12),
                ChatBubble(text: _greeting(p)),
                const SizedBox(height: 4),
                BlobAvatar(
                  avatarId: profile.avatarId,
                  skinId: profile.skinId,
                  stage: p.stage.index,
                  size: 160,
                  mood: p.streak.doneToday ? BlobMood.happy : BlobMood.idle,
                  semanticLabel: 'Your blob, ${p.stage.name} stage',
                ),
                Text(
                  nicknameFor(profile.nicknameId),
                  style: text.headlineMedium?.copyWith(color: Colors.white),
                ),
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
                        Text(
                          'LV ${level.number} · ${level.name}',
                          style: text.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
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
              const SizedBox(height: 12),
              _QuestCard(quest: p.todayQuest, done: p.questDoneToday),
              const SizedBox(height: 20),
              Text("what's the vibe?", style: text.titleLarge),
              const SizedBox(height: 10),
              _VibePicker(
                value: _vibe,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _vibe = v);
                },
              ),
              const SizedBox(height: 18),
              Text('how long?', style: text.titleLarge),
              const SizedBox(height: 10),
              _LengthPicker(
                value: _length,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _length = v);
                },
              ),
              if (_breaksAllowed) ...[
                const SizedBox(height: 10),
                LockCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text('breaks ☕', style: text.titleMedium),
                    subtitle: Text(
                      '25 min on, 5 min off. phone use on breaks is fine.',
                      style: text.bodyMedium,
                    ),
                    value: _breaks,
                    onChanged: (v) => setState(() => _breaks = v),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _vibe.color),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref
                      .read(sessionProvider.notifier)
                      .start(
                        _length,
                        vibe: _vibe,
                        breaks: _breaks && _breaksAllowed,
                      );
                  if (context.mounted) context.go('/session');
                },
                child: Text('Lock in ${_vibe.emoji}'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showSquadSheet(context),
                icon: const Text('🫶', style: TextStyle(fontSize: 18)),
                label: const Text('with friends'),
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

  void _showSquadSheet(BuildContext context) {
    final text = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('lock in with friends 🫶', style: text.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'same room only. phones connect over Bluetooth — no internet, no location, no accounts.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheet);
                  context.push('/squad/host');
                },
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('start a squad'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheet);
                  context.push('/squad/join');
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('join with a code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest, required this.done});
  final Quest quest;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label:
          "Today's quest: ${quest.title}, ${quest.detail}. ${done ? 'Done' : 'Plus $questReward aura'}",
      excludeSemantics: true,
      child: LockCard(
        color: done ? const Color(0xFFE9FBF3) : const Color(0xFFFFF7DD),
        child: Row(
          children: [
            Text(quest.emoji, style: text.headlineMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("today's quest", style: text.bodyMedium),
                  Text(quest.title, style: text.titleLarge),
                  Text(quest.detail, style: text.bodyMedium),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LockRadius.pill),
              ),
              child: Text(
                done ? 'done ✅' : '+$questReward ✦',
                style: text.titleMedium?.copyWith(
                  color: done ? LockColors.mint : LockColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VibePicker extends StatelessWidget {
  const _VibePicker({required this.value, required this.onChanged});
  final Vibe value;
  final ValueChanged<Vibe> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final v in Vibe.values) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: value == v,
              label: '${v.label} vibe',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 72,
                  decoration: BoxDecoration(
                    color: value == v
                        ? v.color.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(LockRadius.button),
                    border: Border.all(
                      color: value == v ? v.color : LockColors.line,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(v.emoji, style: const TextStyle(fontSize: 24)),
                      FittedBox(
                        child: Text(
                          v.label,
                          style: text.bodyMedium?.copyWith(
                            color: value == v ? v.color : LockColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (v != Vibe.values.last) const SizedBox(width: 6),
        ],
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
    final left = ((qualifyingSeconds - p.lockedSecondsToday) / 60).ceil().clamp(
      0,
      qualifyingMinutes,
    );
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
                child: Text(
                  s.days == 1 ? '1-day streak' : '${s.days}-day streak',
                  style: text.titleLarge,
                ),
              ),
              Semantics(
                label: '${s.freezes} streak freezes',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                    border: Border.all(
                      color: value == l ? LockColors.blue : LockColors.line,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l == null ? '∞' : '${l.inMinutes}',
                        style: text.titleLarge?.copyWith(
                          color: value == l ? LockColors.blue : LockColors.ink,
                        ),
                      ),
                      Text(
                        l == null ? 'open' : 'min',
                        style: text.bodyMedium?.copyWith(height: 1),
                      ),
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
  const _Warning({
    required this.interrupted,
    required this.onFix,
    required this.onClose,
  });
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
                Text(
                  interrupted
                      ? 'your phone killed the last session'
                      : 'your phone might kill sessions',
                  style: text.titleMedium,
                ),
                Text(
                  'tap → battery saver → no restrictions',
                  style: text.bodyMedium?.copyWith(color: LockColors.blue),
                ),
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
