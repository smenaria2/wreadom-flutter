import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../../localization/generated/app_localizations.dart';
import '../../../utils/tier_utils.dart';

class LeaderboardInfoModal extends StatelessWidget {
  const LeaderboardInfoModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.aboutLeaderboardTiers,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.wreadomRankSystem,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: controller,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSectionHeader(context, l10n.howToEarnPoints),
                      _buildListItem(context, Icons.rate_review_outlined, l10n.publishChaptersPoints),
                      _buildListItem(context, Icons.chat_bubble_outline_rounded, l10n.receiveCommentsPoints),
                      _buildListItem(context, Icons.menu_book_outlined, l10n.readBooksPoints),
                      _buildListItem(context, Icons.comment_bank_outlined, l10n.postCommentsPoints),
                      
                      const SizedBox(height: 20),
                      _buildSectionHeader(context, l10n.tracksCalculations),
                      _buildListItem(context, Icons.swap_calls_rounded, '${l10n.authorStatus} / ${l10n.readerStatus}', l10n.tracksExplanation),
                      _buildListItem(context, Icons.history_toggle_off_rounded, l10n.leaderboard, l10n.periodsExplanation),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, l10n.tierProgressionLadder),
                      _buildTierList(context),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, IconData icon, String text, [String? description]) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: description != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<GlassTokens>() ?? GlassTokens.light;
    final l10n = AppLocalizations.of(context)!;
    
    final tierData = [
      {'tier': '1', 'range': '0 - 499 pts', 'icon': '🌱'},
      {'tier': '2', 'range': '500 - 4,999 pts', 'icon': '📚'},
      {'tier': '3', 'range': '5,000 - 24,999 pts', 'icon': '⭐'},
      {'tier': '4', 'range': '25,000 - 49,999 pts', 'icon': '🔥'},
      {'tier': '5', 'range': '50,000 - 99,999 pts', 'icon': '💎'},
      {'tier': '6', 'range': '100,000 - 499,999 pts', 'icon': '👑'},
      {'tier': '7', 'range': '500,000 - 999,999 pts', 'icon': '🌟'},
      {'tier': '8', 'range': '1,000,000+ pts', 'icon': '✨'},
    ];

    return Column(
      children: tierData.map((data) {
        final tierNum = int.parse(data['tier']!);
        final readerTitle = getLocalizedTierTitle(context, tierNum, 'reader');
        final authorTitle = getLocalizedTierTitle(context, tierNum, 'author');

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.borderColor),
          ),
          child: Row(
            children: [
              Text(data['icon']!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tier ${data['tier']}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary, fontSize: 13),
                        ),
                        Text(
                          data['range']!,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.readerStatus}: $readerTitle',
                      style: TextStyle(color: scheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${l10n.authorStatus}: $authorTitle',
                      style: TextStyle(color: scheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
