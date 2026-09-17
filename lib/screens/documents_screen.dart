import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/document_model.dart';
import '../providers/download_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/download_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/document_card.dart';
import '../widgets/google_sign_in_modal.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/tinted_icon.dart';
import '../widgets/top_notification_bar.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<DocumentModel>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.fetchDocuments();
  }

  Future<void> _refresh() async {
    setState(() => _future = ApiService.instance.fetchDocuments(force: true));
    await _future;
  }

  /// Login gate: guests get the Google modal first, then the download runs.
  Future<void> _onDownloadTap(DocumentModel doc) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool loggedIn = AuthService.instance.isLoggedIn();

    if (!loggedIn) {
      if (!mounted) return;
      final bool signedIn = await GoogleSignInModal.show(context);
      if (!signedIn) return;
      // Re-fetch after authentication so private Storage files receive a
      // fresh, user-scoped Signed URL.
      await _refresh();
      final List<DocumentModel> refreshed = await _future;
      doc = refreshed.firstWhere(
        (DocumentModel item) => item.id == doc.id,
        orElse: () => doc,
      );
    }
    if (!mounted) return;
    await _startDownload(doc, l10n);
  }

  Future<void> _startDownload(DocumentModel doc, AppLocalizations l10n) async {
    final DownloadProvider downloads = context.read<DownloadProvider>();
    downloads.setProgress(doc.id, 0);

    final DownloadResult result = await DownloadService.instance.download(
      doc,
      onProgress: (double value) => downloads.setProgress(doc.id, value),
    );

    downloads.clearProgress(doc.id);
    if (!mounted) return;

    if (result.ok) {
      await downloads.bump(doc.id);
      if (!mounted) return;
      Helpers.showSnack(context, l10n.downloadDone);
    } else if (result.message == 'no-url') {
      Helpers.showSnack(context, l10n.downloadNotAvailable);
    } else {
      Helpers.showSnack(context, l10n.downloadFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String lang = context.watch<LanguageProvider>().code;
    final DownloadProvider downloads = context.watch<DownloadProvider>();
    final bool signedIn = AuthService.instance.isLoggedIn();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.documentsTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const TopNotificationBar(),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  const TintedIcon(AppAssets.iconConditions,
                      size: 30, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.downloadConditions,
                        style: theme.textTheme.bodySmall),
                  ),
                  if (!signedIn)
                    TextButton(
                      onPressed: () => GoogleSignInModal.show(context),
                      child: Text(l10n.signIn),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                onChanged: (String value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.search,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<DocumentModel>>(
                  future: _future,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<DocumentModel>> snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, __) =>
                            const LoadingSkeleton(height: 76, radius: 20),
                      );
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(28),
                        children: <Widget>[
                          const Icon(Icons.cloud_off_rounded, size: 44),
                          const SizedBox(height: 12),
                          Center(child: Text(l10n.errorNetwork)),
                          const SizedBox(height: 12),
                          Center(
                            child: FilledButton(
                              onPressed: _refresh,
                              child: Text(l10n.retry),
                            ),
                          ),
                        ],
                      );
                    }
                    final List<DocumentModel> items =
                        (snapshot.data ?? <DocumentModel>[])
                            .where((DocumentModel d) => d.matches(_query))
                            .toList();
                    if (items.isEmpty) {
                      return Center(child: Text(l10n.noResults));
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (BuildContext context, int index) {
                        final DocumentModel doc = items[index];
                        return DocumentCard(
                          document: doc,
                          languageCode: lang,
                          downloads: downloads.countFor(doc.id),
                          downloadsLabel: l10n.downloadsCount,
                          downloadLabel: l10n.download,
                          progress: downloads.progressFor(doc.id),
                          locked: !signedIn,
                          onDownload: () => _onDownloadTap(doc),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
