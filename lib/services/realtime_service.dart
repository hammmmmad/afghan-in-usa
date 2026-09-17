import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_service.dart';
import 'supabase_service.dart';

/// Subscribes to the public `news` table through Supabase Realtime so a newly
/// published or unpublished article reaches the app without pull-to-refresh.
///
/// The channel only listens to published-feed-relevant columns; RLS on the
/// table means drafts never reach anon/authenticated subscribers anyway. The
/// payload is not parsed — any change simply re-fetches the published feed.
class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  RealtimeChannel? _channel;
  RealtimeChannel? _notificationsChannel;
  Timer? _debounce;
  bool _started = false;

  /// Called (debounced) after any committed change to public.news.
  void Function()? onNewsChanged;

  /// Called (debounced) after any committed change to public_notifications.
  /// Only published rows are broadcast and those are public by design.
  void Function()? onPublicNotificationChanged;

  void start() {
    if (_started || !SupabaseService.isReady) return;
    _started = true;
    _channel = SupabaseService.client
        .channel('public:news')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'news',
          callback: (PostgresChangePayload _) => _handle(),
        )
        .subscribe();
    _notificationsChannel = SupabaseService.client
        .channel('public:public_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'public_notifications',
          callback: (PostgresChangePayload _) => _handleNotification(),
        )
        .subscribe();
  }

  void _handleNotification() {
    // Bursts of updates collapse into one refresh.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      onPublicNotificationChanged?.call();
    });
  }

  void _handle() {
    // Bursts of updates (an admin saving twice) collapse into one refresh.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        await ApiService.instance.fetchNews(force: true);
      } catch (_) {
        // The next manual refresh picks the change up; realtime is a bonus.
      }
      onNewsChanged?.call();
    });
  }

  Future<void> stop() async {
    _debounce?.cancel();
    final RealtimeChannel? channel = _channel;
    final RealtimeChannel? notificationsChannel = _notificationsChannel;
    _channel = null;
    _notificationsChannel = null;
    _started = false;
    if (SupabaseService.isReady) {
      if (channel != null) {
        await SupabaseService.client.removeChannel(channel);
      }
      if (notificationsChannel != null) {
        await SupabaseService.client.removeChannel(notificationsChannel);
      }
    }
  }
}
