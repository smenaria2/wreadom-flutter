import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF10151F),
                  Color(0xFF171327),
                  Color(0xFF091F24),
                  Color(0xFF15120F),
                ]
              : const [
                  Color(0xFFFBF8F2),
                  Color(0xFFF1E9F8),
                  Color(0xFFE8F5F2),
                  Color(0xFFFFF0D2),
                ],
          stops: const [0, 0.42, 0.74, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              Colors.transparent,
              scheme.secondary.withValues(alpha: isDark ? 0.14 : 0.10),
              scheme.tertiary.withValues(alpha: isDark ? 0.12 : 0.10),
            ],
            stops: const [0, 0.34, 0.68, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                scheme.surface.withValues(alpha: isDark ? 0.18 : 0.28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
