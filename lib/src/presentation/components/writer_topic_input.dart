import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../localization/generated/app_localizations.dart';
import '../providers/topic_tag_providers.dart';

class WriterTopicInput extends ConsumerStatefulWidget {
  const WriterTopicInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  ConsumerState<WriterTopicInput> createState() => _WriterTopicInputState();
}

class _WriterTopicInputState extends ConsumerState<WriterTopicInput>
    with WidgetsBindingObserver {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _inputBoxKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  final Object _tapRegionGroup = Object();
  OverlayEntry? _menuOverlay;
  Timer? _debounce;
  List<String> _suggestions = const [];
  bool _loading = false;
  bool _menuOpen = false;
  int _requestId = 0;

  List<String> get _topics => widget.controller.text
      .split(',')
      .map(_cleanTag)
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_externalValueChanged);
    _focusNode.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(covariant WriterTopicInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_externalValueChanged);
    widget.controller.addListener(_externalValueChanged);
  }

  @override
  void didChangeMetrics() {
    _menuOverlay?.markNeedsBuild();
    _keepInputVisible();
  }

  void _externalValueChanged() {
    if (mounted) setState(() {});
  }

  void _focusChanged() {
    if (!mounted) return;
    if (!_focusNode.hasFocus) {
      _menuOverlay?.markNeedsBuild();
      return;
    }
    setState(() => _menuOpen = true);
    _syncMenuOverlay();
    _keepInputVisible();
    if (_cleanTag(_inputController.text).isEmpty) {
      unawaited(_loadPopularTopics());
    }
  }

  Future<void> _loadPopularTopics() async {
    final requestId = ++_requestId;
    setState(() => _loading = true);
    try {
      final results = await ref.read(popularTopicTagsProvider.future);
      if (!mounted ||
          requestId != _requestId ||
          _cleanTag(_inputController.text).isNotEmpty) {
        return;
      }
      _setSuggestions(results);
    } catch (_) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _suggestions = const [];
          _loading = false;
        });
        _syncMenuOverlay();
      }
    }
  }

  void _inputChanged(String value) {
    if (value.contains(',')) {
      final parts = value.split(',');
      for (final part in parts.take(parts.length - 1)) {
        _commit(part);
      }
      _inputController.text = parts.last;
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
      value = parts.last;
    }

    _debounce?.cancel();
    final query = _cleanTag(value);
    setState(() => _menuOpen = true);
    _syncMenuOverlay();
    _keepInputVisible();
    if (query.isEmpty) {
      unawaited(_loadPopularTopics());
      return;
    }

    final requestId = ++_requestId;
    setState(() => _loading = true);
    _syncMenuOverlay();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await ref.read(
          topicTagSuggestionsProvider(query).future,
        );
        if (!mounted ||
            requestId != _requestId ||
            _cleanTag(_inputController.text) != query) {
          return;
        }
        _setSuggestions(results);
      } catch (_) {
        if (mounted && requestId == _requestId) {
          setState(() {
            _suggestions = const [];
            _loading = false;
          });
          _syncMenuOverlay();
        }
      }
    });
  }

  void _setSuggestions(List<String> results) {
    final selected = _topics.map(normalizeTopicTag).toSet();
    setState(() {
      _suggestions = results
          .where((tag) => !selected.contains(normalizeTopicTag(tag)))
          .toList(growable: false);
      _loading = false;
    });
    _syncMenuOverlay();
  }

  void _commit(String rawTag) {
    final tag = _cleanTag(rawTag);
    if (tag.isEmpty) return;
    final existing = _topics.map(normalizeTopicTag).toSet();
    if (!existing.contains(normalizeTopicTag(tag))) {
      widget.controller.text = [..._topics, tag].join(', ');
    }
    _requestId++;
    _inputController.clear();
    _removeMenuOverlay();
    setState(() {
      _menuOpen = false;
      _suggestions = const [];
      _loading = false;
    });
    _focusNode.requestFocus();
  }

  void _remove(String tag) {
    widget.controller.text = _topics
        .where((topic) => normalizeTopicTag(topic) != normalizeTopicTag(tag))
        .join(', ');
  }

  bool get _shouldShowMenu {
    final typedTag = _cleanTag(_inputController.text);
    return _menuOpen &&
        (typedTag.isNotEmpty || _loading || _suggestions.isNotEmpty);
  }

  void _syncMenuOverlay() {
    if (!mounted || !_shouldShowMenu) {
      _removeMenuOverlay();
      return;
    }
    if (_menuOverlay != null) {
      _menuOverlay!.markNeedsBuild();
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncMenuOverlay());
      return;
    }
    _menuOverlay = OverlayEntry(builder: _buildMenuOverlay);
    overlay.insert(_menuOverlay!);
  }

  void _removeMenuOverlay() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  void _keepInputVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus) return;
      final inputContext = _inputBoxKey.currentContext;
      if (inputContext == null) return;
      unawaited(
        Scrollable.ensureVisible(
          inputContext,
          alignment: 0.82,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  Widget _buildMenuOverlay(BuildContext overlayContext) {
    final renderBox =
        _inputBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (!_shouldShowMenu || renderBox == null || !renderBox.hasSize) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(overlayContext);
    final fieldSize = renderBox.size;
    final fieldTop = renderBox.localToGlobal(Offset.zero).dy;
    final keyboardTop = media.size.height - media.viewInsets.bottom;
    final safeTop = media.padding.top + 8;
    final spaceAbove = math.max(0.0, fieldTop - safeTop - 8);
    final fieldBottom = fieldTop + fieldSize.height;
    final spaceBelow = math.max(0.0, keyboardTop - fieldBottom - 8);
    final keyboardVisible = media.viewInsets.bottom > 0;
    final openAbove =
        keyboardVisible || (spaceBelow < 180 && spaceAbove > spaceBelow);
    final availableHeight = openAbove ? spaceAbove : spaceBelow;
    final menuHeight = math.min(280.0, availableHeight);
    if (menuHeight <= 0) return const SizedBox.shrink();

    return Positioned(
      width: fieldSize.width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: openAbove ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: openAbove ? Alignment.bottomLeft : Alignment.topLeft,
        offset: Offset(0, openAbove ? -6 : 6),
        child: TapRegion(
          groupId: _tapRegionGroup,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: menuHeight),
            child: _buildMenu(overlayContext),
          ),
        ),
      ),
    );
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    _removeMenuOverlay();
    setState(() => _menuOpen = false);
    _focusNode.unfocus();
  }

  String _cleanTag(String value) => cleanTopicTag(value);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeMenuOverlay();
    _debounce?.cancel();
    widget.controller.removeListener(_externalValueChanged);
    _focusNode.removeListener(_focusChanged);
    _focusNode.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TapRegion(
      groupId: _tapRegionGroup,
      onTapOutside: (_) => _closeMenu(),
      child: CompositedTransformTarget(
        key: _inputBoxKey,
        link: _layerLink,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focusNode.requestFocus,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.32),
              contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary, width: 1.4),
              ),
            ),
            isFocused: _focusNode.hasFocus,
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final topic in _topics)
                  InputChip(
                    key: ValueKey('writer-topic-$topic'),
                    label: Text(topic),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: colors.primary.withValues(alpha: 0.5),
                    ),
                    backgroundColor: colors.primaryContainer.withValues(
                      alpha: 0.55,
                    ),
                    deleteIconColor: colors.onPrimaryContainer,
                    onDeleted: () => _remove(topic),
                  ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 150,
                    maxWidth: 260,
                  ),
                  child: TextField(
                    key: const ValueKey('writer-topic-input'),
                    controller: _inputController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      isDense: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: _inputChanged,
                    onSubmitted: _commit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final typedTag = _cleanTag(_inputController.text);

    return Material(
      key: const ValueKey('writer-topic-menu'),
      color: colors.surface,
      elevation: 8,
      shadowColor: colors.shadow.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (typedTag.isNotEmpty)
                FilledButton.tonalIcon(
                  key: const ValueKey('create-writer-topic'),
                  onPressed: () => _commit(typedTag),
                  icon: const Icon(Icons.add_rounded),
                  label: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(l10n.createTopicTag(typedTag)),
                  ),
                ),
              if (typedTag.isNotEmpty && (_loading || _suggestions.isNotEmpty))
                const SizedBox(height: 12),
              if (_loading)
                const LinearProgressIndicator(minHeight: 2)
              else if (_suggestions.isNotEmpty) ...[
                Text(
                  typedTag.isEmpty ? l10n.popularTopics : l10n.topicSuggestions,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in _suggestions)
                      ActionChip(
                        key: ValueKey('suggested-writer-topic-$suggestion'),
                        avatar: const Icon(Icons.tag_rounded, size: 17),
                        label: Text(suggestion),
                        onPressed: () => _commit(suggestion),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
