import 'package:flutter/material.dart';

import '../../../domain/models/book.dart';
import '../../../localization/generated/app_localizations.dart';
import '../../utils/writer_html_codec.dart';

typedef ImportDraftsPage = ({List<Book> drafts, int? nextOffset});

/// Bottom sheet that lists single-chapter drafts page by page and returns the
/// drafts the user selected. It opens immediately and loads page 1 itself.
class ImportDraftsSheet extends StatefulWidget {
  const ImportDraftsSheet({
    super.key,
    required this.loadPage,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  /// Loads the page starting at `offset` (0 for the first page).
  final Future<ImportDraftsPage> Function(int offset) loadPage;
  final Color surfaceColor;
  final Color onSurfaceColor;

  @override
  State<ImportDraftsSheet> createState() => _ImportDraftsSheetState();
}

class _ImportDraftsSheetState extends State<ImportDraftsSheet> {
  final List<Book> _drafts = [];
  // Kept across pages so earlier selections survive "Load more".
  final Map<String, Book> _selected = {};
  int? _nextOffset;
  bool _loading = false;
  bool _loadedFirstPage = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadNext(0);
  }

  Future<void> _loadNext(int offset) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.loadPage(offset);
      if (!mounted) return;
      setState(() {
        _drafts.addAll(page.drafts);
        _nextOffset = page.nextOffset;
        _loadedFirstPage = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = widget.onSurfaceColor;
    final selectedDrafts = _selected.values.toList();

    Widget body;
    if (!_loadedFirstPage && _error == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!_loadedFirstPage) {
      body = _ErrorView(
        message: l10n.couldNotImportDrafts('$_error'),
        retryLabel: l10n.retry,
        color: textColor,
        onRetry: () => _loadNext(0),
      );
    } else if (_drafts.isEmpty && _nextOffset == null) {
      body = Center(
        child: Text(
          l10n.noSingleChapterDraftsToImport,
          style: TextStyle(color: textColor.withValues(alpha: 0.7)),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        itemCount: _drafts.length + 1,
        itemBuilder: (context, i) {
          if (i == _drafts.length) return _buildFooter(l10n, textColor);
          final draft = _drafts[i];
          final chapter = draft.chapters!.first;
          final preview = plainTextFromHtml(chapter.content);
          return CheckboxListTile(
            value: _selected.containsKey(draft.id),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selected[draft.id] = draft;
                } else {
                  _selected.remove(draft.id);
                }
              });
            },
            activeColor: theme.colorScheme.primary,
            checkColor: theme.colorScheme.onPrimary,
            title: Text(
              draft.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              preview.isEmpty
                  ? l10n.noContentYet
                  : preview.length > 96
                  ? '${preview.substring(0, 96).trim()}...'
                  : preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor.withValues(alpha: 0.66)),
            ),
            secondary: Icon(
              Icons.description_outlined,
              color: textColor.withValues(alpha: 0.7),
            ),
          );
        },
      );
    }

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.importFromDrafts,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  color: textColor,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(child: body),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: selectedDrafts.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(selectedDrafts),
                icon: const Icon(Icons.download_done_rounded),
                label: Text(l10n.importSelectedDrafts(selectedDrafts.length)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n, Color textColor) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _ErrorView(
        message: l10n.couldNotImportDrafts('$_error'),
        retryLabel: l10n.retry,
        color: textColor,
        onRetry: () => _loadNext(_nextOffset ?? 0),
      );
    }
    final next = _nextOffset;
    if (next == null) return const SizedBox.shrink();
    return Center(
      child: TextButton(
        onPressed: () => _loadNext(next),
        child: Text(l10n.loadMore),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.color,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final Color color;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: TextStyle(color: color)),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
