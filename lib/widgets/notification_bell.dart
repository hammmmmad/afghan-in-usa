import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Bell that turns green when the user follows a case.
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.active,
    required this.onTap,
    this.size = 22,
    this.tooltip,
  });

  final bool active;
  final VoidCallback onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color onColor = dark ? AppColors.bellOnDark : AppColors.bellOn;
    final Color color = active ? onColor : AppColors.inactive;

    final Widget bell = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      padding: EdgeInsets.all(size * 0.36),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(active ? 0.16 : 0.10),
        border: Border.all(color: color.withOpacity(active ? 0.7 : 0.25)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (Widget child, Animation<double> animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          active
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          key: ValueKey<bool>(active),
          size: size,
          color: color,
        ),
      ),
    );

    return Tooltip(
      message: tooltip ?? '',
      child: InkResponse(
        onTap: onTap,
        radius: size * 1.6,
        child: bell,
      ),
    );
  }
}
