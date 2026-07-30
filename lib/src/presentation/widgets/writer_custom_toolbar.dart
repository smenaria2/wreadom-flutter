import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../localization/generated/app_localizations.dart';

class WriterCustomToolbar extends StatefulWidget {
  const WriterCustomToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onInsertImage,
    required this.isUploadingInlineImage,
    required this.onInsertVideo,
    required this.onVersionHistory,
    required this.onAiEdit,
    this.isReadOnly = false,
    this.isHindiModeEnabled = false,
    this.onToggleHindi,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final VoidCallback? onInsertImage;
  final bool isUploadingInlineImage;
  final VoidCallback? onInsertVideo;
  final VoidCallback? onVersionHistory;
  final VoidCallback? onAiEdit;
  final bool isReadOnly;
  final bool isHindiModeEnabled;
  final VoidCallback? onToggleHindi;

  @override
  State<WriterCustomToolbar> createState() => _WriterCustomToolbarState();
}

class _WriterCustomToolbarState extends State<WriterCustomToolbar> {
  final ScrollController _scrollController = ScrollController();
  bool? _wasKeyboardOpen;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
  }

  @override
  void didUpdateWidget(WriterCustomToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateState);
      widget.controller.addListener(_updateState);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  bool _isHindi(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'hi';

  String _getUndoLabel(BuildContext context) =>
      _isHindi(context) ? 'पूर्ववत' : 'Undo';
  String _getRedoLabel(BuildContext context) =>
      _isHindi(context) ? 'फिर से' : 'Redo';
  String _getBoldLabel(BuildContext context) =>
      _isHindi(context) ? 'बोल्ड' : 'Bold';
  String _getItalicLabel(BuildContext context) =>
      _isHindi(context) ? 'इटैलिक' : 'Italic';
  String _getUnderlineLabel(BuildContext context) =>
      _isHindi(context) ? 'अंडरलाइन' : 'Underline';
  String _getVersionLabel(BuildContext context) =>
      _isHindi(context) ? 'संस्करण' : 'Version';

  bool get _hasEditableText =>
      !widget.isReadOnly &&
      widget.controller.document.toPlainText().trim().isNotEmpty;

  void _hideTextInput() {
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  void _runToolbarAction(
    VoidCallback? action, {
    bool requireEditorFocus = true,
    bool hideAfterAction = true,
  }) {
    if (widget.isReadOnly || action == null) return;
    if (requireEditorFocus && !widget.focusNode.hasFocus) return;
    if (hideAfterAction) _hideTextInput();
    action();
    if (hideAfterAction) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _hideTextInput());
    } else {
      // Restore focus so the soft keyboard stays visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.focusNode.canRequestFocus) {
          widget.focusNode.requestFocus();
        }
      });
    }
  }

  void _toggleFormat(Attribute attribute) {
    _runToolbarAction(
      () {
        final styles = widget.controller.getSelectionStyle();
        final hasAttr = styles.containsKey(attribute.key);
        widget.controller.formatSelection(
          hasAttr ? Attribute.clone(attribute, null) : attribute,
        );
      },
      hideAfterAction: false,
    );
  }

  /// Scrolls to the end (formatting buttons) when keyboard opens,
  /// or scrolls to the beginning (image/media) when keyboard closes.
  void _autoScrollForKeyboard(bool keyboardOpen) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (keyboardOpen) {
        // Scroll to end: formatting tools (Undo, Redo, Bold, etc.) are at right
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        // Scroll to start: Image, Media, AI, Version, 'अ'
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Trigger auto-scroll when keyboard state changes
    if (_wasKeyboardOpen != keyboardOpen) {
      _wasKeyboardOpen = keyboardOpen;
      _autoScrollForKeyboard(keyboardOpen);
    }

    final selectionStyle = widget.controller.getSelectionStyle();
    final isBold = selectionStyle.containsKey(Attribute.bold.key);
    final isItalic = selectionStyle.containsKey(Attribute.italic.key);
    final isUnderline = selectionStyle.containsKey(Attribute.underline.key);

    // ─── Toolbar Items ───
    final imageItem = _buildItem(
      icon: widget.isUploadingInlineImage
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.image_outlined),
      label: l10n.insertImage,
      onTap: widget.isUploadingInlineImage
          ? null
          : () => _runToolbarAction(widget.onInsertImage),
      keyboardOpen: keyboardOpen,
    );

    final videoItem = _buildItem(
      icon: const Icon(Icons.play_circle_outline_rounded),
      label: l10n.insertMedia,
      onTap: () => _runToolbarAction(
        widget.onInsertVideo,
        hideAfterAction: false,
      ),
      keyboardOpen: keyboardOpen,
    );

    final aiItem = _buildItem(
      icon: const Icon(Icons.auto_awesome_rounded),
      label: l10n.aiEdit,
      onTap: widget.onAiEdit == null || !_hasEditableText
          ? null
          : () => _runToolbarAction(
              widget.onAiEdit,
              requireEditorFocus: false,
              hideAfterAction: false,
            ),
      keyboardOpen: keyboardOpen,
    );

    final versionItem = _buildItem(
      icon: const Icon(Icons.access_time_rounded),
      label: _getVersionLabel(context),
      onTap: widget.onVersionHistory == null
          ? null
          : () => _runToolbarAction(
              widget.onVersionHistory,
              requireEditorFocus: false,
            ),
      keyboardOpen: keyboardOpen,
    );

    final hindiItem = _buildItem(
      icon: Text(
        'अ',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: widget.isHindiModeEnabled
              ? theme.colorScheme.primary
              : onSurfaceColor,
        ),
      ),
      label: l10n.hindiInputMode,
      onTap: widget.isReadOnly || widget.onToggleHindi == null
          ? null
          : () {
              widget.onToggleHindi!();
              // Restore focus so the keyboard stays open
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (widget.focusNode.canRequestFocus) {
                  widget.focusNode.requestFocus();
                }
              });
            },
      isActive: widget.isHindiModeEnabled,
      keyboardOpen: keyboardOpen,
    );

    final undoItem = _buildItem(
      icon: const Icon(Icons.undo_rounded),
      label: _getUndoLabel(context),
      onTap: () => _runToolbarAction(
        widget.controller.undo,
        hideAfterAction: false,
      ),
      keyboardOpen: keyboardOpen,
    );

    final redoItem = _buildItem(
      icon: const Icon(Icons.redo_rounded),
      label: _getRedoLabel(context),
      onTap: () => _runToolbarAction(
        widget.controller.redo,
        hideAfterAction: false,
      ),
      keyboardOpen: keyboardOpen,
    );

    final boldItem = _buildItem(
      icon: Text(
        'B',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
          color: isBold ? theme.colorScheme.primary : onSurfaceColor,
        ),
      ),
      label: _getBoldLabel(context),
      onTap: () => _toggleFormat(Attribute.bold),
      isActive: isBold,
      keyboardOpen: keyboardOpen,
    );

    final italicItem = _buildItem(
      icon: Text(
        'I',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 17,
          color: isItalic ? theme.colorScheme.primary : onSurfaceColor,
        ),
      ),
      label: _getItalicLabel(context),
      onTap: () => _toggleFormat(Attribute.italic),
      isActive: isItalic,
      keyboardOpen: keyboardOpen,
    );

    final underlineItem = _buildItem(
      icon: Text(
        'U',
        style: TextStyle(
          decoration: TextDecoration.underline,
          fontSize: 17,
          color: isUnderline ? theme.colorScheme.primary : onSurfaceColor,
        ),
      ),
      label: _getUnderlineLabel(context),
      onTap: () => _toggleFormat(Attribute.underline),
      isActive: isUnderline,
      keyboardOpen: keyboardOpen,
    );

    // ─── Order: Image | Media | AI | Version | अ | Undo | Redo | Bold | Italic | Underline ───
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          imageItem,
          videoItem,
          aiItem,
          _buildDivider(),
          versionItem,
          _buildDivider(),
          hindiItem,
          _buildDivider(),
          undoItem,
          redoItem,
          _buildDivider(),
          boldItem,
          italicItem,
          underlineItem,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 1,
      height: 24,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.36),
    );
  }

  Widget _buildItem({
    required Widget icon,
    required String label,
    required VoidCallback? onTap,
    required bool keyboardOpen,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final isEnabled = !widget.isReadOnly && onTap != null;
    final baseColor = isActive
        ? theme.colorScheme.primary
        : isEnabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    // Show labels only when keyboard is closed
    final shouldShowLabel = !keyboardOpen;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: isEnabled,
        label: label,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: keyboardOpen ? 8 : 10,
              vertical: 6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: baseColor,
                    size: keyboardOpen ? 21 : 23,
                  ),
                  child: icon,
                ),
                if (shouldShowLabel) ...[
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: baseColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
