import 'package:flutter/material.dart';

import '../models/document_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'tinted_icon.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.languageCode,
    required this.downloads,
    required this.downloadsLabel,
    required this.downloadLabel,
    required this.progress,
    required this.locked,
    required this.onDownload,
  });

  final DocumentModel document;
  final String languageCode;
  final int downloads;
  final String downloadsLabel;
  final String downloadLabel;
  final double? progress;
  final bool locked;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool busy = progress != null;
    final Color documentColor =
        document.type == 'pdf' ? const Color(0xFFE53935) : AppColors.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: documentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      document.type == 'pdf'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.description_rounded,
                      color: documentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        document.localizedTitle(languageCode),
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document.localizedDescription(languageCode),
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.download_done_rounded,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${Helpers.localizedNumber(languageCode, downloads)} '
                            '$downloadsLabel',
                            style: theme.textTheme.labelSmall,
                          ),
                          if (locked) ...<Widget>[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : onDownload,
                  tooltip: downloadLabel,
                  icon: busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            value: progress == 0 ? null : progress,
                          ),
                        )
                      : const TintedIcon(AppAssets.iconDownload, size: 26),
                ),
              ],
            ),
          ),
          if (busy)
            LinearProgressIndicator(
              minHeight: 3,
              value: progress == 0 ? null : progress,
            ),
        ],
      ),
    );
  }
}
