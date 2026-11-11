import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/avatars.dart';
import '../../catalog/nicknames.dart';
import '../../platform/device_bridge.dart';
import '../../progression/aura.dart';
import '../../session/session_controller.dart';
import '../../storage/profile_store.dart';
import '../theme/tokens.dart';
import '../widgets/blob_avatar.dart';
import '../widgets/common.dart';
import 'settings_sheet.dart';

/// null = open-ended.
const _lengths = <Duration?>[
  Duration(minutes: 25),
  Duration(minutes: 50),
  Duration(minutes: 90),
  null,
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Duration? _length = const Duration(minutes: 25);
  bool _dismissedWarning = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (profile == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final avatar = avatarById(profile.avatarId);
    final level = profile.level;
    final interrupted = ref.watch(interruptedAtLaunchProvider);
    final info = ref.watch(deviceInfoProvider).value ?? const {};
    final batteryRisk = info['batteryOptimized'] == true;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AuraPill(aura: profile.auraTotal),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Settings',
                    iconSize: 28,
                    onPressed: () => showSettingsSheet(context),
                    icon: const Icon(Icons.settings_rounded, color: LockColors.muted),
                  ),
                ],
              ),
              if (!_dismissedWarning && (interrupted || batteryRisk))
                _Warning(
                  interrupted: interrupted,
                  onFix: () => ref.read(deviceBridgeProvider).openAppSettings(),
                  onClose: () => setState(() => _dismissedWarning = true),
                ),
              const Spacer(),
              Center(
                child: Glow(
                  color: avatar.color,
                  size: 280,
                  child: BlobAvatar(avatarId: avatar.id, size: 190, semanticLabel: 'Your blob, ${avatar.name}'),
                ),
              ),
              const SizedBox(height: 8),
              Text(nicknameFor(profile.nicknameId), textAlign: TextAlign.center, style: text.headlineMedium),
              const SizedBox(height: 14),
              _LevelRow(level: level, aura: profile.auraTotal),
              const Spacer(),
              _LengthPicker(
                value: _length,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _length = v);
                },
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(sessionProvider.notifier).start(_length);
                  if (context.mounted) context.go('/session');
                },
                child: const Text('lock in 🔒'),
              ),
              const SizedBox(height: 10),
              Text(
                profile.auraToday >= AuraRules.dailyCap
                    ? 'daily cap hit. touch grass 🌱'
                    : 'today ✦ ${profile.auraToday} / ${AuraRules.dailyCap}  ·  friends mode soon',
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level, required this.aura});
  final Level level;
  final int aura;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final next = level.next;
    return Semantics(
      label: 'Level ${level.number}, ${level.name}. '
          '${next == null ? 'Max level' : '${next - aura} aura to next level'}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text('LV ${level.number} · ${level.name}',
              style: text.titleMedium?.copyWith(color: LockColors.lime)),
          const SizedBox(height: 8),
          SizedBox(width: 200, child: FatBar(value: level.progress(aura))),
          const SizedBox(height: 6),
          Text(next == null ? 'max level. legend.' : '${next - aura} to next', style: text.bodyMedium),
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
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == l ? LockColors.text : LockColors.surface,
                    borderRadius: BorderRadius.circular(LockRadius.pill),
                  ),
                  child: Text(
                    l == null ? '∞' : '${l.inMinutes}m',
                    style: text.titleLarge?.copyWith(color: value == l ? LockColors.bg : LockColors.text),
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
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(color: LockColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interrupted ? 'your phone killed the last session' : 'your phone might kill sessions',
                  style: text.titleMedium,
                ),
                GestureDetector(
                  onTap: onFix,
                  child: Text('open settings → battery → no restrictions',
                      style: text.bodyMedium?.copyWith(color: LockColors.lime)),
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
