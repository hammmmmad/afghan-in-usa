import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'supabase_service.dart';

/// Device-side half of push delivery. Sending is deliberately server-only in
/// `supabase/functions/send-push`; this class requests permission, stores the
/// current device token for the authenticated owner, and surfaces FCM
/// messages that arrive while the app is in the foreground (Android suppresses
/// those unless the app displays them itself).
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _started = false;

  /// Fired for every foreground push so the UI can refresh the bell badge.
  void Function()? onMessageReceived;

  /// Fired when the user taps a push (system tray) or the in-app banner:
  /// the map carries notificationId, kind, caseId, title and body.
  void Function(Map<String, String> data)? onNotificationTap;

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    // Every step is optional: offline devices or missing Play Services must
    // never prevent the app from starting or subscribing later.
    try {
      await _messaging.requestPermission();
    } catch (_) {}
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _fireTapFromPayload(response.payload);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'afghan_notifications',
            'Afghan in USA notifications',
            importance: Importance.high,
          ));
    } catch (_) {}
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        onMessageReceived?.call();
        final RemoteNotification? data = message.notification;
        if (data == null) return;
        try {
          _local.show(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: data.title ?? '',
            body: data.body ?? '',
            payload: _payloadFrom(message),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'afghan_notifications',
                'Afghan in USA notifications',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
          );
        } catch (_) {}
      });
    } catch (_) {}
    try {
      // Push opened from the system tray while the app was in background.
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        onNotificationTap?.call(_tapDataFrom(message));
      });
    } catch (_) {}
    try {
      // Push opened from the system tray while the app was fully closed.
      _messaging
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) onNotificationTap?.call(_tapDataFrom(message));
      });
    } catch (_) {}
    try {
      await _messaging.subscribeToTopic('public-news');
    } catch (_) {}
    try {
      _messaging.onTokenRefresh.listen((String _) => registerDevice());
    } catch (_) {}
    // Personal pushes only reach tokens stored in device_tokens, and old
    // tokens die silently (reinstall/token rotation). Public pushes survive
    // via the FCM topic, but a signed-in session restored at startup must
    // re-register the current token or case notifications never arrive.
    try {
      await registerDevice();
    } catch (_) {}
  }

  Map<String, String> _tapDataFrom(RemoteMessage message) {
    final RemoteNotification? n = message.notification;
    return <String, String>{
      'notificationId': message.data['notificationId'] ?? '',
      'kind': message.data['kind'] ?? '',
      'caseId': message.data['caseId'] ?? '',
      'title': n?.title ?? '',
      'body': n?.body ?? '',
    };
  }

  String _payloadFrom(RemoteMessage message) {
    String clean(String? value) => (value ?? '').replaceAll('|', ' ');
    return <String>[
      'push',
      clean(message.data['notificationId']),
      clean(message.data['kind']),
      clean(message.data['caseId']),
      clean(message.notification?.title),
      clean(message.notification?.body),
    ].join('|');
  }

  void _fireTapFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final List<String> parts = payload.split('|');
    if (parts.length < 6) return;
    onNotificationTap?.call(<String, String>{
      'notificationId': parts[1],
      'kind': parts[2],
      'caseId': parts[3],
      'title': parts[4],
      'body': parts.sublist(5).join('|'),
    });
  }

  Future<void> registerDevice() async {
    if (!SupabaseService.isReady ||
        SupabaseService.client.auth.currentUser == null) {
      return;
    }
    final String? token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await SupabaseService.client.from('device_tokens').upsert(<String, dynamic>{
      'user_id': SupabaseService.client.auth.currentUser!.id,
      'fcm_token': token,
      'platform': Platform.isAndroid ? 'android' : 'other',
      'active': true,
    }, onConflict: 'fcm_token');
  }

  Future<void> setCaseSubscription(String caseId, bool active,
      {String caseType = 'afghan'}) async {
    if (!SupabaseService.isReady ||
        SupabaseService.client.auth.currentUser == null) {
      return;
    }
    await registerDevice();
    await SupabaseService.client
        .from('case_subscriptions')
        .upsert(<String, dynamic>{
      'user_id': SupabaseService.client.auth.currentUser!.id,
      'case_id': caseId,
      'case_type': caseType,
      'active': active,
    }, onConflict: 'user_id,case_id');
  }
}
