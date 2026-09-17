import 'package:flutter/material.dart';

/// Central typography roles. News typography is intentionally separate from
/// the app-wide typography so the navigation bar and general UI can evolve
/// independently from editorial fonts.
class AppTypography {
  AppTypography._();

  static const String persianNewsTitle = 'PersianNewsTitle';
  static const String persianNewsBody = 'PersianNewsBody';
  static const String english = 'EnglishApp';
  static const String navigation = 'NavigationBar';

  static TextStyle newsTitle(String languageCode, Color color) => TextStyle(
        fontFamily: languageCode == 'fa' ? persianNewsTitle : english,
        fontSize: languageCode == 'fa' ? 25 : 21,
        fontWeight: FontWeight.w700,
        color: color,
        height: languageCode == 'fa' ? 1.45 : 1.35,
      );

  static TextStyle newsBody(String languageCode, Color color) => TextStyle(
        fontFamily: languageCode == 'fa' ? persianNewsBody : english,
        fontSize: languageCode == 'fa' ? 17 : 15.5,
        color: color,
        height: languageCode == 'fa' ? 1.9 : 1.6,
      );

  static const TextStyle navigationBar = TextStyle(
    fontFamily: navigation,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
