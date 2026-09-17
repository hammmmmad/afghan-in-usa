import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Slim bar pinned under the AppBar once the user is signed in:
/// Google photo + name + bell with unread badge.
class TopNotificationBar extends StatelessWidget {
  const TopNotificationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final NotificationProvider notifications =
        context.watch<NotificationProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool visible = auth.isLoggedIn && !auth.topBarHidden;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: !visible
          ? const SizedBox(width: double.infinity, height: 0)
          : TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: -1, end: 0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, Widget? child) =>
                  Transform.translate(
                offset: Offset(0, value * 40),
                child:
                    Opacity(opacity: 1 + value.clamp(-1.0, 0.0), child: child),
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 6, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.primary.withOpacity(0.14),
                      AppColors.accent.withOpacity(0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: <Widget>[
                    _Avatar(user: auth.user, fallbackAsset: auth.avatarAsset),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l10n.welcomeBack,
                              style: theme.textTheme.labelSmall),
                          Text(
                            auth.user?.fullName ?? '',
                            style: theme.textTheme.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.notifications,
                      onPressed: () => showNotificationSheet(context),
                      icon: Badge(
                        isLabelVisible: notifications.unreadCount > 0,
                        label: Text(Helpers.localizedNumber(
                            l10n.languageCode, notifications.unreadCount)),
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.close,
                      onPressed: () =>
                          context.read<AuthProvider>().setTopBarHidden(true),
                      icon:
                          const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.fallbackAsset});

  final UserModel? user;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    if (user?.hasPhoto == true) {
      return CircleAvatar(
        radius: 19,
        backgroundImage: CachedNetworkImageProvider(user!.photoUrl),
      );
    }
    if (fallbackAsset.isNotEmpty) {
      return CircleAvatar(
          radius: 19, backgroundImage: AssetImage(fallbackAsset));
    }
    return CircleAvatar(
      radius: 19,
      backgroundColor: AppColors.primary.withOpacity(0.15),
      child: Text(Helpers.initials(user?.fullName)),
    );
  }
}

/// Bottom sheet with the notification list.
Future<void> showNotificationSheet(BuildContext context) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return Consumer<NotificationProvider>(
        builder: (BuildContext context, NotificationProvider provider, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.notifications_active_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l10n.notifications,
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      if (provider.items.isNotEmpty)
                        TextButton(
                          onPressed: provider.markAllRead,
                          child: Text(l10n.markAllRead),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (provider.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      child: Center(
                        child: Text(l10n.noNotifications,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: provider.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final AppNotification n = provider.items[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (n.read
                                        ? AppColors.inactive
                                        : AppColors.bellOn)
                                    .withOpacity(0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                n.read
                                    ? Icons.mark_email_read_outlined
                                    : Icons.notifications_active_rounded,
                                size: 20,
                                color: n.read
                                    ? AppColors.inactive
                                    : AppColors.bellOn,
                              ),
                            ),
                            title: Text(n.localizedTitle(l10n.languageCode),
                                maxLines: 2,
                                style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text(n.localizedBody(l10n.languageCode),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () => provider.markRead(n.id),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
