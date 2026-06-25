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
  });

  final QuillController controller;
  final FocusNode focusNode;
  final VoidCallback? onInsertImage;
  final bool isUploadingInlineImage;
  final VoidCallback? onInsertVideo;
  final VoidCallback? onVersionHistory;

  @override
  State<WriterCustomToolbar> createState() => _WriterCustomToolbarState();
}

class _WriterCustomToolbarState extends State<WriterCustomToolbar> {
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
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _isHindi(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'hi';
  }

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

  void _hideTextInput() {
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  void _hideKeyboardAfterToolbarTap() {
    _hideTextInput();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hideTextInput();
    });
  }

  void _runToolbarAction(
    VoidCallback? action, {
    bool requireEditorFocus = true,
    bool hideAfterAction = true,
  }) {
    if (action == null) return;
    if (requireEditorFocus && !widget.focusNode.hasFocus) return;
    _hideTextInput();
    action();
    if (hideAfterAction) _hideKeyboardAfterToolbarTap();
  }

  void _toggleFormat(Attribute attribute) {
    _runToolbarAction(() {
      final styles = widget.controller.getSelectionStyle();
      final hasAttr = styles.containsKey(attribute.key);
      widget.controller.formatSelection(
        hasAttr ? Attribute.clone(attribute, null) : attribute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;

    final selectionStyle = widget.controller.getSelectionStyle();
    final isBold = selectionStyle.containsKey(Attribute.bold.key);
    final isItalic = selectionStyle.containsKey(Attribute.italic.key);
    final isUnderline = selectionStyle.containsKey(Attribute.underline.key);

    return Row(
      children: [
        _buildItem(
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
        ),
        _buildItem(
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: l10n.insertMedia,
          onTap: () =>
              _runToolbarAction(widget.onInsertVideo, hideAfterAction: false),
        ),
        _buildDivider(),
        _buildItem(
          icon: const Icon(Icons.access_time_rounded),
          label: _getVersionLabel(context),
          onTap: widget.onVersionHistory == null
              ? null
              : () => _runToolbarAction(
                  widget.onVersionHistory,
                  requireEditorFocus: false,
                ),
        ),
        _buildDivider(),
        _buildItem(
          icon: const Icon(Icons.undo_rounded),
          label: _getUndoLabel(context),
          onTap: () => _runToolbarAction(widget.controller.undo),
        ),
        _buildItem(
          icon: const Icon(Icons.redo_rounded),
          label: _getRedoLabel(context),
          onTap: () => _runToolbarAction(widget.controller.redo),
        ),
        _buildDivider(),
        _buildItem(
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
        ),
        _buildItem(
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
        ),
        _buildItem(
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
        ),
      ],
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);
    return Container(
      width: 1,
      height: 24,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.36),
    );
  }

  Widget _buildItem({
    required Widget icon,
    required String label,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;
    final baseColor = isActive
        ? theme.colorScheme.primary
        : isEnabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: baseColor, size: 23),
                child: icon,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 14,
                width: double.infinity,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: baseColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
