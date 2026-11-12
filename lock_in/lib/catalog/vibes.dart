import 'dart:ui';

/// What you're locking in for. Changes colours and what your blob says.
/// Stored by name; never reorder/rename without a migration.
enum Vibe {
  study('📚', 'study', Color(0xFF2C6BFF)),
  dinner('🍜', 'dinner', Color(0xFFFF8A2C)),
  gym('💪', 'gym', Color(0xFF14B87C)),
  sleep('🌙', 'sleep', Color(0xFF5B4BDB)),
  hangout('🫶', 'hangout', Color(0xFFE5489C));

  const Vibe(this.emoji, this.label, this.color);
  final String emoji;
  final String label;
  final Color color;

  static Vibe byName(String? n) =>
      Vibe.values.firstWhere((v) => v.name == n, orElse: () => Vibe.study);

  /// What the blob says while you're locked in.
  String get lockedLine => switch (this) {
    Vibe.study => 'big brain hours 🧠',
    Vibe.dinner => 'phones stacked. eat up 🍜',
    Vibe.gym => 'lift, not scroll 💪',
    Vibe.sleep => 'zzz… night night 🌙',
    Vibe.hangout => 'eyes up, besties 🫶',
  };

  String get startLine => switch (this) {
    Vibe.study => 'lock your phone, open your notes 👇',
    Vibe.dinner => 'stack those phones 👇',
    Vibe.gym => 'lock it and lift 👇',
    Vibe.sleep => 'lock it. lights out 👇',
    Vibe.hangout => 'lock it. be here 👇',
  };
}
