import '../models/news_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

/// In-app notification feed: every news item that belongs to a case the
/// user follows (green bell) becomes a notification entry.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<List<AppNotification>> build(Set<String> followedCases) async {
    final List<AppNotification> stored = StorageService.instance.notifications;
    final Map<String, AppNotification> byId = <String, AppNotification>{
      for (final AppNotification n in stored) n.id: n,
    };

    final List<NewsModel> news = await ApiService.instance.fetchNews();
    final List<AppNotification> result = <AppNotification>[];

    if (SupabaseService.isReady) {
      try {
        final List<dynamic> publicRows = await SupabaseService.client
            .from('public_notifications')
            .select('id,title_i18n,body_i18n,data,published_at')
            .eq('status', 'published')
            .order('published_at', ascending: false);
        result.addAll(publicRows.map((dynamic row) => _fromRemote(
              Map<String, dynamic>.from(row as Map),
              prefix: 'public_',
            )));

        // RLS only returns records where recipient_user_id = auth.uid().
        // Never attempt this query for anonymous users.
        if (SupabaseService.client.auth.currentUser != null) {
          final List<dynamic> specialRows = await SupabaseService.client
              .from('special_notifications')
              .select('id,case_id,title_i18n,body_i18n,data,created_at,read_at')
              .order('created_at', ascending: false);
          result.addAll(specialRows.map((dynamic row) => _fromRemote(
                Map<String, dynamic>.from(row as Map),
                prefix: 'special_',
                special: true,
              )));
        }
      } catch (_) {
        // The saved/local alerts remain available during an outage. Supabase
        // exceptions are not swallowed in the news/documents debug paths.
      }
    }

    for (final NewsModel item in news) {
      if (!followedCases.contains(item.category.id)) continue;
      final String id = 'news_${item.id}';
      final AppNotification? existing = byId[id];
      result.add(
        AppNotification(
          id: id,
          title: <String, String>{'fa': item.titleFa, 'en': item.titleEn},
          body: <String, String>{'fa': item.summaryFa, 'en': item.summaryEn},
          caseId: item.category.id,
          createdAt: item.parsedDate ?? DateTime.now(),
          read: existing?.read ?? false,
        ),
      );
    }

    final Map<String, AppNotification> unique = <String, AppNotification>{
      for (final AppNotification item in result) item.id: item,
    };
    final List<AppNotification> sorted = unique.values.toList();
    sorted.sort((AppNotification a, AppNotification b) =>
        b.createdAt.compareTo(a.createdAt));
    await StorageService.instance.saveNotifications(sorted);
    return sorted;
  }

  AppNotification _fromRemote(
    Map<String, dynamic> row, {
    required String prefix,
    bool special = false,
  }) {
    final Map<String, dynamic> data = row['data'] is Map
        ? Map<String, dynamic>.from(row['data'] as Map)
        : <String, dynamic>{};
    final Map<String, String> title = _i18n(row['title_i18n']);
    final Map<String, String> body = _i18n(row['body_i18n']);
    final String id = '$prefix${row['id']}';
    AppNotification? cached;
    for (final AppNotification item in StorageService.instance.notifications) {
      if (item.id == id) {
        cached = item;
        break;
      }
    }
    return AppNotification(
      id: id,
      title: title,
      body: body,
      caseId: (special ? row['case_id'] : data['case_id'] ?? '').toString(),
      createdAt: DateTime.tryParse(
            (row['published_at'] ?? row['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      read: special ? row['read_at'] != null : cached?.read ?? false,
    );
  }

  Map<String, String> _i18n(Object? value) {
    final Map<dynamic, dynamic> map =
        value is Map ? value : <dynamic, dynamic>{};
    return <String, String>{
      'fa': (map['fa'] ?? '').toString(),
      'en': (map['en'] ?? map['fa'] ?? '').toString(),
    };
  }

}
