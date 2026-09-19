import 'dart:convert';

import '../utils/shamsi_date.dart';

class NewsCategory {
  const NewsCategory({required this.id, required this.labels});
  final String id;
  final Map<String, String> labels;

  factory NewsCategory.fromJson(Map<String, dynamic> json) => NewsCategory(
        id: (json['id'] ?? '') as String,
        labels: <String, String>{
          'fa': (json['fa'] ?? json['name_fa'] ?? '') as String,
          'en': (json['en'] ?? json['name_en'] ?? json['fa'] ?? '') as String,
        },
      );

  String label(String languageCode) =>
      labels[languageCode] ?? labels['fa'] ?? labels['en'] ?? id;
}

/// A publisher is stored once and can be attached to many news records.
class Publisher {
  /// The public editorial identity is intentionally not remote-configurable.
  /// This guarantees the supplied brand photograph is used for every article,
  /// including legacy rows with stale or malformed publisher metadata.
  static const String defaultName = 'Sarfraz Khamoosh';
  static const String defaultAvatarAsset = 'assets/images/creator_profile.png';

  const Publisher({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.bioFa,
    required this.bioEn,
    required this.websiteUrl,
    required this.verified,
    required this.isActive,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String bioFa;
  final String bioEn;
  final String websiteUrl;
  final bool verified;
  final bool isActive;

  /// Backwards-compatible alias used by existing widgets.
  String get avatar => avatarUrl;

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
        id: (json['id'] ?? '') as String,
        name: defaultName,
        avatarUrl: defaultAvatarAsset,
        bioFa: (json['bioFa'] ?? json['bio_fa'] ?? '') as String,
        bioEn: (json['bioEn'] ?? json['bio_en'] ?? '') as String,
        websiteUrl: (json['websiteUrl'] ?? json['website_url'] ?? '') as String,
        verified: (json['verified'] ?? false) as bool,
        isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
      );

  String localizedBio(String languageCode) =>
      languageCode == 'en' && bioEn.isNotEmpty ? bioEn : bioFa;
}

enum NewsStatus { draft, published, archived }

NewsStatus _statusFromJson(Object? value) => switch (value) {
      'draft' => NewsStatus.draft,
      'archived' => NewsStatus.archived,
      _ => NewsStatus.published,
    };

/// A bilingual editorial article. It accepts bundled JSON (camel case) and
/// Supabase/Postgres rows (snake case), so offline content remains usable.
class NewsModel {
  const NewsModel({
    required this.id,
    required this.slug,
    required this.dateFa,
    required this.dateEn,
    required this.dateIso,
    required this.titleFa,
    required this.titleEn,
    required this.summaryFa,
    required this.summaryEn,
    required this.contentFa,
    required this.contentEn,
    required this.image,
    required this.category,
    required this.publisher,
    required this.source,
    required this.sourceUrl,
    required this.featured,
    required this.status,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String dateFa;
  final String dateEn;
  final String dateIso;
  final String titleFa;
  final String titleEn;
  final String summaryFa;
  final String summaryEn;
  final List<String> contentFa;
  final List<String> contentEn;

  /// Local asset path or a public Supabase Storage/HTTPS URL.
  final String image;
  final NewsCategory category;
  final Publisher publisher;
  final String source;
  final String sourceUrl;
  final bool featured;
  final NewsStatus status;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isRemoteImage =>
      image.startsWith('https://') || image.startsWith('http://');

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> legacyBody =
        (json['body'] ?? const <dynamic>[]) as List<dynamic>;
    final String legacyTitle = (json['title'] ?? '') as String;
    final String legacySummary = (json['summary'] ?? '') as String;
    final Object? categoryValue = json['category'];
    final Object? publisherValue = json['publisher'];

    return NewsModel(
      id: (json['id'] ?? '') as String,
      slug: (json['slug'] ?? json['id'] ?? '') as String,
      dateFa:
          (json['dateFa'] ?? json['date_fa'] ?? json['date'] ?? '') as String,
      dateEn:
          (json['dateEn'] ?? json['date_en'] ?? json['dateFa'] ?? '') as String,
      dateIso: (json['dateIso'] ?? json['date_iso'] ?? '') as String,
      titleFa: (json['titleFa'] ?? json['title_fa'] ?? legacyTitle) as String,
      titleEn: (json['titleEn'] ?? json['title_en'] ?? legacyTitle) as String,
      summaryFa:
          (json['summaryFa'] ?? json['summary_fa'] ?? legacySummary) as String,
      summaryEn:
          (json['summaryEn'] ?? json['summary_en'] ?? legacySummary) as String,
      contentFa:
          _stringList(json['contentFa'] ?? json['content_fa'] ?? legacyBody),
      contentEn:
          _stringList(json['contentEn'] ?? json['content_en'] ?? legacyBody),
      image: (json['image'] ?? json['image_url'] ?? '') as String,
      category: NewsCategory.fromJson(
        categoryValue is Map
            ? Map<String, dynamic>.from(categoryValue)
            : <String, dynamic>{
                'id': json['category_id'] ?? '',
                'fa': json['category_fa'] ?? '',
                'en': json['category_en'] ?? '',
              },
      ),
      publisher: Publisher.fromJson(
        publisherValue is Map
            ? Map<String, dynamic>.from(publisherValue)
            : <String, dynamic>{'id': json['publisher_id'] ?? ''},
      ),
      source: (json['source'] ?? '') as String,
      sourceUrl: (json['sourceUrl'] ?? json['source_url'] ?? '') as String,
      featured: (json['featured'] ?? false) as bool,
      status: _statusFromJson(json['status']),
      publishedAt: _date(json['published_at'] ?? json['publishedAt']),
      createdAt: _date(json['created_at'] ?? json['createdAt']),
      updatedAt: _date(json['updated_at'] ?? json['updatedAt']),
    );
  }

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .map((Object? item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }

    // Older dashboard records can contain the article body as a single text
    // value instead of a JSON array. Preserve it as paragraphs rather than
    // treating it as an empty article in the Read more screen.
    if (value is String && value.trim().isNotEmpty) {
      final String text = value.trim();
      // A few older rows stored a JSON array as a text column. Decode it
      // first; otherwise the brackets would be rendered as article content.
      try {
        final Object? decoded = jsonDecode(text);
        if (decoded is List) return _stringList(decoded);
      } on FormatException {
        // Plain legacy text is handled below.
      }
      return text
          .split(RegExp(r'\r?\n\s*\r?\n'))
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return <String>[];
  }

  DateTime? get parsedDate => publishedAt ?? DateTime.tryParse(dateIso);
  String localizedDate(String languageCode) {
    if (languageCode == 'en') return dateEn;
    // Persian: render the Solar Hijri date (Afghan + Iranian month names)
    // from date_iso so every row — old or new — shows the correct date.
    final DateTime? d = DateTime.tryParse(dateIso);
    if (d != null) return ShamsiDate.format(d);
    return dateFa;
  }
  String localizedTitle(String languageCode) =>
      languageCode == 'en' && titleEn.isNotEmpty ? titleEn : titleFa;
  String localizedSummary(String languageCode) =>
      languageCode == 'en' && summaryEn.isNotEmpty ? summaryEn : summaryFa;
  List<String> localizedContent(String languageCode) {
    final List<String> preferred = languageCode == 'en' ? contentEn : contentFa;
    if (preferred.isNotEmpty) return preferred;

    // A summary is still meaningful article content when an older dashboard
    // row did not yet populate the new content_* fields.
    final String fallback = localizedSummary(languageCode).trim();
    return fallback.isEmpty ? const <String>[] : <String>[fallback];
  }

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final String q = query.toLowerCase().trim();
    final Iterable<String> searchable = <String>[
      titleFa,
      titleEn,
      summaryFa,
      summaryEn,
      publisher.name,
      ...contentFa,
      ...contentEn,
      ...category.labels.values,
    ];
    return searchable.any((String value) => value.toLowerCase().contains(q));
  }
}
