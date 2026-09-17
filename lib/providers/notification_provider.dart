import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../services/fcm_service.dart';
import '../services/storage_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider() {
    _bells = StorageService.instance.bells;
    refresh();
    // Once a session exists (fresh sign-in or app restart while signed in),
    // replay every locally followed bell so the server knows the
    // subscriptions — following as a guest alone never reaches the server.
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          syncBellsToServer();
          // The Supabase session may arrive later than Firebase's; make sure
          // this device's token lands in device_tokens for case pushes.
          FcmService.instance.registerDevice();
        }
      });
    } catch (_) {}
  }

  Set<String> _bells = <String>{};
  List<AppNotification> _items = <AppNotification>[];
  String _languageCode = 'fa';

  Set<String> get bells => _bells;
  List<AppNotification> get items => _items;
  int get unreadCount => _items.where((AppNotification n) => !n.read).length;

  bool isFollowing(String caseId) => _bells.contains(caseId);

  /// Called by the app-level language provider so the notification feed also
  /// switches language without storing one-language-only notification text.
  void setLanguageCode(String languageCode) {
    if (languageCode != 'fa' && languageCode != 'en') return;
    if (_languageCode == languageCode) return;
    _languageCode = languageCode;
    refresh();
  }

  Future<bool> toggleBell(String caseId) async {
    final bool nowOn = !_bells.contains(caseId);
    if (nowOn) {
      _bells.add(caseId);
    } else {
      _bells.remove(caseId);
    }
    notifyListeners();
    await StorageService.instance.saveBells(_bells);
    try {
      // Iranian guides use the `ir_` id prefix so the two sections can never
      // collide; the type travels with the subscription row.
      await FcmService.instance.setCaseSubscription(caseId, nowOn,
          caseType: caseId.startsWith('ir_') ? 'iranian' : 'afghan');
    } catch (_) {
      // The local preference remains useful while the account is offline.
    }
    await refresh();
    return nowOn;
  }

  Future<void> refresh() async {
    _items = await NotificationService.instance.build(_bells);
    notifyListeners();
  }

  /// Re-upserts every locally followed case so case_subscriptions and the
  /// device token exist server-side. Safe to call repeatedly: the upserts
  /// conflict on (user_id, case_id) and no-op without a session.
  Future<void> syncBellsToServer() async {
    for (final String caseId in _bells) {
      try {
        await FcmService.instance.setCaseSubscription(caseId, true,
            caseType: caseId.startsWith('ir_') ? 'iranian' : 'afghan');
      } catch (_) {}
    }
  }

  Future<void> markAllRead() async {
    _items = _items
        .map((AppNotification n) => n.copyWith(read: true))
        .toList(growable: false);
    notifyListeners();
    await StorageService.instance.saveNotifications(_items);
  }

  Future<void> markRead(String id) async {
    _items = _items
        .map((AppNotification n) => n.id == id ? n.copyWith(read: true) : n)
        .toList(growable: false);
    notifyListeners();
    await StorageService.instance.saveNotifications(_items);
  }
}
