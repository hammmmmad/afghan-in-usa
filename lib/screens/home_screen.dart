import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/news_model.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/news_card.dart';
import '../widgets/top_notification_bar.dart';
import 'news_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  final List<NewsModel> _items = <NewsModel>[];
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String _query = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final double threshold = _scroll.position.maxScrollExtent - 320;
    if (_scroll.position.pixels >= threshold) _loadMore();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = '';
      _page = 0;
      _hasMore = true;
      _items.clear();
    });
    try {
      final List<NewsModel> first =
          await ApiService.instance.fetchNewsPage(page: 0, query: _query);
      if (!mounted) return;
      setState(() {
        _items.addAll(first);
        _loading = false;
        _hasMore = first.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    final List<NewsModel> next =
        await ApiService.instance.fetchNewsPage(page: _page + 1, query: _query);
    if (!mounted) return;
    setState(() {
      _page += 1;
      _items.addAll(next);
      _hasMore = next.isNotEmpty;
      _loadingMore = false;
    });
  }

  void _onSearchChanged(String value) {
    _query = value;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String lang = context.watch<LanguageProvider>().code;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipOval(
              child: Image.asset(
                AppAssets.appLogo,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 9),
            Text(l10n.appName),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const TopNotificationBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _search,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchNewsHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            _onSearchChanged('');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ApiService.instance.fetchNews(force: true);
                  await _reload();
                },
                child: _buildBody(l10n, lang, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, String lang, ThemeData theme) {
    if (_loading) return const NewsSkeletonList();

    if (_error.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(28),
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, size: 44),
          const SizedBox(height: 12),
          Center(
              child:
                  Text(l10n.errorGeneric, style: theme.textTheme.titleMedium)),
          if (kDebugMode) ...<Widget>[
            const SizedBox(height: 8),
            SelectableText(_error,
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          Center(
            child: FilledButton(onPressed: _reload, child: Text(l10n.retry)),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(28),
        children: <Widget>[
          const SizedBox(height: 40),
          Icon(Icons.search_off_rounded,
              size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Center(
              child: Text(l10n.noResults, style: theme.textTheme.titleMedium)),
        ],
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
      itemCount: _items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int index) {
        if (index == _items.length) {
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox(height: 8);
        }
        final NewsModel news = _items[index];
        return NewsCard(
          news: news,
          languageCode: lang,
          readMoreLabel: l10n.readMore,
          delayMs: (index % 4) * 90,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => NewsDetailScreen(news: news),
            ),
          ),
        );
      },
    );
  }
}
