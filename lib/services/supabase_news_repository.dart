import '../models/news_model.dart';
import 'news_repository.dart';
import 'supabase_service.dart';

/// Remote read repository for the public news feed. Editing remains protected
/// by Supabase RLS; this client deliberately exposes no service-role key.
class SupabaseNewsRepository implements NewsRepository {
  SupabaseNewsRepository({required this.fallback});

  final NewsRepository fallback;
  List<NewsModel>? _cache;

  static const String _newsSelect =
      'id,slug,date_fa,date_en,date_iso,title_fa,title_en,summary_fa,'
      'summary_en,content_fa,content_en,image_url,category_id,category_fa,'
      'category_en,source,source_url,featured,status,published_at,created_at,'
      'updated_at,publisher:publishers(id,display_name,avatar_url,bio_fa,'
      'bio_en,website_url,verified,is_active)';

  @override
  Future<List<NewsModel>> fetchNews({bool force = false}) async {
    if (_cache != null && !force) return _cache!;
    if (!SupabaseService.isReady) return fallback.fetchNews(force: force);

    try {
      final List<dynamic> rows = await SupabaseService.client
          .from('news')
          .select(_newsSelect)
          .eq('status', 'published')
          .order('featured', ascending: false)
          .order('published_at', ascending: false);
      final List<NewsModel> remote = rows
          .map((dynamic row) => NewsModel.fromJson(_map(row)))
          .toList(growable: false);
      final List<NewsModel> bundled = await fallback.fetchNews(force: force);
      // Never let a successful remote request hide the editorial history
      // shipped with the app. A matching ID intentionally updates its local
      // counterpart with the current dashboard version.
      final Map<String, NewsModel> merged = <String, NewsModel>{
        for (final NewsModel item in bundled) item.id: item,
        for (final NewsModel item in remote) item.id: item,
      };
      _cache = merged.values.toList(growable: false)
        ..sort((NewsModel a, NewsModel b) {
          final DateTime dateA = a.parsedDate ?? DateTime(1970);
          final DateTime dateB = b.parsedDate ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
      return _cache!;
    } catch (_) {
      // The bundled feed keeps the app useful during initial setup or outages.
      return fallback.fetchNews(force: force);
    }
  }

  @override
  Future<List<NewsModel>> fetchNewsPage({
    required int page,
    int pageSize = 4,
    String query = '',
  }) async {
    final List<NewsModel> all = await fetchNews();
    final List<NewsModel> filtered =
        all.where((NewsModel item) => item.matches(query)).toList();
    final int start = page * pageSize;
    if (start >= filtered.length) return <NewsModel>[];
    final int end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Future<List<NewsModel>> fetchNewsForCase(String caseId) async {
    final List<NewsModel> all = await fetchNews();
    return all.where((NewsModel item) => item.category.id == caseId).toList();
  }

  static Map<String, dynamic> _map(dynamic row) =>
      Map<String, dynamic>.from(row as Map);
}
