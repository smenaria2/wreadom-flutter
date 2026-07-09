import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../../domain/models/user_model.dart';
import '../../../utils/tier_utils.dart';
import '../../providers/navigation_providers.dart';
import '../../../localization/generated/app_localizations.dart';

class WriterRankCard extends ConsumerWidget {
  const WriterRankCard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final authorPoints = user.authorPoints ?? 0;
    final readerPoints = user.readerPoints ?? 0;
    final authorTier = getTierInfo(authorPoints, 'author');
    final readerTier = getTierInfo(readerPoints, 'reader');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Drop down to column on small phones (<500dp)
        final useVerticalLayout = constraints.maxWidth < 500;

        return Column(
          children: [
            if (useVerticalLayout) ...[
              _buildTrackProgressCard(
                context,
                title: l10n.authorStatus,
                icon: '🖋️',
                rank: user.authorRank,
                points: authorPoints,
                tier: authorTier,
                cheatsheet: [l10n.publishChaptersPoints, l10n.receiveCommentsPoints],
                category: 'author',
              ),
              const SizedBox(height: 10),
              _buildTrackProgressCard(
                context,
                title: l10n.readerStatus,
                icon: '📖',
                rank: user.readerRank,
                points: readerPoints,
                tier: readerTier,
                cheatsheet: [l10n.readBooksPoints, l10n.postCommentsPoints],
                category: 'reader',
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTrackProgressCard(
                      context,
                      title: l10n.authorStatus,
                      icon: '🖋️',
                      rank: user.authorRank,
                      points: authorPoints,
                      tier: authorTier,
                      cheatsheet: [l10n.publishChaptersPoints, l10n.receiveCommentsPoints],
                      category: 'author',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTrackProgressCard(
                      context,
                      title: l10n.readerStatus,
                      icon: '📖',
                      rank: user.readerRank,
                      points: readerPoints,
                      tier: readerTier,
                      cheatsheet: [l10n.readBooksPoints, l10n.postCommentsPoints],
                      category: 'reader',
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            _buildLeaderboardShortcut(context, ref, theme, scheme, l10n),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardShortcut(BuildContext context, WidgetRef ref, ThemeData theme, ColorScheme scheme, AppLocalizations l10n) {
    return GlassSurface(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(profileTabIndexProvider.notifier).setIndex(6);
        ref.read(selectedTabProvider.notifier).setTab(4);
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

  Widget _buildTrackProgressCard(
    BuildContext context, {
    required String title,
    required String icon,
    required int? rank,
    required int points,
    required TierInfo tier,
    required List<String> cheatsheet,
    required String category,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<GlassTokens>() ?? GlassTokens.light;
    final l10n = AppLocalizations.of(context)!;

    return GlassSurface(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: tokens.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(icon, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              rank != null ? 'Rank #$rank' : 'Rank #--',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            Text(
              '$points PTS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: tier.gradient,
                borderRadius: BorderRadius.circular(12),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Custom Animated Progress Indicator
            AnimatedProgressBar(progress: tier.progressPercent / 100),
            
            const SizedBox(height: 4),
            Text(
              tier.pointsToNext != null
                  ? l10n.ptsToNextTier(tier.pointsToNext!)
                  : l10n.maxLevelReached,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 8,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            ...cheatsheet.map((text) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: scheme.primary, fontSize: 8)),
                    Expanded(
                      child: Text(
                        text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 9,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Custom Implicitly Animated Linear Indicator ──────────────────────────────

class AnimatedProgressBar extends StatelessWidget {
  final double progress; // Range 0.0 to 1.0

  const AnimatedProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedVal, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: animatedVal,
            backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            minHeight: 5,
          ),
        );
      },
    );
  }
}
