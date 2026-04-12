import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/author.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../providers/auth_providers.dart';
import '../providers/writer_providers.dart';

class WriterPadScreen extends ConsumerStatefulWidget {
  const WriterPadScreen({
    super.key,
    this.book,
  });

  final Book? book;

  @override
  ConsumerState<WriterPadScreen> createState() => _WriterPadScreenState();
}

class _WriterPadScreenState extends ConsumerState<WriterPadScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final List<_ChapterDraft> _chapters = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.book?.description ?? '');
    for (final chapter in widget.book?.chapters ?? const <Chapter>[]) {
      _chapters.add(
        _ChapterDraft(
          title: TextEditingController(text: chapter.title),
          content: TextEditingController(text: chapter.content),
        ),
      );
    }
    if (_chapters.isEmpty) {
      _chapters.add(_ChapterDraft.empty());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final chapter in _chapters) {
      chapter.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? 'New Story' : 'Edit Story'),
        actions: [
          TextButton(
            onPressed: () => _save(status: 'draft'),
            child: const Text('Save Draft'),
          ),
          TextButton(
            onPressed: () => _save(status: 'published'),
            child: const Text('Publish'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 24),
          Text(
            'Chapters',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _chapters.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _chapters[i].title,
                      decoration: InputDecoration(labelText: 'Chapter ${i + 1} title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _chapters[i].content,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(labelText: 'Content'),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _chapters.add(_ChapterDraft.empty()));
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Chapter'),
          ),
        ],
      ),
    );
  }

  Future<void> _save({required String status}) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final chapters = <Chapter>[];
    for (var i = 0; i < _chapters.length; i++) {
      final draft = _chapters[i];
      if (draft.title.text.trim().isEmpty && draft.content.text.trim().isEmpty) {
        continue;
      }
      chapters.add(
        Chapter(
          id: widget.book?.chapters != null && i < widget.book!.chapters!.length
              ? widget.book!.chapters![i].id
              : 'chapter_${now}_$i',
          title: draft.title.text.trim().isEmpty
              ? 'Chapter ${i + 1}'
              : draft.title.text.trim(),
          content: draft.content.text.trim(),
          index: i,
          status: status == 'published' ? 'published' : 'draft',
          lastSavedAt: now,
        ),
      );
    }

    final book = Book(
      id: widget.book?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      authors: [
        Author(name: user.displayName ?? user.username, birthYear: null, deathYear: null),
      ],
      subjects: const [],
      languages: const ['en'],
      formats: const {},
      downloadCount: 0,
      mediaType: 'text',
      bookshelves: const [],
      source: 'firestore',
      isOriginal: true,
      contentType: 'story',
      authorId: user.id,
      chapters: chapters,
      status: status,
      createdAt: widget.book?.createdAt ?? now,
      updatedAt: now,
      averageRating: widget.book?.averageRating,
      viewCount: widget.book?.viewCount,
      chapterCount: chapters.length,
    );

    if (widget.book == null) {
      await ref.read(writerRepositoryProvider).createBook(book);
    } else {
      await ref.read(writerRepositoryProvider).updateBook(widget.book!.id, book);
    }
    ref.invalidate(myBooksProvider);
    if (mounted) Navigator.of(context).pop();
  }
}

class _ChapterDraft {
  _ChapterDraft({
    required this.title,
    required this.content,
  });

  factory _ChapterDraft.empty() {
    return _ChapterDraft(
      title: TextEditingController(),
      content: TextEditingController(),
    );
  }

  final TextEditingController title;
  final TextEditingController content;

  void dispose() {
    title.dispose();
    content.dispose();
  }
}
