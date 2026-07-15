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

typedef LeaderboardLoader =
    Future<List<LeaderboardRank>> Function({
      required String period,
      required String type,
    });

class LeaderboardTab extends StatefulWidget {
  final UserModel currentUser;
  final String initialCategory;
  final String initialPeriod;
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
  final LeaderboardLoader? leaderboardLoader;

  const LeaderboardTab({
    super.key,
    required this.currentUser,
    required this.onUserClick,
    this.initialCategory = 'author',
    this.initialPeriod = 'monthly',
    this.targetUserId,
    this.targetUserPoints,
    this.targetUserRank,
    this.targetUserReaderPoints,
    this.targetUserReaderRank,
    this.targetUserDisplayName,
    this.targetUserPhotoUrl,
    this.leaderboardLoader,
  });

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  LeaderboardRepository? _repository;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _targetRowKey = GlobalKey();
  String? _revealedSelection;

  late String _period;
  late String _category;

  // The ranked list shown (always capped at 20)
  List<LeaderboardRank> _rankings = [];
  bool _loading = true;
  Object? _loadError;
  int _loadRequest = 0;

  // Whether the target user card at the bottom was tapped
  String? _highlightedUserId;

  @override
  void initState() {
    super.initState();
    if (widget.leaderboardLoader == null) _repository = LeaderboardRepository();
    _category = widget.initialCategory;
    _period = widget.initialPeriod == 'daily'
        ? 'monthly'
        : widget.initialPeriod;
    _highlightedUserId = widget.targetUserId;
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Returns the target user's points for the currently active category tab
  int? get _activeTargetPoints {
    if (_period != 'total') return null;
    return _category == 'reader'
        ? widget.targetUserReaderPoints
        : widget.targetUserPoints;
  }

  // Returns the target user's rank for the currently active category tab
  int? get _activeTargetRank {
    if (_period != 'total') return null;
    return _category == 'reader'
        ? widget.targetUserReaderRank
        : widget.targetUserRank;
  }

  Future<void> _loadLeaderboard() async {
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final loader = widget.leaderboardLoader ?? _repository!.fetchLeaderboard;
      final results = await loader(period: _period, type: _category);
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _rankings = results.take(20).toList();
        _loading = false;
      });
      _scheduleTargetReveal();
    } catch (error) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
      return;
    }
  }

  void _selectCategory(RankTrack track) {
    if (_category == track.value) return;
    setState(() {
      _category = track.value;
      _highlightedUserId = widget.targetUserId;
      _revealedSelection = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    _loadLeaderboard();
  }

  String get _selectionKey => '$_category:$_period';
  void _selectPeriod(String period) {
    if (_period == period) return;
    setState(() {
      _period = period;
      _highlightedUserId = widget.targetUserId;
      _revealedSelection = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    _loadLeaderboard();
  }

  bool get _shouldAppendTarget =>
      widget.targetUserId != null &&
      _period == 'total' &&
      (_activeTargetPoints ?? 0) > 0 &&
      (_activeTargetRank ?? 0) > 20 &&
      !_rankings.any((entry) => entry.userId == widget.targetUserId);

  void _scheduleTargetReveal() {
    final selection = _selectionKey;
    if (widget.targetUserId == null ||
        _period != 'total' ||
        _activeTargetRank == null ||
        (_activeTargetPoints ?? 0) <= 0) {
      _revealedSelection = selection;
      return;
    }
    if (_activeTargetRank! <= 3) {
      _revealedSelection = selection;
      return;
    }
    final targetWillRender =
        _shouldAppendTarget ||
        _rankings.any((entry) => entry.userId == widget.targetUserId);
    if (!targetWillRender) {
      _revealedSelection = selection;
      return;
    }
    if (_revealedSelection == selection) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _revealedSelection == selection) return;
      _revealedSelection = selection;
      final targetContext = _targetRowKey.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.82,
        );
        return;
      }
      if (_scrollController.hasClients) {
        final disableAnimations = MediaQuery.disableAnimationsOf(context);
        _scrollController
            .animateTo(
              _scrollController.position.maxScrollExtent,
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            )
            .then((_) {
              if (!mounted || !_scrollController.hasClients) return;
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            });
      }
    });
  }

  void _showInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          LeaderboardInfoModal(initialTrack: RankTrack.fromValue(_category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final appendTarget = _shouldAppendTarget;

    // Podium: only when the first three renumbered ranks are 1, 2, 3
    final hasPodium = _rankings.length >= 3;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              GlassSegmentedControl(
                selectedValue: _category,
                options: {
                  'author': '\u{270D}\u{FE0F} ${l10n.authors}',
                  'reader': '\u{1F4D6} ${l10n.readers}',
                },
                onChanged: (val) => _selectCategory(RankTrack.fromValue(val)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GlassControlSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
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
                          dropdownColor: theme
                              .extension<GlassTokens>()
                              ?.strongSurfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurface,
                          ),
                          onChanged: (val) {
                            if (val != null) _selectPeriod(val);
                          },
                          items: [
                            DropdownMenuItem(
                              value: 'total',
                              child: Text('\u{1F3C6}  ${l10n.totalAllTime}'),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('\u{1F5D3}\u{FE0F}  ${l10n.monthly}'),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text('\u{1F4C5}  ${l10n.weekly}'),
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
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: scheme.primary))
              : _loadError != null
              ? _buildErrorState(context)
              : _rankings.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (hasPodium)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: LayoutBuilder(
                              builder: (ctx, constraints) => _PodiumStrip(
                                top3: _rankings.take(3).toList(),
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
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        sliver: SliverList.builder(
                          itemCount:
                              (hasPodium
                                  ? _rankings.length - 3
                                  : _rankings.length) +
                              (appendTarget ? 1 : 0),
                          itemBuilder: (ctx, index) {
                            final normalCount = hasPodium
                                ? _rankings.length - 3
                                : _rankings.length;
                            final isAppendedTarget = index == normalCount;
                            final entry = isAppendedTarget
                                ? LeaderboardRank(
                                    rank: _activeTargetRank!,
                                    userId: widget.targetUserId!,
                                    displayName:
                                        widget.targetUserDisplayName ?? 'User',
                                    photoUrl: widget.targetUserPhotoUrl ?? '',
                                    points: _activeTargetPoints ?? 0,
                                  )
                                : _rankings[hasPodium ? index + 3 : index];
                            final isMe = entry.userId == widget.currentUser.id;
                            final isTarget =
                                entry.userId == widget.targetUserId;
                            return AnimatedEntrance(
                              key: isTarget ? _targetRowKey : null,
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
                    ],
                  ),
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
          const Text('\u{1F3C6}', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            l10n.noRankingsPeriod,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.startReadingAppear, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              l10n.leaderboardLoadError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadLeaderboard,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  (selectedIdx / (keys.length - 1)) * 2 - 1,
                  0.0,
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: Container(
                  width: itemWidth,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.85,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.24),
                    ),
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

class AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final int index;

  const AnimatedEntrance({super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 25).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - val)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _PodiumStrip extends StatelessWidget {
  const _PodiumStrip({
    required this.top3,
    required this.highlightedUserId,
    required this.category,
    required this.width,
    required this.onUserClick,
    required this.onBarTap,
  });

  final List<LeaderboardRank> top3;
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
    final medals = ['\u{1F948}', '\u{1F947}', '\u{1F949}'];
    final accentColors = [
      const Color(0xFF64748B),
      const Color(0xFFD4AF37),
      const Color(0xFFCD7F32),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final entry = order[i];
        final sizeFactor = i == 1 ? 1.0 : 0.82;
        final isHighlighted = entry.userId == highlightedUserId;

        return Expanded(
          child: Column(
            children: [
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
                                ? Image.network(
                                    entry.photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) =>
                                        _fallback(entry, scheme, i),
                                  )
                                : _fallback(entry, scheme, i),
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
                      top: Radius.circular(12),
                    ),
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
                                : accentColors[i].withValues(alpha: 0.28),
                            accentColors[i].withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        border: isHighlighted
                            ? Border(
                                top: BorderSide(
                                  color: scheme.primary.withValues(alpha: 0.8),
                                  width: 2,
                                ),
                                left: BorderSide(
                                  color: scheme.primary.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                                right: BorderSide(
                                  color: scheme.primary.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
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
                  color: scheme.primary.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                color: scheme.primaryContainer.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
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
                    ? Image.network(
                        entry.photoUrl,
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
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
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
                              color: scheme.onPrimaryContainer,
                            ),
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
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
                  Builder(
                    builder: (_) {
                      final tier = getTierInfo(entry.points, category);
                      return Row(
                        children: [
                          Text(tier.icon, style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            getLocalizedTierTitle(
                              context,
                              tier.tier,
                              category,
                            ).toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // Points
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
                  l10n.pointsLabel.toUpperCase(),
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
