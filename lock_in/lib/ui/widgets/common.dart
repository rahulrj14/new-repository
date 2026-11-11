import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// Soft coloured glow behind a hero element.
class Glow extends StatelessWidget {
  const Glow({super.key, required this.color, required this.child, this.size = 260});
  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)]),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// "✦ 120" pill.
class AuraPill extends StatelessWidget {
  const AuraPill({super.key, required this.aura});
  final int aura;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$aura aura',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: LockColors.surface, borderRadius: BorderRadius.circular(LockRadius.pill)),
        child: Text('✦ $aura', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: LockColors.lime)),
      ),
    );
  }
}

/// Chunky progress bar.
class FatBar extends StatelessWidget {
  const FatBar({super.key, required this.value, this.color = LockColors.lime});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LockRadius.pill),
      child: SizedBox(
        height: 12,
        child: Stack(
          children: [
            Container(color: LockColors.surfaceHi),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

String fmtClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
