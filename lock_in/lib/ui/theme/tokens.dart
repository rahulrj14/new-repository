import 'package:flutter/widgets.dart';

/// Design tokens. Dark by default, one loud accent, one alarm colour.
abstract final class LockColors {
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF16161F);
  static const surfaceHi = Color(0xFF22222E);
  static const text = Color(0xFFF7F7FA);
  static const muted = Color(0xFF9A9AAD);

  /// Main accent: "aura" lime.
  static const lime = Color(0xFFC8FF2E);

  /// Crack / warning.
  static const crack = Color(0xFFFF3D7F);
  static const onLime = Color(0xFF0A0A0F);
}

abstract final class LockRadius {
  static const pill = 999.0;
  static const card = 28.0;
}

const kFont = 'Fredoka';
