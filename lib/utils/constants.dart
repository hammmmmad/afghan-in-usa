import 'package:flutter/material.dart';

/// Global, immutable app configuration.
class AppConfig {
  AppConfig._();

  static const String appName = 'Afghan in USA';
  static const String developerName = 'Sarfraz Khamoosh';
  static const String version = '1.0.0';

  static const String shareMessage =
      'اپلیکیشن Afghan in USA - راهنمای مهاجرت افغان‌ها در آمریکا';

  static const String storeUrl =
      'https://play.google.com/store/apps/details?id=com.sarfrazkhamoosh.afghaninusa';

  /// Default weather location (Open-Meteo; no API key required).
  static const String defaultCity = 'Kabul';
  static const double defaultLat = 34.5253;
  static const double defaultLon = 69.1783;

  static const String geocodeApi =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String forecastApi = 'https://api.open-meteo.com/v1/forecast';

  static const List<SocialLink> socials = <SocialLink>[
    SocialLink(
      'Facebook',
      'https://www.facebook.com/Khamoooooosh',
      Icons.facebook_rounded,
    ),
    SocialLink(
      'Instagram',
      'https://www.instagram.com/sarfraz_khamoosh_?igsi=MXRvMG55cjRieGhucg==',
      Icons.camera_alt_rounded,
    ),
    SocialLink(
      'YouTube',
      'https://youtube.com/@khamoosh68?si=pKsaFP-FscQuWrNc',
      Icons.play_circle_fill_rounded,
    ),
    SocialLink(
      'Telegram',
      'https://t.me/visaguidee',
      Icons.send_rounded,
    ),
    SocialLink(
      'TikTok',
      'https://www.tiktok.com/@khamoosh305?_r=1&_t=ZS-99QNgwxPlqP',
      Icons.music_note_rounded,
    ),
    SocialLink(
      'WhatsApp · @Khamooooosh',
      'https://www.whatsapp.com/',
      Icons.chat_rounded,
    ),
    SocialLink(
      'Website',
      'https://www.sarfraz.abrdns.com',
      Icons.language_rounded,
    ),
    SocialLink(
      'Pinterest',
      'https://pin.it/2jvOm2udj',
      Icons.push_pin_rounded,
    ),
    SocialLink(
      'GitHub · hammmmmad',
      'https://github.com/hammmmmad',
      Icons.code_rounded,
    ),
    SocialLink(
      'GitLab · khamoosh23',
      'https://gitlab.com/khamoosh23',
      Icons.merge_type_rounded,
    ),
  ];
}

class SocialLink {
  const SocialLink(this.label, this.url, this.icon);

  final String label;
  final String url;
  final IconData icon;
}

/// Brand palette.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color accent = Color(0xFFE91E63);
  static const Color bellOn = Color(0xFF43A047);
  static const Color bellOnDark = Color(0xFF66BB6A);
  static const Color inactive = Color(0xFF9E9E9E);
  static const Color lightBg = Color(0xFFF6F8FB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
}

/// Asset paths.
class AppAssets {
  AppAssets._();

  static const String splash = 'assets/animations/splash.json';
  static const String logo = 'assets/images/logo.png';
  static const String appLogo = 'assets/images/app_logo.png';
  static const String appIcon = 'assets/images/app_icon.png';
  static const String creatorProfile = 'assets/images/creator_profile.png';
  static const String publishedNews = 'assets/images/published_news.png';

  static const String navHome = 'assets/images/nav/home.png';
  static const String navCases = 'assets/images/nav/cases.png';
  static const String navDocuments = 'assets/images/nav/documents.png';
  static const String navProfile = 'assets/images/nav/profile.png';
  static const String navSettings = 'assets/images/nav/settings.png';

  static const String iconCalculator = 'assets/images/settings/calculator.png';
  static const String iconDeveloper = 'assets/images/settings/developer.png';
  static const String iconModeNight = 'assets/images/settings/mode_night.png';
  static const String iconModeDay = 'assets/images/settings/mode_day.png';
  static const String iconLanguage = 'assets/images/settings/language.png';
  static const String iconShare = 'assets/images/settings/share.png';
  static const String iconVersion = 'assets/images/settings/version.png';
  static const String iconWeather = 'assets/images/settings/weather.png';

  static const String iconGuide = 'assets/images/cases/guide.png';
  static const String iconCaseBell = 'assets/images/cases/notification.png';
  static const String iconSteps = 'assets/images/cases/steps.png';

  static const String iconDownload = 'assets/images/documents/download.png';
  static const String iconConditions = 'assets/images/documents/conditions.png';

  static const String iconLatestEvent =
      'assets/images/profile/latest_event.png';
  static const String iconSignUp = 'assets/images/profile/sign_up.png';

  static const String newsData = 'assets/data/news.json';
  static const String documentsData = 'assets/data/documents.json';
  static const String casesIndex = 'assets/cases/index.json';

  static const List<String> avatars = <String>[
    'assets/avatars/avatar_01.jpg',
    'assets/avatars/avatar_02.jpg',
    'assets/avatars/avatar_04.jpg',
    'assets/avatars/avatar_05.jpg',
    'assets/avatars/avatar_06.jpg',
    'assets/avatars/avatar_07.jpg',
    'assets/avatars/avatar_08.jpg',
    'assets/avatars/avatar_09.jpg',
    'assets/avatars/avatar_10.jpg',
    'assets/avatars/avatar_11.jpg',
    'assets/avatars/avatar_12.jpg',
    'assets/avatars/avatar_13.jpg',
    'assets/avatars/avatar_14.jpg',
    'assets/avatars/avatar_15.jpg',
    'assets/avatars/avatar_16.jpg',
    'assets/avatars/avatar_17.jpg',
    'assets/avatars/avatar_18.jpg',
  ];
}

/// Storage keys (SharedPreferences + Hive).
class StorageKeys {
  StorageKeys._();

  static const String box = 'afghan_in_usa';
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String avatar = 'avatar';
  static const String firstName = 'first_name';
  static const String lastName = 'last_name';
  static const String phone = 'phone';
  static const String bells = 'case_bells';
  static const String downloads = 'download_counts';
  static const String notifications = 'notifications';
  static const String weatherCity = 'weather_city';
  static const String weatherLat = 'weather_lat';
  static const String weatherLon = 'weather_lon';
  static const String user = 'google_user';
  static const String topBarHidden = 'top_bar_hidden';
  static const String notificationTopics = 'notification_topics';
}
