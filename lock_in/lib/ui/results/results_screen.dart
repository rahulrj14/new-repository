import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../catalog/avatars.dart';
import '../../progression/aura.dart';
import '../../session/session_controller.dart';
import '../../storage/profile_store.dart';
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
    final avatar = avatarById(profile.avatarId);
    final level = levelFor(r.auraTotalAfter);
    final a = r.aura;
    final title = r.leveledUp
        ? 'level up! ${level.name} 🎉'
        : r.cracks == 0 && r.completed
            ? 'clean run. no cracks.'
            : r.cracks == 0
                ? 'no cracks. respect.'
                : 'cracked ${r.cracks}× — next one\'s cleaner';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Glow(
                  color: avatar.color,
                  child: BlobAvatar(
                    avatarId: avatar.id,
                    size: 160,
                    mood: r.cracks == 0 ? BlobMood.happy : BlobMood.idle,
                  ),
                ),
              ),
              _PopIn(
                child: Semantics(
                  label: 'Plus ${a.total} aura',
                  excludeSemantics: true,
                  child: Text('+${a.total}',
                      textAlign: TextAlign.center,
                      style: text.displayLarge?.copyWith(color: LockColors.lime)),
                ),
              ),
              Text('aura farmed ✦', textAlign: TextAlign.center, style: text.titleLarge),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: LockColors.muted)),
              const SizedBox(height: 24),
              Row(
                children: [
                  _Stat(value: '${a.lockedMinutes}m', label: 'locked'),
                  const SizedBox(width: 10),
                  _Stat(value: '${r.cracks}', label: r.cracks == 1 ? 'crack' : 'cracks', alarm: r.cracks > 0),
                  const SizedBox(width: 10),
                  _Stat(value: a.bonus > 0 ? '+${a.bonus}' : '—', label: 'clean bonus'),
                ],
              ),
              if (a.hitCap) ...[
                const SizedBox(height: 12),
                Text('daily cap hit. go touch grass 🌱',
                    textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: LockColors.lime)),
              ],
              const SizedBox(height: 24),
              Text('LV ${level.number} · ${level.name}', textAlign: TextAlign.center, style: text.titleMedium),
              const SizedBox(height: 8),
              FatBar(value: level.progress(r.auraTotalAfter)),
              const Spacer(),
              FilledButton(onPressed: () => context.go('/'), child: const Text('nice')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.alarm = false});
  final String value;
  final String label;
  final bool alarm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: LockColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Text(value, style: text.headlineMedium?.copyWith(color: alarm ? LockColors.crack : LockColors.text)),
              Text(label, style: text.bodyMedium),
            ],
          ),
        ),
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
