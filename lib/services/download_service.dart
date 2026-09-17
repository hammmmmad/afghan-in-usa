import 'package:url_launcher/url_launcher.dart';

import '../models/document_model.dart';

class DownloadResult {
  const DownloadResult({
    required this.ok,
    required this.path,
    this.message = '',
  });

  final bool ok;
  final String path;
  final String message;
}

class DownloadService {
  DownloadService._();

  static final DownloadService instance = DownloadService._();

  Future<DownloadResult> download(
    DocumentModel doc, {
    void Function(double progress)? onProgress,
  }) async {
    final String rawUrl = doc.url.trim();

    if (rawUrl.isEmpty) {
      return const DownloadResult(
        ok: false,
        path: '',
        message: 'no-url',
      );
    }

    final Uri uri = Uri.tryParse(rawUrl) ?? Uri();

    if (uri.scheme != 'https') {
      return const DownloadResult(
        ok: false,
        path: '',
        message: 'unsafe-url',
      );
    }

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    return DownloadResult(
      ok: launched,
      path: rawUrl,
      message: launched ? '' : 'launch-failed',
    );
  }
}
