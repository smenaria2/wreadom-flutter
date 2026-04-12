import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/book.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/bookmark_providers.dart';
import '../providers/comment_providers.dart';

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
  bool _sepia = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.initialChapterIndex;
  }

  @override
  void dispose() {
    _commentController.dispose();
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
            icon: const Icon(Icons.tune),
            onPressed: _showSettings,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => _addBookmark(chapter),
          ),
        ],
      ),
      body: Container(
        color: _sepia ? const Color(0xFFF4ECD8) : null,
        child: Column(
          children: [
            if (chapters.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: chapters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ChoiceChip(
                    selected: index == _chapterIndex,
                    label: Text('Chapter ${index + 1}'),
                    onSelected: (_) => setState(() => _chapterIndex = index),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    chapter?.title ?? widget.book.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _plainText(
                      chapter?.content ?? widget.book.description ?? 'No readable content available yet.',
                    ),
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.8,
                      color: const Color(0xFF2E261B),
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
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(comment.displayName ?? comment.username),
                            subtitle: Text(comment.text),
                          ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text('Failed to load comments: $error'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add a comment about this chapter',
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
    await ref.read(commentRepositoryProvider).addComment(
          Comment(
            bookId: widget.book.id,
            bookTitle: widget.book.title,
            userId: user.id,
            username: user.username,
            displayName: user.displayName,
            penName: user.penName,
            text: text,
            chapterTitle: chapter?.title,
            chapterIndex: _chapterIndex,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            userPhotoURL: user.photoURL,
          ),
        );
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
                  value: _sepia,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sepia Theme'),
                  onChanged: (value) {
                    setState(() => _sepia = value);
                    setModalState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _plainText(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
