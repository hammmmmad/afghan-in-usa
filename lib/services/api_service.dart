import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/case_model.dart';
import '../models/document_model.dart';
import '../models/news_model.dart';
import '../utils/constants.dart';
import 'news_repository.dart';
import 'supabase_service.dart';

class ApiService implements NewsRepository {
  ApiService._();

  static final ApiService instance = ApiService._();

  List<NewsModel>? _news;
  List<DocumentModel>? _documents;
  List<CaseSummary>? _cases;
  final Map<String, CaseModel> _caseCache = <String, CaseModel>{};

  Future<Map<String, dynamic>> _loadJson(String path) async {
    final String raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<NewsModel>> _loadBundledNews() async {
    final Map<String, dynamic> json = await _loadJson(AppAssets.newsData);

    return ((json['news'] ?? const <dynamic>[]) as List<dynamic>)
        .map(
          (dynamic item) => NewsModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  List<NewsModel> _sortNews(Iterable<NewsModel> source) {
    final List<NewsModel> items = source.toList();

    items.sort((NewsModel a, NewsModel b) {
      final DateTime dateA = a.parsedDate ?? DateTime(1970);
      final DateTime dateB = b.parsedDate ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return items;
  }

  @override
  Future<List<NewsModel>> fetchNews({bool force = false}) async {
    if (_news != null && !force) return _news!;

    final List<NewsModel> bundledNews = await _loadBundledNews();

    if (!SupabaseService.isReady) {
      _news = _sortNews(bundledNews);
      return _news!;
    }

    try {
      final List<dynamic> rows = await SupabaseService.client
          .from('news')
          .select(
            'id,slug,date_fa,date_en,date_iso,title_fa,title_en,summary_fa,'
            'summary_en,content_fa,content_en,image_url,category_id,category_fa,'
            'category_en,source,source_url,featured,status,published_at,created_at,'
            'updated_at,publisher:publishers(id,display_name,avatar_url,bio_fa,'
            'bio_en,website_url,verified,is_active)',
          )
          .eq('status', 'published')
          .order('featured', ascending: false)
          .order('published_at', ascending: false);
      final List<NewsModel> remoteNews = rows
          .map(
            (dynamic row) => NewsModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
      // An online feed is authoritative. The bundled JSON is deliberately
      // reserved for offline/unconfigured operation, so deleted or archived
      // remote articles cannot survive indefinitely in an online session.
      _news = _sortNews(remoteNews);
      return _news!;
    } catch (error, stackTrace) {
      // Remote feed unavailable: preserve the bundled news for offline use.
      if (kDebugMode) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      _news = _sortNews(bundledNews);
      return _news!;
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
        all.where((NewsModel news) => news.matches(query)).toList();

    final int start = page * pageSize;
    if (start >= filtered.length) return <NewsModel>[];

    final int end = (start + pageSize) > filtered.length
        ? filtered.length
        : start + pageSize;

    return filtered.sublist(start, end);
  }

  Future<List<DocumentModel>> fetchDocuments({bool force = false}) async {
    if (_documents != null && !force) return _documents!;

    final Map<String, dynamic> json = await _loadJson(AppAssets.documentsData);

    final List<DocumentModel> bundled =
        ((json['documents'] ?? const <dynamic>[]) as List<dynamic>)
            .map(
              (dynamic item) =>
                  DocumentModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();

    if (!SupabaseService.isReady) {
      _documents = bundled;
      return _documents!;
    }

    try {
      final List<dynamic> rows = await SupabaseService.client
          .from('documents')
          .select(
              'id,title_i18n,description_i18n,file_url,storage_path,file_type,'
              'size_bytes,requires_login,status,downloads,published_at')
          .eq('status', 'published')
          .order('published_at', ascending: false);
      final List<DocumentModel> remote = <DocumentModel>[];
      for (final dynamic row in rows) {
        final Map<String, dynamic> source =
            Map<String, dynamic>.from(row as Map);
        source['title'] = source['title_i18n'];
        source['description'] = source['description_i18n'];
        // Supabase documents use the private Storage object, never a public
        // file_url. External URLs remain supported only by bundled offline
        // JSON records.
        source['url'] = '';
        source['type'] = source['file_type'];
        source['requiresLogin'] = source['requires_login'];
        if (SupabaseService.client.auth.currentUser != null &&
            (source['url'] as String? ?? '').isEmpty &&
            (source['storage_path'] as String? ?? '').isNotEmpty) {
          source['url'] = await SupabaseService.client.storage
              .from('documents')
              .createSignedUrl(source['storage_path'] as String, 3600);
        }
        remote.add(DocumentModel.fromJson(source));
      }
      _documents = remote;
      return _documents!;
    } catch (error, stackTrace) {
      if (kDebugMode) Error.throwWithStackTrace(error, stackTrace);
      _documents = bundled;
    }

    return _documents!;
  }

  Future<List<CaseSummary>> fetchCases({bool force = false}) async {
    if (_cases != null && !force) return _cases!;

    final Map<String, dynamic> json = await _loadJson(AppAssets.casesIndex);

    _cases = ((json['cases'] ?? const <dynamic>[]) as List<dynamic>)
        .map(
          (dynamic item) => CaseSummary.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return _cases!;
  }

  Future<CaseModel> fetchCase(String id) async {
    final CaseModel? cached = _caseCache[id];
    if (cached != null) return cached;

    final Map<String, dynamic> json = await _loadJson('assets/cases/$id.json');

    final CaseModel model = CaseModel.fromJson(json);
    _caseCache[id] = model;
    return model;
  }

  @override
  Future<List<NewsModel>> fetchNewsForCase(String caseId) async {
    final List<NewsModel> all = await fetchNews();

    return all.where((NewsModel news) => news.category.id == caseId).toList();
  }
}
