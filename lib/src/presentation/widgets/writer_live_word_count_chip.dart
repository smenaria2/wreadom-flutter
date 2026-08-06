import 'package:flutter/material.dart';

import '../../localization/generated/app_localizations.dart';

/// A subtle, non-invasive live word count text widget displayed inside the editor.
/// Visible only when the keyboard is closed (user is not typing).
class WriterLiveWordCountChip extends StatelessWidget {
  const WriterLiveWordCountChip({
    super.key,
    required this.wordCount,
    required this.isVisible,
    this.alignment = Alignment.bottomRight,
    this.padding = const EdgeInsets.only(right: 8, bottom: 4),
  });

  final int wordCount;
  final bool isVisible;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final countText = l10n != null
        ? l10n.wordCountLabel(wordCount)
        : '$wordCount ${wordCount == 1 ? 'word' : 'words'}';

    final textColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: AnimatedOpacity(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          opacity: isVisible ? 1.0 : 0.0,
          child: AnimatedSlide(
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            offset: isVisible ? Offset.zero : const Offset(0, 0.4),
            child: IgnorePointer(
              ignoring: !isVisible,
              child: Text(
                countText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
