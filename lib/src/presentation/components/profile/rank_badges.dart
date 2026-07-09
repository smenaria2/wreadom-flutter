import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../../domain/models/user_model.dart';
import '../../../utils/tier_utils.dart';

class RankBadges extends StatelessWidget {
  final UserModel user;
  final void Function(String type)? onClick;
  final bool showTierLabel;

  const RankBadges({
    super.key,
    required this.user,
    this.onClick,
    this.showTierLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasAuthorRank = user.authorRank != null;
    final readerPoints = user.readerPoints ?? 0;
    final authorPoints = user.authorPoints ?? 0;
    final readerTier = getTierInfo(readerPoints, 'reader');
    final authorTier = hasAuthorRank ? getTierInfo(authorPoints, 'author') : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (authorTier != null)
              _RankBadgePressable(
                categoryIcon: '🖋️',
                rankLabel: '#${user.authorRank}',
                gradient: authorTier.gradient,
                onTap: () => onClick?.call('author'),
              ),
            _RankBadgePressable(
              categoryIcon: '📖',
              rankLabel: user.readerRank != null ? '#${user.readerRank}' : '#--',
              gradient: readerTier.gradient,
              onTap: () => onClick?.call('reader'),
            ),
          ],
        ),
        if (showTierLabel) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (authorTier != null) ...[
                _TierLabel(tier: authorTier, category: 'author'),
                Text(
                  '·',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
              _TierLabel(tier: readerTier, category: 'reader'),
            ],
          ),
        ],
      ],
    );
  }
}

class _TierLabel extends StatelessWidget {
  const _TierLabel({required this.tier, required this.category});
  final TierInfo tier;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tier.icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          getLocalizedTierTitle(context, tier.tier, category),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _RankBadgePressable extends StatefulWidget {
  const _RankBadgePressable({
    required this.categoryIcon,
    required this.rankLabel,
    required this.gradient,
    required this.onTap,
  });

  final String categoryIcon;
  final String rankLabel;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  @override
  State<_RankBadgePressable> createState() => _RankBadgePressableState();
}

class _RankBadgePressableState extends State<_RankBadgePressable> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    setState(() => _scale = 0.95);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GlassTokens>() ?? GlassTokens.light;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.shadowColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.categoryIcon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                widget.rankLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
