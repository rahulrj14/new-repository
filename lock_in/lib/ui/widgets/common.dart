import 'package:material_ui/material_ui.dart';

import '../../progression/streaks.dart';
import '../../storage/db.dart';
import '../theme/tokens.dart';

/// White rounded card with a soft shadow.
class LockCard extends StatelessWidget {
  const LockCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(LockRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(color: color ?? LockColors.card, borderRadius: radius, boxShadow: kCardShadow),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Chat-style speech bubble with a little tail, like a message from your blob.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.text, this.color = Colors.white, this.textColor = LockColors.ink, this.tailLeft = true});
  final String text;
  final Color color;
  final Color textColor;
  final bool tailLeft;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor);
    return CustomPaint(
      painter: _BubblePainter(color, tailLeft),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Text(text, style: style, textAlign: TextAlign.center),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.color, this.tailLeft);
  final Color color;
  final bool tailLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height - 8), const Radius.circular(18));
    final tx = tailLeft ? size.width * 0.28 : size.width * 0.72;
    final p = Path()
      ..addRRect(r)
      ..moveTo(tx - 9, size.height - 9)
      ..lineTo(tx - 4, size.height)
      ..lineTo(tx + 9, size.height - 9)
      ..close();
    canvas.drawShadow(p, const Color(0x55111827), 3, false);
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color || old.tailLeft != tailLeft;
}

/// Blue header with a curved bottom edge.
class BlueHeader extends StatelessWidget {
  const BlueHeader({super.key, required this.child, this.color = LockColors.blue});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.18)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(bottom: false, child: child),
    );
  }
}

/// "✦ 120" pill.
class AuraPill extends StatelessWidget {
  const AuraPill({super.key, required this.aura, this.onBlue = false});
  final int aura;
  final bool onBlue;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$aura aura',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: onBlue ? Colors.white.withValues(alpha: 0.18) : Colors.white,
          borderRadius: BorderRadius.circular(LockRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✦', style: TextStyle(color: LockColors.sun, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Text('$aura',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: onBlue ? Colors.white : LockColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// Chunky progress bar.
class FatBar extends StatelessWidget {
  const FatBar({super.key, required this.value, this.color = LockColors.sun, this.track = LockColors.line, this.height = 12});
  final double value;
  final Color color;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LockRadius.pill),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: track),
            FractionallySizedBox(widthFactor: value.clamp(0.0, 1.0), child: Container(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Mon–Sun dots for this week: done, frozen, today, missed.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days, required this.today});
  final Map<int, DayRow> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final t = dayNumber(today);
    final monday = t - (today.weekday - 1);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Builder(builder: (context) {
            final d = monday + i;
            final row = days[d];
            final done = row?.qualified ?? false;
            final frozen = row?.frozen ?? false;
            final isToday = d == t;
            final bg = done
                ? LockColors.blue
                : frozen
                    ? LockColors.ice
                    : LockColors.bg;
            final label = done ? 'done' : frozen ? 'frozen' : d < t ? 'missed' : 'not yet';
            return Semantics(
              label: '${labels[i]}: $label',
              excludeSemantics: true,
              child: Column(
                children: [
                  Text(labels[i], style: text.bodyMedium?.copyWith(fontWeight: isToday ? FontWeight.w700 : null)),
                  const SizedBox(height: 6),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: isToday && !done ? Border.all(color: LockColors.blue, width: 2) : null,
                    ),
                    child: Text(
                      done ? '🔥' : frozen ? '❄️' : '',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

/// Big number + small label tile.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.color = LockColors.ink});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: LockCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              FittedBox(child: Text(value, style: text.headlineMedium?.copyWith(color: color))),
              Text(label, style: text.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
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
