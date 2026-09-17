import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/news_model.dart';
import '../providers/language_provider.dart';
import '../theme/app_typography.dart';
import '../utils/constants.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.news});

  final NewsModel news;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String lang = context.watch<LanguageProvider>().code;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: news.image.isEmpty ? 0 : 240,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            actions: <Widget>[
              IconButton(
                tooltip: l10n.shareApp,
                onPressed: () => Share.share(
                  '${news.localizedTitle(lang)}\n\n${news.localizedContent(lang).join('\n\n')}\n\n${AppConfig.shareMessage}',
                  subject: l10n.shareSubject,
                ),
                icon: const Icon(Icons.share_rounded),
              ),
            ],
            flexibleSpace: news.image.isEmpty
                ? null
                : FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Image(
                          image: news.isRemoteImage
                              ? NetworkImage(news.image)
                              : AssetImage(news.image) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.black54,
                                Colors.transparent
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      Chip(label: Text(news.category.label(lang))),
                      Chip(
                        avatar:
                            const Icon(Icons.calendar_today_rounded, size: 15),
                        label: Text(news.localizedDate(lang)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(news.localizedTitle(lang),
                      style: AppTypography.newsTitle(
                          lang, theme.colorScheme.onSurface)),
                  const SizedBox(height: 10),
                  Directionality(
                    textDirection:
                        lang == 'en' ? TextDirection.ltr : TextDirection.rtl,
                    child: Row(
                      children: <Widget>[
                        const CircleAvatar(
                          radius: 16,
                          backgroundImage: AssetImage(AppAssets.creatorProfile),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lang == 'en'
                              ? 'Published by: Sarfraz Khamoosh'
                              : 'منتشر شده توسط: Sarfraz Khamoosh',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 28),
                  for (final String paragraph
                      in news.localizedContent(lang)) ...<Widget>[
                    Text(paragraph,
                        style: AppTypography.newsBody(
                            lang, theme.colorScheme.onSurface)),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 10),
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
            ),
          ),
        ],
      ),
    );
  }
}
