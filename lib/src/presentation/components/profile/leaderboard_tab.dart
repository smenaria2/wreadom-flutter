import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/models/leaderboard_model.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../utils/tier_utils.dart';
import '../../../localization/generated/app_localizations.dart';
import 'leaderboard_info_modal.dart';

class LeaderboardTab extends StatefulWidget {
  final UserModel currentUser;
  final String initialCategory;
  final void Function(String userId) onUserClick;

  const LeaderboardTab({
    super.key,
    required this.currentUser,
    required this.onUserClick,
    this.initialCategory = 'reader',
  });

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  final _repository = LeaderboardRepository();

  String _period = 'total';
  late String _category;
  List<LeaderboardRank> _rankings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    final results = await _repository.fetchLeaderboard(
      period: _period,
      type: _category,
    );
    if (mounted) {
      setState(() {
        _rankings = results;
        _loading = false;
      });
    }
  }

  void _showInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LeaderboardInfoModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // ── Controls Header ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              // Custom Sliding Segment Selector
              GlassSegmentedControl(
                selectedValue: _category,
                options: {
                  'reader': '📖 ${l10n.readers}',
                  'author': '🖋️ ${l10n.authors}',
                },
                onChanged: (val) {
                  setState(() => _category = val);
                  _loadLeaderboard();
                },
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: GlassControlSurface(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      borderRadius: BorderRadius.circular(20),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _period,
                          isExpanded: true,
                          icon: Icon(
                            Icons.expand_more_rounded,
                            color: scheme.onSurfaceVariant,
                            size: 20,
                          ),
                          dropdownColor: theme.extension<GlassTokens>()?.strongSurfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurface,
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _period = val);
                              _loadLeaderboard();
                            }
                          },
                          items: [
                            DropdownMenuItem(
                              value: 'total',
                              child: Text('🏆  ${l10n.totalAllTime}'),
                            ),
                            DropdownMenuItem(
                              value: 'daily',
                              child: Text('☀️  ${l10n.daily}'),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text('📅  ${l10n.weekly}'),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('🗓️  ${l10n.monthly}'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _showInfoModal,
                    icon: const Icon(Icons.info_outline_rounded),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── List / Podium Area ──────────────────────────────────
        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: scheme.primary),
                )
              : _rankings.isEmpty
                  ? _buildEmptyState(context)
                  : CustomScrollView(
                      slivers: [
                        // Podium (ranks 1-3) with scale constraints
                        if (_rankings.length >= 3)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return _PodiumStrip(
                                    top3: _rankings.take(3).toList(),
                                    currentUserId: widget.currentUser.id,
                                    category: _category,
                                    width: constraints.maxWidth,
                                    onUserClick: widget.onUserClick,
                                  );
                                },
                              ),
                            ),
                          ),

                        // Ranks 4+ lists with staggered entry animations
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          sliver: SliverList.builder(
                            itemCount: _rankings.length > 3
                                ? _rankings.length - 3
                                : 0,
                            itemBuilder: (context, index) {
                              final entry = _rankings[index + 3];
                              final isMe =
                                  entry.userId == widget.currentUser.id;
                              return AnimatedEntrance(
                                index: index,
                                child: _RankingCard(
                                  entry: entry,
                                  isCurrentUser: isMe,
                                  category: _category,
                                  onTap: () => widget.onUserClick(entry.userId),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            l10n.noRankingsPeriod,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.startReadingAppear,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ── Custom Sliding Segment Switcher ──────────────────────────────────────────

class GlassSegmentedControl extends StatelessWidget {
  final String selectedValue;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const GlassSegmentedControl({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = options.keys.toList();
    final selectedIdx = keys.indexOf(selectedValue);

    return GlassControlSurface(
      borderRadius: BorderRadius.circular(28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / keys.length;
          return Stack(
            children: [
              // Fluid Background sliding pill
              AnimatedAlign(
                alignment: Alignment(
                  (selectedIdx / (keys.length - 1)) * 2 - 1,
                  0.0,
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: Container(
                  width: itemWidth,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.24),
                    ),
                  ),
                ),
              ),

              // Labels row
              Row(
                children: keys.map((key) {
                  final isSelected = key == selectedValue;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(key);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          options[key]!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Staggered Entrance Animator ──────────────────────────────────────────────

class AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final int index;

  const AnimatedEntrance({super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: (index * 40).clamp(0, 400));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, 20 * (1.0 - val)),
            child: child,
          ),
        );
      },
      child: FutureBuilder(
        future: Future.delayed(delay),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return child;
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Podium Strip ─────────────────────────────────────────────────────────────

class _PodiumStrip extends StatelessWidget {
  const _PodiumStrip({
    required this.top3,
    required this.currentUserId,
    required this.category,
    required this.width,
    required this.onUserClick,
  });

  final List<LeaderboardRank> top3;
  final String currentUserId;
  final String category;
  final double width;
  final void Function(String) onUserClick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final order = [top3[1], top3[0], top3[2]];
    final heights = [90.0, 120.0, 75.0];
    final medals = ['🥈', '🥇', '🥉'];
    final accentColors = [
      scheme.outlineVariant,
      scheme.tertiary,
      const Color(0xFFCD7F32),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final entry = order[i];
        final isMe = entry.userId == currentUserId;
        final sizeFactor = i == 1 ? 1.0 : 0.82;

        return Expanded(
          child: GestureDetector(
            onTap: () => onUserClick(entry.userId),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 60 * sizeFactor,
                      height: 60 * sizeFactor,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isMe ? scheme.primary : accentColors[i],
                          width: isMe ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColors[i].withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: entry.photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: entry.photoUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: scheme.primaryContainer,
                                child: Center(
                                  child: Text(
                                    entry.displayName.isNotEmpty
                                        ? entry.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: i == 1 ? 22 : 18,
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Text(medals[i], style: const TextStyle(fontSize: 14)),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isMe ? scheme.primary : scheme.onSurface,
                      ),
                ),
                Text(
                  '${entry.points} pts',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentColors[i],
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                ),

                const SizedBox(height: 6),

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: heights[i]),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, heightVal, child) {
                    return GlassSurface(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: heightVal,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColors[i].withValues(alpha: 0.15),
                              accentColors[i].withValues(alpha: 0.03),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '#${entry.rank}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: i == 1 ? 20 : 15,
                              color: accentColors[i],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Rank Card (4th place onwards) ────────────────────────────────────────────

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.entry,
    required this.isCurrentUser,
    required this.category,
    required this.onTap,
  });

  final LeaderboardRank entry;
  final bool isCurrentUser;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<GlassTokens>() ?? GlassTokens.light;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: isCurrentUser
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.60),
                    width: 1.5,
                  ),
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.borderColor),
                ),
                child: Center(
                  child: Text(
                    '${entry.rank}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser
                        ? scheme.primary.withValues(alpha: 0.5)
                        : tokens.borderColor,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: entry.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: entry.photoUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: scheme.primaryContainer,
                          child: Center(
                            child: Text(
                              entry.displayName.isNotEmpty
                                  ? entry.displayName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onPrimaryContainer),
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.you,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                                fontSize: 8,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Builder(builder: (context) {
                      final tier = getTierInfo(entry.points, category);
                      return Row(
                        children: [
                          Text(tier.icon, style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            getLocalizedTierTitle(context, tier.tier, category).toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.points}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    'PTS',
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
      ),
    );
  }
}
