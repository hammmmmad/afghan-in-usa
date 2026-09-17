import 'package:flutter/material.dart';

import '../models/news_model.dart';
import '../theme/app_typography.dart';
import '../utils/constants.dart';

class NewsCard extends StatefulWidget {
  const NewsCard({
    super.key,
    required this.news,
    required this.languageCode,
    required this.readMoreLabel,
    required this.onTap,
    this.delayMs = 0,
  });

  final NewsModel news;
  final String languageCode;
  final String readMoreLabel;
  final VoidCallback onTap;
  final int delayMs;

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final NewsModel news = widget.news;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      opacity: _visible ? 1 : 0,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        curve: Curves.easeOut,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (news.image.isNotEmpty)
                  Stack(
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image(
                          image: news.isRemoteImage
                              ? NetworkImage(news.image)
                              : AssetImage(news.image) as ImageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            child: const Center(
                              child: Icon(Icons.newspaper_rounded, size: 40),
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: 10,
                        start: 10,
                        child: _Badge(
                          label: news.category.label(widget.languageCode),
                          color: AppColors.accent,
                        ),
                      ),
                      if (news.featured)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: const CircleAvatar(
                            radius: 17,
                            backgroundImage:
                                AssetImage(AppAssets.publishedNews),
                          ),
                        ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (news.image.isEmpty) ...<Widget>[
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            _Badge(
                              label: news.category.label(widget.languageCode),
                              color: AppColors.accent,
                            ),
                            Text(
                              news.localizedDate(widget.languageCode),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        news.localizedTitle(widget.languageCode),
                        style: AppTypography.newsTitle(
                            widget.languageCode, theme.colorScheme.onSurface),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news.localizedSummary(widget.languageCode),
                        style: AppTypography.newsBody(widget.languageCode,
                            theme.colorScheme.onSurface.withOpacity(0.78)),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 15,
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.12),
                            // Publisher identity is always the bundled,
                            // approved image; remote avatars are never used.
                            backgroundImage:
                                const AssetImage(AppAssets.creatorProfile),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  news.publisher.name,
                                  style: theme.textTheme.labelLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  news.localizedDate(widget.languageCode),
                                  style: theme.textTheme.labelSmall,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: widget.onTap,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            label: Text(widget.readMoreLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
