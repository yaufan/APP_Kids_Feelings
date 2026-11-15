import 'package:flutter/material.dart';

/// The app's colours (docs/design.md 「棉花糖雲朵風」: lavender, cream
/// yellow, pink, mint, baby blue; soft plum words, never black).
abstract final class Mallow {
  static const ink = Color(0xFF4A3F5C);
  static const inkSoft = Color(0xFF8C8299);
  static const cream = Color(0xFFFFF8EE);
  static const sky1 = Color(0xFFE9E2FA);
  static const sky2 = Color(0xFFFFF1E6);
  static const pink = Color(0xFFF9BBD0);
  static const rose = Color(0xFFF4A6B8);
  static const yellow = Color(0xFFFFE08A);
  static const peach = Color(0xFFFFC9A6);
  static const mint = Color(0xFFB8EAD8);
  static const blue = Color(0xFFB5D4F4);
  static const lilac = Color(0xFFD3C4F3);
  static const green = Color(0xFF6CC3A0);
  static const coral = Color(0xFFEE8C7E);
  static const gold = Color(0xFFFFC53D);
  static const shade = Color(0xFF5A4A6E);
  static const night1 = Color(0xFF8E84C8);
  static const night2 = Color(0xFFF6B9A8);
  static const parentBg = Color(0xFFF5F2F8);
}

abstract final class MallowTheme {
  /// jf open 粉圓 (OFL): a rounded typeface made in Taiwan.
  static const font = 'Huninn';

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Mallow.lilac, surface: Mallow.cream),
      scaffoldBackgroundColor: Mallow.cream,
      fontFamily: font,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    return base.copyWith(textTheme: base.textTheme.apply(bodyColor: Mallow.ink, displayColor: Mallow.ink, fontFamily: font));
  }
}
