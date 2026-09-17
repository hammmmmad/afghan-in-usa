import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

/// Single entry point for every piece of persisted state.
/// SharedPreferences holds simple settings, Hive holds structured data.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;
  late Box<dynamic> _box;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(StorageKeys.box);
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  // ── simple settings ────────────────────────────────────────────────
  String get themeMode => _prefs.getString(StorageKeys.themeMode) ?? 'system';
  Future<void> setThemeMode(String value) =>
      _prefs.setString(StorageKeys.themeMode, value);

  String get locale => _prefs.getString(StorageKeys.locale) ?? 'fa';
  Future<void> setLocale(String value) =>
      _prefs.setString(StorageKeys.locale, value);

  String get avatar => _prefs.getString(StorageKeys.avatar) ?? '';
  Future<void> setAvatar(String value) =>
      _prefs.setString(StorageKeys.avatar, value);

  bool get topBarHidden => _prefs.getBool(StorageKeys.topBarHidden) ?? false;
  Future<void> setTopBarHidden(bool value) =>
      _prefs.setBool(StorageKeys.topBarHidden, value);

  String get weatherCity =>
      _prefs.getString(StorageKeys.weatherCity) ?? AppConfig.defaultCity;
  double get weatherLat =>
      _prefs.getDouble(StorageKeys.weatherLat) ?? AppConfig.defaultLat;
  double get weatherLon =>
      _prefs.getDouble(StorageKeys.weatherLon) ?? AppConfig.defaultLon;

  Future<void> setWeatherPlace(String city, double lat, double lon) async {
    await _prefs.setString(StorageKeys.weatherCity, city);
    await _prefs.setDouble(StorageKeys.weatherLat, lat);
    await _prefs.setDouble(StorageKeys.weatherLon, lon);
  }

  // ── profile fields (available with or without Google) ──────────────
  String get firstName => _prefs.getString(StorageKeys.firstName) ?? '';
  String get lastName => _prefs.getString(StorageKeys.lastName) ?? '';
  String get phone => _prefs.getString(StorageKeys.phone) ?? '';

  Future<void> setProfileFields({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    await _prefs.setString(StorageKeys.firstName, firstName);
    await _prefs.setString(StorageKeys.lastName, lastName);
    await _prefs.setString(StorageKeys.phone, phone);
  }

  // ── google user ───────────────────────────────────────────────────
  UserModel? get user {
    final Object? raw = _box.get(StorageKeys.user);
    if (raw == null) return null;
    if (raw is Map) return UserModel.fromJson(raw);
    if (raw is String) {
      return UserModel.fromJson(jsonDecode(raw) as Map<dynamic, dynamic>);
    }
    return null;
  }

  Future<void> saveUser(UserModel user) =>
      _box.put(StorageKeys.user, user.toJson());

  Future<void> clearUser() => _box.delete(StorageKeys.user);

  // ── case notification bells ───────────────────────────────────────
  Set<String> get bells {
    final Object? raw = _box.get(StorageKeys.bells);
    if (raw is List) return raw.map((dynamic e) => e.toString()).toSet();
    return <String>{};
  }

  Future<void> saveBells(Set<String> value) =>
      _box.put(StorageKeys.bells, value.toList());

  Set<String> get notificationTopics {
    final Object? raw = _box.get(StorageKeys.notificationTopics);
    if (raw is List) return raw.map((dynamic e) => e.toString()).toSet();
    return <String>{};
  }

  Future<void> saveNotificationTopics(Set<String> value) =>
      _box.put(StorageKeys.notificationTopics, value.toList());

  // ── download counters ─────────────────────────────────────────────
  Map<String, int> get downloadCounts {
    final Object? raw = _box.get(StorageKeys.downloads);
    if (raw is Map) {
      return raw.map<String, int>((dynamic k, dynamic v) =>
          MapEntry<String, int>(k.toString(), int.tryParse(v.toString()) ?? 0));
    }
    return <String, int>{};
  }

  Future<int> bumpDownload(String documentId) async {
    final Map<String, int> counts = downloadCounts;
    final int next = (counts[documentId] ?? 0) + 1;
    counts[documentId] = next;
    await _box.put(StorageKeys.downloads, counts);
    return next;
  }

  // ── notifications ─────────────────────────────────────────────────
  List<AppNotification> get notifications {
    final Object? raw = _box.get(StorageKeys.notifications);
    if (raw is List) {
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
    }
    return <AppNotification>[];
  }

  Future<void> saveNotifications(List<AppNotification> items) => _box.put(
        StorageKeys.notifications,
        items.map((AppNotification e) => e.toJson()).toList(),
      );
}
