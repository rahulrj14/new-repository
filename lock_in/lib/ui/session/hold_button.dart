import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// Press and hold to confirm. Prevents ending a session by accident without
/// a nagging "are you sure?" dialog. Screen readers: double-tap and hold.
class HoldButton extends StatefulWidget {
  const HoldButton({super.key, required this.label, required this.onConfirmed});
  final String label;
  final VoidCallback onConfirmed;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'End session',
      onLongPressHint: 'end the session',
      onLongPress: widget.onConfirmed,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          _c.forward();
        },
        onTapUp: (_) => _c.reverse(),
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => ClipRRect(
            borderRadius: BorderRadius.circular(LockRadius.button),
            child: SizedBox(
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.18)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _c.value,
                    child: Container(color: Colors.white.withValues(alpha: 0.45)),
                  ),
                  Center(child: Text(widget.label, style: text.titleMedium?.copyWith(color: Colors.white))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
