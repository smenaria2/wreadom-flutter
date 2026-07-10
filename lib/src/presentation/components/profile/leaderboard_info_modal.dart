import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/glass_surface.dart';
import '../../../localization/generated/app_localizations.dart';
import '../../providers/auth_providers.dart';
import 'tier_ladder_widget.dart';

class LeaderboardInfoModal extends ConsumerWidget {
  const LeaderboardInfoModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    
    final user = ref.watch(currentUserProvider).value;
    final readerPoints = user?.readerPoints ?? 0;
    final authorPoints = user?.authorPoints ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return GlassSurface(
          strong: true,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.wreadomRankSystem,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: controller,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Concise explanation
                      _buildExplanationCard(context, l10n),
                      
                      const SizedBox(height: 24),
                      
                      // Interactive Tier Ladder
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          l10n.tierProgressionLadder,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      TierLadderWidget(
                        readerPoints: readerPoints,
                        authorPoints: authorPoints,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExplanationCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.howToEarnPoints,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Points can be earned through engaging in activities such as reading books, writing stories or chapters, commenting on content, and getting reads from other users.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Earn points to level up your tiers, increase your ranks, and reach the top of the leaderboards!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
