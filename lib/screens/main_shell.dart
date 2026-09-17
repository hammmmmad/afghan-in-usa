import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';
import '../widgets/curved_bottom_nav_bar.dart';
import 'cases_screen.dart';
import 'documents_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Hosts the five tabs and keeps their state alive between switches.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  final List<Widget> _pages = const <Widget>[
    HomeScreen(),
    CasesScreen(),
    DocumentsScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<NavItemData> items = <NavItemData>[
      NavItemData(asset: AppAssets.navHome, label: l10n.navHome),
      NavItemData(asset: AppAssets.navCases, label: l10n.navCases),
      NavItemData(asset: AppAssets.navDocuments, label: l10n.navDocuments),
      NavItemData(asset: AppAssets.navProfile, label: l10n.navProfile),
      NavItemData(asset: AppAssets.navSettings, label: l10n.navSettings),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: CurvedBottomNavBar(
        items: items,
        currentIndex: _index,
        onTap: (int index) => setState(() => _index = index),
      ),
    );
  }
}
