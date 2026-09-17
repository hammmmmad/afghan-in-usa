import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/case_model.dart';
import '../models/news_model.dart';
import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/case_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/notification_bell.dart';
import '../widgets/tinted_icon.dart';
import 'news_detail_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.summary});

  final CaseSummary summary;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late Future<CaseModel> _future;
  late Future<List<NewsModel>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.fetchCase(widget.summary.id);
    _newsFuture = ApiService.instance.fetchNewsForCase(widget.summary.id);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String lang = context.watch<LanguageProvider>().code;
    final NotificationProvider notifications =
        context.watch<NotificationProvider>();
    final ThemeData theme = Theme.of(context);
    final Color color = Helpers.parseHex(widget.summary.colorHex);
    final bool following = notifications.isFollowing(widget.summary.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.fromSTEB(56, 0, 56, 16),
              title: Text(
                widget.summary.localizedName(lang),
                style:
                    theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[color, color.withOpacity(0.55)],
                  ),
                ),
                child: Align(
                  alignment: const Alignment(0, -0.35),
                  child: Icon(caseIconFor(widget.summary.icon),
                      size: 62, color: Colors.white.withOpacity(0.9)),
                ),
              ),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 8),
                child: NotificationBell(
                  active: following,
                  size: 20,
                  onTap: () async {
                    final bool on = await context
                        .read<NotificationProvider>()
                        .toggleBell(widget.summary.id);
                    if (!context.mounted) return;
                    Helpers.showSnack(
                        context, on ? l10n.followOn : l10n.followOff);
                  },
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<CaseModel>(
              future: _future,
              builder:
                  (BuildContext context, AsyncSnapshot<CaseModel> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      children: <Widget>[
                        LoadingSkeleton(height: 70),
                        SizedBox(height: 14),
                        LoadingSkeleton(height: 70),
                        SizedBox(height: 14),
                        LoadingSkeleton(height: 70),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(child: Text(l10n.errorGeneric)),
                  );
                }

                final CaseModel model = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(model.localizedTitle(lang),
                          style: theme.textTheme.titleLarge),
                      if (model.localizedDescription(lang).isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(model.localizedDescription(lang),
                            style: theme.textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          const TintedIcon(AppAssets.iconSteps,
                              size: 22, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.caseGuide} · ${Helpers.localizedNumber(lang, model.steps.length)} ${l10n.stepsCount}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _Timeline(model: model, lang: lang, color: color),
                      if (model.notes.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 22),
                        Text(l10n.caseNotes, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 10),
                        for (final CaseNote note in model.notes)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ExpansionTile(
                              shape: const Border(),
                              collapsedShape: const Border(),
                              leading:
                                  const Icon(Icons.lightbulb_outline_rounded),
                              title: Text(
                                note.localizedTitle(lang).isEmpty
                                    ? l10n.caseNotes
                                    : note.localizedTitle(lang),
                                style: theme.textTheme.titleMedium,
                              ),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 14),
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(note.localizedBody(lang),
                                    style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 18),
                      FutureBuilder<List<NewsModel>>(
                        future: _newsFuture,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<NewsModel>> snap) {
                          final List<NewsModel> related =
                              snap.data ?? <NewsModel>[];
                          if (related.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(l10n.caseNews,
                                  style: theme.textTheme.titleLarge),
                              const SizedBox(height: 8),
                              for (final NewsModel item in related)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.article_outlined),
                                  title: Text(item.localizedTitle(lang),
                                      maxLines: 2,
                                      style: theme.textTheme.titleMedium),
                                  subtitle: Text(item.localizedDate(lang)),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          NewsDetailScreen(news: item),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(l10n.disclaimer,
                                  style: theme.textTheme.bodySmall),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical step timeline with a connector line and numbered bullets.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.model,
    required this.lang,
    required this.color,
  });

  final CaseModel model;
  final String lang;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        for (int i = 0; i < model.steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          Helpers.localizedNumber(lang, i + 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (i != model.steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: color.withOpacity(0.25),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          model.steps[i].localizedTitle(lang),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          model.steps[i].localizedBody(lang),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
