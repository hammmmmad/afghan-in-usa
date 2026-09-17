import '../utils/helpers.dart';

class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    required this.requiresLogin,
    required this.description,
    this.storagePath = '',
    this.sizeBytes = 0,
    this.status = 'published',
    this.downloads = 0,
  });

  final String id;
  final Map<String, dynamic> title;
  final String type;
  final String url;
  final bool requiresLogin;
  final Map<String, dynamic> description;
  final String storagePath;
  final int sizeBytes;
  final String status;
  final int downloads;

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: (json['id'] ?? '') as String,
        title: _localizedMap(json['title'] ?? json['title_i18n']),
        type: (json['type'] ?? 'pdf') as String,
        url: (json['url'] ?? json['file_url'] ?? '') as String,
        requiresLogin:
            (json['requiresLogin'] ?? json['requires_login'] ?? true) as bool,
        description:
            _localizedMap(json['description'] ?? json['description_i18n']),
        storagePath: (json['storage_path'] ?? '') as String,
        sizeBytes: int.tryParse((json['size_bytes'] ?? 0).toString()) ?? 0,
        status: (json['status'] ?? 'published') as String,
        downloads: int.tryParse((json['downloads'] ?? 0).toString()) ?? 0,
      );

  static Map<String, dynamic> _localizedMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    final String text = value?.toString() ?? '';
    return <String, dynamic>{'fa': text, 'en': text};
  }

  String localizedTitle(String lang) => Helpers.pick(title, lang, fallback: id);
  String localizedDescription(String lang) => Helpers.pick(description, lang);

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final String q = query.toLowerCase().trim();
    return title.values
        .any((Object? v) => v.toString().toLowerCase().contains(q));
  }
}
