import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Grid of the bundled Afghan-style avatars.
class AfghanAvatarSelector extends StatelessWidget {
  const AfghanAvatarSelector({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AfghanAvatarSelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthProvider auth = context.watch<AuthProvider>();
    final List<String> avatars = AppAssets.avatars;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.face_retouching_natural_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.chooseAvatar,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: avatars.length,
                itemBuilder: (BuildContext context, int index) {
                  final String asset = avatars[index];
                  final bool selected = auth.avatarAsset == asset;
                  return GestureDetector(
                    onTap: () async {
                      await context.read<AuthProvider>().setAvatar(asset);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      Helpers.showSnack(context, l10n.avatarSaved);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              selected ? AppColors.accent : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.4),
                                  blurRadius: 12,
                                )
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          asset,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.15),
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person_rounded, size: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circle avatar that resolves: Google photo -> chosen asset -> initials.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.radius = 42});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final String? photo = auth.user?.photoUrl;
    final String asset = auth.avatarAsset;

    if (photo != null && photo.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(photo));
    }
    if (asset.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(asset),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.14),
      child: Icon(Icons.person_rounded, size: radius, color: AppColors.primary),
    );
  }
}
