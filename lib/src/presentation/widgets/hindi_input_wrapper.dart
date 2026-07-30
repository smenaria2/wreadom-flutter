import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/devlipi_hindi_engine.dart';
import 'glass_surface.dart';

/// A reusable wrapper widget that equips any standard text input field (like TextField
/// or TextFormField) with offline Hindi transliteration.
///
/// Displays:
/// - A small floating toggle button ('अ') in the bottom right corner above the keyboard.
/// - A horizontal scrollable suggestion bar directly above the toggle button.
class HindiInputWrapper extends StatefulWidget {
  const HindiInputWrapper({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.child,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget child;

  @override
  State<HindiInputWrapper> createState() => _HindiInputWrapperState();
}

class _HindiInputWrapperState extends State<HindiInputWrapper> {
  static const _engine = DevlipiHindiEngine();

  bool _isEnabled = false;
  List<String> _suggestions = [];
  int _selectedIndex = 0;

  String? _activeRomanToken;
  int? _tokenStartOffset;
  int? _tokenEndOffset;

  // Backspace restoration state
  String? _lastCommittedRoman;
  String? _lastCommittedHindi;
  String? _lastCommittedAppended;
  int? _lastCommittedStart;

  final ScrollController _rowScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(HindiInputWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onControllerChanged);
    _rowScrollController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _clearSuggestionState() {
    _suggestions = [];
    _selectedIndex = 0;
    _activeRomanToken = null;
    _tokenStartOffset = null;
    _tokenEndOffset = null;
  }

  void _clearLastCommitted() {
    _lastCommittedRoman = null;
    _lastCommittedHindi = null;
    _lastCommittedAppended = null;
    _lastCommittedStart = null;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _isDelimiter(String char) {
    const delimiters = r'.,;:!?()[]{}<>"«»‘’“”/\-*+=&%|@#';
    return delimiters.contains(char) || char == "'" || char == '"';
  }

  void _onControllerChanged() {
    if (!_isEnabled) {
      if (_suggestions.isNotEmpty) {
        setState(_clearSuggestionState);
      }
      return;
    }

    final selection = widget.controller.selection;
    if (!selection.isCollapsed || selection.extentOffset <= 0) {
      if (_suggestions.isNotEmpty) {
        setState(_clearSuggestionState);
      }
      return;
    }

    final caretOffset = selection.extentOffset;
    final plainText = widget.controller.text;

    if (caretOffset > plainText.length) {
      if (_suggestions.isNotEmpty) {
        setState(_clearSuggestionState);
      }
      return;
    }

    // 1. Replace single period followed by space with । followed by space
    if (caretOffset >= 2) {
      final lastChar = plainText[caretOffset - 1];
      final prevChar = plainText[caretOffset - 2];
      if (lastChar == ' ' && prevChar == '.') {
        bool isEllipsis = false;
        if (caretOffset >= 3 && plainText[caretOffset - 3] == '.') {
          isEllipsis = true;
        }
        if (!isEllipsis) {
          final newText = '${plainText.substring(0, caretOffset - 2)}।${plainText.substring(caretOffset - 1)}';
          widget.controller.removeListener(_onControllerChanged);
          widget.controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: caretOffset),
          );
          widget.controller.addListener(_onControllerChanged);
          return;
        }
      }
    }

    // 2. Check if the user typed punctuation or space immediately after the active Roman token
    if (_suggestions.isNotEmpty && _activeRomanToken != null && _tokenStartOffset != null && _tokenEndOffset != null) {
      final start = _tokenStartOffset!;
      final end = _tokenEndOffset!;
      if (caretOffset == end + 1 && caretOffset <= plainText.length) {
        final lastChar = plainText[caretOffset - 1];
        if (lastChar == ' ' || lastChar == '.' || lastChar == ',' || lastChar == ':') {
          final prefixText = plainText.substring(start, end);
          if (prefixText == _activeRomanToken) {
            final topSuggestion = _suggestions.firstOrNull;
            if (topSuggestion != null && topSuggestion.isNotEmpty) {
              final replacementPunc = (lastChar == '.') ? '।' : lastChar;
              final replacement = '$topSuggestion$replacementPunc';
              final romanToken = _activeRomanToken!;

              _clearSuggestionState();

              final newText = '${plainText.substring(0, start)}$replacement${plainText.substring(end + 1)}';
              final newCaret = start + replacement.length;

              widget.controller.removeListener(_onControllerChanged);
              widget.controller.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: newCaret),
              );
              widget.controller.addListener(_onControllerChanged);

              // Set up backspace restoration state
              _lastCommittedRoman = romanToken;
              _lastCommittedHindi = topSuggestion;
              _lastCommittedAppended = replacementPunc;
              _lastCommittedStart = start;

              setState(() {});
              return;
            }
          }
        }
      }
    }

    // 3. If caret has moved away from the last committed position, discard restoration buffer.
    if (_lastCommittedStart != null && _lastCommittedHindi != null) {
      final appendedLen = _lastCommittedAppended?.length ?? 0;
      final expectedEndWithAppended = _lastCommittedStart! + _lastCommittedHindi!.length + appendedLen;
      final expectedEndWithoutAppended = _lastCommittedStart! + _lastCommittedHindi!.length;
      if (caretOffset != expectedEndWithAppended && caretOffset != expectedEndWithoutAppended) {
        _clearLastCommitted();
      }
    }

    // 4. Scan backwards from caret to find start of active Roman token
    int start = caretOffset;
    while (start > 0) {
      final char = plainText[start - 1];
      if (char == ' ' || char == '\n' || char == '\t' || _isDelimiter(char)) {
        break;
      }
      start--;
    }

    if (start >= caretOffset) {
      if (_suggestions.isNotEmpty) {
        setState(_clearSuggestionState);
      }
      return;
    }

    final token = plainText.substring(start, caretOffset);
    final suggestions = _engine.transliterateToken(token);

    if (suggestions.isNotEmpty) {
      final changed = _activeRomanToken != token ||
          _tokenStartOffset != start ||
          _tokenEndOffset != caretOffset ||
          !_listEquals(_suggestions, suggestions);
      _activeRomanToken = token;
      _tokenStartOffset = start;
      _tokenEndOffset = caretOffset;
      if (changed) {
        setState(() {
          _suggestions = suggestions;
          _selectedIndex = 0;
        });
      }
    } else {
      if (_suggestions.isNotEmpty) {
        setState(_clearSuggestionState);
      }
    }
  }

  void _commitSuggestion(String suggestion) {
    if (_tokenStartOffset == null || _tokenEndOffset == null || _activeRomanToken == null) {
      return;
    }

    final start = _tokenStartOffset!;
    final end = _tokenEndOffset!;
    final romanToken = _activeRomanToken!;
    final plainText = widget.controller.text;

    final newText = '${plainText.substring(0, start)}$suggestion${plainText.substring(end)}';
    final newCaret = start + suggestion.length;

    _clearSuggestionState();

    widget.controller.removeListener(_onControllerChanged);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );
    widget.controller.addListener(_onControllerChanged);

    // Set up backspace restoration state
    _lastCommittedRoman = romanToken;
    _lastCommittedHindi = suggestion;
    _lastCommittedAppended = '';
    _lastCommittedStart = start;

    setState(() {});
    _restoreFocus();
  }

  bool _handleBackspace() {
    if (_lastCommittedStart == null || _lastCommittedHindi == null || _lastCommittedRoman == null) {
      return false;
    }

    final caretOffset = widget.controller.selection.extentOffset;
    final plainText = widget.controller.text;

    final committedHindi = _lastCommittedHindi!;
    final committedRoman = _lastCommittedRoman!;
    final committedStart = _lastCommittedStart!;
    final committedAppended = _lastCommittedAppended ?? '';

    final expectedEndWithAppended = committedStart + committedHindi.length + committedAppended.length;
    final expectedEndWithoutAppended = committedStart + committedHindi.length;

    bool matchWithAppended = caretOffset == expectedEndWithAppended;
    bool matchWithoutAppended = caretOffset == expectedEndWithoutAppended;

    if (matchWithAppended || matchWithoutAppended) {
      final newText = '${plainText.substring(0, committedStart)}$committedRoman${plainText.substring(caretOffset)}';
      final newCaret = committedStart + committedRoman.length;

      _clearLastCommitted();

      widget.controller.removeListener(_onControllerChanged);
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCaret),
      );
      widget.controller.addListener(_onControllerChanged);

      final suggestions = _engine.transliterateToken(committedRoman);
      setState(() {
        _suggestions = suggestions;
        _selectedIndex = 0;
        _activeRomanToken = committedRoman;
        _tokenStartOffset = committedStart;
        _tokenEndOffset = newCaret;
      });

      return true;
    }

    return false;
  }

  void _restoreFocus() {
    if (widget.focusNode.canRequestFocus) {
      widget.focusNode.requestFocus();
    }
  }

  void _scrollSelectedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_rowScrollController.hasClients) return;
      const chipWidth = 70.0;
      final targetOffset = (_selectedIndex * chipWidth).clamp(
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (_suggestions.isNotEmpty) {
      if (key == LogicalKeyboardKey.tab || key == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
        });
        _scrollSelectedIntoView();
        return KeyEventResult.handled;
      }

      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if ((key == LogicalKeyboardKey.tab && isShiftPressed) ||
          key == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _suggestions.length) % _suggestions.length;
        });
        _scrollSelectedIntoView();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        _commitSuggestion(_suggestions[_selectedIndex]);
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.escape) {
        setState(_clearSuggestionState);
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.backspace) {
      if (_handleBackspace()) {
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = bottomInset > 0;
    final hasFocus = widget.focusNode.hasFocus;
    final showUI = hasFocus && keyboardOpen;

    return Focus(
      onKeyEvent: (node, event) => _handleKeyEvent(node, event),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (showUI) ...[
            // ── Floating Toggle Button 'अ' ─────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              bottom: bottomInset + 12,
              right: 12,
              child: Listener(
                onPointerDown: (_) => _restoreFocus(),
                child: FloatingActionButton.small(
                  elevation: 4,
                  backgroundColor: _isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  foregroundColor: _isEnabled
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  onPressed: () {
                    setState(() {
                      _isEnabled = !_isEnabled;
                      if (!_isEnabled) {
                        _clearSuggestionState();
                      } else {
                        _onControllerChanged();
                      }
                    });
                    _restoreFocus();
                  },
                  child: const Text(
                    'अ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // ── Floating Suggestion Bar ────────────────────────────────────
            if (_isEnabled && _suggestions.isNotEmpty)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                bottom: bottomInset + 64,
                left: 0,
                right: 0,
                child: TextFieldTapRegion(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: GlassSurface(
                      strong: true,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            for (int i = 0; i < _suggestions.length; i++) ...[
                              Listener(
                                onPointerDown: (_) => _restoreFocus(),
                                child: _HindiSuggestionChip(
                                  text: _suggestions[i],
                                  isSelected: i == _selectedIndex,
                                  isPrimary: i == 0,
                                  theme: Theme.of(context),
                                  onTap: () => _commitSuggestion(_suggestions[i]),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (_activeRomanToken != null) ...[
                              Listener(
                                onPointerDown: (_) => _restoreFocus(),
                                child: InkWell(
                                  canRequestFocus: false,
                                  onTap: () {
                                    setState(_clearSuggestionState);
                                    _restoreFocus();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outlineVariant
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      _activeRomanToken!,
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HindiSuggestionChip extends StatelessWidget {
  const _HindiSuggestionChip({
    required this.text,
    required this.isSelected,
    required this.isPrimary,
    required this.theme,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final bool isPrimary;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final isDark = theme.brightness == Brightness.dark;

    if (isSelected) {
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
              fontWeight: (isPrimary || isSelected) ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
