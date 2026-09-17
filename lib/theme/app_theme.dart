import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

class AppTheme {
  AppTheme._();

  /// General UI fonts. Editorial/news fonts are applied only by news widgets.
  static String bodyFontFor(String languageCode) =>
      languageCode == 'en' ? AppTypography.english : 'Lateef';

  static String titleFontFor(String languageCode) =>
      languageCode == 'en' ? AppTypography.english : 'SultanK';

  static ThemeData light(String languageCode) => buildLightTheme(languageCode);

  static ThemeData dark(String languageCode) => buildDarkTheme(languageCode);
}

TextTheme buildTextTheme(String languageCode, Color onSurface) {
  final String body = AppTheme.bodyFontFor(languageCode);
  final String title = AppTheme.titleFontFor(languageCode);
  final bool arabicScript = languageCode == 'fa';
  final double scale = arabicScript ? 1.18 : 1.0;
  final double height = arabicScript ? 1.75 : 1.45;

  return TextTheme(
    displayLarge: TextStyle(
      fontFamily: title,
      fontSize: 30 * scale,
      color: onSurface,
      height: 1.3,
    ),
    headlineMedium: TextStyle(
      fontFamily: title,
      fontSize: 22 * scale,
      fontWeight: FontWeight.w700,
      color: onSurface,
      height: 1.4,
    ),
    titleLarge: TextStyle(
      fontFamily: body,
      fontSize: 19 * scale,
      fontWeight: FontWeight.w700,
      color: onSurface,
      height: 1.5,
    ),
    titleMedium: TextStyle(
      fontFamily: body,
      fontSize: 17 * scale,
      fontWeight: FontWeight.w600,
      color: onSurface,
      height: 1.5,
    ),
    bodyLarge: TextStyle(
      fontFamily: body,
      fontSize: 16 * scale,
      color: onSurface,
      height: height,
    ),
    bodyMedium: TextStyle(
      fontFamily: body,
      fontSize: 15 * scale,
      color: onSurface,
      height: height,
    ),
    bodySmall: TextStyle(
      fontFamily: body,
      fontSize: 13 * scale,
      color: onSurface.withOpacity(0.7),
      height: height,
    ),
    labelLarge: TextStyle(
      fontFamily: body,
      fontSize: 14 * scale,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    labelSmall: TextStyle(
      fontFamily: body,
      fontSize: 12 * scale,
      color: onSurface.withOpacity(0.7),
    ),
  );
}
