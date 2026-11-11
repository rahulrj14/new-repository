import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: LockColors.lime,
    brightness: Brightness.dark,
  ).copyWith(
    primary: LockColors.lime,
    onPrimary: LockColors.onLime,
    surface: LockColors.bg,
    onSurface: LockColors.text,
    error: LockColors.crack,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: kFont,
    scaffoldBackgroundColor: LockColors.bg,
  );
  TextStyle t(double size, FontWeight w, {double height = 1.1, Color? color}) =>
      TextStyle(fontFamily: kFont, fontSize: size, fontWeight: w, height: height, color: color ?? LockColors.text);
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: t(96, FontWeight.w700, height: 1),
      displayMedium: t(64, FontWeight.w700, height: 1),
      headlineLarge: t(40, FontWeight.w700),
      headlineMedium: t(30, FontWeight.w600),
      titleLarge: t(22, FontWeight.w600),
      titleMedium: t(18, FontWeight.w600),
      bodyLarge: t(17, FontWeight.w500, height: 1.35),
      bodyMedium: t(15, FontWeight.w500, height: 1.35, color: LockColors.muted),
      labelLarge: t(18, FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LockColors.lime,
        foregroundColor: LockColors.onLime,
        minimumSize: const Size.fromHeight(64),
        shape: const StadiumBorder(),
        textStyle: t(20, FontWeight.w700, color: LockColors.onLime),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LockColors.text,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: LockColors.surfaceHi, width: 2),
        shape: const StadiumBorder(),
        textStyle: t(18, FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LockColors.muted,
        minimumSize: const Size(48, 48),
        textStyle: t(16, FontWeight.w600),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LockColors.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(LockRadius.card))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? LockColors.onLime : LockColors.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? LockColors.lime : LockColors.surfaceHi),
    ),
  );
}
