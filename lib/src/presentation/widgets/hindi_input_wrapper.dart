import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/devlipi_hindi_engine.dart';
import '../../localization/generated/app_localizations.dart';
import 'glass_surface.dart';

/// A reusable wrapper widget that equips any standard text input field (like TextField
/// or TextFormField) with offline Hindi transliteration.
///
/// Displays:
/// - A small toggle button ('अ') positioned INSIDE the text field container at all times.
/// - A horizontal scrollable suggestion bar directly above the keyboard via a global overlay.
class HindiInputWrapper extends StatefulWidget {
  const HindiInputWrapper({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.child,
    this.centerVertically = false,
    this.rightOffset,
    this.leftOffset,
    this.bottomOffset = 8.0,
    this.enabled = true,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget child;
  final bool centerVertically;
  final double? rightOffset;
  final double? leftOffset;
  final double bottomOffset;
  final bool enabled;
  final bool readOnly;

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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _suggestionOverlayEntry;
  bool _pointerDownOnOverlay = false;

  bool get _isInputActive => widget.enabled && !widget.readOnly;

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
    if (!widget.enabled || widget.readOnly) {
      if (_suggestions.isNotEmpty) {
        _clearSuggestionState();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverlay());
  }

  @override
  void dispose() {
    _suggestionOverlayEntry?.remove();
    _suggestionOverlayEntry = null;
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onControllerChanged);
    _rowScrollController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (!widget.focusNode.hasFocus) {
      // Delay hiding the overlay so that taps on chips/toggle have time to fire
      // before the overlay is torn down.
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        if (!widget.focusNode.hasFocus && !_pointerDownOnOverlay) {
          setState(() {});
          _updateOverlay();
        }
      });
    } else {
      setState(() {});
    }
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
    if (!_isEnabled || !_isInputActive) {
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

    // Restore focus synchronously first so the keyboard stays visible
    if (widget.focusNode.canRequestFocus) {
      widget.focusNode.requestFocus();
    }
    setState(() {});
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
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

      // 1. Shift+Tab or Left Arrow: previous suggestion
      if ((key == LogicalKeyboardKey.tab && isShiftPressed) || key == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _suggestions.length) % _suggestions.length;
        });
        _scrollSelectedIntoView();
        return KeyEventResult.handled;
      }

      // 2. Tab or Right Arrow: next suggestion
      if ((key == LogicalKeyboardKey.tab && !isShiftPressed) || key == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
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

  Widget _buildSuggestionContent(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
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
                      onPointerDown: (_) {
                        // Immediately restore focus on pointer-down so
                        // the overlay isn't torn down before onTap fires.
                        _pointerDownOnOverlay = true;
                        if (widget.focusNode.canRequestFocus) {
                          widget.focusNode.requestFocus();
                        }
                      },
                      onPointerUp: (_) => _pointerDownOnOverlay = false,
                      onPointerCancel: (_) => _pointerDownOnOverlay = false,
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
                      onPointerDown: (_) {
                        _pointerDownOnOverlay = true;
                        if (widget.focusNode.canRequestFocus) {
                          widget.focusNode.requestFocus();
                        }
                      },
                      onPointerUp: (_) => _pointerDownOnOverlay = false,
                      onPointerCancel: (_) => _pointerDownOnOverlay = false,
                      child: InkWell(
                        canRequestFocus: false,
                        onTap: () {
                          setState(_clearSuggestionState);
                          if (widget.focusNode.canRequestFocus) {
                            widget.focusNode.requestFocus();
                          }
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
    );
  }

  void _updateOverlay() {
    if (!mounted) return;

    final hasFocus = widget.focusNode.hasFocus;
    final showSuggestions = _isEnabled && _isInputActive && _suggestions.isNotEmpty && hasFocus;
    final overlayState = Overlay.maybeOf(context);

    if (overlayState == null) {
      _suggestionOverlayEntry?.remove();
      _suggestionOverlayEntry = null;
      return;
    }

    if (showSuggestions) {
      if (_suggestionOverlayEntry == null) {
        _suggestionOverlayEntry = OverlayEntry(
          builder: (context) {
            double targetGlobalTop = 500.0;
            final renderBox = this.context.findRenderObject() as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              targetGlobalTop = renderBox.localToGlobal(Offset.zero).dy;
            }

            final bool isNearScreenTop = targetGlobalTop < 70;

            if (isNearScreenTop) {
              // For search bars at top of screen (e.g. Discovery search),
              // float 6px directly BELOW the input container.
              return CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 6),
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildSuggestionContent(context),
                ),
              );
            } else {
              // For all standard input fields (reviews, comments, replies, post composer),
              // float 6px directly ABOVE the top of the input box container.
              return CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, -6),
                targetAnchor: Alignment.topCenter,
                followerAnchor: Alignment.bottomCenter,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildSuggestionContent(context),
                ),
              );
            }
          },
        );
        overlayState.insert(_suggestionOverlayEntry!);
      } else {
        _suggestionOverlayEntry!.markNeedsBuild();
      }
    } else {
      _suggestionOverlayEntry?.remove();
      _suggestionOverlayEntry = null;
    }
  }

  Widget _buildHindiToggleButton() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final Color bg;
    final Color fg;

    if (_isEnabled) {
      bg = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
    } else {
      bg = theme.colorScheme.surfaceContainerHigh;
      fg = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    }

    final semanticLabel = l10n != null
        ? (_isEnabled ? l10n.hindiInputModeEnabled : l10n.hindiInputModeDisabled)
        : (_isEnabled ? 'Hindi input mode enabled' : 'Hindi input mode disabled');

    return Semantics(
      button: true,
      enabled: _isInputActive,
      toggled: _isEnabled,
      label: semanticLabel,
      child: Listener(
        onPointerDown: (_) {
          if (!_isInputActive) return;
          _pointerDownOnOverlay = true;
          if (widget.focusNode.canRequestFocus) {
            widget.focusNode.requestFocus();
          }
        },
        onPointerUp: (_) => _pointerDownOnOverlay = false,
        onPointerCancel: (_) => _pointerDownOnOverlay = false,
        child: Container(
          margin: const EdgeInsets.only(left: 4, right: 2),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: _isEnabled
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.24),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              canRequestFocus: false,
              onTap: !_isInputActive
                  ? null
                  : () {
                      setState(() {
                        _isEnabled = !_isEnabled;
                        if (!_isEnabled) {
                          _clearSuggestionState();
                        } else {
                          _onControllerChanged();
                        }
                      });
                      if (widget.focusNode.canRequestFocus) {
                        widget.focusNode.requestFocus();
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverlay());
                    },
              child: Center(
                child: Text(
                  'अ',
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverlay());

    final double? right = (widget.leftOffset == null && widget.rightOffset == null)
        ? 8.0
        : widget.rightOffset;
    final double? left = widget.leftOffset;

    return Focus(
      onKeyEvent: (node, event) => _handleKeyEvent(node, event),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_isInputActive)
              if (widget.centerVertically)
                Positioned(
                  left: left,
                  right: right,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: left != null ? Alignment.centerLeft : Alignment.centerRight,
                    child: _buildHindiToggleButton(),
                  ),
                )
              else
                Positioned(
                  left: left,
                  right: right,
                  bottom: widget.bottomOffset,
                  child: _buildHindiToggleButton(),
                ),
          ],
        ),
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
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 150),
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
