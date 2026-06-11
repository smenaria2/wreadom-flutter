import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'glass_surface.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: GlassSurface(
        strong: true,
        borderRadius: BorderRadius.circular(16.r),
        onTap: isLoading ? null : onPressed,
        semanticButton: true,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.24),
                scheme.secondary.withValues(alpha: 0.16),
                scheme.tertiary.withValues(alpha: 0.12),
              ],
              stops: const [0, 0.58, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      height: 24.h,
                      width: 24.h,
                      child: CircularProgressIndicator(
                        color: scheme.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      text,
                      key: const ValueKey('label'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
