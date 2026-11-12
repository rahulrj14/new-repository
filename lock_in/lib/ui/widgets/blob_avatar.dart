import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../catalog/avatars.dart';
import '../../catalog/skins.dart';

enum BlobMood { idle, sleepy, shocked, happy }

/// An expressive blob character drawn as a sticker: thick white outline,
/// soft drop shadow, optional skin accessory. Bobs gently (unless reduced
/// motion is on) and can show a crack that draws itself across the body.
class BlobAvatar extends StatefulWidget {
  const BlobAvatar({
    super.key,
    required this.avatarId,
    this.skinId = 0,
    this.size = 160,
    this.mood = BlobMood.idle,
    this.cracked = false,
    this.animate = true,
    this.semanticLabel,
    this.stage = 1,
  });

  /// Growth stage (0 Sprout … 4 Legend): size, glow, sparkles, gold outline.
  final int stage;
  final int avatarId;
  final int skinId;
  final double size;
  final BlobMood mood;
  final bool cracked;
  final bool animate;
  final String? semanticLabel;

  @override
  State<BlobAvatar> createState() => _BlobAvatarState();
}

class _BlobAvatarState extends State<BlobAvatar> with TickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _crack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: widget.cracked ? 1 : 0,
  );

  bool get _motion =>
      widget.animate &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

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
    if (widget.animate != old.animate) didChangeDependencies();
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
    final skin = skinById(widget.skinId);
    return Semantics(
      label:
          widget.semanticLabel ??
          (skin.id == 0 ? spec.name : '${spec.name} wearing ${skin.name}'),
      image: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bob, _crack]),
        builder: (context, _) {
          final t = _bob.value * 2 * math.pi;
          final shake = _crack.isAnimating
              ? math.sin(_crack.value * 40) * 6 * (1 - _crack.value)
              : 0.0;
          final bob = _motion ? math.sin(t) * widget.size * 0.03 : 0.0;
          final squash = _motion ? 1 + math.sin(t * 2) * 0.015 : 1.0;
          return Transform.translate(
            offset: Offset(shake, bob),
            child: Transform.scale(
              scaleX: squash,
              scaleY: 2 - squash,
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: BlobPainter(
                  spec,
                  skin.accessory,
                  widget.mood,
                  _crack.value,
                  stage: widget.stage,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BlobPainter extends CustomPainter {
  BlobPainter(
    this.spec,
    this.accessory,
    this.mood,
    this.crack, {
    this.stage = 1,
  });
  final int stage;
  final AvatarSpec spec;
  final Accessory accessory;
  final BlobMood mood;
  final double crack;

  static const ink = Color(0xFF111827);
  static const sun = Color(0xFFFFC530);
  static const coral = Color(0xFFFF4D6A);

  bool get _hat => switch (accessory) {
    Accessory.beanie ||
    Accessory.partyHat ||
    Accessory.crown ||
    Accessory.cap ||
    Accessory.pumpkin => true,
    _ => false,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Stage effects that sit behind the blob.
    if (stage >= 2) {
      canvas.drawCircle(
        Offset(s * 0.5, s * 0.55),
        s * 0.44,
        Paint()
          ..color = spec.color.withValues(alpha: stage >= 4 ? 0.55 : 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08),
      );
    }
    if (stage >= 3) {
      for (final (x, y, r) in const [
        (0.1, 0.25, 0.05),
        (0.9, 0.3, 0.04),
        (0.08, 0.78, 0.035),
        (0.92, 0.82, 0.05),
      ]) {
        canvas.drawPath(
          _star(Offset(s * x, s * y), s * r, s * r * 0.4),
          Paint()..color = sun,
        );
      }
    }
    // Younger blobs are smaller.
    final scale = switch (stage) {
      0 => 0.8,
      1 => 0.92,
      _ => 1.0,
    };
    canvas.save();
    canvas.translate(s * 0.5, s * 0.55);
    canvas.scale(scale);
    canvas.translate(-s * 0.5, -s * 0.55);
    _paintBlob(canvas, s);
    canvas.restore();
  }

  void _paintBlob(Canvas canvas, double s) {
    final body = _bodyPath(s);
    final outlineW = s * 0.06;

    // Drop shadow.
    canvas.drawPath(
      body.shift(Offset(0, s * 0.04)),
      Paint()
        ..color = const Color(0x33111827)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Sticker outline (white), then fills.
    final outline = Paint()
      ..color = stage >= 4 ? const Color(0xFFFFD54A) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineW
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    if (!_hat) _topper(canvas, s, outline: outline);
    canvas.drawPath(body, outline);
    if (!_hat) _topper(canvas, s);
    canvas.drawPath(body, Paint()..color = spec.color);
    // Highlight.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawCircle(
      Offset(s * 0.33, s * 0.33),
      s * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
    canvas.restore();

    _face(canvas, s);
    _accessory(canvas, s);
    if (crack > 0) _crackLines(canvas, s, body);
  }

  Path _bodyPath(double s) {
    final r = Rect.fromLTWH(s * 0.14, s * 0.2, s * 0.72, s * 0.68);
    switch (spec.shape) {
      case BlobShape.round:
        return Path()..addOval(r.inflate(s * 0.01));
      case BlobShape.squircle:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(r, Radius.circular(s * 0.26)));
      case BlobShape.bean:
        return Path()
          ..addOval(Rect.fromLTWH(s * 0.12, s * 0.24, s * 0.76, s * 0.62));
      case BlobShape.ghost:
        final p = Path()
          ..moveTo(r.left, r.center.dy)
          ..arcToPoint(
            Offset(r.right, r.center.dy),
            radius: Radius.circular(r.width / 2),
          )
          ..lineTo(r.right, r.bottom);
        const waves = 4;
        final w = r.width / waves;
        for (var i = 0; i < waves; i++) {
          final x = r.right - w * i;
          p.quadraticBezierTo(
            x - w / 2,
            r.bottom - s * (i.isEven ? 0.08 : -0.02),
            x - w,
            r.bottom,
          );
        }
        return p..close();
    }
  }

  void _topper(Canvas canvas, double s, {Paint? outline}) {
    final fill = outline ?? (Paint()..color = spec.color);
    final stroke = Paint()
      ..color = outline?.color ?? spec.color
      ..strokeWidth = s * 0.03 + (outline?.strokeWidth ?? 0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    void shape(Path p, Paint own) => canvas.drawPath(p, outline ?? own);
    switch (spec.topper) {
      case BlobTopper.none:
        break;
      case BlobTopper.antenna:
        canvas.drawLine(
          Offset(s * 0.5, s * 0.22),
          Offset(s * 0.56, s * 0.08),
          stroke,
        );
        canvas.drawCircle(Offset(s * 0.56, s * 0.08), s * 0.045, fill);
      case BlobTopper.ears:
        for (final x in [0.28, 0.72]) {
          shape(
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
          shape(
            Path()
              ..moveTo(s * (x - 0.06), s * 0.26)
              ..quadraticBezierTo(
                s * (x + 0.02 * d),
                s * 0.18,
                s * (x + 0.08 * d),
                s * 0.08,
              )
              ..lineTo(s * (x + 0.06), s * 0.26)
              ..close(),
            Paint()..color = const Color(0xFFFFF4E0),
          );
        }
      case BlobTopper.sprout:
        canvas.drawLine(
          Offset(s * 0.5, s * 0.26),
          Offset(s * 0.5, s * 0.14),
          stroke,
        );
        for (final d in [-1.0, 1.0]) {
          final leaf = Path()
            ..addOval(
              Rect.fromCenter(
                center: Offset(s * (0.5 + 0.07 * d), s * 0.12),
                width: s * 0.13,
                height: s * 0.07,
              ),
            );
          shape(leaf, Paint()..color = const Color(0xFF19C38A));
        }
      case BlobTopper.flame:
        shape(
          Path()
            ..moveTo(s * 0.4, s * 0.24)
            ..quadraticBezierTo(s * 0.38, s * 0.1, s * 0.5, s * 0.03)
            ..quadraticBezierTo(s * 0.48, s * 0.14, s * 0.58, s * 0.12)
            ..quadraticBezierTo(s * 0.64, s * 0.18, s * 0.6, s * 0.24)
            ..close(),
          Paint()..color = sun,
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
    final coversEyes =
        accessory == Accessory.shades || accessory == Accessory.starGlasses;
    switch (mood) {
      case BlobMood.idle:
        if (!coversEyes) {
          for (final e in eyes) {
            canvas.drawOval(
              Rect.fromCenter(center: e, width: s * 0.07, height: s * 0.1),
              inkP,
            );
            canvas.drawCircle(
              e.translate(s * 0.012, -s * 0.02),
              s * 0.012,
              Paint()..color = Colors.white,
            );
          }
        }
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.62),
            width: s * 0.12,
            height: s * 0.08,
          ),
          0.2,
          math.pi - 0.4,
          false,
          line,
        );
      case BlobMood.sleepy:
        if (!coversEyes) {
          for (final e in eyes) {
            canvas.drawArc(
              Rect.fromCenter(center: e, width: s * 0.09, height: s * 0.06),
              0.1,
              math.pi - 0.2,
              false,
              line,
            );
          }
        }
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.64),
            width: s * 0.05,
            height: s * 0.035,
          ),
          inkP,
        );
      case BlobMood.shocked:
        if (!coversEyes) {
          for (final e in eyes) {
            canvas.drawCircle(e, s * 0.06, Paint()..color = Colors.white);
            canvas.drawCircle(e, s * 0.03, inkP);
          }
        }
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.67),
            width: s * 0.08,
            height: s * 0.1,
          ),
          inkP,
        );
      case BlobMood.happy:
        if (!coversEyes) {
          for (final e in eyes) {
            canvas.drawArc(
              Rect.fromCenter(
                center: e.translate(0, s * 0.02),
                width: s * 0.09,
                height: s * 0.08,
              ),
              math.pi + 0.2,
              math.pi - 0.4,
              false,
              line,
            );
          }
        }
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.42, s * 0.61)
            ..quadraticBezierTo(s * 0.5, s * 0.73, s * 0.58, s * 0.61)
            ..close(),
          inkP,
        );
    }
    for (final x in [0.3, 0.7]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * x, s * 0.6),
          width: s * 0.08,
          height: s * 0.04,
        ),
        Paint()..color = const Color(0xFFFF5F8F).withValues(alpha: 0.45),
      );
    }
  }

  void _accessory(Canvas canvas, double s) {
    final edge = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeJoin = StrokeJoin.round;
    void filled(Path p, Color c) {
      canvas.drawPath(p, Paint()..color = c);
      canvas.drawPath(p, edge);
    }

    switch (accessory) {
      case Accessory.none:
        break;
      case Accessory.shades:
        for (final x in [0.39, 0.61]) {
          filled(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset(s * x, s * 0.5),
                  width: s * 0.17,
                  height: s * 0.11,
                ),
                Radius.circular(s * 0.04),
              ),
            ),
            ink,
          );
          canvas.drawLine(
            Offset(s * (x - 0.05), s * 0.48),
            Offset(s * (x - 0.02), s * 0.465),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.8)
              ..strokeWidth = s * 0.015
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawLine(
          Offset(s * 0.47, s * 0.49),
          Offset(s * 0.53, s * 0.49),
          edge,
        );
      case Accessory.starGlasses:
        for (final x in [0.39, 0.61]) {
          filled(
            _star(Offset(s * x, s * 0.5), s * 0.095, s * 0.045),
            const Color(0xFFFF7EB6),
          );
        }
        canvas.drawLine(
          Offset(s * 0.47, s * 0.49),
          Offset(s * 0.53, s * 0.49),
          edge,
        );
      case Accessory.headphones:
        canvas.drawArc(
          Rect.fromLTRB(s * 0.14, s * 0.1, s * 0.86, s * 0.7),
          math.pi * 1.05,
          math.pi * 0.9,
          false,
          Paint()
            ..color = const Color(0xFF374151)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.05
            ..strokeCap = StrokeCap.round,
        );
        for (final x in [0.13, 0.87]) {
          filled(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset(s * x, s * 0.45),
                  width: s * 0.11,
                  height: s * 0.2,
                ),
                Radius.circular(s * 0.05),
              ),
            ),
            coral,
          );
        }
      case Accessory.beanie:
        filled(
          Path()
            ..moveTo(s * 0.2, s * 0.34)
            ..cubicTo(s * 0.2, s * 0.08, s * 0.8, s * 0.08, s * 0.8, s * 0.34)
            ..close(),
          const Color(0xFF2C6BFF),
        );
        filled(
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(s * 0.17, s * 0.29, s * 0.83, s * 0.38),
              Radius.circular(s * 0.04),
            ),
          ),
          const Color(0xFF1C4ED8),
        );
        filled(
          Path()..addOval(
            Rect.fromCircle(
              center: Offset(s * 0.5, s * 0.12),
              radius: s * 0.05,
            ),
          ),
          Colors.white,
        );
      case Accessory.partyHat:
        final hat = Path()
          ..moveTo(s * 0.38, s * 0.27)
          ..lineTo(s * 0.62, s * 0.27)
          ..lineTo(s * 0.53, s * 0.02)
          ..close();
        filled(hat, sun);
        canvas.save();
        canvas.clipPath(hat);
        for (final y in [0.2, 0.12]) {
          canvas.drawLine(
            Offset(s * 0.3, s * (y + 0.04)),
            Offset(s * 0.7, s * (y - 0.04)),
            Paint()
              ..color = coral
              ..strokeWidth = s * 0.03,
          );
        }
        canvas.restore();
        canvas.drawPath(hat, edge);
        filled(
          Path()..addOval(
            Rect.fromCircle(
              center: Offset(s * 0.53, s * 0.03),
              radius: s * 0.035,
            ),
          ),
          coral,
        );
      case Accessory.flower:
        final c = Offset(s * 0.76, s * 0.27);
        for (var i = 0; i < 5; i++) {
          final a = i * 2 * math.pi / 5;
          filled(
            Path()..addOval(
              Rect.fromCircle(
                center: c + Offset(math.cos(a), math.sin(a)) * s * 0.055,
                radius: s * 0.045,
              ),
            ),
            const Color(0xFFFF9EC4),
          );
        }
        filled(
          Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.035)),
          sun,
        );
      case Accessory.crown:
        filled(
          Path()
            ..moveTo(s * 0.33, s * 0.27)
            ..lineTo(s * 0.33, s * 0.1)
            ..lineTo(s * 0.42, s * 0.18)
            ..lineTo(s * 0.5, s * 0.05)
            ..lineTo(s * 0.58, s * 0.18)
            ..lineTo(s * 0.67, s * 0.1)
            ..lineTo(s * 0.67, s * 0.27)
            ..close(),
          sun,
        );
        for (final x in [0.42, 0.5, 0.58]) {
          canvas.drawCircle(
            Offset(s * x, s * 0.23),
            s * 0.018,
            Paint()..color = coral,
          );
        }
      case Accessory.halo:
        final r = Rect.fromCenter(
          center: Offset(s * 0.5, s * 0.1),
          width: s * 0.42,
          height: s * 0.1,
        );
        canvas.drawOval(
          r,
          Paint()
            ..color = sun.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.06
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawOval(
          r,
          Paint()
            ..color = sun
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.03,
        );
      case Accessory.cap:
        filled(
          Path()
            ..moveTo(s * 0.5, s * 0.31)
            ..lineTo(s * 0.96, s * 0.33)
            ..quadraticBezierTo(s * 0.9, s * 0.26, s * 0.62, s * 0.26)
            ..close(),
          const Color(0xFFD93A55),
        );
        filled(
          Path()
            ..moveTo(s * 0.2, s * 0.34)
            ..cubicTo(s * 0.2, s * 0.1, s * 0.8, s * 0.1, s * 0.8, s * 0.34)
            ..close(),
          coral,
        );
        filled(
          Path()..addOval(
            Rect.fromCircle(
              center: Offset(s * 0.5, s * 0.15),
              radius: s * 0.025,
            ),
          ),
          Colors.white,
        );
      case Accessory.diya:
        // A little oil lamp held at the side, with a warm glow.
        final c = Offset(s * 0.84, s * 0.78);
        canvas.drawCircle(
          c.translate(0, -s * 0.08),
          s * 0.07,
          Paint()
            ..color = const Color(0x88FFC530)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        filled(
          Path()
            ..moveTo(c.dx - s * 0.11, c.dy - s * 0.02)
            ..quadraticBezierTo(
              c.dx,
              c.dy + s * 0.1,
              c.dx + s * 0.11,
              c.dy - s * 0.02,
            )
            ..close(),
          const Color(0xFFE0632B),
        );
        filled(
          Path()
            ..moveTo(c.dx, c.dy - s * 0.13)
            ..quadraticBezierTo(
              c.dx + s * 0.045,
              c.dy - s * 0.06,
              c.dx,
              c.dy - s * 0.03,
            )
            ..quadraticBezierTo(
              c.dx - s * 0.045,
              c.dy - s * 0.06,
              c.dx,
              c.dy - s * 0.13,
            )
            ..close(),
          sun,
        );
      case Accessory.pumpkin:
        final body = Rect.fromCenter(
          center: Offset(s * 0.5, s * 0.2),
          width: s * 0.42,
          height: s * 0.26,
        );
        filled(Path()..addOval(body), const Color(0xFFFF8A2C));
        for (final dx in [-0.07, 0.07]) {
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(s * (0.5 + dx), s * 0.2),
              width: s * 0.12,
              height: s * 0.24,
            ),
            -1.3,
            2.6,
            false,
            edge,
          );
        }
        filled(
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(s * 0.48, s * 0.03, s * 0.05, s * 0.06),
              Radius.circular(s * 0.015),
            ),
          ),
          const Color(0xFF3E7D3A),
        );
      case Accessory.sparkleSpecs:
        for (final x in [0.39, 0.61]) {
          filled(
            Path()..addOval(
              Rect.fromCenter(
                center: Offset(s * x, s * 0.5),
                width: s * 0.17,
                height: s * 0.13,
              ),
            ),
            const Color(0xFFFFD54A),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(s * x, s * 0.5),
              width: s * 0.1,
              height: s * 0.07,
            ),
            Paint()..color = ink,
          );
        }
        canvas.drawLine(
          Offset(s * 0.47, s * 0.49),
          Offset(s * 0.53, s * 0.49),
          edge,
        );
        for (final (x, y) in const [(0.24, 0.36), (0.78, 0.38)]) {
          canvas.drawPath(
            _star(Offset(s * x, s * y), s * 0.04, s * 0.015),
            Paint()..color = sun,
          );
        }
      case Accessory.nerd:
        final rim = Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.022;
        for (final x in [0.39, 0.61]) {
          canvas.drawCircle(Offset(s * x, s * 0.5), s * 0.075, rim);
        }
        canvas.drawLine(
          Offset(s * 0.465, s * 0.5),
          Offset(s * 0.535, s * 0.5),
          rim,
        );
        // Pencil behind the ear.
        canvas.save();
        canvas.translate(s * 0.8, s * 0.3);
        canvas.rotate(-0.7);
        filled(
          Path()
            ..addRect(Rect.fromLTWH(-s * 0.12, -s * 0.02, s * 0.2, s * 0.04)),
          sun,
        );
        filled(
          Path()
            ..moveTo(s * 0.08, -s * 0.02)
            ..lineTo(s * 0.12, 0)
            ..lineTo(s * 0.08, s * 0.02)
            ..close(),
          const Color(0xFFF5D6A8),
        );
        canvas.restore();
    }
  }

  Path _star(Offset c, double outer, double inner) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
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
    final branch = [
      Offset(s * 0.56, s * 0.44),
      Offset(s * 0.7, s * 0.4),
      Offset(s * 0.78, s * 0.48),
    ];
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
      canvas.drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.045,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.015,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BlobPainter old) =>
      old.spec != spec ||
      old.accessory != accessory ||
      old.mood != mood ||
      old.crack != crack ||
      old.stage != stage;
}
