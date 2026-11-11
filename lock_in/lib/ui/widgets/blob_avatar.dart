import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../catalog/avatars.dart';

enum BlobMood { idle, sleepy, shocked, happy }

/// An expressive blob character. Bobs gently (unless reduced motion is on)
/// and can show a crack that draws itself across the body.
class BlobAvatar extends StatefulWidget {
  const BlobAvatar({
    super.key,
    required this.avatarId,
    this.size = 160,
    this.mood = BlobMood.idle,
    this.cracked = false,
    this.animate = true,
    this.semanticLabel,
  });

  final int avatarId;
  final double size;
  final BlobMood mood;
  final bool cracked;
  final bool animate;
  final String? semanticLabel;

  @override
  State<BlobAvatar> createState() => _BlobAvatarState();
}

class _BlobAvatarState extends State<BlobAvatar> with TickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  late final AnimationController _crack =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650), value: widget.cracked ? 1 : 0);

  bool get _motion => widget.animate && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motion) {
      if (!_bob.isAnimating) _bob.repeat();
    } else {
      _bob.stop();
    }
  }

  @override
  void didUpdateWidget(BlobAvatar old) {
    super.didUpdateWidget(old);
    if (widget.cracked && !old.cracked) {
      _motion ? _crack.forward(from: 0) : _crack.value = 1;
    } else if (!widget.cracked && old.cracked) {
      _crack.value = 0;
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _crack.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = avatarById(widget.avatarId);
    return Semantics(
      label: widget.semanticLabel ?? spec.name,
      image: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bob, _crack]),
        builder: (context, _) {
          final t = _bob.value * 2 * math.pi;
          // Shake while the crack is drawing in.
          final shake = _crack.isAnimating ? math.sin(_crack.value * 40) * 6 * (1 - _crack.value) : 0.0;
          final bob = _motion ? math.sin(t) * widget.size * 0.03 : 0.0;
          final squash = _motion ? 1 + math.sin(t * 2) * 0.015 : 1.0;
          return Transform.translate(
            offset: Offset(shake, bob),
            child: Transform.scale(
              scaleX: squash,
              scaleY: 2 - squash,
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _BlobPainter(spec, widget.mood, _crack.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.spec, this.mood, this.crack);
  final AvatarSpec spec;
  final BlobMood mood;
  final double crack;

  static const ink = Color(0xFF0A0A0F);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final body = _bodyPath(s);
    final fill = Paint()..color = spec.color;

    // Soft glow.
    canvas.drawPath(
      body.shift(Offset(0, s * 0.03)),
      Paint()
        ..color = spec.color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    _topper(canvas, s);
    canvas.drawPath(body, fill);
    // Highlight.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawCircle(Offset(s * 0.33, s * 0.33), s * 0.16,
        Paint()..color = Colors.white.withValues(alpha: 0.22));
    canvas.restore();

    _face(canvas, s);
    if (crack > 0) _crackLines(canvas, s, body);
  }

  Path _bodyPath(double s) {
    final r = Rect.fromLTWH(s * 0.14, s * 0.2, s * 0.72, s * 0.68);
    switch (spec.shape) {
      case BlobShape.round:
        return Path()..addOval(r.inflate(s * 0.01));
      case BlobShape.squircle:
        return Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(s * 0.26)));
      case BlobShape.bean:
        return Path()..addOval(Rect.fromLTWH(s * 0.12, s * 0.24, s * 0.76, s * 0.62));
      case BlobShape.ghost:
        final p = Path()
          ..moveTo(r.left, r.center.dy)
          ..arcToPoint(Offset(r.right, r.center.dy), radius: Radius.circular(r.width / 2))
          ..lineTo(r.right, r.bottom);
        const waves = 4;
        final w = r.width / waves;
        for (var i = 0; i < waves; i++) {
          final x = r.right - w * i;
          p.quadraticBezierTo(x - w / 2, r.bottom - s * (i.isEven ? 0.08 : -0.02), x - w, r.bottom);
        }
        return p..close();
    }
  }

  void _topper(Canvas canvas, double s) {
    final fill = Paint()..color = spec.color;
    final stroke = Paint()
      ..color = spec.color
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    switch (spec.topper) {
      case BlobTopper.none:
        break;
      case BlobTopper.antenna:
        canvas.drawLine(Offset(s * 0.5, s * 0.22), Offset(s * 0.56, s * 0.08), stroke);
        canvas.drawCircle(Offset(s * 0.56, s * 0.08), s * 0.045, fill);
      case BlobTopper.ears:
        for (final x in [0.28, 0.72]) {
          canvas.drawPath(
            Path()
              ..moveTo(s * (x - 0.1), s * 0.3)
              ..lineTo(s * x, s * 0.1)
              ..lineTo(s * (x + 0.1), s * 0.3)
              ..close(),
            fill,
          );
        }
      case BlobTopper.horns:
        for (final d in [-1.0, 1.0]) {
          final x = 0.5 + 0.2 * d;
          canvas.drawPath(
            Path()
              ..moveTo(s * (x - 0.06), s * 0.26)
              ..quadraticBezierTo(s * (x + 0.02 * d), s * 0.18, s * (x + 0.08 * d), s * 0.08)
              ..lineTo(s * (x + 0.06), s * 0.26)
              ..close(),
            Paint()..color = Colors.white.withValues(alpha: 0.9),
          );
        }
      case BlobTopper.sprout:
        canvas.drawLine(Offset(s * 0.5, s * 0.26), Offset(s * 0.5, s * 0.14), stroke);
        for (final d in [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(s * (0.5 + 0.07 * d), s * 0.12), width: s * 0.13, height: s * 0.07),
            Paint()..color = const Color(0xFF3DFF8F),
          );
        }
      case BlobTopper.flame:
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.4, s * 0.24)
            ..quadraticBezierTo(s * 0.38, s * 0.1, s * 0.5, s * 0.03)
            ..quadraticBezierTo(s * 0.48, s * 0.14, s * 0.58, s * 0.12)
            ..quadraticBezierTo(s * 0.64, s * 0.18, s * 0.6, s * 0.24)
            ..close(),
          Paint()..color = const Color(0xFFFFD23D),
        );
    }
  }

  void _face(Canvas canvas, double s) {
    final inkP = Paint()..color = ink;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round;
    final eyeY = s * 0.5;
    final eyes = [Offset(s * 0.39, eyeY), Offset(s * 0.61, eyeY)];
    switch (mood) {
      case BlobMood.idle:
        for (final e in eyes) {
          canvas.drawOval(Rect.fromCenter(center: e, width: s * 0.07, height: s * 0.1), inkP);
          canvas.drawCircle(e.translate(s * 0.012, -s * 0.02), s * 0.012, Paint()..color = Colors.white);
        }
        canvas.drawArc(Rect.fromCenter(center: Offset(s * 0.5, s * 0.6), width: s * 0.12, height: s * 0.08),
            0.2, math.pi - 0.4, false, line);
      case BlobMood.sleepy:
        for (final e in eyes) {
          canvas.drawArc(Rect.fromCenter(center: e, width: s * 0.09, height: s * 0.06), 0.1, math.pi - 0.2, false, line);
        }
        canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.5, s * 0.63), width: s * 0.05, height: s * 0.035), inkP);
      case BlobMood.shocked:
        for (final e in eyes) {
          canvas.drawCircle(e, s * 0.06, Paint()..color = Colors.white);
          canvas.drawCircle(e, s * 0.03, inkP);
        }
        canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.5, s * 0.66), width: s * 0.08, height: s * 0.1), inkP);
      case BlobMood.happy:
        for (final e in eyes) {
          canvas.drawArc(Rect.fromCenter(center: e.translate(0, s * 0.02), width: s * 0.09, height: s * 0.08),
              math.pi + 0.2, math.pi - 0.4, false, line);
        }
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.42, s * 0.6)
            ..quadraticBezierTo(s * 0.5, s * 0.72, s * 0.58, s * 0.6)
            ..close(),
          inkP,
        );
    }
    // Cheeks.
    for (final x in [0.3, 0.7]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(s * x, s * 0.6), width: s * 0.08, height: s * 0.04),
          Paint()..color = const Color(0xFFFF5F8F).withValues(alpha: 0.45));
    }
  }

  void _crackLines(Canvas canvas, double s, Path body) {
    final pts = <Offset>[
      Offset(s * 0.52, s * 0.2),
      Offset(s * 0.46, s * 0.34),
      Offset(s * 0.56, s * 0.44),
      Offset(s * 0.44, s * 0.58),
      Offset(s * 0.54, s * 0.7),
      Offset(s * 0.48, s * 0.88),
    ];
    final branch = [Offset(s * 0.56, s * 0.44), Offset(s * 0.7, s * 0.4), Offset(s * 0.78, s * 0.48)];
    Path poly(List<Offset> p, double frac) {
      final path = Path()..moveTo(p.first.dx, p.first.dy);
      final n = ((p.length - 1) * frac).clamp(0.0, p.length - 1.0);
      for (var i = 1; i <= n.floor(); i++) {
        path.lineTo(p[i].dx, p[i].dy);
      }
      final rem = n - n.floor();
      if (rem > 0 && n.floor() + 1 < p.length) {
        final a = p[n.floor()], b = p[n.floor() + 1];
        path.lineTo(a.dx + (b.dx - a.dx) * rem, a.dy + (b.dy - a.dy) * rem);
      }
      return path;
    }

    canvas.save();
    canvas.clipPath(body);
    for (final (p, start) in [(pts, 0.0), (branch, 0.4)]) {
      final f = ((crack - start) / (1 - start)).clamp(0.0, 1.0);
      if (f <= 0) continue;
      final path = poly(p, f);
      canvas.drawPath(path, Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.045
        ..strokeJoin = StrokeJoin.miter);
      canvas.drawPath(path, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.015);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.spec != spec || old.mood != mood || old.crack != crack;
}
