import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/case_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';
import '../services/admin_gate.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/afghan_avatar_selector.dart';
import '../widgets/google_sign_in_modal.dart';
import '../widgets/tinted_icon.dart';
import 'admin_documents_screen.dart';
import 'admin_news_screen.dart';
import 'admin_notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  final TextEditingController _adminEmail = TextEditingController();
  final TextEditingController _adminPassword = TextEditingController();
  bool _adminBusy = false;

  @override
  void initState() {
    super.initState();
    final StorageService storage = StorageService.instance;
    final UserModel? user = storage.user;
    _firstName = TextEditingController(
        text: user?.firstName.isNotEmpty == true
            ? user!.firstName
            : storage.firstName);
    _lastName = TextEditingController(
        text: user?.lastName.isNotEmpty == true
            ? user!.lastName
            : storage.lastName);
    _phone = TextEditingController(
        text: user?.phone.isNotEmpty == true ? user!.phone : storage.phone);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String lang = context.watch<LanguageProvider>().code;
    final AuthProvider auth = context.watch<AuthProvider>();
    final NotificationProvider notifications =
        context.watch<NotificationProvider>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    const ProfileAvatar(radius: 46),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: AppColors.accent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => AfghanAvatarSelector.show(context),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(Icons.edit_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  auth.isLoggedIn ? auth.user!.fullName : l10n.guest,
                  style: theme.textTheme.titleLarge,
                ),
                if (auth.isLoggedIn)
                  Text(auth.user!.email, style: theme.textTheme.labelSmall),
                const SizedBox(height: 12),
                if (!auth.isLoggedIn)
                  FilledButton.icon(
                    onPressed: () => GoogleSignInModal.show(context),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(l10n.signInGoogle),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => context.read<AuthProvider>().signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(l10n.signOut),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _Section(
            title: l10n.profileTitle,
            iconAsset: AppAssets.iconSignUp,
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _firstName,
                  decoration: InputDecoration(labelText: l10n.firstName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastName,
                  decoration: InputDecoration(labelText: l10n.lastName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.phone),
                ),
                if (auth.isLoggedIn) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: auth.user!.email),
                    decoration: InputDecoration(labelText: l10n.email),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().saveProfile(
                            firstName: _firstName.text.trim(),
                            lastName: _lastName.text.trim(),
                            phone: _phone.text.trim(),
                          );
                      if (!context.mounted) return;
                      Helpers.showSnack(context, l10n.saved);
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Section(
            title: l10n.myCases,
            iconAsset: AppAssets.iconLatestEvent,
            child: FutureBuilder<List<CaseSummary>>(
              future: ApiService.instance.fetchCases(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<CaseSummary>> snapshot) {
                final List<CaseSummary> all = snapshot.data ?? <CaseSummary>[];
                final List<CaseSummary> followed = all
                    .where((CaseSummary c) => notifications.isFollowing(c.id))
                    .toList();
                if (followed.isEmpty) {
                  return Text(l10n.noFollowedCases,
                      style: theme.textTheme.bodyMedium);
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: followed
                      .map((CaseSummary c) => Chip(
                            avatar: const Icon(
                                Icons.notifications_active_rounded,
                                size: 16,
                                color: AppColors.bellOn),
                            label: Text(c.localizedName(lang)),
                          ))
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _Section(
            title: l10n.notifications,
            iconAsset: AppAssets.iconLatestEvent,
            child: notifications.items.isEmpty
                ? Text(l10n.noNotifications, style: theme.textTheme.bodyMedium)
                : Column(
                    children: notifications.items
                        .take(4)
                        .map((AppNotification n) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: Icon(
                                n.read
                                    ? Icons.mark_email_read_outlined
                                    : Icons.notifications_active_rounded,
                                color: n.read
                                    ? AppColors.inactive
                                    : AppColors.bellOn,
                              ),
                              title: Text(n.localizedTitle(lang), maxLines: 2),
                            ))
                        .toList(),
                  ),
          ),
          if (auth.isAdmin) ...<Widget>[
            const SizedBox(height: 18),
            _Section(
              title: 'پنل مدیر',
              iconAsset: AppAssets.iconDownload,
              child: AdminGate.instance.unlocked
                  ? Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminNewsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.newspaper_rounded),
                      label: const Text('مدیریت اخبار'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminNotificationsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('ارسال اعلان'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminDocumentsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.admin_panel_settings_rounded),
                      label: const Text('بارگذاری و انتشار فایل'),
                    ),
                  ),
                ],
              )
                  : _buildAdminUnlock(),
            ),
          ],
        ],
      ),
    );
  }

  /// Email+password gate for the admin panel (independent of the Google
  /// session): regular users can never open it, and the unlock expires.
  Widget _buildAdminUnlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'برای استفاده از پنل مدیر، ایمیل و رمز مدیر را وارد کنید.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _adminEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'ایمیل مدیر',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _adminPassword,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'رمز مدیر',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _adminBusy
              ? null
              : () async {
                  setState(() => _adminBusy = true);
                  final String? error = await AdminGate.instance.unlock(
                    _adminEmail.text,
                    _adminPassword.text,
                  );
                  if (!mounted) return;
                  setState(() => _adminBusy = false);
                  if (error != null) {
                    Helpers.showSnack(context, error);
                  } else {
                    _adminPassword.clear();
                    Helpers.showSnack(context, 'پنل مدیر باز شد.');
                  }
                },
          icon: _adminBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.lock_open_rounded),
          label: const Text('باز کردن پنل مدیر'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    required this.iconAsset,
  });

  final String title;
  final Widget child;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                TintedIcon(iconAsset, size: 24, color: AppColors.primary),
                const SizedBox(width: 8),
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
