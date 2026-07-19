import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Creates a page-turn animation resembling a rigid book page.
///
/// Place this widget around every item returned by PageView.builder.
///
/// The implementation:
/// - Cancels PageView's default horizontal movement.
/// - Rotates the active page around its spine.
/// - Keeps the next page underneath.
/// - Calculates the moving edge using cos(rotation).
/// - Draws a shadow beside that moving edge.
/// - Supports reversed PageViews.
class BookPageTurn extends StatelessWidget {
  const BookPageTurn({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
    this.reverse = false,
    this.perspective = 0.0014,
    this.maxRotation = math.pi * 0.49,
    this.underPageScale = 0.985,
    this.pageShadowOpacity = 0.38,
    this.castShadowOpacity = 0.28,
  });

  final PageController controller;
  final int index;
  final Widget child;

  /// Must match PageView.reverse.
  final bool reverse;

  /// Usually looks best between 0.001 and 0.002.
  final double perspective;

  /// Slightly less than 90 degrees prevents backface flickering.
  final double maxRotation;

  /// Initial scale of the page underneath.
  final double underPageScale;

  /// Maximum darkness applied to the turning page.
  final double pageShadowOpacity;

  /// Maximum shadow cast on the underneath page.
  final double castShadowOpacity;

  double _currentPage() {
    if (!controller.hasClients) {
      return controller.initialPage.toDouble();
    }

    final position = controller.position;

    if (!position.hasPixels || !position.hasContentDimensions) {
      return controller.initialPage.toDouble();
    }

    return controller.page ?? controller.initialPage.toDouble();
  }

  double _pageExtent(double fallbackWidth) {
    if (!controller.hasClients) return fallbackWidth;

    final viewport = controller.position.viewportDimension;

    if (viewport <= 0) return fallbackWidth;

    return viewport * controller.viewportFraction;
  }

  double _clamp01(double value) => value.clamp(0.0, 1.0);

  /// Smooth interpolation used for visual effects only.
  ///
  /// The actual rotation remains linear so the page continues to follow the
  /// user's finger accurately.
  double _smoothStep(double value) {
    final t = _clamp01(value);
    return t * t * (3.0 - (2.0 * t));
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          child: RepaintBoundary(child: child),
          builder: (context, cachedChild) {
            final page = _currentPage();
            final rawDelta = index - page;

            // These pages are outside the visible transition.
            //
            // Returning them normally lets PageView position them off-screen.
            if (rawDelta <= -1.0 || rawDelta >= 1.0) {
              return cachedChild!;
            }

            final delta = rawDelta.clamp(-1.0, 1.0);
            final extent = _pageExtent(constraints.maxWidth);

            // Normal PageView:
            // index + 1 is positioned on the right.
            //
            // Reversed PageView:
            // index + 1 is positioned on the left.
            final direction = reverse ? -1.0 : 1.0;

            // Cancel PageView's standard sliding movement so pages remain
            // stacked while the upper page rotates.
            final pinnedOffset = -delta * extent * direction;

            final isTurningPage = delta < 0.0;

            if (isTurningPage) {
              return _buildTurningPage(
                child: cachedChild!,
                pinnedOffset: pinnedOffset,
                turnProgress: _clamp01(-delta),
                direction: direction,
              );
            }

            return _buildUnderPage(
              child: cachedChild!,
              pinnedOffset: pinnedOffset,
              revealProgress: _clamp01(1.0 - delta),
              width: constraints.maxWidth,
              direction: direction,
            );
          },
        );
      },
    );
  }

  Widget _buildTurningPage({
    required Widget child,
    required double pinnedOffset,
    required double turnProgress,
    required double direction,
  }) {
    // Keep rotation directly linked to scroll progress.
    final rotation = -direction * maxRotation * turnProgress;

    final visualProgress = _smoothStep(turnProgress);
    final angleStrength = math.sin(maxRotation * turnProgress);

    // A tiny reduction prevents the page from appearing vertically oversized
    // while perspective is applied.
    final scale = 1.0 - (0.012 * visualProgress);

    // Fade only when almost edge-on. This hides raster/backface flickering
    // without making the transition look like a cross-fade.
    final edgeFade = turnProgress <= 0.96
        ? 1.0
        : 1.0 - _clamp01((turnProgress - 0.96) / 0.04);

    final hinge = reverse
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final pageSurface = Stack(
      fit: StackFit.expand,
      children: [
        child,

        // Surface shading follows the physical rotation of the page.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: reverse
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                end: reverse
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                colors: [
                  Colors.white.withValues(
                    alpha: 0.035 * angleStrength,
                  ),
                  Colors.transparent,
                  Colors.black.withValues(
                    alpha: pageShadowOpacity * angleStrength,
                  ),
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
        ),

        // A narrow darker strip gives the free edge more definition.
        Positioned(
          top: 0,
          bottom: 0,
          left: reverse ? 0 : null,
          right: reverse ? null : 0,
          width: 8,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: reverse
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  end: reverse
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: 0.12 * angleStrength,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return ClipRect(
      child: Transform.translate(
        offset: Offset(pinnedOffset, 0),
        child: Opacity(
          opacity: edgeFade,
          child: Transform(
            alignment: hinge,
            filterQuality: FilterQuality.medium,
            transform: Matrix4.identity()
              ..setEntry(3, 2, perspective)
              ..scale(scale, scale)
              ..rotateY(rotation),
            child: pageSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildUnderPage({
    required Widget child,
    required double pinnedOffset,
    required double revealProgress,
    required double width,
    required double direction,
  }) {
    final visualProgress = _smoothStep(revealProgress);

    final scale = underPageScale +
        ((1.0 - underPageScale) * visualProgress);

    // The upper page's visible width is approximately:
    //
    // width × cos(rotation)
    //
    // This lets the shadow follow the moving free edge rather than remaining
    // fixed at the spine.
    final angle = maxRotation * revealProgress;
    final projectedPageWidth = width * math.cos(angle);

    final castStrength =
        math.sin(math.pi * revealProgress).clamp(0.0, 1.0);

    final shadowWidth = (width * 0.14).clamp(24.0, 72.0);

    double shadowLeft;

    if (!reverse) {
      shadowLeft = projectedPageWidth - (shadowWidth * 0.18);
    } else {
      final movingEdge = width - projectedPageWidth;
      shadowLeft = movingEdge - (shadowWidth * 0.82);
    }

    shadowLeft = shadowLeft.clamp(-shadowWidth, width);

    final underPage = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        child,

        Positioned(
          top: 0,
          bottom: 0,
          left: shadowLeft,
          width: shadowWidth,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: reverse
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  end: reverse
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(
                      alpha: castShadowOpacity * castStrength,
                    ),
                    Colors.black.withValues(
                      alpha: castShadowOpacity *
                          0.35 *
                          castStrength,
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.32, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return ClipRect(
      child: Transform.translate(
        offset: Offset(pinnedOffset, 0),
        child: Transform.scale(
          alignment: reverse
              ? Alignment.centerRight
              : Alignment.centerLeft,
          scale: scale,
          filterQuality: FilterQuality.medium,
          child: underPage,
        ),
      ),
    );
  }
}
