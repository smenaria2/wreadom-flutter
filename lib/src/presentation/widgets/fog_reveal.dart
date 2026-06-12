import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FogReveal extends StatefulWidget {
  const FogReveal({
    super.key,
    required this.child,
    required this.revealed,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 360),
    this.strong = false,
    this.animateFog = true,
  });

  final Widget child;
  final bool revealed;
  final BorderRadiusGeometry? borderRadius;
  final Duration duration;
  final bool strong;
  final bool animateFog;

  @override
  State<FogReveal> createState() => _FogRevealState();
}

class _FogRevealState extends State<FogReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _shouldAnimate {
    final mediaQuery = MediaQuery.maybeOf(context);
    return widget.animateFog &&
        !widget.revealed &&
        !(mediaQuery?.disableAnimations ?? false);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant FogReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    if (_shouldAnimate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<GlassTokens>() ?? GlassTokens.light;
    final radius = widget.borderRadius ?? BorderRadius.circular(tokens.radius);
    final resolvedRadius = radius.resolve(Directionality.of(context));
    final fogColor = widget.strong
        ? tokens.strongSurfaceColor
        : tokens.surfaceColor;
    final fogOpacity = widget.strong
        ? tokens.strongOpacity + 0.14
        : tokens.surfaceOpacity + 0.18;

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                key: const ValueKey('fog-reveal-overlay'),
                opacity: widget.revealed ? 0 : 1,
                duration: widget.duration,
                curve: Curves.easeOutCubic,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: tokens.blurSigma * (widget.strong ? 0.9 : 0.7),
                    sigmaY: tokens.blurSigma * (widget.strong ? 0.9 : 0.7),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: fogColor.withValues(alpha: fogOpacity.clamp(0, 1)),
                      borderRadius: resolvedRadius,
                      border: Border.all(
                        color: tokens.borderColor.withValues(alpha: 0.55),
                      ),
                    ),
                    child: widget.animateFog
                        ? _FogMist(
                            animation: _controller,
                            animated: _shouldAnimate,
                            strong: widget.strong,
                          )
                        : const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FogMist extends StatelessWidget {
  const _FogMist({
    required this.animation,
    required this.animated,
    required this.strong,
  });

  final Animation<double> animation;
  final bool animated;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    if (!animated) {
      return _FogMistPaint(progress: 0, strong: strong);
    }

    return AnimatedBuilder(
      key: const ValueKey('fog-reveal-animated-mist'),
      animation: animation,
      builder: (context, _) {
        return _FogMistPaint(progress: animation.value, strong: strong);
      },
    );
  }
}

class _FogMistPaint extends StatelessWidget {
  const _FogMistPaint({required this.progress, required this.strong});

  final double progress;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final baseOpacity = strong ? 0.18 : 0.13;
    final slide = (progress * 2) - 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(
          offset: Offset(slide * 72, -slide * 18),
          child: _MistBand(
            opacity: baseOpacity,
            alignment: Alignment.centerLeft,
          ),
        ),
        Transform.translate(
          offset: Offset(-slide * 54, slide * 26),
          child: _MistBand(
            opacity: baseOpacity * 0.72,
            alignment: Alignment.centerRight,
          ),
        ),
      ],
    );
  }
}

class _MistBand extends StatelessWidget {
  const _MistBand({required this.opacity, required this.alignment});

  final double opacity;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1.35,
      heightFactor: 1.25,
      alignment: alignment,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: opacity),
              Colors.white.withValues(alpha: 0.035),
              Colors.white.withValues(alpha: opacity * 0.7),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.28, 0.48, 0.68, 1],
          ),
        ),
      ),
    );
  }
}
