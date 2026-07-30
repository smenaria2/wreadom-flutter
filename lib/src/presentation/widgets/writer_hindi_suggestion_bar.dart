import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../controllers/hindi_transliteration_controller.dart';
import 'glass_surface.dart';

/// Suggestion bar displayed above the writer toolbar when Hindi transliteration
/// suggests Devanagari replacements for the active typed Roman token.
///
/// - Renders 3-4 suggestion chips horizontally scrollable.
/// - The chip at [HindiTransliterationController.selectedIndex] is highlighted.
/// - Tapping a chip commits that suggestion and keeps the keyboard open.
/// - Tapping the raw English word chip dismisses the bar.
class WriterHindiSuggestionBar extends StatefulWidget {
  const WriterHindiSuggestionBar({
    super.key,
    required this.transliterationController,
    required this.quillController,
    this.editorFocusNode,
  });

  final HindiTransliterationController transliterationController;
  final QuillController quillController;

  /// When provided, focus is restored to the editor after committing so the
  /// soft keyboard stays visible.
  final FocusNode? editorFocusNode;

  @override
  State<WriterHindiSuggestionBar> createState() =>
      _WriterHindiSuggestionBarState();
}

class _WriterHindiSuggestionBarState extends State<WriterHindiSuggestionBar> {
  final ScrollController _rowScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.transliterationController.addListener(_onTransliterationChanged);
    widget.quillController.addListener(_onQuillControllerChanged);
  }

  @override
  void didUpdateWidget(WriterHindiSuggestionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transliterationController !=
        widget.transliterationController) {
      oldWidget.transliterationController
          .removeListener(_onTransliterationChanged);
      widget.transliterationController.addListener(_onTransliterationChanged);
    }
    if (oldWidget.quillController != widget.quillController) {
      oldWidget.quillController.removeListener(_onQuillControllerChanged);
      widget.quillController.addListener(_onQuillControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.transliterationController
        .removeListener(_onTransliterationChanged);
    widget.quillController.removeListener(_onQuillControllerChanged);
    _rowScrollController.dispose();
    super.dispose();
  }

  void _onTransliterationChanged() {
    if (mounted) setState(() {});
    // Scroll selected chip into view when navigating via keyboard
    _scrollSelectedIntoView();
  }

  void _onQuillControllerChanged() {
    if (mounted) {
      widget.transliterationController.updateForSelection(widget.quillController);
    }
  }

  void _scrollSelectedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_rowScrollController.hasClients) return;
      final idx = widget.transliterationController.selectedIndex;
      // Approximate per-chip width to scroll to the right position
      const chipWidth = 70.0;
      final targetOffset = (idx * chipWidth).clamp(
        0.0,
        _rowScrollController.position.maxScrollExtent,
      );
      _rowScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  /// Commits the given suggestion and restores editor focus so keyboard stays.
  void _commitAndKeepFocus(String suggestion) {
    widget.transliterationController.commitSuggestion(
      widget.quillController,
      selectedSuggestion: suggestion,
    );
    _restoreFocus();
  }

  void _restoreFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editorFocusNode?.canRequestFocus == true) {
        widget.editorFocusNode!.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = widget.transliterationController;
    final hasSuggestion = tc.hasSuggestion;
    final suggestions = tc.hindiSuggestions;
    final romanToken = tc.activeRomanToken ?? '';
    final selectedIndex = tc.selectedIndex;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFieldTapRegion(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          height: hasSuggestion ? null : 0,
          alignment: Alignment.center,
          child: hasSuggestion
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GlassSurface(
                    strong: true,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: SingleChildScrollView(
                      controller: _rowScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          // ── Suggestion chips ────────────────────────────────
                          for (int i = 0; i < suggestions.length; i++) ...[
                            _SuggestionChip(
                              text: suggestions[i],
                              isSelected: i == selectedIndex,
                              isPrimary: i == 0,
                              isDark: isDark,
                              theme: theme,
                              onTap: () => _commitAndKeepFocus(suggestions[i]),
                            ),
                            const SizedBox(width: 6),
                          ],
                          // ── Raw English word chip ───────────────────────────
                          if (romanToken.isNotEmpty) ...[
                            InkWell(
                              canRequestFocus: false,
                              onTap: () {
                                tc.dismissSuggestion();
                                _restoreFocus();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  romanToken,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ─── Chip widget ────────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.text,
    required this.isSelected,
    required this.isPrimary,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final bool isPrimary;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (isSelected) {
      // Keyboard-highlighted: use primary colour with stronger contrast
      bg = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
    } else if (isPrimary) {
      bg = theme.colorScheme.primaryContainer;
      fg = theme.colorScheme.onPrimaryContainer;
    } else {
      bg = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.07);
      fg = theme.colorScheme.onSurface;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight:
                  (isPrimary || isSelected) ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
