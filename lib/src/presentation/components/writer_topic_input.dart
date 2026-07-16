import 'dart:async';

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

class _WriterTopicInputState extends ConsumerState<WriterTopicInput> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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

  void _externalValueChanged() {
    if (mounted) setState(() {});
  }

  void _focusChanged() {
    if (!_focusNode.hasFocus || !mounted) return;
    setState(() => _menuOpen = true);
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
    if (query.isEmpty) {
      unawaited(_loadPopularTopics());
      return;
    }

    final requestId = ++_requestId;
    setState(() => _loading = true);
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

  void _closeMenu() {
    if (!_menuOpen) return;
    setState(() => _menuOpen = false);
    _focusNode.unfocus();
  }

  String _cleanTag(String value) => cleanTopicTag(value);

  @override
  void dispose() {
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
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final typedTag = _cleanTag(_inputController.text);
    final showMenu =
        _menuOpen &&
        (typedTag.isNotEmpty || _loading || _suggestions.isNotEmpty);

    return TapRegion(
      onTapOutside: (_) => _closeMenu(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focusNode.requestFocus,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: widget.label,
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(
                  alpha: 0.32,
                ),
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
          if (showMenu)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
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
                  if (typedTag.isNotEmpty &&
                      (_loading || _suggestions.isNotEmpty))
                    const SizedBox(height: 12),
                  if (_loading)
                    const LinearProgressIndicator(minHeight: 2)
                  else if (_suggestions.isNotEmpty) ...[
                    Text(
                      typedTag.isEmpty
                          ? l10n.popularTopics
                          : l10n.topicSuggestions,
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
        ],
      ),
    );
  }
}
