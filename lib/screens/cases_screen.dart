import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/case_model.dart';
import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/case_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/tinted_icon.dart';
import '../widgets/top_notification_bar.dart';
import 'case_detail_screen.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<CaseSummary>> _future;
  String _query = '';
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.fetchCases();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String lang = context.watch<LanguageProvider>().code;
    final NotificationProvider notifications =
        context.watch<NotificationProvider>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.navCases),
        bottom: TabBar(
          controller: _tabs,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: <Widget>[
            Tab(text: l10n.casesAfghan),
            Tab(text: l10n.casesIranian),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: <Widget>[
          _buildList(context, 'afghan', l10n, lang, notifications, theme),
          _buildList(context, 'iranian', l10n, lang, notifications, theme),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    String kind,
    AppLocalizations l10n,
    String lang,
    NotificationProvider notifications,
    ThemeData theme,
  ) {
    return Column(
      children: <Widget>[
        const TopNotificationBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: <Widget>[
              const TintedIcon(AppAssets.iconGuide,
                  size: 30, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child:
                    Text(l10n.followHint, style: theme.textTheme.bodySmall),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: TextField(
            onChanged: (String value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: l10n.search,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<CaseSummary>>(
            future: _future,
            builder: (BuildContext context,
                AsyncSnapshot<List<CaseSummary>> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, __) =>
                      const LoadingSkeleton(height: 86, radius: 20),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text(l10n.errorGeneric));
              }

              final List<CaseSummary> all = snapshot.data ?? <CaseSummary>[];
              // The two sections never mix: each tab shows only its kind.
              final List<CaseSummary> items = all
                  .where((CaseSummary c) => c.kind == kind)
                  .where((CaseSummary c) {
                if (_query.trim().isEmpty) return true;
                final String q = _query.toLowerCase().trim();
                return c.name.values
                    .any((Object? v) => v.toString().toLowerCase().contains(q));
              }).toList();

              if (items.isEmpty) {
                return Center(child: Text(l10n.noResults));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (BuildContext context, int index) {
                  final CaseSummary summary = items[index];
                  return CaseCard(
                    summary: summary,
                    languageCode: lang,
                    following: notifications.isFollowing(summary.id),
                    stepsLabel: l10n.stepsCount,
                    delayMs: (index % 6) * 70,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CaseDetailScreen(summary: summary),
                      ),
                    ),
                    onBellTap: () async {
                      final bool on = await context
                          .read<NotificationProvider>()
                          .toggleBell(summary.id);
                      if (!context.mounted) return;
                      Helpers.showSnack(
                          context, on ? l10n.followOn : l10n.followOff);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
