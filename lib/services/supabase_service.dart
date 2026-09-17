import 'package:supabase_flutter/supabase_flutter.dart';

/// Runtime Supabase configuration. Values are intentionally supplied at build
/// time; the anonymous key is safe for a client only when RLS is enabled.
class SupabaseService {
  SupabaseService._();

  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool _initialized = false;

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;
  static bool get isReady => _initialized;

  /// Runtime credentials for secondary clients (e.g., the admin gate that
  /// must never touch the main Google-derived session).
  static String get runtimeUrl => _url;
  static String get runtimeKey => _anonKey;

  static Future<void> initialize() async {
    if (!isConfigured || _initialized) return;
    await Supabase.initialize(url: _url, publishableKey: _anonKey);
    _initialized = true;
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase has not been configured or initialized.');
    }
    return Supabase.instance.client;
  }

  static Future<bool> isCurrentUserAdmin() async {
    if (!isReady || client.auth.currentUser == null) return false;
    final Map<String, dynamic>? row = await client
        .from('admin_users')
        .select('user_id')
        .eq('user_id', client.auth.currentUser!.id)
        .maybeSingle();
    return row != null;
  }
}
