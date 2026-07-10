import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/user_model.dart';
import '../../../utils/tier_utils.dart';
import '../../../localization/generated/app_localizations.dart';
import '../../routing/app_routes.dart';
import '../../routing/app_router.dart';
import '../../widgets/glass_surface.dart';
import '../../theme/app_theme.dart';

class PremiumRanksWidget extends StatelessWidget {
  final UserModel user;

  const PremiumRanksWidget({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final readerPoints = user.readerPoints ?? 0;
    final authorPoints = user.authorPoints ?? 0;
    final readerTier = getTierInfo(readerPoints, 'reader');
    final authorTier = getTierInfo(authorPoints, 'author');

    final displayName = user.displayName ?? user.penName ?? user.username;

    return Row(
      children: [
        // Writer Rank Card
        Expanded(
          child: _RankCard(
            title: l10n.authors.replaceAll('s', ''), // "Author" or "Writer"
            rank: user.authorRank,
            icon: '🖋️',
            points: authorPoints,
            tier: authorTier,
            category: 'author',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pushNamed(
                AppRoutes.leaderboard,
                arguments: LeaderboardScreenArguments(
                  initialCategory: 'author',
                  targetUserId: user.id,
                  targetUserPoints: authorPoints,
                  targetUserRank: user.authorRank,
                  targetUserReaderPoints: readerPoints,
                  targetUserReaderRank: user.readerRank,
                  targetUserDisplayName: displayName,
                  targetUserPhotoUrl: user.photoURL,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        // Reader Rank Card
        Expanded(
          child: _RankCard(
            title: l10n.readers.replaceAll('s', ''), // "Reader"
            rank: user.readerRank,
            icon: '📖',
            points: readerPoints,
            tier: readerTier,
            category: 'reader',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pushNamed(
                AppRoutes.leaderboard,
                arguments: LeaderboardScreenArguments(
                  initialCategory: 'reader',
                  targetUserId: user.id,
                  targetUserPoints: authorPoints,
                  targetUserRank: user.authorRank,
                  targetUserReaderPoints: readerPoints,
                  targetUserReaderRank: user.readerRank,
                  targetUserDisplayName: displayName,
                  targetUserPhotoUrl: user.photoURL,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  final String title;
  final int? rank;
  final String icon;
  final int points;
  final TierInfo tier;
  final String category;
  final VoidCallback onTap;

  const _RankCard({
    required this.title,
    required this.rank,
    required this.icon,
    required this.points,
    required this.tier,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<GlassTokens>() ?? GlassTokens.light;

    final hasRank = rank != null;

    return GlassSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: tokens.borderColor),
          gradient: LinearGradient(
            colors: [
              tier.gradient.colors.first.withValues(alpha: 0.08),
              tier.gradient.colors.last.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Subtle glowing accent dot in top corner
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: tier.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: tier.gradient.colors.first.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      '$title Rank'.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      hasRank ? '$rank' : '--',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (hasRank) ...[
                      const SizedBox(width: 4),
                      Text(
                        'PLACE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tier.icon, style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          getLocalizedTierTitle(context, tier.tier, category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
