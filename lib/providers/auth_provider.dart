import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _hydrate();
  }

  UserModel? _user;
  bool _busy = false;
  String _error = '';
  String _avatarAsset = '';
  bool _topBarHidden = false;
  bool _isAdmin = false;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;
  String get error => _error;
  String get avatarAsset => _avatarAsset;
  bool get topBarHidden => _topBarHidden;
  bool get isAdmin => _isAdmin;

  void _hydrate() {
    final StorageService storage = StorageService.instance;
    _avatarAsset = storage.avatar;
    _topBarHidden = storage.topBarHidden;
    final UserModel? cached = storage.user;
    if (cached != null) {
      _user = cached.copyWith(
        firstName:
            cached.firstName.isEmpty ? storage.firstName : cached.firstName,
        lastName: cached.lastName.isEmpty ? storage.lastName : cached.lastName,
        phone: cached.phone.isEmpty ? storage.phone : cached.phone,
      );
    }
    notifyListeners();
    AuthService.instance.restore().then((UserModel? restored) async {
      if (restored != null) {
        _user = restored;
        await _refreshAdmin();
        notifyListeners();
      }
    });
  }

  Future<bool> signIn() async {
    _busy = true;
    _error = '';
    notifyListeners();
    try {
      final UserModel? signed = await AuthService.instance.signIn();
      _user = signed;
      await _refreshAdmin();
      _busy = false;
      notifyListeners();
      return signed != null;
    } catch (e) {
      _error = e.toString();
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    _user = null;
    _isAdmin = false;
    notifyListeners();
  }

  Future<void> setAvatar(String asset) async {
    _avatarAsset = asset;
    _user = _user?.copyWith(avatarAsset: asset);
    notifyListeners();
    await StorageService.instance.setAvatar(asset);
    if (_user != null) await StorageService.instance.saveUser(_user!);
  }

  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    await StorageService.instance.setProfileFields(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
    if (_user != null) {
      _user = _user!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      await StorageService.instance.saveUser(_user!);
    }
    notifyListeners();
  }

  Future<void> setTopBarHidden(bool value) async {
    _topBarHidden = value;
    notifyListeners();
    await StorageService.instance.setTopBarHidden(value);
  }

  /// Profile fields for a guest (not signed in).
  String get guestFirstName => StorageService.instance.firstName;
  String get guestLastName => StorageService.instance.lastName;
  String get guestPhone => StorageService.instance.phone;

  Future<void> _refreshAdmin() async {
    try {
      _isAdmin = await SupabaseService.isCurrentUserAdmin();
    } catch (_) {
      _isAdmin = false;
    }
  }
}
