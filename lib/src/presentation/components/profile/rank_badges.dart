import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/user_model.dart';
import '../../../utils/tier_utils.dart';

class RankBadges extends StatelessWidget {
  final UserModel user;
  final void Function(String type)? onClick;
  final bool showTierLabel;
  final bool centerAlign;

  const RankBadges({
    super.key,
    required this.user,
    this.onClick,
    this.showTierLabel = true,
    this.centerAlign = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAuthorRank = user.authorRank != null;
    final readerPoints = user.readerPoints ?? 0;
    final authorPoints = user.authorPoints ?? 0;
    final readerTier = getTierInfo(readerPoints, 'reader');
    final authorTier = hasAuthorRank ? getTierInfo(authorPoints, 'author') : null;

    return Column(
      crossAxisAlignment: centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: centerAlign ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (authorTier != null)
              _RankBadgePressable(
                categoryIcon: Icons.history_edu_rounded,
                rankLabel: '#${user.authorRank}',
                gradient: authorTier.gradient,
                onTap: () => onClick?.call('author'),
              ),
            _RankBadgePressable(
              categoryIcon: Icons.menu_book_rounded,
              rankLabel: user.readerRank != null ? '#${user.readerRank}' : '#--',
              gradient: readerTier.gradient,
              onTap: () => onClick?.call('reader'),
            ),
          ],
        ),
        if (showTierLabel) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: centerAlign ? WrapAlignment.center : WrapAlignment.start,
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
                        fontWeight: FontWeight.bold,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tier.icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            getLocalizedTierTitle(context, tier.tier, category),
            style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
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

  final IconData categoryIcon;
  final String rankLabel;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  @override
  State<_RankBadgePressable> createState() => _RankBadgePressableState();
}

class _RankBadgePressableState extends State<_RankBadgePressable>
    with TickerProviderStateMixin {
  double _scale = 1.0;
  
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Breathing pulse glow animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Periodic Shimmer sweep animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOutSine),
      ),
    );

    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _scale = 0.92);
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.colors.first.withValues(alpha: 0.22),
                    blurRadius: _pulseAnimation.value,
                    spreadRadius: _pulseAnimation.value / 6,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Base Badge Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.categoryIcon,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.rankLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Shimmer Overlay
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: FractionalTranslation(
                        translation: Offset(_shimmerAnimation.value, 0),
                        child: Transform(
                          transform: Matrix4.skewX(-0.35),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.35, 0.5, 0.65],
                              ),
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
        ),
      ),
    );
  }
}
