import 'package:material_ui/material_ui.dart';

/// Dark-gold palette used across the app.
abstract final class AppColors {
  static const Color bg = Color(0xFF101115);
  static const Color bgDeep = Color(0xFF0B0C0F);
  static const Color warm = Color(0xFF2A2116);
  static const Color text = Color(0xFFF5EFE3);
  static const Color text2 = Color(0xFFD8D0C1);
  static const Color muted = Color(0xFFA39C8F);
  static const Color faint = Color(0xFF8C8578);
  static const Color gold = Color(0xFFE6C27A);
  static const Color goldHi = Color(0xFFF6DE9E);
  static const Color goldLo = Color(0xFFB8843A);
  static const Color copper = Color(0xFFC9785A);
  static const Color coral = Color(0xFFE59A80);
  static const Color ink = Color(0xFF1A1309);
  static const Color card = Color(0x0AFFFFFF); // 4% white
  static const Color cardLine = Color(0x12FFFFFF); // 7% white
  static const Color field = Color(0x0DFFFFFF);
  static const Color fieldLine = Color(0x1AFFFFFF);

  static const LinearGradient goldButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFF1D48E), Color(0xFFD9A851), goldLo],
    stops: <double>[0, .55, 1],
  );
  static const LinearGradient goldText = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[goldHi, Color(0xFFC8913A)],
  );
}

/// Apple-style motion values (critically damped by default, a little bounce for "pop").
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);
  static const Curve ease = Curves.easeOutCubic;
  static const Curve pop = Curves.easeOutBack;
}

ThemeData buildTheme() {
  final ThemeData base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.ink,
      secondary: AppColors.copper,
      surface: Color(0xFF17181D),
      onSurface: AppColors.text,
      error: AppColors.coral,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xF0282218),
      contentTextStyle: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600),
      shape: StadiumBorder(side: BorderSide(color: Color(0x73E6C27A))),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1B1C21)),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF16171C),
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
  );
}

abstract final class TextStyles {
  static const TextStyle eyebrow = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: Color(0xFFC9A866));
  static TextStyle h1(bool wide) => TextStyle(
      fontSize: wide ? 40 : 34, height: 1.05, fontWeight: FontWeight.w700, letterSpacing: wide ? -1.2 : -0.85);
  static const TextStyle h2 = TextStyle(fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.2);
  static const TextStyle h2Big = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4);
  static const TextStyle body = TextStyle(fontSize: 15, height: 1.45, color: AppColors.text2);
  static const TextStyle small = TextStyle(fontSize: 13, color: AppColors.muted);
  static const TextStyle label = TextStyle(fontSize: 13, color: Color(0xFFB9B1A2));
}
