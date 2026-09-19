import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/user_model.dart';
import 'fcm_service.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

/// Google authenticates the user with Firebase Auth. The same Google ID
/// token is then used to open a Supabase session so the Supabase-backed
/// features (document signed URLs, device tokens, case subscriptions,
/// special notifications, admin checks) keep working. Firebase remains the
/// source of truth for the sign-in UI; Supabase failures never block it.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  // serverClientId must be the Web OAuth client of the Firebase project; it is
  // the audience of the ID token Android requests and Firebase verifies.
  static const String _googleWebClientId =
      '318374626413-r3rbfcv35b7953rv086ic61fukf7bphe.apps.googleusercontent.com';

  final GoogleSignIn _google = GoogleSignIn(
    scopes: <String>['email', 'profile'],
    serverClientId: _googleWebClientId,
  );
  final StorageService _storage = StorageService.instance;

  /// Synchronous sign-in state for UI gates (documents, profile).
  bool get isSignedIn =>
      FirebaseAuth.instance.currentUser != null || _storage.user != null;

  User? get firebaseUser => FirebaseAuth.instance.currentUser;

  bool isLoggedIn() => isSignedIn;

  UserModel? get cachedUser => _storage.user;

  Future<UserModel?> restore() async {
    final UserModel? cached = _storage.user;
    if (kIsWeb) {
      // Web sign-in uses Supabase's OAuth redirect flow (the google_sign_in
      // plugin needs per-origin OAuth configuration we don't control on
      // GitHub Pages). The Supabase session is restored from the redirect
      // URL by supabase_flutter; Firebase has no session on web.
      try {
        final supabase.User? su = SupabaseService.isReady
            ? SupabaseService.client.auth.currentUser
            : null;
        if (su != null) {
          final meta = su.userMetadata ?? const <String, dynamic>{};
          final String displayName =
              (meta['full_name'] ?? meta['name'] ?? su.email ?? '') as String;
          final List<String> parts =
              displayName.trim().split(RegExp(r'\s+'));
          final UserModel user = UserModel(
            id: su.id,
            email: su.email ?? '',
            displayName: displayName,
            photoUrl: (meta['avatar_url'] ?? '') as String,
            firstName: parts.isNotEmpty ? parts.first : '',
            lastName:
                parts.length > 1 ? parts.sublist(1).join(' ') : '',
            phone: '',
            avatarAsset: '',
          );
          await _storage.saveUser(user);
          unawaited(_syncProfile(user));
          return user;
        }
      } catch (_) {
        return cached;
      }
      return cached;
    }
    try {
      final User? current = FirebaseAuth.instance.currentUser;
      if (current == null) return cached;
      // Offline, Google's silent sign-in can hang instead of failing fast;
      // the cached profile must stay usable meanwhile.
      final GoogleSignInAccount? account = await _google.signInSilently()
          .timeout(const Duration(seconds: 6));
      if (account != null) {
        // Best-effort: refresh the Supabase session with the same Google
        // identity. Supabase also restores its persisted session itself.
        await _signInToSupabase(account);
      }
      final UserModel user = _mapSession(current, account, cached);
      await _storage.saveUser(user);
      unawaited(_syncProfile(user));
      unawaited(FcmService.instance.registerDevice());
      return user;
    } catch (_) {
      // A locally saved profile remains usable while offline.
      return cached;
    }
  }

  Future<UserModel?> signIn() async {
    if (kIsWeb) {
      // Redirect OAuth: the browser leaves for Google and returns to the
      // Pages URL with the session in the fragment; supabase_flutter picks
      // it up on load and restore() maps it to a user. The page reloads,
      // so there is no UserModel to return here.
      await SupabaseService.client.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: 'https://hammmmmad.github.io/afghan-in-usa/',
      );
      return null;
    }
    final GoogleSignInAccount? account = await _google.signIn();
    if (account == null) return null;
    final GoogleSignInAuthentication googleAuth = await account.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not provide an ID token.');
    }
    await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      ),
    );
    // The same ID token opens the Supabase session. This only works when
    // the Google provider is enabled in the Supabase dashboard; a failure
    // here degrades Supabase features but never blocks the Firebase login.
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.client.auth.signInWithIdToken(
          provider: supabase.OAuthProvider.google,
          idToken: idToken,
          accessToken: googleAuth.accessToken,
        );
      } catch (_) {}
    }
    final User firebaseUser = FirebaseAuth.instance.currentUser!;
    final UserModel mapped = _mapSession(firebaseUser, account, _storage.user);
    await _storage.saveUser(mapped);
    unawaited(_syncProfile(mapped));
    unawaited(FcmService.instance.registerDevice());
    return mapped;
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.client.auth.signOut();
      } catch (_) {}
    }
    await _storage.clearUser();
  }

  Future<void> _signInToSupabase(GoogleSignInAccount account) async {
    if (!SupabaseService.isReady) return;
    try {
      final GoogleSignInAuthentication googleAuth =
          await account.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) return;
      await SupabaseService.client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
    } catch (_) {
      // Supabase features degrade gracefully without a session.
    }
  }

  /// Best-effort mirror of the signed-in identity in public.profiles. RLS
  /// limits the row to the signed-in user, so a failure can never leak or
  /// block the session. The row id must be the Supabase user id because the
  /// table references auth.users.
  Future<void> _syncProfile(UserModel user) async {
    if (!SupabaseService.isReady) return;
    try {
      final supabase.User? supabaseUser =
          SupabaseService.client.auth.currentUser;
      if (supabaseUser == null) return;
      await SupabaseService.client.from('profiles').upsert(<String, dynamic>{
        'id': supabaseUser.id,
        'email': user.email,
        'display_name': user.displayName,
        'avatar_url': user.photoUrl,
        'last_login': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');
    } catch (_) {
      // Profile sync is optional; the session stays valid without it.
    }
  }

  UserModel _mapSession(
    User user,
    GoogleSignInAccount? account,
    UserModel? previous,
  ) {
    final String displayName = user.displayName ?? account?.displayName ?? '';
    final List<String> parts = displayName.trim().split(RegExp(r'\s+'));
    return UserModel(
      id: user.uid,
      email: user.email ?? account?.email ?? '',
      displayName: displayName.isEmpty ? (user.email ?? '') : displayName,
      photoUrl: user.photoURL ?? account?.photoUrl ?? '',
      firstName: previous?.firstName.isNotEmpty == true
          ? previous!.firstName
          : (parts.isNotEmpty ? parts.first : ''),
      lastName: previous?.lastName.isNotEmpty == true
          ? previous!.lastName
          : (parts.length > 1 ? parts.sublist(1).join(' ') : ''),
      phone: previous?.phone ?? user.phoneNumber ?? '',
      avatarAsset: previous?.avatarAsset ?? '',
    );
  }
}
