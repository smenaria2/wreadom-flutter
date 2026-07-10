import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/models/leaderboard_model.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../utils/tier_utils.dart';
import '../../../localization/generated/app_localizations.dart';
import 'leaderboard_info_modal.dart';

// ── Public Widget ─────────────────────────────────────────────────────────────

class LeaderboardTab extends StatefulWidget {
  final UserModel currentUser;
  final String initialCategory;
  final void Function(String userId) onUserClick;

  final String? targetUserId;
  // Author points/rank
  final int? targetUserPoints;
  final int? targetUserRank;
  // Reader points/rank (for the reader tab)
  final int? targetUserReaderPoints;
  final int? targetUserReaderRank;
  final String? targetUserDisplayName;
  final String? targetUserPhotoUrl;

  const LeaderboardTab({
    super.key,
    required this.currentUser,
    required this.onUserClick,
    this.initialCategory = 'author',
    this.targetUserId,
    this.targetUserPoints,
    this.targetUserRank,
    this.targetUserReaderPoints,
    this.targetUserReaderRank,
    this.targetUserDisplayName,
    this.targetUserPhotoUrl,
  });

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

// ── State ─────────────────────────────────────────────────────────────────────

class _LeaderboardTabState extends State<LeaderboardTab> {
  final _repository = LeaderboardRepository();
  final ScrollController _scrollController = ScrollController();

  String _period = 'monthly';
  late String _category;

  // The ranked list shown (always capped at 20)
  List<LeaderboardRank> _rankings = [];
  bool _loading = true;

  // Whether the target user card at the bottom was tapped
  String? _highlightedUserId;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _highlightedUserId = widget.targetUserId;
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // Returns the target user's points for the currently active category tab
  int? get _activeTargetPoints => _category == 'reader'
      ? widget.targetUserReaderPoints
      : widget.targetUserPoints;

  // Returns the target user's rank for the currently active category tab
  int? get _activeTargetRank =>
      _category == 'reader' ? widget.targetUserReaderRank : widget.targetUserRank;

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    final results = await _repository.fetchLeaderboard(
      period: _period,
      type: _category,
    );
    if (!mounted) return;

    // Always limit to 20 entries max
    final limited = results.take(20).toList();

    // Re-number displayed ranks sequentially (1…20) so that daily/weekly always
    // shows 1, 2, 3 … instead of whatever the backend rank field contains.
    final renumbered = limited.asMap().entries.map((e) {
      return LeaderboardRank(
        userId: e.value.userId,
        displayName: e.value.displayName,
        photoUrl: e.value.photoUrl,
        points: e.value.points,
        rank: e.key + 1, // 1-indexed position in the displayed list
      );
    }).toList();

    setState(() {
      _rankings = renumbered;
      _loading = false;
    });

    if (widget.targetUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTargetUser());
    }
  }

  void _scrollToTargetUser() {
    if (!_scrollController.hasClients) return;
    final targetIndex = _rankings.indexWhere((r) => r.userId == widget.targetUserId);

    final hasPodium = _rankings.length >= 3;
    double scrollOffset;

    if (targetIndex == -1) {
      // Target user is beyond the 20 shown → scroll to very bottom so the
      // pinned card at the end is visible
      scrollOffset = _scrollController.position.maxScrollExtent;
    } else {
      const double controlsHeight = 134.0;
      const double cardHeight = 76.0;
      if (hasPodium && targetIndex < 3) {
        scrollOffset = 0.0;
      } else {
        const double podiumHeight = 260.0;
        final listIndex = hasPodium ? targetIndex - 3 : targetIndex;
        scrollOffset = controlsHeight +
            (hasPodium ? podiumHeight : 0) +
            listIndex * cardHeight;
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (scrollOffset > maxScroll) scrollOffset = maxScroll;
    }

    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
    );
  }

  void _showInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LeaderboardInfoModal(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final targetInList = widget.targetUserId != null &&
        _rankings.any((r) => r.userId == widget.targetUserId);
    final showPinnedCard =
        widget.targetUserId != null && !targetInList && _activeTargetRank != null;

    // Podium: only when the first three renumbered ranks are 1, 2, 3
    final hasPodium = _rankings.length >= 3;

    return Column(
      children: [
        // ── Controls ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              GlassSegmentedControl(
                selectedValue: _category,
                options: {
                  'author': '🖋️ ${l10n.authors}',
                  'reader': '📖 ${l10n.readers}',
                },
                onChanged: (val) {
                  setState(() {
                    _category = val;
                    _highlightedUserId = widget.targetUserId;
                  });
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
                          icon: Icon(Icons.expand_more_rounded,
                              color: scheme.onSurfaceVariant, size: 20),
                          dropdownColor:
                              theme.extension<GlassTokens>()?.strongSurfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: scheme.onSurface),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _period = val);
                              _loadLeaderboard();
                            }
                          },
                          items: [
                            DropdownMenuItem(
                                value: 'monthly',
                                child: Text('🗓️  ${l10n.monthly}')),
                            DropdownMenuItem(
                                value: 'total',
                                child: Text('🏆  ${l10n.totalAllTime}')),
                            DropdownMenuItem(
                                value: 'daily',
                                child: Text('☀️  ${l10n.daily}')),
                            DropdownMenuItem(
                                value: 'weekly',
                                child: Text('📅  ${l10n.weekly}')),
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
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── List ──────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: scheme.primary))
              : _rankings.isEmpty
                  ? _buildEmptyState(context)
                  : CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Podium (renumbered 1-3)
                        if (hasPodium)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: LayoutBuilder(
                                builder: (ctx, constraints) => _PodiumStrip(
                                  top3: _rankings.take(3).toList(),
                                  currentUserId: widget.currentUser.id,
                                  highlightedUserId: _highlightedUserId,
                                  category: _category,
                                  width: constraints.maxWidth,
                                  onUserClick: widget.onUserClick,
                                  onBarTap: (uid) =>
                                      setState(() => _highlightedUserId = uid),
                                ),
                              ),
                            ),
                          ),

                        // Ranks 4-20 (or 1-20 if no podium)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                              16, 12, 16, showPinnedCard ? 8 : 24),
                          sliver: SliverList.builder(
                            itemCount: hasPodium
                                ? (_rankings.length > 3
                                    ? _rankings.length - 3
                                    : 0)
                                : _rankings.length,
                            itemBuilder: (ctx, index) {
                              final entry =
                                  _rankings[hasPodium ? index + 3 : index];
                              final isMe =
                                  entry.userId == widget.currentUser.id;
                              final isTarget =
                                  entry.userId == widget.targetUserId;
                              return AnimatedEntrance(
                                index: index,
                                child: _RankingCard(
                                  entry: entry,
                                  isCurrentUser: isMe,
                                  isTargetUser: isTarget,
                                  category: _category,
                                  onTap: () => widget.onUserClick(entry.userId),
                                ),
                              );
                            },
                          ),
                        ),

                        // Pinned target-user card at the BOTTOM of the list
                        // (only shown when the user's rank is beyond the 20 loaded)
                        if (showPinnedCard)
                          SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverToBoxAdapter(
                              child: _buildPinnedUserCard(
                                  context, scheme, theme, l10n),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  // ── Pinned user card (after rank 20) ──────────────────────────────────────

  Widget _buildPinnedUserCard(
    BuildContext context,
    ColorScheme scheme,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final points = _activeTargetPoints ?? 0;
    final rank = _activeTargetRank;
    final displayName = widget.targetUserDisplayName ?? 'User';
    final photoUrl = widget.targetUserPhotoUrl ?? '';
    final tier = getTierInfo(points, _category);
    final isMe = widget.targetUserId == widget.currentUser.id;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (_, val, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - val)),
        child: Opacity(opacity: val, child: child),
      ),
      child: GlassSurface(
        onTap: () {
          if (widget.targetUserId != null) {
            widget.onUserClick(widget.targetUserId!);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.8),
              width: 1.5,
            ),
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.14),
                scheme.surface.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.2),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    rank != null ? '$rank' : '--',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.5), width: 1.5),
                ),
                child: ClipOval(
                  child: photoUrl.isNotEmpty
                      ? Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) =>
                              _initialsContainer(displayName, scheme))
                      : _initialsContainer(displayName, scheme),
                ),
              ),
              const SizedBox(width: 12),
              // Name + tier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isMe ? l10n.you.toUpperCase() : 'SELECTED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(tier.icon,
                            style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          getLocalizedTierTitle(
                                  context, tier.tier, _category)
                              .toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$points',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary),
                  ),
                  Text(
                    'PTS',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant, fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsContainer(String name, ColorScheme scheme) {
    return Container(
      color: scheme.primary.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
        ),
      ),
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
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(l10n.startReadingAppear,
              style: theme.textTheme.bodySmall),
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
        builder: (ctx, constraints) {
          final itemWidth = constraints.maxWidth / keys.length;
          return Stack(
            children: [
              AnimatedAlign(
                alignment: Alignment(
                    (selectedIdx / (keys.length - 1)) * 2 - 1, 0.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: Container(
                  width: itemWidth,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.24)),
                  ),
                ),
              ),
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

  const AnimatedEntrance(
      {super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration:
          Duration(milliseconds: 300 + (index * 25).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
            offset: Offset(0, 18 * (1 - val)), child: child),
      ),
      child: child,
    );
  }
}

// ── Podium Strip (stateful for bar tap highlights) ───────────────────────────

class _PodiumStrip extends StatelessWidget {
  const _PodiumStrip({
    required this.top3,
    required this.currentUserId,
    required this.highlightedUserId,
    required this.category,
    required this.width,
    required this.onUserClick,
    required this.onBarTap,
  });

  final List<LeaderboardRank> top3;
  final String currentUserId;
  final String? highlightedUserId;
  final String category;
  final double width;
  final void Function(String) onUserClick;
  final void Function(String) onBarTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Display order: 2nd place left, 1st place centre, 3rd place right
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
        final sizeFactor = i == 1 ? 1.0 : 0.82;
        final isHighlighted = entry.userId == currentUserId ||
            entry.userId == highlightedUserId;

        return Expanded(
          child: Column(
            children: [
              // Avatar + name – tapping navigates to profile
              GestureDetector(
                onTap: () => onUserClick(entry.userId),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60 * sizeFactor,
                          height: 60 * sizeFactor,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isHighlighted
                                  ? scheme.primary
                                  : accentColors[i],
                              width: isHighlighted ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isHighlighted
                                    ? scheme.primary.withValues(alpha: 0.3)
                                    : accentColors[i].withValues(alpha: 0.2),
                                blurRadius: 12,
                                spreadRadius: isHighlighted ? 2 : 0,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: entry.photoUrl.isNotEmpty
                                ? Image.network(entry.photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) =>
                                        _fallback(entry, scheme, i))
                                : _fallback(entry, scheme, i),
                          ),
                        ),
                        Text(medals[i],
                            style: const TextStyle(fontSize: 14)),
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
                            color: isHighlighted
                                ? scheme.primary
                                : scheme.onSurface,
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
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Rank bar – tapping only highlights (no navigation)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onBarTap(entry.userId);
                },
                behavior: HitTestBehavior.opaque,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: heights[i]),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (ctx, h, child) => GlassSurface(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      height: h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isHighlighted
                                ? scheme.primary.withValues(alpha: 0.35)
                                : accentColors[i].withValues(alpha: 0.15),
                            accentColors[i].withValues(alpha: 0.03),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        border: isHighlighted
                            ? Border(
                                top: BorderSide(
                                    color: scheme.primary
                                        .withValues(alpha: 0.8),
                                    width: 2),
                                left: BorderSide(
                                    color: scheme.primary
                                        .withValues(alpha: 0.6),
                                    width: 1.5),
                                right: BorderSide(
                                    color: scheme.primary
                                        .withValues(alpha: 0.6),
                                    width: 1.5),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.rank}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: i == 1 ? 20 : 15,
                            color: isHighlighted
                                ? scheme.primary
                                : accentColors[i],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _fallback(LeaderboardRank entry, ColorScheme scheme, int i) {
    return Container(
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
    );
  }
}

// ── Rank Card (rank 4+) ───────────────────────────────────────────────────────

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.entry,
    required this.isCurrentUser,
    required this.isTargetUser,
    required this.category,
    required this.onTap,
  });

  final LeaderboardRank entry;
  final bool isCurrentUser;
  final bool isTargetUser;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<GlassTokens>() ?? GlassTokens.light;
    final l10n = AppLocalizations.of(context)!;
    final isHighlighted = isCurrentUser || isTargetUser;

    final card = GlassSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: isHighlighted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.8), width: 1.5),
                color: scheme.primaryContainer.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: 1),
                ],
              )
            : null,
        child: Row(
          children: [
            // Rank number circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.borderColor),
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isHighlighted
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHighlighted
                      ? scheme.primary.withValues(alpha: 0.5)
                      : tokens.borderColor,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: entry.photoUrl.isNotEmpty
                    ? Image.network(entry.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(
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
                            ))
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
            // Name + tier
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
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.you,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 8,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Builder(builder: (_) {
                    final tier = getTierInfo(entry.points, category);
                    return Row(
                      children: [
                        Text(tier.icon,
                            style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          getLocalizedTierTitle(context, tier.tier, category)
                              .toUpperCase(),
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
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.points}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900, color: scheme.primary),
                ),
                Text(
                  'PTS',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isTargetUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, val, child) => Transform.translate(
            offset: Offset(0, 20 * (1 - val)),
            child: Opacity(opacity: val, child: child),
          ),
          child: card,
        ),
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: card);
  }
}
