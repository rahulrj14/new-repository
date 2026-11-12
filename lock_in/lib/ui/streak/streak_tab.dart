import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../progression/streaks.dart';
import '../../storage/profile_store.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class StreakTab extends ConsumerWidget {
  const StreakTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressValueProvider);
    final s = p.streak;
    final text = Theme.of(context).textTheme;
    final today = dayNumber(DateTime.now());
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        BlueHeader(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Semantics(
              label: '${s.days} day streak. Best ${s.longest} days.',
              excludeSemantics: true,
              child: Column(
                children: [
                  Text('🔥', style: text.displayMedium),
                  Text('${s.days}', style: text.displayLarge?.copyWith(color: Colors.white)),
                  Text(s.days == 1 ? 'day streak' : 'day streak', style: text.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('best: ${s.longest} ${s.longest == 1 ? 'day' : 'days'}',
                      style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LockCard(
                child: Row(
                  children: [
                    Text('❄️', style: text.headlineLarge),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s.freezes} / $maxFreezes freezes', style: text.titleLarge),
                          Text('earn one every $freezeEvery days. it covers a missed day automatically.',
                              style: text.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('last 4 weeks', style: text.titleLarge),
                    const SizedBox(height: 12),
                    _MonthGrid(days: p.days, today: today),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: const [
                        _Legend(color: LockColors.blue, label: 'locked in'),
                        _Legend(color: LockColors.ice, label: 'frozen'),
                        _Legend(color: LockColors.line, label: 'missed'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('how it works', style: text.titleLarge),
                    const SizedBox(height: 10),
                    for (final (e, line) in const [
                      ('⏱️', 'lock in $qualifyingMinutes min in a day. short sessions add up.'),
                      ('❄️', 'miss a day? a freeze saves it.'),
                      ('🤫', 'no reminders, no guilt trips. just vibes.'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(line, style: text.bodyLarge)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.days, required this.today});
  final Map<int, dynamic> days;
  final int today;

  @override
  Widget build(BuildContext context) {
    final first = today - 27;
    return LayoutBuilder(builder: (context, c) {
      const gap = 8.0;
      final cell = (c.maxWidth - gap * 6) / 7;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var d = first; d <= today; d++)
            Builder(builder: (context) {
              final row = days[d];
              final done = row?.qualified == true;
              final frozen = row?.frozen == true;
              final date = dayFromNumber(d);
              return Semantics(
                label: '${date.day}/${date.month}: ${done ? 'locked in' : frozen ? 'frozen' : 'no streak'}',
                excludeSemantics: true,
                child: Container(
                  width: cell,
                  height: cell,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? LockColors.blue : frozen ? LockColors.ice : LockColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: d == today ? Border.all(color: LockColors.blue, width: 2) : null,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontWeight: FontWeight.w600,
                      color: done || frozen ? Colors.white : LockColors.muted,
                    ),
                  ),
                ),
              );
            }),
        ],
      );
    });
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
