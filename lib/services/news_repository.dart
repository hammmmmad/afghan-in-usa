import '../models/news_model.dart';

/// Content contract used by the UI. Both the Supabase feed and the bundled
/// offline fallback satisfy this contract without changing news screens.
abstract interface class NewsRepository {
  Future<List<NewsModel>> fetchNews({bool force = false});
  Future<List<NewsModel>> fetchNewsPage({
    required int page,
    int pageSize = 4,
    String query = '',
  });
  Future<List<NewsModel>> fetchNewsForCase(String caseId);
}
