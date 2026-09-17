import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/calculator_widget.dart';
import '../widgets/top_notification_bar.dart';
import '../widgets/weather_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final LanguageProvider language = context.watch<LanguageProvider>();
    final ThemeData theme = Theme.of(context);
    final bool dark = themeProvider.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
        children: <Widget>[
          const TopNotificationBar(),

          // â”€â”€ appearance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _Tile(
            iconAsset: dark ? AppAssets.iconModeNight : AppAssets.iconModeDay,
            title: dark ? l10n.darkMode : l10n.lightMode,
            trailing: Switch.adaptive(
              value: dark,
              onChanged: (_) => context.read<ThemeProvider>().toggle(context),
            ),
            onTap: () => context.read<ThemeProvider>().toggle(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.wb_sunny_rounded, size: 18),
                  label: Text(l10n.lightMode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.nightlight_round, size: 18),
                  label: Text(l10n.darkMode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                  label: Text(l10n.themeSystem),
                ),
              ],
              selected: <ThemeMode>{themeProvider.mode},
              onSelectionChanged: (Set<ThemeMode> selection) =>
                  context.read<ThemeProvider>().setMode(selection.first),
            ),
          ),

          // â”€â”€ language â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _Card(
            iconAsset: AppAssets.iconLanguage,
            title: l10n.language,
            child: Column(
              children: <Widget>[
                _LanguageRow(
                  label: l10n.languageDari,
                  code: 'fa',
                  native: 'پارسی',
                  selected: language.code == 'fa',
                ),
                _LanguageRow(
                  label: l10n.languageEnglish,
                  code: 'en',
                  native: 'English',
                  selected: language.code == 'en',
                ),
              ],
            ),
          ),

          // â”€â”€ weather â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _Card(
            iconAsset: AppAssets.iconWeather,
            title: l10n.weather,
            child: const WeatherWidget(),
          ),

          // â”€â”€ tools â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _Tile(
            iconAsset: AppAssets.iconCalculator,
            title: l10n.calculator,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => CalculatorWidget.show(context, language.code),
          ),
          _Tile(
            iconAsset: AppAssets.iconShare,
            title: l10n.shareApp,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Share.share(
              '${AppConfig.shareMessage}\n${AppConfig.storeUrl}',
              subject: l10n.shareSubject,
            ),
          ),

          // â”€â”€ developer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _Card(
            iconAsset: AppAssets.iconDeveloper,
            title: l10n.developer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      backgroundImage:
                          const AssetImage(AppAssets.creatorProfile),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(AppConfig.developerName,
                              style: theme.textTheme.titleMedium),
                          Text(l10n.appTagline,
                              style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(l10n.socialLinks, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConfig.socials
                      .map((SocialLink link) => ActionChip(
                            avatar: Icon(link.icon, size: 16),
                            label: Text(link.label),
                            onPressed: () async {
                              final String rawUrl = link.url.trim();
                              final Uri uri = Uri.parse(
                                rawUrl.startsWith('http://') ||
                                        rawUrl.startsWith('https://')
                                    ? rawUrl
                                    : 'https://$rawUrl',
                              );
                              final bool ok = await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                              if (!ok && context.mounted) {
                                Helpers.showSnack(context, l10n.linkFailed);
                              }
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // â”€â”€ about â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _Tile(
            iconAsset: AppAssets.iconVersion,
            title: l10n.appVersion,
            subtitle: language.code == 'en'
                ? AppConfig.version
                : Helpers.toFaDigits(AppConfig.version),
            trailing:
                const Icon(Icons.verified_rounded, color: AppColors.bellOn),
            onTap: null,
          ),
          _Card(
            iconAsset: AppAssets.iconGuide,
            title: l10n.about,
            child: Text(l10n.aboutBody, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.code,
    required this.native,
    required this.selected,
  });

  final String label;
  final String code;
  final String native;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: code,
      groupValue: selected ? code : '',
      contentPadding: EdgeInsets.zero,
      title: Text(native),
      subtitle: Text(label),
      onChanged: (_) => context.read<LanguageProvider>().setLanguage(code),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.iconAsset,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String iconAsset;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Image.asset(iconAsset,
            width: 34,
            height: 34,
            errorBuilder: (_, __, ___) => const Icon(Icons.settings_rounded)),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.iconAsset,
    required this.title,
    required this.child,
  });

  final String iconAsset;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Image.asset(iconAsset,
                    width: 30,
                    height: 30,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.tune_rounded)),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
