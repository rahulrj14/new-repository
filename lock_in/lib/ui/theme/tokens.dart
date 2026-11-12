import 'package:flutter/widgets.dart';

/// Design tokens: bright, friendly, chat-app energy. Light surfaces, one
/// confident blue, sticker-style characters. Original palette.
abstract final class LockColors {
  static const bg = Color(0xFFF2F4FA);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E8F0);

  static const blue = Color(0xFF2C6BFF);
  static const blueDeep = Color(0xFF1C4ED8);
  static const blueSoft = Color(0xFFE8EFFF);

  /// Aura.
  static const sun = Color(0xFFFFC530);

  /// Cracks and warnings.
  static const coral = Color(0xFFFF4D6A);

  /// Streak alive / success.
  static const mint = Color(0xFF19C38A);

  /// Streak freezes.
  static const ice = Color(0xFF5BC0FF);
}

abstract final class LockRadius {
  static const pill = 999.0;
  static const card = 24.0;
  static const button = 18.0;
}

const kFont = 'Fredoka';

const kCardShadow = [
  BoxShadow(color: Color(0x14111827), blurRadius: 16, offset: Offset(0, 6)),
];
