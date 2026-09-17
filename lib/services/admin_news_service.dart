import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Administrative CRUD for the `public.news` table. Every call goes through
/// the anon/authenticated client only; the database `is_admin()` RLS policies
/// are the real authority, this service just gives clearer error messages.
class AdminNewsService {
  AdminNewsService._();

  static final AdminNewsService instance = AdminNewsService._();

  /// The stable fallback publisher created by migration
  /// `20260906000001_upgrade_existing_news.sql`.
  static const String defaultPublisherId =
      '00000000-0000-0000-0000-000000000001';

  static const String _select =
      'id,slug,publisher_id,category_id,category_fa,category_en,date_iso,'
      'date_fa,date_en,title_fa,title_en,summary_fa,summary_en,content_fa,'
      'content_en,image_url,source,source_url,featured,status,published_at,'
      'created_at,updated_at';

  Future<void> _ensureAdmin() async {
    if (!await SupabaseService.isCurrentUserAdmin()) {
      throw StateError('این عملیات دسترسی مدیر لازم دارد.');
    }
  }

  /// Every article, including drafts and archived rows (admin-only via RLS).
  Future<List<Map<String, dynamic>>> fetchAll() async {
    await _ensureAdmin();
    final List<dynamic> rows = await SupabaseService.client
        .from('news')
        .select(_select)
        .order('created_at', ascending: false);
    return rows
        .map((dynamic row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  /// Turns a title into a URL-safe slug. The database requires
  /// `^[a-z0-9]+(?:-[a-z0-9]+)*$`, so non-ASCII titles (e.g. Persian) fall
  /// back to the id-based slug. Public and pure so it can be unit-tested and
  /// reused by the web panel.
  static String makeSlug(String title, String id) {
    final String base = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final String suffix = id.isEmpty
        ? DateTime.now().toUtc().millisecondsSinceEpoch.toString()
        : id.substring(0, 8);
    final String slug = base.isEmpty ? 'news-$suffix' : '$base-$suffix';
    return slug.length > 80
        ? slug.substring(0, 80).replaceAll(RegExp(r'-+$'), '')
        : slug;
  }

  /// Body text is stored as a JSON array of paragraphs, matching how
  /// NewsModel renders articles.
  static List<String> paragraphs(String body) => body
      .split(RegExp(r'\r?\n\s*\r?\n'))
      .map((String p) => p.trim())
      .where((String p) => p.isNotEmpty)
      .toList(growable: false);

  Future<Map<String, dynamic>> create({
    required String titleFa,
    required String titleEn,
    required String summaryFa,
    String summaryEn = '',
    String contentFa = '',
    String contentEn = '',
    String categoryId = 'general',
    String categoryFa = '',
    String categoryEn = '',
    String imageUrl = '',
    String source = '',
    String sourceUrl = '',
    bool featured = false,
    bool publish = false,
  }) async {
    await _ensureAdmin();
    final DateTime now = DateTime.now().toUtc();
    final Map<String, dynamic> row = <String, dynamic>{
      'slug': makeSlug(titleEn.isNotEmpty ? titleEn : titleFa, ''),
      'publisher_id': defaultPublisherId,
      'category_id': categoryId.trim().isEmpty ? 'general' : categoryId.trim(),
      'category_fa': categoryFa,
      'category_en': categoryEn,
      'date_iso': now.toIso8601String().substring(0, 10),
      'date_fa': _formatDate(now),
      'date_en': _formatDate(now),
      'title_fa': titleFa,
      'title_en': titleEn,
      'summary_fa': summaryFa,
      'summary_en': summaryEn,
      'content_fa': paragraphs(contentFa),
      'content_en': paragraphs(contentEn),
      'image_url': imageUrl,
      'source': source,
      'source_url': sourceUrl,
      'featured': featured,
      'status': publish ? 'published' : 'draft',
      if (publish) 'published_at': now.toIso8601String(),
    };
    final List<dynamic> inserted = await SupabaseService.client
        .from('news')
        .insert(row)
        .select('id');
    return Map<String, dynamic>.from(inserted.single as Map);
  }

  Future<void> update(
    String id, {
    required String titleFa,
    required String titleEn,
    required String summaryFa,
    String summaryEn = '',
    String contentFa = '',
    String contentEn = '',
    String categoryId = 'general',
    String categoryFa = '',
    String categoryEn = '',
    String imageUrl = '',
    String source = '',
    String sourceUrl = '',
    bool featured = false,
  }) async {
    await _ensureAdmin();
    await SupabaseService.client.from('news').update(<String, dynamic>{
      'category_id': categoryId.trim().isEmpty ? 'general' : categoryId.trim(),
      'category_fa': categoryFa,
      'category_en': categoryEn,
      'title_fa': titleFa,
      'title_en': titleEn,
      'summary_fa': summaryFa,
      'summary_en': summaryEn,
      'content_fa': paragraphs(contentFa),
      'content_en': paragraphs(contentEn),
      'image_url': imageUrl,
      'source': source,
      'source_url': sourceUrl,
      'featured': featured,
    }).eq('id', id);
  }

  /// Publish or re-publish: the table requires a `published_at` for rows with
  /// status = 'published' (see `published_news_requires_date`).
  Future<void> setPublished(String id, bool published) async {
    await _ensureAdmin();
    await SupabaseService.client.from('news').update(<String, dynamic>{
      'status': published ? 'published' : 'draft',
      'published_at': published
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    }).eq('id', id);
  }

  Future<void> setFeatured(String id, bool featured) async {
    await _ensureAdmin();
    await SupabaseService.client
        .from('news')
        .update(<String, dynamic>{'featured': featured}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _ensureAdmin();
    await SupabaseService.client.from('news').delete().eq('id', id);
  }

  /// Uploads an article image to the public `app-assets` bucket and returns
  /// its public URL for `news.image_url`.
  Future<String> uploadImage(
    String filename,
    Uint8List bytes,
    String contentType,
  ) async {
    await _ensureAdmin();
    final String safe = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String path =
        'news/${DateTime.now().toUtc().millisecondsSinceEpoch}_$safe';
    await SupabaseService.client.storage.from('app-assets').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: false, contentType: contentType),
        );
    return SupabaseService.client.storage.from('app-assets').getPublicUrl(path);
  }

  static String _formatDate(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }
}
