import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AdminDocumentService {
  AdminDocumentService._();

  static final AdminDocumentService instance = AdminDocumentService._();
  static const int maxBytes = 25 * 1024 * 1024;
  static const Set<String> allowedExtensions = <String>{
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
    'zip'
  };

  String? validate(PlatformFile? file) {
    if (file == null) return 'یک فایل انتخاب کنید.';
    final String extension = file.extension?.toLowerCase() ?? '';
    if (!allowedExtensions.contains(extension)) {
      return 'این نوع فایل مجاز نیست: .$extension';
    }
    if (file.size <= 0) return 'فایل انتخاب‌شده خالی است.';
    if (file.size > maxBytes) return 'حجم فایل باید حداکثر 25 مگابایت باشد.';
    if (file.bytes == null) return 'خواندن فایل انتخاب‌شده ممکن نشد.';
    return null;
  }

  Future<void> uploadAndPublish({
    required PlatformFile file,
    required String titleFa,
    required String titleEn,
    required String descriptionFa,
    required String descriptionEn,
    required bool requiresLogin,
  }) async {
    final String? validationError = validate(file);
    if (validationError != null) throw StateError(validationError);
    if (!await SupabaseService.isCurrentUserAdmin()) {
      throw StateError('دسترسی مدیر برای بارگذاری این فایل لازم است.');
    }
    final String extension = file.extension!.toLowerCase();
    final String filename =
        file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String path =
        '${DateTime.now().toUtc().millisecondsSinceEpoch}_$filename';
    final Uint8List bytes = file.bytes!;
    await SupabaseService.client.storage.from('documents').uploadBinary(
          path,
          bytes,
          fileOptions:
              FileOptions(upsert: false, contentType: _contentType(extension)),
        );
    try {
      await SupabaseService.client.from('documents').insert(<String, dynamic>{
        'title_i18n': <String, String>{'fa': titleFa, 'en': titleEn},
        'description_i18n': <String, String>{
          'fa': descriptionFa,
          'en': descriptionEn
        },
        'storage_path': path,
        'file_type': extension,
        'size_bytes': file.size,
        'requires_login': requiresLogin,
        'status': 'published',
        'published_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      await SupabaseService.client.storage
          .from('documents')
          .remove(<String>[path]);
      rethrow;
    }
  }

  String _contentType(String extension) => switch (extension) {
        'pdf' => 'application/pdf',
        'doc' => 'application/msword',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls' => 'application/vnd.ms-excel',
        'xlsx' =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'ppt' => 'application/vnd.ms-powerpoint',
        'pptx' =>
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'csv' => 'text/csv',
        'txt' => 'text/plain',
        _ => 'application/octet-stream',
      };
}
