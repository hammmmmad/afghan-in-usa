import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Modal shown when a signed-out user taps a download.
class GoogleSignInModal extends StatelessWidget {
  const GoogleSignInModal({super.key, this.onSignInSuccess});

  final VoidCallback? onSignInSuccess;

  static Future<bool> show(BuildContext context,
      {VoidCallback? onSignInSuccess}) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => GoogleSignInModal(onSignInSuccess: onSignInSuccess),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthProvider auth = context.watch<AuthProvider>();
    final ThemeData theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Image.asset(AppAssets.iconConditions,
                  width: 44,
                  height: 44,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.lock_outline_rounded, size: 40)),
            ),
            const SizedBox(height: 16),
            Text(l10n.signInTitle,
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.signInBody,
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: auth.busy
                    ? null
                    : () async {
                        final bool ok =
                            await context.read<AuthProvider>().signIn();
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.of(context).pop(true);
                          onSignInSuccess?.call();
                        } else {
                          Helpers.showSnack(context, l10n.signInFailed);
                        }
                      },
                icon: auth.busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.account_circle_rounded),
                label: Text(l10n.signInGoogle),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
