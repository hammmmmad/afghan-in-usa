import 'package:flutter/material.dart';

import '../models/case_model.dart';
import '../utils/helpers.dart';
import 'fade_in_up.dart';
import 'notification_bell.dart';

/// Maps the icon key stored in `assets/cases/index.json` to a Material glyph.
IconData caseIconFor(String key) {
  switch (key) {
    case 'shield':
      return Icons.verified_user_outlined;
    case 'airplane':
      return Icons.flight_takeoff_rounded;
    case 'family':
      return Icons.family_restroom_rounded;
    case 'heart':
      return Icons.volunteer_activism_outlined;
    case 'refresh':
      return Icons.autorenew_rounded;
    case 'diamond':
      return Icons.diamond_outlined;
    case 'handshake':
      return Icons.handshake_outlined;
    case 'card':
      return Icons.badge_outlined;
    case 'ring':
      return Icons.favorite_border_rounded;
    case 'rings':
      return Icons.favorite_rounded;
    case 'scale':
      return Icons.balance_rounded;
    case 'school':
      return Icons.school_outlined;
    default:
      return Icons.folder_copy_outlined;
  }
}

class CaseCard extends StatelessWidget {
  const CaseCard({
    super.key,
    required this.summary,
    required this.languageCode,
    required this.following,
    required this.stepsLabel,
    required this.onTap,
    required this.onBellTap,
    this.delayMs = 0,
  });

  final CaseSummary summary;
  final String languageCode;
  final bool following;
  final String stepsLabel;
  final VoidCallback onTap;
  final VoidCallback onBellTap;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = Helpers.parseHex(summary.colorHex);

    return FadeInUp(
      delayMs: delayMs,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 10, 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        color.withOpacity(0.9),
                        color.withOpacity(0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: color.withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(caseIconFor(summary.icon),
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        summary.localizedName(languageCode),
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.localizedSubtitle(languageCode),
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(Icons.timeline_rounded, size: 15, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '${Helpers.localizedNumber(languageCode, summary.stepCount)} $stepsLabel',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: color),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                NotificationBell(active: following, onTap: onBellTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
