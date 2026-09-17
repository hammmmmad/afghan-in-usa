import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// In-app admin gate: the admin section stays locked until the admin proves
/// email+password credentials that belong to a public.admin_users member.
///
/// Verification runs on a throwaway SupabaseClient with session persistence
/// disabled, so the main Google-derived session of the app is never touched.
/// The unlock is in-memory only: closing the app locks the panel again.
class AdminGate {
  AdminGate._();

  static final AdminGate instance = AdminGate._();

  static const Duration _unlockDuration = Duration(minutes: 30);

  DateTime? _unlockedUntil;

  bool get unlocked =>
      _unlockedUntil != null && DateTime.now().isBefore(_unlockedUntil!);

  void lock() => _unlockedUntil = null;

  /// Returns null on success, otherwise a user-facing error message.
  Future<String?> unlock(String email, String password) async {
    if (!SupabaseService.isConfigured || !SupabaseService.isReady) {
      return 'سرور پیکربندی نشده است.';
    }
    final String url = SupabaseService.runtimeUrl;
    final String key = SupabaseService.runtimeKey;
    final SupabaseClient verifier = SupabaseClient(
      url,
      key,
      authOptions: const FlutterAuthClientOptions(persistSession: false),
    );
    try {
      final AuthResponse result = await verifier.auth
          .signInWithPassword(email: email.trim(), password: password);
      final User? user = result.user;
      if (user == null) {
        return 'ایمیل یا رمز اشتباه است.';
      }
      final Map<String, dynamic>? role = await verifier
          .from('admin_users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (role == null) {
        return 'این حساب در فهرست مدیران نیست.';
      }
      _unlockedUntil = DateTime.now().add(_unlockDuration);
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'بررسی ورود ناموفق بود. اتصال اینترنت را چک کنید.';
    } finally {
      try {
        await verifier.auth.signOut();
      } catch (_) {}
    }
  }
}
