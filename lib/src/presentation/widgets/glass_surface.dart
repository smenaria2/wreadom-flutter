import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';

import '../../utils/app_haptics.dart';
import '../theme/app_theme.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.semanticButton = false,
    this.clipBehavior = Clip.antiAlias,
    this.strong = false,
    this.backgroundDistortion = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final bool semanticButton;
  final Clip clipBehavior;
  final bool strong;
  final bool backgroundDistortion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<GlassTokens>() ?? GlassTokens.light;
    final radius = borderRadius ?? BorderRadius.circular(tokens.radius);
    final resolvedRadius = radius.resolve(Directionality.of(context));
    final content = ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: Stack(
        children: [
          Positioned.fill(
            child: GlassMorphismMaterial(
              blurIntensity: tokens.blurSigma,
              opacity: strong ? tokens.strongOpacity : tokens.surfaceOpacity,
              glassThickness: strong ? 1.4 : 1.0,
              tintColor: strong
                  ? tokens.strongSurfaceColor
                  : tokens.surfaceColor,
              borderRadius: resolvedRadius,
              adaptToBackground: false,
              enableBackgroundDistortion: backgroundDistortion,
              enableGlassBorder: true,
              shadows: [
                BoxShadow(
                  color: tokens.shadowColor,
                  blurRadius: strong ? 30 : 22,
                  offset: Offset(0, strong ? 14 : 9),
                ),
                BoxShadow(
                  color: scheme.primary.withValues(alpha: strong ? 0.12 : 0.06),
                  blurRadius: strong ? 24 : 16,
                  spreadRadius: -4,
                  offset: const Offset(0, 5),
                ),
              ],
              child: const SizedBox.expand(),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: onTap == null
                ? _Padded(padding: padding, child: child)
                : InkWell(
                    onTap: () {
                      unawaited(AppHaptics.selection());
                      onTap!();
                    },
                    borderRadius: resolvedRadius,
                    splashColor: tokens.highlightColor,
                    highlightColor: tokens.highlightColor,
                    child: _Padded(padding: padding, child: child),
                  ),
          ),
        ],
      ),
    );

    final wrapped = margin == null
        ? content
        : Padding(padding: margin!, child: content);

    if (!semanticButton) return wrapped;
    return Semantics(button: true, child: wrapped);
  }
}

class GlassControlSurface extends StatelessWidget {
  const GlassControlSurface({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(2),
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      strong: true,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius ?? BorderRadius.circular(28),
      child: child,
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.padding, required this.child});

  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (padding == null) return child;
    return Padding(padding: padding!, child: child);
  }
}
