import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/bookmark_providers.dart';
import '../providers/comment_providers.dart';
import '../widgets/comment_widgets.dart';

enum ReaderTheme { light, sepia, dark }
enum ReaderFont { sans, serif }

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.book,
    this.initialChapterIndex = 0,
  });

  final Book book;
  final int initialChapterIndex;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late int _chapterIndex;
  double _fontSize = 18;
  ReaderTheme _readerTheme = ReaderTheme.sepia;
  ReaderFont _readerFont = ReaderFont.serif;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Comment? _replyingTo;
  String? _selectedQuote;
  String _selectedText = "";
  final bool _isRestored = false;

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.initialChapterIndex;
    _saveHistory();
    _restoreScrollPosition();
  }

  Future<void> _restoreScrollPosition() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null && user.readingProgress?.containsKey(widget.book.id.toString()) == true) {
      final progress = user.readingProgress![widget.book.id.toString()] as Map<String, dynamic>;
      final savedChapterIndex = progress['chapterIndex'] as int? ?? 0;
      final savedPosition = progress['position'] as double? ?? 0.0;

      if (savedChapterIndex == _chapterIndex && savedPosition > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            _scrollController.animateTo(
              savedPosition * maxScroll,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  Future<void> _saveHistory() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      await ref.read(bookRepositoryProvider).updateReadingHistory(user.id, widget.book.id.toString());
    }
  }

  Future<void> _saveProgress() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      double position = 0.0;
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        position = _scrollController.offset / _scrollController.position.maxScrollExtent;
      }

      await ref.read(bookRepositoryProvider).updateReadingProgress(
            user.id,
            widget.book.id.toString(),
            chapterIndex: _chapterIndex,
            position: position,
          );
    }
  }

  @override
  void dispose() {
    _saveProgress();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.book.chapters ?? const [];
    final chapter = chapters.isEmpty
        ? null
        : chapters[_chapterIndex.clamp(0, chapters.length - 1)];
    final bookmarksAsync = ref.watch(bookBookmarksProvider(widget.book.id));
    final commentsAsync = ref.watch(bookCommentsProvider(widget.book.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            onPressed: _showSettings,
            tooltip: 'Reader Settings',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => _addBookmark(chapter),
            tooltip: 'Add Bookmark',
          ),
        ],
      ),
      drawer: _ChapterDrawer(
        chapters: chapters,
        currentIndex: _chapterIndex,
        onSelect: (index) {
          setState(() => _chapterIndex = index);
          _saveProgress();
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        color: _getBackgroundColor(),
        child: Column(
          children: [
            // Removed horizontal chips - now in Drawer
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    chapter?.title ?? widget.book.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SelectionArea(
                    onSelectionChanged: (content) {
                      setState(() {
                        _selectedText = content?.plainText ?? "";
                      });
                    },
                    contextMenuBuilder: (context, selectableRegionState) {
                      final List<ContextMenuButtonItem> buttonItems =
                          selectableRegionState.contextMenuButtonItems;
                      buttonItems.insert(
                        0,
                        ContextMenuButtonItem(
                          label: 'Quote & Comment',
                          onPressed: () {
                            setState(() {
                              _selectedQuote = _selectedText;
                              _replyingTo = null;
                            });
                            // Close menu
                            selectableRegionState.hideToolbar();
                            // Scroll to comment section
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      );
                      return AdaptiveTextSelectionToolbar.buttonItems(
                        anchors: selectableRegionState.contextMenuAnchors,
                        buttonItems: buttonItems,
                      );
                    },
                    child: Text(
                      _plainText(
                        chapter?.content ?? widget.book.description ?? 'No readable content available yet.',
                      ),
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: 1.8,
                        color: _getTextColor(),
                        fontFamily: _readerFont == ReaderFont.serif ? 'Serif' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bookmarks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  bookmarksAsync.when(
                    data: (items) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: items.isEmpty
                          ? const [Text('No bookmarks yet')]
                          : items
                              .map(
                                (item) => InputChip(
                                  label: Text(item.label),
                                  onDeleted: item.id == null
                                      ? null
                                      : () async {
                                          await ref
                                              .read(bookmarkRepositoryProvider)
                                              .removeBookmark(item.id!);
                                          ref.invalidate(bookBookmarksProvider(widget.book.id));
                                          ref.invalidate(userBookmarksProvider);
                                        },
                                ),
                              )
                              .toList(),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text('Failed to load bookmarks: $error'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Discussion',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  commentsAsync.when(
                    data: (items) => Column(
                      children: [
                        for (final comment in items)
                          CommentTile(
                            comment: comment,
                            onReply: () {
                              setState(() => _replyingTo = comment);
                              FocusScope.of(context).requestFocus();
                            },
                          ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text('Failed to load comments: $error'),
                  ),
                  if (_selectedQuote != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.format_quote, size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              const Text('Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _selectedQuote = null),
                                child: const Icon(Icons.close, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedQuote!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  if (_replyingTo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Replying to ${_replyingTo!.displayName ?? _replyingTo!.username}',
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _replyingTo = null),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _commentController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _replyingTo != null
                          ? 'Add a reply...'
                          : 'Add a comment about this chapter',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => _submitComment(chapter),
                      child: const Text('Comment'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBookmark(dynamic chapter) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    final label = chapter?.title ?? widget.book.title;
    await ref.read(bookmarkRepositoryProvider).addBookmark(
          Bookmark(
            userId: user.id,
            bookId: widget.book.id,
            position: _chapterIndex.toDouble(),
            label: label,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            chapterTitle: chapter?.title,
            chapterIndex: _chapterIndex,
          ),
        );
    ref.invalidate(bookBookmarksProvider(widget.book.id));
    ref.invalidate(userBookmarksProvider);
  }

  Future<void> _submitComment(dynamic chapter) async {
    final text = _commentController.text.trim();
    final user = await ref.read(currentUserProvider.future);
    if (text.isEmpty || user == null) return;

    if (_replyingTo != null) {
      await ref.read(commentRepositoryProvider).addReply(
            _replyingTo!.id!,
            CommentReply(
              userId: user.id,
              username: user.username,
              displayName: user.displayName,
              penName: user.penName,
              text: text,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              userPhotoURL: user.photoURL,
            ),
          );
      setState(() => _replyingTo = null);
    } else {
      await ref.read(commentRepositoryProvider).addComment(
            Comment(
              bookId: widget.book.id,
              bookTitle: widget.book.title,
              userId: user.id,
              username: user.username,
              displayName: user.displayName,
              penName: user.penName,
              text: text,
              quote: _selectedQuote,
              chapterTitle: chapter?.title,
              chapterIndex: _chapterIndex,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              userPhotoURL: user.photoURL,
            ),
          );
      setState(() => _selectedQuote = null);
    }
    _commentController.clear();
    ref.invalidate(bookCommentsProvider(widget.book.id));
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reader Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Font Size: ${_fontSize.toStringAsFixed(0)}'),
                Slider(
                  value: _fontSize,
                  min: 14,
                  max: 28,
                  onChanged: (value) {
                    setState(() => _fontSize = value);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  value: _readerFont == ReaderFont.serif,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Serif Font'),
                  onChanged: (value) {
                    setState(() => _readerFont = value ? ReaderFont.serif : ReaderFont.sans);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 8),
                const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ThemeOption(
                      label: 'Light',
                      color: Colors.white,
                      selected: _readerTheme == ReaderTheme.light,
                      onTap: () {
                        setState(() => _readerTheme = ReaderTheme.light);
                        setModalState(() {});
                      },
                    ),
                    _ThemeOption(
                      label: 'Sepia',
                      color: const Color(0xFFF4ECD8),
                      selected: _readerTheme == ReaderTheme.sepia,
                      onTap: () {
                        setState(() => _readerTheme = ReaderTheme.sepia);
                        setModalState(() {});
                      },
                    ),
                    _ThemeOption(
                      label: 'Dark',
                      color: const Color(0xFF1A1A1A),
                      textColor: Colors.white,
                      selected: _readerTheme == ReaderTheme.dark,
                      onTap: () {
                        setState(() => _readerTheme = ReaderTheme.dark);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return Colors.white;
      case ReaderTheme.sepia:
        return const Color(0xFFF4ECD8);
      case ReaderTheme.dark:
        return const Color(0xFF121212);
    }
  }

  Color _getTextColor() {
    switch (_readerTheme) {
      case ReaderTheme.light:
      case ReaderTheme.sepia:
        return const Color(0xFF2E261B);
      case ReaderTheme.dark:
        return const Color(0xFFE0E0E0);
    }
  }

  String _plainText(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}

class _ChapterDrawer extends StatelessWidget {
  final List<Chapter> chapters;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _ChapterDrawer({
    required this.chapters,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Center(
              child: Text(
                'Chapters',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final isSelected = index == currentIndex;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  title: Text(
                    'Chapter ${index + 1}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.color,
    this.textColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.blue : Colors.grey.withOpacity(0.5),
                width: selected ? 3 : 1,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
