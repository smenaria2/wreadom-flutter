import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../../domain/models/user_model.dart';
import '../../../utils/tier_utils.dart';
import '../../../localization/generated/app_localizations.dart';
import '../../routing/app_routes.dart';
import '../../routing/app_router.dart';

class WriterRankCard extends ConsumerWidget {
  const WriterRankCard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tokens = theme.extension<GlassTokens>() ?? GlassTokens.light;

    final authorPoints = user.authorPoints ?? 0;
    final authorTier = getTierInfo(authorPoints, 'author');
    final rank = user.authorRank;

    return Column(
      children: [
        GlassSurface(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: tokens.borderColor),
              gradient: LinearGradient(
                colors: [
                  authorTier.gradient.colors.first.withValues(alpha: 0.1),
                  authorTier.gradient.colors.last.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Glowing Tier Badge Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: authorTier.gradient,
                    boxShadow: [
                      BoxShadow(
                        color: authorTier.gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      authorTier.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title, Tier, Points & Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.authorStatus.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•  $authorPoints PTS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        getLocalizedTierTitle(context, authorTier.tier, 'author'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedProgressBar(
                              progress: authorTier.progressPercent / 100,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            authorTier.pointsToNext != null
                                ? '${authorTier.pointsToNext} pts left'
                                : 'Max Level',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Compact Rank Info (Without '#' prefix)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rank != null ? '$rank' : '--',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'RANK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLeaderboardShortcut(context, ref, theme, scheme, l10n),
      ],
    );
  }

  Widget _buildLeaderboardShortcut(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme scheme,
    AppLocalizations l10n,
  ) {
    return GlassSurface(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pushNamed(
          AppRoutes.leaderboard,
          arguments: LeaderboardScreenArguments(
            initialCategory: 'author',
            targetUserId: user.id,
            targetUserPoints: user.authorPoints ?? 0,
            targetUserRank: user.authorRank,
            targetUserReaderPoints: user.readerPoints ?? 0,
            targetUserReaderRank: user.readerRank,
            targetUserDisplayName: user.displayName ?? user.penName ?? user.username,
            targetUserPhotoUrl: user.photoURL,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  l10n.viewFullLeaderboard,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Animated ProgressBar ──────────────────────────────────────────────

class AnimatedProgressBar extends StatelessWidget {
  final double progress; // Range 0.0 to 1.0

  const AnimatedProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, animatedVal, child) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: animatedVal.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary,
                      scheme.tertiary,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
