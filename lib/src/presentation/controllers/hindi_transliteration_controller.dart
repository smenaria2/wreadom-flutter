import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../data/services/devlipi_hindi_engine.dart';
import '../../domain/services/hindi_transliteration_engine.dart';

/// Controller managing Hindi transliteration state for Quill editor.
class HindiTransliterationController extends ChangeNotifier {
  HindiTransliterationController({
    HindiTransliterationEngine? engine,
  }) : _engine = engine ?? const DevlipiHindiEngine();

  final HindiTransliterationEngine _engine;

  bool _isEnabled = false;
  String? _activeRomanToken;
  int? _tokenStartOffset;
  int? _tokenEndOffset;
  List<String> _hindiSuggestions = const [];
  int _selectedIndex = 0;

  // ── Backspace-restoration state ───────────────────────────────────────────
  String? _lastCommittedRoman;
  String? _lastCommittedHindi;
  String? _lastCommittedAppended;
  int? _lastCommittedStart;

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get isEnabled => _isEnabled;
  String? get activeRomanToken => _activeRomanToken;
  int? get tokenStartOffset => _tokenStartOffset;
  int? get tokenEndOffset => _tokenEndOffset;
  List<String> get hindiSuggestions => _hindiSuggestions;
  String? get hindiSuggestion => _hindiSuggestions.firstOrNull;
  int get selectedIndex => _selectedIndex;

  String? get selectedSuggestion =>
      _hindiSuggestions.isEmpty
          ? null
          : _hindiSuggestions[_selectedIndex.clamp(0, _hindiSuggestions.length - 1)];

  bool get hasSuggestion =>
      _isEnabled &&
      _hindiSuggestions.isNotEmpty &&
      _activeRomanToken != null &&
      _tokenStartOffset != null;

  /// True when a just-committed Hindi word can be undone via [handleBackspace].
  bool get canRestoreCommit =>
      _isEnabled &&
      _lastCommittedRoman != null &&
      _lastCommittedHindi != null &&
      _lastCommittedStart != null;

  // ── Setters ───────────────────────────────────────────────────────────────

  set isEnabled(bool value) {
    if (_isEnabled == value) return;
    _isEnabled = value;
    if (!_isEnabled) {
      _clearSuggestionState();
      _clearLastCommitted();
    }
    notifyListeners();
  }

  void toggleEnabled() => isEnabled = !_isEnabled;

  // ── Keyboard navigation ───────────────────────────────────────────────────

  void selectNextSuggestion() {
    if (_hindiSuggestions.isEmpty) return;
    _selectedIndex = (_selectedIndex + 1) % _hindiSuggestions.length;
    notifyListeners();
  }

  void selectPreviousSuggestion() {
    if (_hindiSuggestions.isEmpty) return;
    _selectedIndex =
        (_selectedIndex - 1 + _hindiSuggestions.length) % _hindiSuggestions.length;
    notifyListeners();
  }

  // ── Core logic ────────────────────────────────────────────────────────────

  /// Inspects text in [controller] before caret and updates suggestion state.
  void updateForSelection(QuillController controller) {
    if (!_isEnabled) {
      if (_hasActiveState()) {
        _clearSuggestionState();
        notifyListeners();
      }
      return;
    }

    final selection = controller.selection;
    final caretOffset = selection.extentOffset;
    final plainText = controller.document.toPlainText();

    // Check if the user typed punctuation immediately after the active Roman token
    if (hasSuggestion && _tokenStartOffset != null && _tokenEndOffset != null) {
      final start = _tokenStartOffset!;
      final end = _tokenEndOffset!;
      if (caretOffset == end + 1 && caretOffset <= plainText.length) {
        final lastChar = plainText[caretOffset - 1];
        if (lastChar == '.' || lastChar == ',' || lastChar == ':') {
          final prefixText = plainText.substring(start, end);
          if (prefixText == _activeRomanToken) {
            final topSuggestion = hindiSuggestion;
            if (topSuggestion != null && topSuggestion.isNotEmpty) {
              final replacementPunc = (lastChar == '.') ? '।' : lastChar;
              final replacement = topSuggestion + replacementPunc;
              final romanToken = _activeRomanToken!;

              _clearSuggestionState();

              controller.replaceText(
                start,
                end - start + 1,
                replacement,
                TextSelection.collapsed(offset: start + replacement.length),
              );

              // Set up backspace restoration state
              _lastCommittedRoman = romanToken;
              _lastCommittedHindi = topSuggestion;
              _lastCommittedAppended = replacementPunc;
              _lastCommittedStart = start;

              notifyListeners();
              return;
            }
          }
        }
      }
    }

    if (!selection.isCollapsed || selection.extentOffset <= 0) {
      if (_hasActiveState()) {
        _clearSuggestionState();
        notifyListeners();
      }
      return;
    }

    if (caretOffset > plainText.length) {
      if (_hasActiveState()) {
        _clearSuggestionState();
        notifyListeners();
      }
      return;
    }

    // Replace single period followed by space with । followed by space
    if (caretOffset >= 2) {
      final lastChar = plainText[caretOffset - 1];
      final prevChar = plainText[caretOffset - 2];
      if (lastChar == ' ' && prevChar == '.') {
        bool isEllipsis = false;
        if (caretOffset >= 3 && plainText[caretOffset - 3] == '.') {
          isEllipsis = true;
        }
        if (!isEllipsis) {
          controller.replaceText(
            caretOffset - 2,
            1,
            '।',
            TextSelection.collapsed(offset: caretOffset),
          );
          return;
        }
      }
    }

    // If caret has moved away from the last committed position, discard restoration buffer.
    if (_lastCommittedStart != null && _lastCommittedHindi != null) {
      final appendedLen = _lastCommittedAppended?.length ?? 0;
      final expectedEndWithAppended = _lastCommittedStart! + _lastCommittedHindi!.length + appendedLen;
      final expectedEndWithoutAppended = _lastCommittedStart! + _lastCommittedHindi!.length;
      if (caretOffset != expectedEndWithAppended && caretOffset != expectedEndWithoutAppended) {
        _clearLastCommitted();
      }
    }

    // Scan backwards from caret to find start of active Roman token
    int start = caretOffset;
    while (start > 0) {
      final char = plainText[start - 1];
      if (char == ' ' || char == '\n' || char == '\t' || _isDelimiter(char)) {
        break;
      }
      start--;
    }

    if (start >= caretOffset) {
      if (_hasActiveState()) {
        _clearSuggestionState();
        notifyListeners();
      }
      return;
    }

    final token = plainText.substring(start, caretOffset);
    final suggestions = _engine.transliterateToken(token);

    if (suggestions.isNotEmpty) {
      final changed = _activeRomanToken != token ||
          _tokenStartOffset != start ||
          _tokenEndOffset != caretOffset ||
          !_listEquals(_hindiSuggestions, suggestions);
      _activeRomanToken = token;
      _tokenStartOffset = start;
      _tokenEndOffset = caretOffset;
      if (changed) {
        _hindiSuggestions = suggestions;
        _selectedIndex = 0;
        notifyListeners();
      }
    } else {
      if (_hasActiveState()) {
        _clearSuggestionState();
        notifyListeners();
      }
    }
  }

  /// Replaces the active Roman token with a chosen Hindi suggestion.
  ///
  /// Optionally appends [appendText] (e.g. a space character from Space key).
  bool commitSuggestion(
    QuillController controller, {
    String? selectedSuggestion,
    String appendText = '',
  }) {
    if (!hasSuggestion) return false;

    final replacementText = selectedSuggestion ?? this.selectedSuggestion;
    if (replacementText == null || replacementText.isEmpty) return false;

    final start = _tokenStartOffset!;
    final romanToken = _activeRomanToken!;
    final tokenLen = romanToken.length;
    final replacement = replacementText + appendText;
    final newCaretOffset = start + replacement.length;

    controller.replaceText(
      start,
      tokenLen,
      replacement,
      TextSelection.collapsed(offset: newCaretOffset),
    );

    // Store for backspace restoration
    _lastCommittedRoman = romanToken;
    _lastCommittedHindi = replacementText;
    _lastCommittedAppended = appendText;
    _lastCommittedStart = start;

    _clearSuggestionState();
    notifyListeners();
    return true;
  }

  /// Commits the currently keyboard-selected suggestion.
  bool commitSelected(QuillController controller, {String appendText = ''}) =>
      commitSuggestion(
        controller,
        selectedSuggestion: selectedSuggestion,
        appendText: appendText,
      );

  /// Handles a Backspace key press.
  ///
  /// If caret is immediately after a just-committed Hindi word (or after the space
  /// inserted by Space commit), this restores the original Roman token and re-shows
  /// the suggestion bar.
  /// Returns true if handled (caller should suppress normal backspace).
  bool handleBackspace(QuillController controller) {
    if (!canRestoreCommit) return false;

    final selection = controller.selection;
    if (!selection.isCollapsed) return false;

    final caretOffset = selection.extentOffset;
    final start = _lastCommittedStart!;
    final hindiText = _lastCommittedHindi!;
    final appendedText = _lastCommittedAppended ?? '';

    final expectedEndWithAppended = start + hindiText.length + appendedText.length;
    final expectedEndWithoutAppended = start + hindiText.length;

    int currentReplacementLen = 0;

    if (caretOffset == expectedEndWithAppended && appendedText.isNotEmpty) {
      currentReplacementLen = hindiText.length + appendedText.length;
    } else if (caretOffset == expectedEndWithoutAppended) {
      currentReplacementLen = hindiText.length;
    } else {
      _clearLastCommitted();
      return false;
    }

    final plainText = controller.document.toPlainText();
    if (start + currentReplacementLen > plainText.length) {
      _clearLastCommitted();
      return false;
    }

    final textAtPos = plainText.substring(start, start + currentReplacementLen);
    final expectedText = currentReplacementLen == (hindiText.length + appendedText.length)
        ? (hindiText + appendedText)
        : hindiText;

    if (textAtPos != expectedText) {
      _clearLastCommitted();
      return false;
    }

    // Restore the Roman token
    final romanToken = _lastCommittedRoman!;
    _clearLastCommitted();

    controller.replaceText(
      start,
      currentReplacementLen,
      romanToken,
      TextSelection.collapsed(offset: start + romanToken.length),
    );

    // Re-run suggestion detection immediately and on post-frame
    updateForSelection(controller);
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateForSelection(controller);
      });
    } catch (_) {}

    return true;
  }

  /// Dismisses current suggestion without modifying text.
  void dismissSuggestion() {
    if (_hasActiveState()) {
      _clearSuggestionState();
      notifyListeners();
    }
  }

  /// Clears suggestions when switching chapters or resetting the editor.
  void clearForChapterSwitch() {
    _clearSuggestionState();
    _clearLastCommitted();
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  bool _hasActiveState() =>
      _activeRomanToken != null ||
      _tokenStartOffset != null ||
      _tokenEndOffset != null ||
      _hindiSuggestions.isNotEmpty;

  void _clearSuggestionState() {
    _activeRomanToken = null;
    _tokenStartOffset = null;
    _tokenEndOffset = null;
    _hindiSuggestions = const [];
    _selectedIndex = 0;
  }

  void _clearLastCommitted() {
    _lastCommittedRoman = null;
    _lastCommittedHindi = null;
    _lastCommittedAppended = null;
    _lastCommittedStart = null;
  }

  bool _isDelimiter(String char) {
    const delimiters = r'.,!?;:"()[]{}<>/\|@#$%^&*+=`~';
    return delimiters.contains(char);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
