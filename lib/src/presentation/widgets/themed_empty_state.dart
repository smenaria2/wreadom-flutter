import 'package:flutter/material.dart';

class ThemedEmptyState extends StatelessWidget {
  const ThemedEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.padding = const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    this.iconSize = 56,
    this.textStyle,
  });

  final String message;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: color.withValues(alpha: 0.72)),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  textStyle ??
                  theme.textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
