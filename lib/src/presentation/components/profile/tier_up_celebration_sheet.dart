import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/models/user_model.dart';
import '../../../localization/generated/app_localizations.dart';
import '../../../utils/app_haptics.dart';
import '../../../utils/tier_utils.dart';
import '../../providers/tier_progress_provider.dart';
import '../../routing/app_router.dart';
import '../../routing/app_routes.dart';

Future<void> showTierUpCelebration(
  BuildContext context, {
  required UserModel user,
  required TierPromotion promotion,
}) async {
  if (promotion.isEmpty || !context.mounted) return;
  unawaited(AppHaptics.medium());
  final primaryTrack = promotion.tiers.keys.first;
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _TierUpCelebrationContent(
      promotion: promotion,
      onViewLeaderboard: () {
        Navigator.of(sheetContext).pop();
        Navigator.of(context).pushNamed(
          AppRoutes.leaderboard,
          arguments: LeaderboardScreenArguments(
            initialCategory: primaryTrack.value,
            initialPeriod: 'total',
            targetUserId: user.id,
            targetUserPoints: user.authorPoints,
            targetUserRank: user.authorRank,
            targetUserReaderPoints: user.readerPoints,
            targetUserReaderRank: user.readerRank,
            targetUserDisplayName:
                user.displayName ?? user.penName ?? user.username,
            targetUserPhotoUrl: user.photoURL,
          ),
        );
      },
    ),
  );
}

class _TierUpCelebrationContent extends StatelessWidget {
  const _TierUpCelebrationContent({
    required this.promotion,
    required this.onViewLeaderboard,
  });

  final TierPromotion promotion;
  final VoidCallback onViewLeaderboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final entries = promotion.tiers.entries.toList();
    final lead = tierDefinitions[entries.first.value - 1];
    final gradient = lead.gradientFor(entries.first.key);

    return Semantics(
      namesRoute: true,
      label: l10n.tierUpTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.35),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Text(
                lead.iconFor(entries.first.key),
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.tierUpTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.tierUpBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) {
              final definition = tierDefinitions[entry.value - 1];
              final trackLabel = entry.key == RankTrack.author
                  ? l10n.authors
                  : l10n.readers;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${definition.iconFor(entry.key)} $trackLabel · ${l10n.tierLabel} ${entry.value} · ${localizedTierTitle(context, entry.value, entry.key)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onViewLeaderboard,
                icon: const Icon(Icons.leaderboard_rounded),
                label: Text(l10n.viewLeaderboard),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.dismiss),
            ),
          ],
        ),
      ),
    );
  }
}
