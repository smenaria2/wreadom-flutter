import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/author.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/user_model.dart';
import '../../localization/generated/app_localizations.dart';
import '../../utils/book_collaboration_utils.dart';
import '../providers/auth_providers.dart';
import '../providers/follow_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/writer_taxonomy_provider.dart';
import '../providers/writer_providers.dart';
import '../utils/writer_html_codec.dart';
import '../utils/writer_media_utils.dart';
import '../widgets/writer_media_embed.dart';

class WriterPadScreen extends ConsumerStatefulWidget {
  const WriterPadScreen({super.key, this.book, this.initialTopic});

  final Book? book;
  final String? initialTopic;

  @override
  ConsumerState<WriterPadScreen> createState() => _WriterPadScreenState();
}

class _WriterPadScreenState extends ConsumerState<WriterPadScreen>
    with RestorationMixin, WidgetsBindingObserver {
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
  final RestorableString _restorableLanguage = RestorableString('Hindi');
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<_ChapterDraft> _chapters = [];

  Timer? _autosaveTimer;
  String? _bookId;
  late final String _localDraftId;
  int _step = 0;
  int _currentChapterIndex = 0;
  bool _isSaving = false;
  bool _isUploadingInlineImage = false;
  bool _isUploadingCover = false;
  bool _isDirty = false;
  bool _isLocalDirty = false;
  bool _isRestoringLocalDraft = false;
  bool _metadataListenersAttached = false;
  bool _bookTitleEditedByUser = false;
  bool _syncingBookTitleFromChapter = false;
  String _saveStatus = 'Not saved yet';
  String _contentType = 'story';
  String _category = 'Romance';
  String _language = 'Hindi';
  String? _coverUrl;
  bool _collabEnabled = false;
  String? _selectedCollaboratorId;
  String? _selectedCollaboratorName;
  String? _selectedCollaboratorPhotoURL;

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
        ? 'Hindi'
        : _restorableLanguage.value;
    _attachMetadataListeners();
  }

  void _attachMetadataListeners() {
    if (_metadataListenersAttached) return;
    _titleController.value.addListener(_handleBookTitleChanged);
    _descriptionController.value.addListener(_markDirty);
    _topicsController.value.addListener(_markDirty);
    _metadataListenersAttached = true;
  }

  void _handleBookTitleChanged() {
    if (!_syncingBookTitleFromChapter && widget.book == null) {
      _bookTitleEditedByUser = true;
    }
    _markDirty();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final book = widget.book;
    _bookId = book?.id;
    _localDraftId =
        book?.id ??
        'new_${DateTime.now().millisecondsSinceEpoch}_${identityHashCode(this)}';
    _coverUrl = book?.coverUrl;
    _titleController = RestorableTextEditingController(text: book?.title ?? '');
    _descriptionController = RestorableTextEditingController(
      text: book?.description ?? '',
    );
    _contentType = _contentTypeFromBook(book?.contentType);
    _language = _languageFromBook(book?.languages.firstOrNull);
    _category = _initialCategory(book);
    _collabEnabled =
        book?.collaboratorId?.trim().isNotEmpty == true &&
        book?.collaborationStatus != collaborationStatusDeclined;
    _selectedCollaboratorId = book?.collaboratorId?.trim();
    _selectedCollaboratorName = book?.collaboratorName?.trim();
    _selectedCollaboratorPhotoURL = book?.collaboratorPhotoURL?.trim();
    if (!_currentCategories.contains(_category)) {
      _category = _defaultCategory;
    }
    _topicsController = RestorableTextEditingController(
      text: _initialTopicsText(book),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreLocalDraft());
    });
  }

  String _initialTopicsText(Book? book) {
    final topics = <String>{...(book?.topics ?? const <String>[])};
    if (book == null) {
      final initialTopic = widget.initialTopic?.trim();
      if (initialTopic != null && initialTopic.isNotEmpty) {
        topics.add(initialTopic);
      }
    }
    return topics.join(', ');
  }

  String _draftKey(String userId) {
    return '$userId:${_bookId ?? widget.book?.id ?? _localDraftId}';
  }

  Future<void> _restoreLocalDraft() async {
    final user = await _currentUserOrNull();
    if (!mounted || user == null) return;

    final draft = await ref
        .read(writerDraftServiceProvider)
        .getDraft(_draftKey(user.id));
    if (!mounted || draft == null) return;

    _isRestoringLocalDraft = true;
    setState(() {
      _titleController.value.text = draft.title == 'Untitled Story'
          ? ''
          : draft.title;
      _descriptionController.value.text = draft.description ?? '';
      _coverUrl = draft.coverUrl;
      _contentType = _contentTypeFromBook(draft.contentType);
      _restorableContentType.value = _contentType;
      _language = _languageFromBook(draft.languages.firstOrNull);
      _restorableLanguage.value = _language;
      _category = _initialCategory(draft);
      if (!_currentCategories.contains(_category)) {
        _category = _defaultCategory;
      }
      _restorableCategory.value = _category;
      _topicsController.value.text = _initialTopicsText(draft);
      for (final chapter in _chapters) {
        chapter.dispose();
      }
      _chapters
        ..clear()
        ..addAll(
          (draft.chapters ?? const <Chapter>[]).map(
            (chapter) => _ChapterDraft.fromChapter(chapter, _markDirty),
          ),
        );
      if (_chapters.isEmpty) {
        _chapters.add(_ChapterDraft.empty(_markDirty));
      }
      _setCurrentChapterIndex(
        _currentChapterIndex.clamp(0, _chapters.length - 1),
      );
      _isDirty = true;
      _isLocalDirty = false;
      _saveStatus = AppLocalizations.of(context)!.savedOnDevice;
    });
    _isRestoringLocalDraft = false;
  }

  Future<UserModel?> _currentUserOrNull() async {
    try {
      return await ref.read(currentUserProvider.future);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    if (_metadataListenersAttached) {
      _titleController.value.removeListener(_handleBookTitleChanged);
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_syncDraftCheckpoint());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _currentChapter.controller;
    final chromeColor = _writerChromeColor(context);
    final onChromeColor = _onWriterChromeColor(context);

    return Scaffold(
      backgroundColor: chromeColor,
      appBar: AppBar(
        backgroundColor: chromeColor,
        foregroundColor: onChromeColor,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _step == 0 ? l10n.writerWritingEditor : l10n.writerContentDetails,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              _isSaving ? l10n.writerSaving : _saveStatus,
              style: TextStyle(
                color: onChromeColor.withValues(alpha: 0.58),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: l10n.back,
          icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
          onPressed: _handleBack,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(status: 'draft'),
            child: Text(
              widget.book?.status == 'published'
                  ? l10n.writerConvertToDraft
                  : l10n.writerDraft,
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: _isSaving
                ? null
                : () {
                    if (_step == 0) {
                      _populateSynopsisFromFirstLines();
                      unawaited(_syncDraftCheckpoint());
                      setState(() => _setStep(1));
                    } else {
                      _save(status: 'published', closeAfterSave: true);
                    }
                  },
            child: Text(_step == 0 ? l10n.writerNext : l10n.writerPublish),
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

  Future<void> _handleBack() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == 1) {
      setState(() => _setStep(0));
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      await _syncDraftCheckpoint();
      if (!mounted) return;
      navigator.pop();
    }
  }

  Widget _buildEditorStep() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final paperColor = _writerPaperColor(context);
    final paperTextColor = _writerPaperTextColor(context);
    final paperMutedColor = paperTextColor.withValues(alpha: 0.72);
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
                    style: TextStyle(
                      color: _onWriterSurfaceColor(context),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: l10n.writerChapterTitleHint(
                        _currentChapterIndex + 1,
                      ),
                      hintStyle: TextStyle(
                        color: _onWriterSurfaceColor(
                          context,
                        ).withValues(alpha: 0.36),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: l10n.writerChapters,
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
              color: paperColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: QuillEditor(
              controller: _currentChapter.controller,
              focusNode: _editorFocusNode,
              scrollController: _editorScrollController,
              config: QuillEditorConfig(
                embedBuilders: const [
                  WriterImageEmbedBuilder(),
                  WriterMediaEmbedBuilder(),
                ],
                placeholder: l10n.writerStartWriting,
                padding: EdgeInsets.zero,
                expands: true,
                autoFocus: false,
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 17,
                      height: 1.55,
                      color: paperTextColor,
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(8, 0),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  h1: DefaultTextBlockStyle(
                    theme.textTheme.headlineMedium!.copyWith(
                      color: paperTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(14, 6),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  h2: DefaultTextBlockStyle(
                    theme.textTheme.headlineSmall!.copyWith(
                      color: paperTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(12, 4),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  quote: DefaultTextBlockStyle(
                    TextStyle(
                      color: paperMutedColor,
                      fontSize: 17,
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                    ),
                    const HorizontalSpacing(12, 0),
                    const VerticalSpacing(8, 8),
                    const VerticalSpacing(0, 0),
                    BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 4,
                        ),
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
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      key: const ValueKey('details-step'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.writerContentIdentity,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _onWriterSurfaceColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _darkField(
                controller: _titleController.value,
                label: l10n.title,
                hint: l10n.writerTitleHint,
              ),
              const SizedBox(height: 14),
              _darkField(
                controller: _descriptionController.value,
                label: l10n.synopsis,
                hint: l10n.writerSynopsisHint,
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
                l10n.writerCoverOptional,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _onWriterSurfaceColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 96,
                    height: 144,
                    decoration: BoxDecoration(
                      color: _writerFieldColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      image: _coverUrl == null
                          ? null
                          : DecorationImage(
                              image: NetworkImage(_coverUrl!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: _coverUrl == null
                        ? Icon(
                            Icons.auto_stories_outlined,
                            color: _onWriterSurfaceColor(
                              context,
                            ).withValues(alpha: 0.42),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _isUploadingCover ? null : _pickCover,
                          icon: _isUploadingCover
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            _isUploadingCover
                                ? l10n.writerUploading
                                : l10n.writerUploadCover,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _coverUrl == null || _isUploadingCover
                              ? null
                              : () {
                                  setState(() => _coverUrl = null);
                                  _markDirty();
                                },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(l10n.remove),
                        ),
                      ],
                    ),
                  ),
                ],
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
                l10n.writerDiscovery,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _onWriterSurfaceColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _dropdown(
                label: l10n.contentType,
                value: _contentType,
                values: _taxonomy.contentTypes,
                displayLabel: _localizedContentType,
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
                label: l10n.category,
                value: _category,
                values: _currentCategories,
                displayLabel: _localizedCategory,
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
                label: l10n.language,
                value: _language,
                values: _languageOptions,
                displayLabel: _localizedLanguage,
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
                label: l10n.topicsOptional,
                hint: l10n.topicsHint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildCollaborationSection(),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isSaving
              ? null
              : () => _save(status: 'published', closeAfterSave: true),
          icon: const Icon(Icons.publish_rounded),
          label: Text(l10n.publishContent),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : () => _save(status: 'draft'),
          icon: const Icon(Icons.save_outlined),
          label: Text(l10n.saveDraft),
        ),
      ],
    );
  }

  Widget _buildToolbar(QuillController controller) {
    final l10n = AppLocalizations.of(context)!;
    final toolbarColor = _writerToolbarColor(context);
    final onToolbarColor = _onWriterSurfaceColor(context);
    return SafeArea(
      child: Container(
        color: toolbarColor,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.insertImage,
              color: onToolbarColor,
              onPressed: _isUploadingInlineImage ? null : _pickInlineImage,
              icon: _isUploadingInlineImage
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
            ),
            IconButton(
              tooltip: l10n.insertMedia,
              color: onToolbarColor,
              onPressed: _showMediaInsertDialog,
              icon: const Icon(Icons.smart_display_outlined),
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
                  showLink: false,
                  showSubscript: false,
                  showSuperscript: false,
                  color: toolbarColor,
                  toolbarSectionSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _useDarkWriterChrome(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _writerChromeColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _useDarkWriterChrome(context) ? scheme.surface : scheme.surface;
  }

  Color _writerToolbarColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _useDarkWriterChrome(context)
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainer;
  }

  Color _writerSurfaceColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _useDarkWriterChrome(context)
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerHighest;
  }

  Color _writerFieldColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _useDarkWriterChrome(context)
        ? scheme.surfaceContainer
        : scheme.surface;
  }

  Color _onWriterChromeColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _onWriterSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _writerPaperColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _useDarkWriterChrome(context) ? scheme.surface : scheme.surface;
  }

  Color _writerPaperTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Widget _surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _writerSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
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
    final onSurfaceColor = _onWriterSurfaceColor(context);
    final fieldColor = _writerFieldColor(context);
    final outlineColor = Theme.of(context).colorScheme.outlineVariant;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: onSurfaceColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: onSurfaceColor.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: onSurfaceColor.withValues(alpha: 0.32)),
        filled: true,
        fillColor: fieldColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
    String Function(String)? displayLabel,
  }) {
    final onSurfaceColor = _onWriterSurfaceColor(context);
    final fieldColor = _writerFieldColor(context);
    final outlineColor = Theme.of(context).colorScheme.outlineVariant;
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: _writerSurfaceColor(context),
      style: TextStyle(color: onSurfaceColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: onSurfaceColor.withValues(alpha: 0.7)),
        filled: true,
        fillColor: fieldColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(displayLabel?.call(item) ?? _titleCase(item)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  void _showChapterSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sheetColor = _writerSurfaceColor(context);
        final onSheetColor = _onWriterSurfaceColor(context);
        final outlineColor = Theme.of(context).colorScheme.outlineVariant;
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, modalSetState) {
              return Container(
                height: MediaQuery.sizeOf(context).height * 0.9,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: outlineColor),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.chapterOverview,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: onSheetColor,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.chapterCount(_chapters.length),
                                  style: TextStyle(
                                    color: onSheetColor.withValues(alpha: 0.62),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.close,
                            color: onSheetColor,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        itemCount: _chapters.length,
                        proxyDecorator: (child, index, animation) => Material(
                          color: Colors.transparent,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 1, end: 1.02).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: child,
                          ),
                        ),
                        onReorder: (oldIndex, newIndex) {
                          setState(() => _reorderChapter(oldIndex, newIndex));
                          unawaited(_syncDraftCheckpoint());
                          modalSetState(() {});
                        },
                        itemBuilder: (context, i) {
                          final chapter = _chapters[i];
                          final isCurrent = i == _currentChapterIndex;
                          return _ChapterOverviewCard(
                            key: ValueKey(chapter.key),
                            index: i,
                            title: chapter.title.text.trim().isEmpty
                                ? l10n.chapterNumber(i + 1)
                                : chapter.title.text.trim(),
                            preview: _chapterPreview(chapter),
                            wordCount: chapter.wordCount,
                            isCurrent: isCurrent,
                            canDelete: _chapters.length > 1,
                            textColor: onSheetColor,
                            onTap: () {
                              setState(() => _setCurrentChapterIndex(i));
                              unawaited(_syncDraftCheckpoint());
                              Navigator.of(context).pop();
                            },
                            onDelete: () async {
                              final deleted = await _confirmDeleteChapter(i);
                              if (deleted && context.mounted) {
                                unawaited(_syncDraftCheckpoint());
                                modalSetState(() {});
                              }
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _addChapter();
                          unawaited(_syncDraftCheckpoint());
                          modalSetState(() {});
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: onSheetColor.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add_rounded, color: onSheetColor),
                              const SizedBox(width: 10),
                              Text(
                                l10n.addNewChapter,
                                style: TextStyle(
                                  color: onSheetColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
      _isLocalDirty = true;
      _saveStatus = AppLocalizations.of(context)!.unsavedChanges;
    });
  }

  void _reorderChapter(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final moving = _chapters[oldIndex];
    final current = _currentChapter;
    _chapters
      ..removeAt(oldIndex)
      ..insert(newIndex, moving);
    _setCurrentChapterIndex(_chapters.indexOf(current));
    _isDirty = true;
    _isLocalDirty = true;
    _saveStatus = AppLocalizations.of(context)!.unsavedChanges;
  }

  Future<bool> _confirmDeleteChapter(int index) async {
    if (_chapters.length <= 1) return false;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteChapterTitle),
        content: Text(l10n.deleteChapterBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    setState(() {
      final removed = _chapters.removeAt(index);
      removed.dispose();
      _setCurrentChapterIndex(
        _currentChapterIndex.clamp(0, _chapters.length - 1),
      );
      _isDirty = true;
      _isLocalDirty = true;
      _saveStatus = l10n.unsavedChanges;
    });
    return true;
  }

  String _chapterPreview(_ChapterDraft chapter) {
    final text = plainTextFromHtml(
      htmlFromDocument(chapter.controller.document),
    );
    if (text.isEmpty) return AppLocalizations.of(context)!.noContentYet;
    if (text.length <= 96) return text;
    return '${text.substring(0, 96).trim()}...';
  }

  void _populateSynopsisFromFirstLines() {
    if (_descriptionController.value.text.trim().isNotEmpty) return;
    for (final chapter in _chapters) {
      final text =
          plainTextFromHtml(htmlFromDocument(chapter.controller.document))
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .join(' ');
      if (text.isEmpty) continue;
      _descriptionController.value.text = text.length <= 260
          ? text
          : '${text.substring(0, 260).trimRight()}...';
      _markDirty();
      return;
    }
  }

  Future<void> _pickInlineImage() async {
    final l10n = AppLocalizations.of(context)!;
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      _showSnack(l10n.signInBeforeUploadingImages);
      return;
    }
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploadingInlineImage = true);
    try {
      final uploaded = await ref
          .read(cloudinaryUploadServiceProvider)
          .uploadImage(file: file, folder: 'books', userId: user.id);
      final url = optimizeCloudinaryImageUrl(uploaded);
      _insertEmbed(BlockEmbed.image(url));
      _showSnack(l10n.imageInserted);
    } catch (error) {
      _showSnack(l10n.couldNotUploadImage('$error'));
    } finally {
      if (mounted) setState(() => _isUploadingInlineImage = false);
    }
  }

  Future<void> _pickCover() async {
    final l10n = AppLocalizations.of(context)!;
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      _showSnack(l10n.signInBeforeUploadingCover);
      return;
    }
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploadingCover = true);
    try {
      final uploaded = await ref
          .read(cloudinaryUploadServiceProvider)
          .uploadImage(file: file, folder: 'covers', userId: user.id);
      final url = optimizeCloudinaryImageUrl(
        uploaded,
        transform: 'f_auto,q_auto,w_600,h_900,c_fill',
      );
      setState(() => _coverUrl = url);
      _markDirty();
      _showSnack(l10n.coverUploaded);
    } catch (error) {
      _showSnack(l10n.couldNotUploadCover('$error'));
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _showMediaInsertDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.insertMedia),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.writerMediaUrlLabel),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.insert),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    final info = classifyWriterMediaUrl(result);
    if (info.isSupported) {
      _insertEmbed(BlockEmbed.video(info.originalUrl));
      return;
    }
    _insertText(result.trim());
    _showSnack(l10n.unsupportedLinksInsertedAsPlainText);
  }

  void _insertEmbed(BlockEmbed embed) {
    final controller = _currentChapter.controller;
    final selection = controller.selection;
    var index = selection.baseOffset < 0 ? 0 : selection.baseOffset;
    final length = selection.isCollapsed ? 0 : selection.end - selection.start;
    final plainText = controller.document.toPlainText();
    if (length == 0 &&
        index > 0 &&
        index <= plainText.length &&
        plainText[index - 1] != '\n') {
      controller.replaceText(
        index,
        0,
        '\n',
        TextSelection.collapsed(offset: index + 1),
      );
      index += 1;
    }
    controller.replaceText(
      index,
      length,
      embed,
      TextSelection.collapsed(offset: index + 1),
    );
    controller.replaceText(
      index + 1,
      0,
      '\n',
      TextSelection.collapsed(offset: index + 2),
    );
    _markDirty();
  }

  void _insertText(String text) {
    if (text.trim().isEmpty) return;
    final controller = _currentChapter.controller;
    final selection = controller.selection;
    final index = selection.baseOffset < 0 ? 0 : selection.baseOffset;
    final length = selection.isCollapsed ? 0 : selection.end - selection.start;
    controller.replaceText(
      index,
      length,
      text,
      TextSelection.collapsed(offset: index + text.length),
    );
    _markDirty();
  }

  Future<void> _autosaveDraft() async {
    if (!_isLocalDirty || _isSaving || !_hasSavableContent) return;
    await _saveLocalDraft();
  }

  Future<void> _save({
    required String status,
    bool closeAfterSave = false,
    bool allowUntitled = false,
    bool showSnack = true,
  }) async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;

    final title = _titleController.value.text.trim();
    if (title.isEmpty && !allowUntitled) {
      _showSnack(l10n.addTitleBeforeSaving);
      setState(() => _setStep(1));
      return;
    }

    final user = await _currentUserOrNull();
    if (user == null) return;
    if (_collabEnabled &&
        !isAcceptedCollaboration(widget.book ?? _emptyBookForCollabCheck()) &&
        (_selectedCollaboratorId == null ||
            _selectedCollaboratorId!.trim().isEmpty)) {
      _showSnack(l10n.selectCoAuthorBeforeSaving);
      setState(() => _setStep(1));
      return;
    }

    setState(() {
      _isSaving = true;
      _saveStatus = status == 'published'
          ? l10n.writerPublishing
          : l10n.writerSavingDraft;
    });

    try {
      final localDraftKey = _draftKey(user.id);
      final book = _buildBookForSave(user, status: status);
      final shouldNotifyFollowers =
          status == 'published' && widget.book?.status != 'published';

      if ((_bookId ?? widget.book?.id ?? '').isEmpty) {
        _bookId = await ref.read(writerRepositoryProvider).createBook(book);
      } else {
        await ref.read(writerRepositoryProvider).updateBook(_bookId!, book);
      }
      if (shouldNotifyFollowers && _bookId != null) {
        // Cloud Functions generate follower notifications for new publications.
      }
      await ref.read(writerDraftServiceProvider).deleteDraft(localDraftKey);
      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
      if (!mounted) return;
      setState(() {
        _isDirty = false;
        _isLocalDirty = false;
        _isSaving = false;
        _saveStatus = status == 'published'
            ? l10n.writerPublishedStatus
            : l10n.writerDraft;
      });
      if (showSnack) {
        _showSnack(
          status == 'published' ? l10n.storyPublished : l10n.writerDraft,
        );
      }
      if (closeAfterSave && mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveStatus = l10n.writerSaveFailed;
      });
      if (showSnack) {
        _showSnack(l10n.couldNotSave('$error'));
      }
    }
  }

  Future<void> _syncDraftCheckpoint() async {
    if (!_isDirty || _isSaving || !_hasSavableContent) return;
    await _save(status: 'draft', allowUntitled: true, showSnack: false);
  }

  Future<void> _saveLocalDraft() async {
    final user = await _currentUserOrNull();
    if (user == null) return;

    try {
      final book = _buildBookForSave(user, status: 'draft');
      await ref
          .read(writerDraftServiceProvider)
          .saveDraft(draftKey: _draftKey(user.id), book: book);
      if (!mounted) return;
      setState(() {
        _isLocalDirty = false;
        _saveStatus = AppLocalizations.of(context)!.savedOnDevice;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _saveStatus = AppLocalizations.of(context)!.localSaveFailed,
      );
    }
  }

  Book _buildBookForSave(UserModel user, {required String status}) {
    _syncBookTitleFromFirstChapter();
    final now = DateTime.now().millisecondsSinceEpoch;
    final chapters = <Chapter>[];
    for (var i = 0; i < _chapters.length; i++) {
      final draft = _chapters[i];
      final content = htmlFromDocument(draft.controller.document);
      final plainContent = plainTextFromHtml(content);
      if (draft.title.text.trim().isEmpty &&
          plainContent.isEmpty &&
          !hasMeaningfulWriterHtml(content)) {
        continue;
      }
      chapters.add(
        Chapter(
          id: draft.id ?? 'chapter_${now}_$i',
          title: draft.title.text.trim().isEmpty
              ? AppLocalizations.of(context)!.chapterNumber(i + 1)
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
    final existingBook = widget.book;
    final primaryAuthorId = existingBook?.authorId?.trim().isNotEmpty == true
        ? existingBook!.authorId!.trim()
        : user.id;
    final primaryAuthorName = primaryAuthorId == user.id
        ? (user.displayName ?? user.username)
        : existingBook?.authors.firstOrNull?.name.trim().isNotEmpty == true
        ? existingBook!.authors.first.name.trim()
        : 'Author';
    final collaborationWasAccepted =
        existingBook != null && isAcceptedCollaboration(existingBook);
    final collaboratorId = !_collabEnabled
        ? null
        : collaborationWasAccepted
        ? existingBook.collaboratorId?.trim()
        : _selectedCollaboratorId?.trim();
    final collaboratorName = !_collabEnabled
        ? null
        : collaborationWasAccepted
        ? existingBook.collaboratorName?.trim()
        : _selectedCollaboratorName?.trim();
    final collaboratorPhotoURL = !_collabEnabled
        ? null
        : collaborationWasAccepted
        ? existingBook.collaboratorPhotoURL?.trim()
        : _selectedCollaboratorPhotoURL?.trim();
    final collaborationStatus =
        !_collabEnabled || collaboratorId == null || collaboratorId.isEmpty
        ? null
        : collaborationWasAccepted
        ? collaborationStatusAccepted
        : collaborationStatusPending;
    final bookAuthors =
        collaborationStatus == collaborationStatusAccepted &&
            existingBook?.authors.isNotEmpty == true
        ? existingBook!.authors
        : <Author>[
            Author(name: primaryAuthorName, birthYear: null, deathYear: null),
            if (collaborationStatus == collaborationStatusAccepted &&
                collaboratorName != null &&
                collaboratorName.isNotEmpty)
              Author(name: collaboratorName, birthYear: null, deathYear: null),
          ];
    final authorIds = collaborationStatus == collaborationStatusAccepted
        ? <String>{
            primaryAuthorId,
            if (collaboratorId != null && collaboratorId.isNotEmpty)
              collaboratorId,
          }.toList()
        : <String>[primaryAuthorId];
    return Book(
      id: _bookId ?? widget.book?.id ?? '',
      title: _titleController.value.text.trim().isEmpty
          ? AppLocalizations.of(context)!.untitledStory
          : _titleController.value.text.trim(),
      description: _descriptionController.value.text.trim(),
      coverUrl: _coverUrl?.trim().isEmpty == true ? null : _coverUrl,
      authors: bookAuthors,
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
      authorId: primaryAuthorId,
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
      collaborationStatus: collaborationStatus,
      collaboratorId: collaboratorId?.isEmpty == true ? null : collaboratorId,
      collaboratorName: collaboratorName?.isEmpty == true
          ? null
          : collaboratorName,
      collaboratorPhotoURL: collaboratorPhotoURL?.isEmpty == true
          ? null
          : collaboratorPhotoURL,
      collaborationRequestedBy:
          collaborationStatus == collaborationStatusPending
          ? (existingBook?.collaborationRequestedBy ?? user.id)
          : null,
      collaborationRequestedAt:
          collaborationStatus == collaborationStatusPending
          ? (existingBook?.collaborationRequestedAt ?? now)
          : null,
      collaborationRespondedAt:
          collaborationStatus == collaborationStatusAccepted
          ? existingBook?.collaborationRespondedAt
          : null,
      authorIds: authorIds,
    );
  }

  Widget _buildCollaborationSection() {
    final l10n = AppLocalizations.of(context)!;
    final existingBook = widget.book;
    final isAccepted =
        existingBook != null && isAcceptedCollaboration(existingBook);
    final isPending =
        existingBook != null && isPendingCollaboration(existingBook);
    final currentUserId = ref
        .watch(currentUserProvider)
        .asData
        ?.value
        ?.id
        .trim();
    final primaryAuthorId = existingBook?.authorId?.trim();
    final collaboratorId = existingBook?.collaboratorId?.trim();
    final canRemoveAccepted =
        isAccepted &&
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        (currentUserId == primaryAuthorId || currentUserId == collaboratorId);
    final canEditInvite = !isAccepted || canRemoveAccepted;
    final canChangeCollaborator = !isAccepted;
    final followingAsync = ref.watch(followingListProvider);
    final followingIds = followingAsync.asData?.value ?? const <String>[];
    final profilesKey = followingIds.join('|');
    final profilesAsync = profilesKey.isEmpty
        ? const AsyncValue<List<UserModel>>.data(<UserModel>[])
        : ref.watch(publicProfilesByStableIdsProvider(profilesKey));
    final profiles = profilesAsync.asData?.value ?? const <UserModel>[];
    final selectedId = _selectedCollaboratorId?.trim();
    final selectedKnown =
        selectedId != null &&
        selectedId.isNotEmpty &&
        profiles.any((profile) => profile.id == selectedId);
    final dropdownProfiles = [
      ...profiles,
      if (!selectedKnown &&
          selectedId != null &&
          selectedId.isNotEmpty &&
          _selectedCollaboratorName?.isNotEmpty == true)
        UserModel(
          id: selectedId,
          username: _selectedCollaboratorName!,
          email: '',
          displayName: _selectedCollaboratorName,
          photoURL: _selectedCollaboratorPhotoURL,
          readingHistory: const [],
          savedBooks: const [],
          bookmarks: const [],
        ),
    ];

    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.collab,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _onWriterSurfaceColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              isAccepted
                  ? l10n.collabAcceptedDescription
                  : isPending
                  ? l10n.collabPendingDescription
                  : l10n.collabInviteDescription,
              style: TextStyle(
                color: _onWriterSurfaceColor(context).withValues(alpha: 0.65),
              ),
            ),
            value: _collabEnabled,
            onChanged: canEditInvite
                ? (value) {
                    setState(() {
                      _collabEnabled = value;
                      if (!value) {
                        _selectedCollaboratorId = null;
                        _selectedCollaboratorName = null;
                        _selectedCollaboratorPhotoURL = null;
                      }
                    });
                    _markDirty();
                  }
                : null,
          ),
          if (_collabEnabled) ...[
            const SizedBox(height: 12),
            _CollabWarningCard(message: l10n.collabEditWarning),
            const SizedBox(height: 12),
            profilesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(
                l10n.collabLoadAuthorsFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (_) {
                if (dropdownProfiles.isEmpty) {
                  return Text(
                    l10n.collabFollowAuthorFirst,
                    style: TextStyle(
                      color: _onWriterSurfaceColor(
                        context,
                      ).withValues(alpha: 0.72),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: selectedKnown || !canChangeCollaborator
                      ? selectedId
                      : null,
                  dropdownColor: _writerSurfaceColor(context),
                  decoration: InputDecoration(
                    labelText: l10n.coAuthor,
                    filled: true,
                    fillColor: _writerFieldColor(context),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  items: dropdownProfiles
                      .map(
                        (profile) => DropdownMenuItem(
                          value: profile.id,
                          child: Text(_profileName(profile)),
                        ),
                      )
                      .toList(),
                  onChanged: canChangeCollaborator
                      ? (value) {
                          final profile = dropdownProfiles
                              .where((item) => item.id == value)
                              .firstOrNull;
                          setState(() {
                            _selectedCollaboratorId = value;
                            _selectedCollaboratorName = profile == null
                                ? null
                                : _profileName(profile);
                            _selectedCollaboratorPhotoURL = profile?.photoURL;
                          });
                          _markDirty();
                        }
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Book _emptyBookForCollabCheck() {
    return const Book(
      id: '',
      title: '',
      authors: [],
      subjects: [],
      languages: [],
      formats: {},
      downloadCount: 0,
      mediaType: 'text',
      bookshelves: [],
    );
  }

  bool get _hasSavableContent {
    if (_titleController.value.text.trim().isNotEmpty) return true;
    return _chapters.any((chapter) {
      final html = htmlFromDocument(chapter.controller.document);
      return plainTextFromHtml(html).isNotEmpty ||
          hasMeaningfulWriterHtml(html);
    });
  }

  void _markDirty() {
    if (!mounted || _isRestoringLocalDraft) return;
    _syncBookTitleFromFirstChapter();
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
        _isLocalDirty = true;
        _saveStatus = AppLocalizations.of(context)!.unsavedChanges;
      });
    } else if (!_isLocalDirty) {
      setState(() {
        _isLocalDirty = true;
        _saveStatus = AppLocalizations.of(context)!.unsavedChanges;
      });
    }
  }

  void _syncBookTitleFromFirstChapter() {
    if (widget.book != null || _bookTitleEditedByUser || _chapters.isEmpty) {
      return;
    }
    final firstChapterTitle = _chapters.first.title.text.trim();
    if (firstChapterTitle.isEmpty ||
        _titleController.value.text.trim() == firstChapterTitle) {
      return;
    }

    _syncingBookTitleFromChapter = true;
    _titleController.value.text = firstChapterTitle;
    _syncingBookTitleFromChapter = false;
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
    if (normalized == null || normalized.isEmpty) return 'Hindi';
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
    };
    return aliases[normalized] ?? value!.trim();
  }

  bool get _isHindiLocale =>
      Localizations.localeOf(context).languageCode == 'hi';

  String _localizedContentType(String value) {
    if (!_isHindiLocale) return _titleCase(value);
    return switch (value.trim().toLowerCase()) {
      'story' => 'कहानी',
      'poem' || 'poetry' => 'कविता',
      'article' => 'लेख',
      _ => _titleCase(value),
    };
  }

  String _localizedCategory(String value) {
    if (!_isHindiLocale) return _titleCase(value);
    const labels = {
      'romance': 'रोमांस',
      'mystery': 'रहस्य',
      'thriller': 'थ्रिलर',
      'science fiction': 'विज्ञान कथा',
      'fantasy': 'फंतासी',
      'horror': 'हॉरर',
      'adventure': 'साहसिक',
      'historical fiction': 'ऐतिहासिक कथा',
      'young adult': 'युवा साहित्य',
      'literary fiction': 'साहित्यिक कथा',
      'comedy': 'हास्य',
      'drama': 'नाटक',
      'crime': 'अपराध',
      'stories': 'कहानियां',
      'fan fiction': 'फैन फिक्शन',
      'lyrical': 'गीतात्मक',
      'narrative': 'कथात्मक',
      'haiku': 'हाइकु',
      'free verse': 'मुक्त छंद',
      'sonnet': 'सॉनेट',
      'ghazal': 'ग़ज़ल',
      'blank verse': 'अतुकांत छंद',
      'ode': 'ओड',
      'elegy': 'शोकगीत',
      'ballad': 'बैलेड',
      'prose poetry': 'गद्य कविता',
      'spoken word': 'स्पोकन वर्ड',
      'visual poetry': 'दृश्य कविता',
      'acrostic': 'अक्रॉस्टिक',
      'experimental': 'प्रयोगात्मक',
      'technology': 'प्रौद्योगिकी',
      'science': 'विज्ञान',
      'health': 'स्वास्थ्य',
      'education': 'शिक्षा',
      'business': 'व्यवसाय',
      'politics': 'राजनीति',
      'travel': 'यात्रा',
      'lifestyle': 'जीवनशैली',
      'personal development': 'व्यक्तिगत विकास',
      'finance': 'वित्त',
      'environment': 'पर्यावरण',
      'arts & culture': 'कला और संस्कृति',
      'food & cooking': 'भोजन और पाक-कला',
      'sports': 'खेल',
      'history': 'इतिहास',
      'other': 'अन्य',
    };
    return labels[value.trim().toLowerCase()] ?? _titleCase(value);
  }

  String _localizedLanguage(String value) {
    if (!_isHindiLocale) return _titleCase(value);
    const labels = {
      'hindi': 'हिंदी',
      'english': 'अंग्रेज़ी',
      'bengali': 'बंगाली',
      'telugu': 'तेलुगु',
      'marathi': 'मराठी',
      'tamil': 'तमिल',
      'gujarati': 'गुजराती',
      'urdu': 'उर्दू',
      'kannada': 'कन्नड़',
      'malayalam': 'मलयालम',
    };
    return labels[value.trim().toLowerCase()] ?? _titleCase(value);
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _profileName(UserModel profile) {
    final displayName = profile.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final penName = profile.penName?.trim();
    if (penName != null && penName.isNotEmpty) return penName;
    return profile.username.trim().isEmpty ? 'Author' : profile.username.trim();
  }
}

class _CollabWarningCard extends StatelessWidget {
  const _CollabWarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onTertiaryContainer,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterOverviewCard extends StatelessWidget {
  const _ChapterOverviewCard({
    super.key,
    required this.index,
    required this.title,
    required this.preview,
    required this.wordCount,
    required this.isCurrent,
    required this.canDelete,
    required this.textColor,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final String title;
  final String preview;
  final int wordCount;
  final bool isCurrent;
  final bool canDelete;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final borderColor = isCurrent
        ? Theme.of(context).colorScheme.primary
        : textColor.withValues(alpha: 0.18);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: isCurrent ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: textColor.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.editing,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.66),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.wordCountLabel(wordCount),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.52),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.deleteChapter,
                onPressed: canDelete ? onDelete : null,
                color: textColor.withValues(alpha: 0.74),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
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
  String get key => id ?? identityHashCode(this).toString();
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
