import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/author.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../providers/auth_providers.dart';
import '../providers/writer_taxonomy_provider.dart';
import '../providers/writer_providers.dart';
import '../utils/writer_html_codec.dart';

class WriterPadScreen extends ConsumerStatefulWidget {
  const WriterPadScreen({super.key, this.book});

  final Book? book;

  @override
  ConsumerState<WriterPadScreen> createState() => _WriterPadScreenState();
}

class _WriterPadScreenState extends ConsumerState<WriterPadScreen>
    with RestorationMixin {
  WriterTaxonomy get _taxonomy => ref.read(writerTaxonomyProvider);

  List<String> get _currentCategories => _taxonomy.categoriesFor(_contentType);

  String get _defaultCategory => _taxonomy.defaultCategoryFor(_contentType);

  List<String> get _languageOptions {
    if (_taxonomy.languages.contains(_language)) return _taxonomy.languages;
    return [..._taxonomy.languages, _language];
  }

  late final RestorableTextEditingController _titleController;
  late final RestorableTextEditingController _descriptionController;
  late final RestorableTextEditingController _topicsController;
  final RestorableInt _restorableStep = RestorableInt(0);
  final RestorableInt _restorableCurrentChapterIndex = RestorableInt(0);
  final RestorableString _restorableContentType = RestorableString('story');
  final RestorableString _restorableCategory = RestorableString('Romance');
  final RestorableString _restorableLanguage = RestorableString('English');
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final List<_ChapterDraft> _chapters = [];

  Timer? _autosaveTimer;
  String? _bookId;
  int _step = 0;
  int _currentChapterIndex = 0;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _metadataListenersAttached = false;
  String _saveStatus = 'Not saved yet';
  String _contentType = 'story';
  String _category = 'Romance';
  String _language = 'English';

  _ChapterDraft get _currentChapter => _chapters[_currentChapterIndex];

  void _setStep(int value) {
    _step = value.clamp(0, 1);
    _restorableStep.value = _step;
  }

  void _setCurrentChapterIndex(int value) {
    _currentChapterIndex = value.clamp(0, _chapters.length - 1);
    _restorableCurrentChapterIndex.value = _currentChapterIndex;
  }

  @override
  String? get restorationId => 'writer_pad_${widget.book?.id ?? 'new'}';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_titleController, 'title');
    registerForRestoration(_descriptionController, 'description');
    registerForRestoration(_topicsController, 'topics');
    registerForRestoration(_restorableStep, 'step');
    registerForRestoration(
      _restorableCurrentChapterIndex,
      'current_chapter_index',
    );
    registerForRestoration(_restorableContentType, 'content_type');
    registerForRestoration(_restorableCategory, 'category');
    registerForRestoration(_restorableLanguage, 'language');
    if (oldBucket == null) {
      _restorableContentType.value = _contentType;
      _restorableCategory.value = _category;
      _restorableLanguage.value = _language;
    }
    _step = _restorableStep.value.clamp(0, 1);
    _currentChapterIndex = _restorableCurrentChapterIndex.value.clamp(
      0,
      _chapters.length - 1,
    );
    _contentType = _contentTypeFromBook(_restorableContentType.value);
    _category = _restorableCategory.value;
    if (!_currentCategories.contains(_category)) _category = _defaultCategory;
    _language = _restorableLanguage.value.trim().isEmpty
        ? 'English'
        : _restorableLanguage.value;
    _attachMetadataListeners();
  }

  void _attachMetadataListeners() {
    if (_metadataListenersAttached) return;
    _titleController.value.addListener(_markDirty);
    _descriptionController.value.addListener(_markDirty);
    _topicsController.value.addListener(_markDirty);
    _metadataListenersAttached = true;
  }

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _bookId = book?.id;
    _titleController = RestorableTextEditingController(text: book?.title ?? '');
    _descriptionController = RestorableTextEditingController(
      text: book?.description ?? '',
    );
    _contentType = _contentTypeFromBook(book?.contentType);
    _language = _languageFromBook(book?.languages.firstOrNull);
    _category = _initialCategory(book);
    if (!_currentCategories.contains(_category)) {
      _category = _defaultCategory;
    }
    _topicsController = RestorableTextEditingController(
      text: (book?.topics ?? const <String>[]).join(', '),
    );

    for (final chapter in book?.chapters ?? const <Chapter>[]) {
      _chapters.add(_ChapterDraft.fromChapter(chapter, _markDirty));
    }
    if (_chapters.isEmpty) {
      _chapters.add(_ChapterDraft.empty(_markDirty));
    }

    _autosaveTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _autosaveDraft(),
    );
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    if (_metadataListenersAttached) {
      _titleController.value.removeListener(_markDirty);
      _descriptionController.value.removeListener(_markDirty);
      _topicsController.value.removeListener(_markDirty);
    }
    _titleController.dispose();
    _descriptionController.dispose();
    _topicsController.dispose();
    _restorableStep.dispose();
    _restorableCurrentChapterIndex.dispose();
    _restorableContentType.dispose();
    _restorableCategory.dispose();
    _restorableLanguage.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    for (final chapter in _chapters) {
      chapter.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _currentChapter.controller;

    return Scaffold(
      backgroundColor: const Color(0xFF111018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111018),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _step == 0 ? 'Writing Editor' : 'Story Details',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              _isSaving ? 'Saving...' : _saveStatus,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
          onPressed: _handleBack,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(status: 'draft'),
            child: const Text('Draft'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: _isSaving
                ? null
                : () {
                    if (_step == 0) {
                      setState(() => _setStep(1));
                    } else {
                      _save(status: 'published', closeAfterSave: true);
                    }
                  },
            child: Text(_step == 0 ? 'Next' : 'Publish'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _step == 0 ? _buildEditorStep() : _buildDetailsStep(),
        ),
      ),
      bottomNavigationBar: _step == 0 ? _buildToolbar(controller) : null,
    );
  }

  void _handleBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == 1) {
      setState(() => _setStep(0));
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildEditorStep() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('editor-step'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: _surface(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _currentChapter.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Chapter ${_currentChapterIndex + 1} title',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.36),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Chapters',
                onPressed: _showChapterSheet,
                icon: const Icon(Icons.view_list_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5EF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0D8C9)),
            ),
            child: QuillEditor(
              controller: _currentChapter.controller,
              focusNode: _editorFocusNode,
              scrollController: _editorScrollController,
              config: QuillEditorConfig(
                placeholder: 'Start writing...',
                padding: EdgeInsets.zero,
                expands: true,
                autoFocus: false,
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    const TextStyle(
                      fontSize: 17,
                      height: 1.55,
                      color: Color(0xFF241F1A),
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(8, 0),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  h1: DefaultTextBlockStyle(
                    theme.textTheme.headlineMedium!.copyWith(
                      color: const Color(0xFF201A16),
                      fontWeight: FontWeight.w800,
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(14, 6),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  h2: DefaultTextBlockStyle(
                    theme.textTheme.headlineSmall!.copyWith(
                      color: const Color(0xFF201A16),
                      fontWeight: FontWeight.w700,
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(12, 4),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  quote: DefaultTextBlockStyle(
                    const TextStyle(
                      color: Color(0xFF5F5145),
                      fontSize: 17,
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                    ),
                    const HorizontalSpacing(12, 0),
                    const VerticalSpacing(8, 8),
                    const VerticalSpacing(0, 0),
                    BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFFB65A3B), width: 4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return ListView(
      key: const ValueKey('details-step'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Story identity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _darkField(
                controller: _titleController.value,
                label: 'Title',
                hint: 'Give your work a title',
              ),
              const SizedBox(height: 14),
              _darkField(
                controller: _descriptionController.value,
                label: 'Synopsis',
                hint: 'A short pitch for readers',
                maxLines: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discovery',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _dropdown(
                label: 'Content type',
                value: _contentType,
                values: _taxonomy.contentTypes,
                onChanged: (value) {
                  setState(() {
                    _contentType = value;
                    _restorableContentType.value = _contentType;
                    if (!_currentCategories.contains(_category)) {
                      _category = _defaultCategory;
                      _restorableCategory.value = _category;
                    }
                  });
                  _markDirty();
                },
              ),
              const SizedBox(height: 14),
              _dropdown(
                label: 'Category',
                value: _category,
                values: _currentCategories,
                onChanged: (value) {
                  setState(() {
                    _category = value;
                    _restorableCategory.value = _category;
                  });
                  _markDirty();
                },
              ),
              const SizedBox(height: 14),
              _dropdown(
                label: 'Language',
                value: _language,
                values: _languageOptions,
                onChanged: (value) {
                  setState(() {
                    _language = value;
                    _restorableLanguage.value = _language;
                  });
                  _markDirty();
                },
              ),
              const SizedBox(height: 14),
              _darkField(
                controller: _topicsController.value,
                label: 'Topics',
                hint: 'magic, friendship, survival',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isSaving
              ? null
              : () => _save(status: 'published', closeAfterSave: true),
          icon: const Icon(Icons.publish_rounded),
          label: const Text('Publish Story'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : () => _save(status: 'draft'),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Draft'),
        ),
      ],
    );
  }

  Widget _buildToolbar(QuillController controller) {
    return SafeArea(
      child: Container(
        color: const Color(0xFF191722),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Chapters',
              color: Colors.white,
              onPressed: _showChapterSheet,
              icon: const Icon(Icons.menu_book_rounded),
            ),
            Expanded(
              child: QuillSimpleToolbar(
                controller: controller,
                config: QuillSimpleToolbarConfig(
                  axis: Axis.horizontal,
                  multiRowsDisplay: false,
                  showDividers: false,
                  showFontFamily: false,
                  showFontSize: false,
                  showSmallButton: false,
                  showStrikeThrough: false,
                  showInlineCode: false,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showClearFormat: false,
                  showAlignmentButtons: false,
                  showLeftAlignment: false,
                  showCenterAlignment: false,
                  showRightAlignment: false,
                  showJustifyAlignment: false,
                  showListCheck: false,
                  showCodeBlock: false,
                  showIndent: false,
                  showUndo: true,
                  showRedo: true,
                  showDirection: false,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                  color: const Color(0xFF191722),
                  toolbarSectionSpacing: 2,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Add chapter',
              color: Colors.white,
              onPressed: _addChapter,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1D1A25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.32)),
        filled: true,
        fillColor: const Color(0xFF14121B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB65A3B)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1D1A25),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: const Color(0xFF14121B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB65A3B)),
        ),
      ),
      items: values
          .map(
            (item) =>
                DropdownMenuItem(value: item, child: Text(_titleCase(item))),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  void _showChapterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17151F),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chapters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add chapter',
                    color: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _addChapter();
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              for (var i = 0; i < _chapters.length; i++)
                ListTile(
                  selected: i == _currentChapterIndex,
                  selectedTileColor: Colors.white.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  title: Text(
                    _chapters[i].title.text.trim().isEmpty
                        ? 'Chapter ${i + 1}'
                        : _chapters[i].title.text.trim(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${_chapters[i].wordCount} words',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.52),
                    ),
                  ),
                  trailing: i == _currentChapterIndex
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                  onTap: () {
                    setState(() => _setCurrentChapterIndex(i));
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _addChapter() {
    setState(() {
      _chapters.add(_ChapterDraft.empty(_markDirty));
      _setCurrentChapterIndex(_chapters.length - 1);
      _isDirty = true;
    });
  }

  Future<void> _autosaveDraft() async {
    if (!_isDirty || _isSaving || !_hasSavableContent) return;
    await _save(status: 'draft', isAutosave: true);
  }

  Future<void> _save({
    required String status,
    bool closeAfterSave = false,
    bool isAutosave = false,
  }) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null || _isSaving) return;

    final title = _titleController.value.text.trim();
    if (title.isEmpty && !isAutosave) {
      _showSnack('Add a title before saving.');
      setState(() => _setStep(1));
      return;
    }

    setState(() {
      _isSaving = true;
      _saveStatus = status == 'published' ? 'Publishing...' : 'Saving draft...';
    });

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final chapters = <Chapter>[];
      for (var i = 0; i < _chapters.length; i++) {
        final draft = _chapters[i];
        final content = htmlFromDocument(draft.controller.document);
        final plainContent = plainTextFromHtml(content);
        if (draft.title.text.trim().isEmpty && plainContent.isEmpty) continue;
        chapters.add(
          Chapter(
            id: draft.id ?? 'chapter_${now}_$i',
            title: draft.title.text.trim().isEmpty
                ? 'Chapter ${i + 1}'
                : draft.title.text.trim(),
            content: content,
            index: i,
            status: status == 'published' ? 'published' : 'draft',
            lastSavedAt: now,
            versions: draft.original?.versions,
            isTitleLocked: draft.original?.isTitleLocked,
            originalBookId: draft.original?.originalBookId,
          ),
        );
      }

      final topics = _topicsController.value.text
          .split(',')
          .map((topic) => topic.trim())
          .where((topic) => topic.isNotEmpty)
          .toList();
      final subjects = <String>{_category, ...topics}.toList();
      final book = Book(
        id: _bookId ?? widget.book?.id ?? '',
        title: title.isEmpty ? 'Untitled Story' : title,
        description: _descriptionController.value.text.trim(),
        coverUrl: widget.book?.coverUrl,
        authors: [
          Author(
            name: user.displayName ?? user.username,
            birthYear: null,
            deathYear: null,
          ),
        ],
        subjects: subjects,
        languages: [_language],
        formats: widget.book?.formats ?? const {},
        downloadCount: widget.book?.downloadCount ?? 0,
        mediaType: widget.book?.mediaType ?? 'text',
        bookshelves: widget.book?.bookshelves ?? const [],
        year: widget.book?.year,
        source: 'firestore',
        isOriginal: true,
        contentType: _contentType,
        authorId: user.id,
        chapters: chapters,
        status: status,
        createdAt: widget.book?.createdAt ?? now,
        updatedAt: now,
        identifier: widget.book?.identifier,
        recommendationCount: widget.book?.recommendationCount,
        weightedScore: widget.book?.weightedScore,
        averageRating: widget.book?.averageRating,
        viewCount: widget.book?.viewCount,
        ratingsCount: widget.book?.ratingsCount,
        topics: topics,
        chapterCount: chapters.length,
      );

      if ((_bookId ?? widget.book?.id ?? '').isEmpty) {
        _bookId = await ref.read(writerRepositoryProvider).createBook(book);
      } else {
        await ref.read(writerRepositoryProvider).updateBook(_bookId!, book);
      }
      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
      if (!mounted) return;
      setState(() {
        _isDirty = false;
        _isSaving = false;
        _saveStatus = status == 'published' ? 'Published' : 'Draft saved';
      });
      if (!isAutosave) {
        _showSnack(status == 'published' ? 'Story published.' : 'Draft saved.');
      }
      if (closeAfterSave && mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveStatus = 'Save failed';
      });
      if (!isAutosave) _showSnack('Could not save: $error');
    }
  }

  bool get _hasSavableContent {
    if (_titleController.value.text.trim().isNotEmpty) return true;
    return _chapters.any((chapter) {
      return plainTextFromHtml(
        htmlFromDocument(chapter.controller.document),
      ).isNotEmpty;
    });
  }

  void _markDirty() {
    if (!mounted) return;
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
        _saveStatus = 'Unsaved changes';
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _initialCategory(Book? book) {
    final subjects = book?.subjects ?? const <String>[];
    for (final subject in subjects) {
      final match = _taxonomy.allCategories.where(
        (category) => category.toLowerCase() == subject.toLowerCase(),
      );
      if (match.isNotEmpty) return match.first;
    }
    return _defaultCategory;
  }

  String _contentTypeFromBook(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'poetry') return 'poem';
    if (normalized != null && _taxonomy.contentTypes.contains(normalized)) {
      return normalized;
    }
    return 'story';
  }

  String _languageFromBook(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return 'English';
    const aliases = {
      'en': 'English',
      'eng': 'English',
      'english': 'English',
      'hi': 'Hindi',
      'hin': 'Hindi',
      'hindi': 'Hindi',
      'bn': 'Bengali',
      'bengali': 'Bengali',
      'te': 'Telugu',
      'telugu': 'Telugu',
      'mr': 'Marathi',
      'marathi': 'Marathi',
      'ta': 'Tamil',
      'tamil': 'Tamil',
      'gu': 'Gujarati',
      'gujarati': 'Gujarati',
      'ur': 'Urdu',
      'urdu': 'Urdu',
      'kn': 'Kannada',
      'kannada': 'Kannada',
      'ml': 'Malayalam',
      'malayalam': 'Malayalam',
      'ar': 'Arabic',
      'arabic': 'Arabic',
      'fr': 'French',
      'french': 'French',
      'de': 'German',
      'german': 'German',
      'es': 'Spanish',
      'spanish': 'Spanish',
      'pt': 'Portuguese',
      'portuguese': 'Portuguese',
      'ru': 'Russian',
      'russian': 'Russian',
      'zh': 'Chinese',
      'chinese': 'Chinese',
      'ja': 'Japanese',
      'japanese': 'Japanese',
      'ko': 'Korean',
      'korean': 'Korean',
    };
    return aliases[normalized] ?? value!.trim();
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class _ChapterDraft {
  _ChapterDraft({
    required this.title,
    required this.controller,
    required this.original,
    required this.id,
    required VoidCallback onChanged,
  }) : _onChanged = onChanged {
    _attachListeners();
  }

  factory _ChapterDraft.fromChapter(Chapter chapter, VoidCallback onChanged) {
    return _ChapterDraft(
      id: chapter.id,
      title: TextEditingController(text: chapter.title),
      controller: QuillController(
        document: documentFromHtml(chapter.content),
        selection: const TextSelection.collapsed(offset: 0),
      ),
      original: chapter,
      onChanged: onChanged,
    );
  }

  factory _ChapterDraft.empty(VoidCallback onChanged) {
    return _ChapterDraft(
      id: null,
      title: TextEditingController(),
      controller: QuillController.basic(),
      original: null,
      onChanged: onChanged,
    );
  }

  final String? id;
  final TextEditingController title;
  final QuillController controller;
  final Chapter? original;
  final VoidCallback _onChanged;
  late final StreamSubscription<dynamic> _documentChanges;
  late int wordCount;

  void _handleDocumentChanged() {
    _refreshWordCount();
    _onChanged();
  }

  void _refreshWordCount() {
    wordCount = wordCountFromHtml(htmlFromDocument(controller.document));
  }

  void _attachListeners() {
    title.addListener(_onChanged);
    _refreshWordCount();
    _documentChanges = controller.document.changes.listen(
      (_) => _handleDocumentChanged(),
    );
  }

  void dispose() {
    title.removeListener(_onChanged);
    _documentChanges.cancel();
    title.dispose();
    controller.dispose();
  }
}
