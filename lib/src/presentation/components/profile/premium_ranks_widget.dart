import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/user_model.dart';
import '../../../localization/generated/app_localizations.dart';
import '../../../utils/app_haptics.dart';
import '../../../utils/tier_utils.dart';
import '../../routing/app_router.dart';
import '../../routing/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_surface.dart';

class PremiumRanksWidget extends StatefulWidget {
  const PremiumRanksWidget({
    super.key,
    required this.user,
    this.compact = false,
    this.onTrackSelected,
  });

  final UserModel user;
  final bool compact;
  final ValueChanged<RankTrack>? onTrackSelected;

  @override
  State<PremiumRanksWidget> createState() => _PremiumRanksWidgetState();
}

class _PremiumRanksWidgetState extends State<PremiumRanksWidget> {
  RankTrack _track = RankTrack.author;

  bool get _hasAuthor => (widget.user.authorPoints ?? 0) > 0;
  bool get _hasReader => (widget.user.readerPoints ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _track = _hasAuthor ? RankTrack.author : RankTrack.reader;
  }

  @override
  void didUpdateWidget(covariant PremiumRanksWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasAuthor) _track = RankTrack.reader;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAuthor && !_hasReader) return const SizedBox.shrink();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: _hasAuthor,
      onTap: _hasAuthor ? _flip : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _hasAuthor ? _flip : null,
        child: AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 520),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            if (reduceMotion) return child;
            final isIncoming =
                (child.key as ValueKey<RankTrack>?)?.value == _track;

            return AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, child) {
                final value = animation.value;

                if (isIncoming) {
                  if (value < 0.5) {
                    return const SizedBox.shrink();
                  }
                  final angle = -(1.0 - value) * math.pi;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(angle),
                    child: child,
                  );
                } else {
                  if (value < 0.5) {
                    return const SizedBox.shrink();
                  }
                  final angle = (1.0 - value) * math.pi;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(angle),
                    child: child,
                  );
                }
              },
            );
          },
          child: _RankStatusFace(
            key: ValueKey(_track),
            user: widget.user,
            track: _track,
            onLeaderboardTap: () => _openLeaderboard(_track),
          ),
        ),
      ),
    );
  }

  void _flip() {
    unawaited(AppHaptics.light());
    setState(() {
      _track = _track == RankTrack.author ? RankTrack.reader : RankTrack.author;
    });
  }

  void _openLeaderboard(RankTrack track) {
    unawaited(AppHaptics.light());
    final callback = widget.onTrackSelected;
    if (callback != null) {
      callback(track);
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.leaderboard,
      arguments: LeaderboardScreenArguments(
        initialCategory: track.value,
        initialPeriod: 'total',
        targetUserId: widget.user.id,
        targetUserPoints: widget.user.authorPoints,
        targetUserRank: widget.user.authorRank,
        targetUserReaderPoints: widget.user.readerPoints,
        targetUserReaderRank: widget.user.readerRank,
        targetUserDisplayName:
            widget.user.displayName ??
            widget.user.penName ??
            widget.user.username,
        targetUserPhotoUrl: widget.user.photoURL,
      ),
    );
  }
}

class _RankStatusFace extends StatelessWidget {
  const _RankStatusFace({
    super.key,
    required this.user,
    required this.track,
    required this.onLeaderboardTap,
  });

  final UserModel user;
  final RankTrack track;
  final VoidCallback onLeaderboardTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<GlassTokens>() ?? GlassTokens.light;
    final l10n = AppLocalizations.of(context)!;
    final points = track == RankTrack.author
        ? (user.authorPoints ?? 0)
        : (user.readerPoints ?? 0);
    final rank = track == RankTrack.author ? user.authorRank : user.readerRank;
    final tier = tierInfoFor(points, track);
    final status = track == RankTrack.author
        ? l10n.authorStatus
        : l10n.readerStatus;
    final title = localizedTierTitle(context, tier.tier, track);

    return Semantics(
      label: '$status, $title, $points ${l10n.pointsLabel}',
      child: GlassSurface(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 98),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: tokens.borderColor),
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                tier.gradient.colors.first.withValues(alpha: 0.10),
                tier.gradient.colors.last.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: tier.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: tier.gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(tier.icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            status.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                              letterSpacing: 0.5,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${formatRankPointsExact(context, points)} ${l10n.pointsLabel}',
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: tier.progressPercent / 100,
                            ),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 700),
                            builder: (context, value, child) =>
                                LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                  backgroundColor: scheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  valueColor: AlwaysStoppedAnimation(
                                    tier.gradient.colors.first,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tier.pointsToNext == null
                              ? l10n.maxLevelReached
                              : l10n.ptsToNextTier(tier.pointsToNext!),
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
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Semantics(
                    button: true,
                    label: l10n.viewLeaderboard,
                    child: InkResponse(
                      key: const ValueKey('rank-leaderboard-arrow'),
                      onTap: onLeaderboardTap,
                      radius: 22,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: tier.definition.mainColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tier.definition.mainColor.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    child: Text(
                      rank?.toString() ?? '--',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tier.definition.mainColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                  ),
                  Text(
                    rank == null
                        ? l10n.notRankedYet.toUpperCase()
                        : (track == RankTrack.author
                                  ? l10n.authorRankLabel
                                  : l10n.readerRankLabel)
                              .toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: rank == null ? 6 : 8,
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
