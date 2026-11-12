import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: LockColors.blue,
        brightness: Brightness.light,
      ).copyWith(
        primary: LockColors.blue,
        onPrimary: Colors.white,
        surface: LockColors.bg,
        onSurface: LockColors.ink,
        error: LockColors.coral,
      );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: kFont,
    scaffoldBackgroundColor: LockColors.bg,
  );
  TextStyle t(
    double size,
    FontWeight w, {
    double height = 1.15,
    Color color = LockColors.ink,
  }) => TextStyle(
    fontFamily: kFont,
    fontSize: size,
    fontWeight: w,
    height: height,
    color: color,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: t(88, FontWeight.w700, height: 1),
      displayMedium: t(60, FontWeight.w700, height: 1),
      headlineLarge: t(34, FontWeight.w700),
      headlineMedium: t(26, FontWeight.w700),
      titleLarge: t(21, FontWeight.w600),
      titleMedium: t(17, FontWeight.w600),
      bodyLarge: t(16, FontWeight.w500, height: 1.35),
      bodyMedium: t(14, FontWeight.w500, height: 1.35, color: LockColors.muted),
      labelLarge: t(17, FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LockColors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: LockColors.line,
        minimumSize: const Size.fromHeight(60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LockRadius.button),
        ),
        textStyle: t(19, FontWeight.w700, color: Colors.white),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LockColors.blue,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: LockColors.blueSoft, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LockRadius.button),
        ),
        textStyle: t(17, FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LockColors.blue,
        minimumSize: const Size(48, 48),
        textStyle: t(16, FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: LockColors.blueSoft,
      height: 72,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => t(
          12,
          FontWeight.w600,
          color: s.contains(WidgetState.selected)
              ? LockColors.blue
              : LockColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 26,
          color: s.contains(WidgetState.selected)
              ? LockColors.blue
              : LockColors.muted,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LockRadius.card),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? LockColors.blue
            : LockColors.line,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LockColors.ink,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: t(15, FontWeight.w600, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
