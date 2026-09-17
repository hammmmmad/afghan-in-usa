import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/download_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/constants.dart';
import 'services/storage_service.dart';
import 'services/fcm_service.dart';
import 'services/realtime_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nothing below may block or crash the first frame: the app must open
  // fully offline with its bundled content. Every plugin call is guarded so
  // a missing Play Services / offline device still reaches runApp. Timeouts
  // matter as much as the catches: offline, Firebase/FCM calls can hang for
  // minutes without throwing, and a hung await would freeze the splash.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 6));
  } catch (_) {
    // Firebase Auth (Google Sign-In) and FCM degrade gracefully offline.
  }

  try {
    // Omitted credentials intentionally leave the app in bundled-news mode.
    await SupabaseService.initialize()
        .timeout(const Duration(seconds: 4));
  } catch (_) {
    // Remote data is unreachable; bundled news/cases keep working.
  }

  try {
    await StorageService.instance.init()
        .timeout(const Duration(seconds: 4));
  } catch (_) {
    // Preferences fall back to defaults when Hive/SharedPreferences fails.
  }

  // Push subscription is entirely optional; it needs Play Services and
  // network, so it must never sit on the startup critical path.
  unawaited(FcmService.instance.initialize());

  // Release builds render a blank screen for uncaught widget errors; show a
  // friendly fallback instead so failures are never invisible.
  ErrorWidget.builder = (FlutterErrorDetails details) => const ColoredBox(
        color: Color(0xFF101828),
        child: Center(
          child: Icon(Icons.hourglass_empty_rounded,
              color: Colors.white54, size: 42),
        ),
      );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  final NotificationProvider notifications = NotificationProvider();
  // A foreground push refreshes the bell feed the moment it arrives.
  FcmService.instance.onMessageReceived = notifications.refresh;
  // Tapping a push in the system tray (app open, background or killed) or
  // the in-app banner opens the notification with its full content.
  FcmService.instance.onNotificationTap = (Map<String, String> data) {
    notifications.refresh();
    final String id = data['notificationId'] ?? '';
    if (id.isNotEmpty) {
      final bool special = data['kind'] == 'special';
      unawaited(notifications.markRead('${special ? 'special' : 'public'}_$id'));
    }
    final BuildContext? context = appNavigatorKey.currentContext;
    if (context == null) return;
    final String title = data['title'] ?? '';
    final String body = data['body'] ?? '';
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: <Widget>[
              const Icon(Icons.notifications_active_rounded,
                  color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: Theme.of(dialogContext).textTheme.titleMedium),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SelectableText(
              body,
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  };
  // Live news: a publish/unpublish by the admin refreshes the feed without a
  // manual pull-to-refresh.
  RealtimeService.instance.onNewsChanged = notifications.refresh;
  // A newly published public announcement reaches the bell feed live too.
  RealtimeService.instance.onPublicNotificationChanged = notifications.refresh;
  RealtimeService.instance.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notifications,
        ),
        ProxyProvider<LanguageProvider, NotificationProvider>(
          update: (_, LanguageProvider language, __) {
            notifications.setLanguageCode(language.code);
            return notifications;
          },
        ),
        ChangeNotifierProvider<DownloadProvider>(
          create: (_) => DownloadProvider(),
        ),
      ],
      child: const AfghanInUsaApp(),
    ),
  );
}
