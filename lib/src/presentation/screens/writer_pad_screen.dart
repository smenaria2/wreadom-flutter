import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/author.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/leaf_attachment.dart';
import '../../domain/models/user_model.dart';
import '../../data/services/analytics_service.dart';
import '../../utils/app_review_helper.dart';
import '../../localization/generated/app_localizations.dart';
import '../../utils/book_collaboration_utils.dart';
import '../providers/auth_providers.dart';
import '../providers/follow_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/writer_taxonomy_provider.dart';
import '../providers/writer_providers.dart';
import '../routing/app_routes.dart';
import '../routing/writer_pad_mode.dart';
import '../utils/chapter_version_history.dart';
import '../utils/writer_html_codec.dart';
import '../utils/writer_media_utils.dart';
import '../widgets/auth_required_view.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/writer_media_embed.dart';
import '../../data/services/cover_image_service.dart';

class WriterPadScreen extends ConsumerStatefulWidget {
  const WriterPadScreen({
    super.key,
    this.book,
    this.initialTopic,
    this.restoreLocalDrafts = true,
    this.showToolbar = true,
    this.optOutComplementary,
    this.openPrintPage,
  });

  final Book? book;
  final String? initialTopic;
  final bool restoreLocalDrafts;
  final bool showToolbar;
  final bool? optOutComplementary;
  final Future<bool> Function(Uri uri)? openPrintPage;

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
  List<LeafAttachment>? _savedBookLeaves;
  int? _savedPublishedAt;
  String? _savedStatus;
  late final String _localDraftId;
  int _step = 0;
  int _currentChapterIndex = 0;
  bool _isSaving = false;
  bool _isUploadingInlineImage = false;
  bool _isUploadingCover = false;
  bool _isDirty = false;
  bool _isLocalDirty = false;
  bool _isRestoringLocalDraft = false;
  bool _allowPop = false;
  bool _isHandlingBack = false;
  bool _metadataListenersAttached = false;
  bool _bookTitleEditedByUser = false;
  bool _syncingBookTitleFromChapter = false;
  String _saveStatus = 'Not saved yet';
  String _contentType = 'story';
  String _category = 'Romance';
  String _language = 'Hindi';
  String? _coverUrl;
  final CoverImageService _coverImageService = CoverImageService();
  List<String> _autoCoverUrls = [];
  int _autoCoverIndex = 0;
  bool _isFetchingAutoCover = false;
  bool _autoCoverFetched = false;
  bool _collabEnabled = false;
  bool _optOutComplementary = false;
  String? _selectedCollaboratorId;
  String? _selectedCollaboratorName;
  String? _selectedCollaboratorPhotoURL;

  _ChapterDraft get _currentChapter => _chapters[_currentChapterIndex];

  bool get _isPublished =>
      (_savedStatus ?? widget.book?.status)?.trim().toLowerCase() ==
      'published';

  bool get _isSingleChapter => _chapters.length <= 1;

  String get _statusForSave => _isPublished ? 'published' : 'draft';

  void _setStep(int value) {
    final oldStep = _step;
    _step = value.clamp(0, 1);
    _restorableStep.value = _step;
    if (oldStep == 0 && _step == 1) {
      _checkAndFetchAutoCover();
    }
  }

  Future<void> _checkAndFetchAutoCover() async {
    if (_coverUrl != null || _autoCoverFetched) {
      return;
    }

    _autoCoverFetched = true;
    final title = _titleController.value.text.trim();
    if (title.isEmpty || title.toLowerCase() == 'untitled story') {
      return;
    }

    setState(() {
      _isFetchingAutoCover = true;
    });

    try {
      final translatedQuery = await _coverImageService.translateTitle(title);
      final images = await _coverImageService.searchImages(translatedQuery);

      if (mounted && images.isNotEmpty) {
        setState(() {
          _autoCoverUrls = images;
          _autoCoverIndex = 0;
          _coverUrl = images[0];
        });
        _markDirty();
      }
    } catch (_) {
      // Fail silently
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingAutoCover = false;
        });
      }
    }
  }

  void _cycleAutoCover() {
    if (_autoCoverUrls.isEmpty) return;
    setState(() {
      _autoCoverIndex = (_autoCoverIndex + 1) % _autoCoverUrls.length;
      _coverUrl = _autoCoverUrls[_autoCoverIndex];
    });
    _markDirty();
  }

  Future<void> _retryAutoCoverFetch() async {
    _autoCoverFetched = false;
    await _checkAndFetchAutoCover();
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
    _savedStatus = book?.status;
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
    _optOutComplementary =
        book?.optOutComplementary ?? widget.optOutComplementary ?? false;
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
      unawaited(_initializeAuthoringState());
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

  Future<void> _initializeAuthoringState() async {
    await _hydrateAuthoringChapters();
    if (widget.restoreLocalDrafts) await _restoreLocalDraft();
  }

  Future<void> _hydrateAuthoringChapters() async {
    final bookId = _bookId ?? widget.book?.id;
    if (bookId == null || bookId.trim().isEmpty) return;
    try {
      final chapters = await ref
          .read(writerRepositoryProvider)
          .getAuthoringChapters(bookId);
      if (!mounted || chapters.isEmpty) return;
      final hydrated = <Chapter>[
        for (final chapter in chapters)
          if (_isPublished && chapter.status == 'draft' && !chapter.isHidden)
            chapter.copyWith(isHidden: true)
          else
            chapter,
      ];
      setState(() {
        for (final chapter in _chapters) {
          chapter.dispose();
        }
        _chapters
          ..clear()
          ..addAll(
            hydrated.map(
              (chapter) => _ChapterDraft.fromChapter(chapter, _markDirty),
            ),
          );
        _setCurrentChapterIndex(
          _currentChapterIndex.clamp(0, _chapters.length - 1),
        );
      });
    } catch (_) {
      // Legacy books continue using their embedded visible chapter projection.
    }
  }

  Future<void> _restoreLocalDraft() async {
    final user = await _currentUserOrNull();
    if (!mounted || user == null) return;

    final draft = await ref
        .read(writerDraftServiceProvider)
        .getDraft(_draftKey(user.id));
    if (!mounted || draft == null) return;

    final serverUpdatedAt = widget.book?.updatedAt;
    final localUpdatedAt = draft.updatedAt;
    if (serverUpdatedAt != null &&
        localUpdatedAt != null &&
        localUpdatedAt <= serverUpdatedAt) {
      await ref
          .read(writerDraftServiceProvider)
          .deleteDraft(_draftKey(user.id));
      return;
    }

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.restoreLocalDraftTitle),
        content: Text(AppLocalizations.of(context)!.restoreLocalDraftBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context)!.discard),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(context)!.restoreVersion),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldRestore != true) {
      await ref
          .read(writerDraftServiceProvider)
          .deleteDraft(_draftKey(user.id));
      return;
    }

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
      _optOutComplementary = draft.optOutComplementary ?? _optOutComplementary;
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
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;
    final controller = _currentChapter.controller;

    if (currentUserAsync.isLoading) {
      return GlassScaffold(
        appBar: glassAppBar(title: Text(l10n.writerWritingEditor)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return GlassScaffold(
        appBar: glassAppBar(title: Text(l10n.writerWritingEditor)),
        body: const AuthRequiredView(icon: Icons.edit_note_outlined),
      );
    }

    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: GlassScaffold(
        appBar: glassAppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _step == 0
                    ? l10n.writerWritingEditor
                    : l10n.writerContentDetails,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                _isSaving ? l10n.writerSaving : _saveStatus,
                style: TextStyle(
                  color: _onWriterChromeColor(context).withValues(alpha: 0.58),
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
          automaticallyImplyLeading: false,
          actions: _step == 0 ? _buildEditorAppBarActions(l10n) : null,
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _step == 0 ? _buildEditorStep() : _buildDetailsStep(),
          ),
        ),
        bottomNavigationBar: _step == 0 && widget.showToolbar
            ? _buildToolbar(controller)
            : null,
      ),
    );
  }

  List<Widget> _buildEditorAppBarActions(AppLocalizations l10n) {
    final saveTooltip = _isPublished ? l10n.save : l10n.saveDraft;
    final saveButton = Tooltip(
      message: saveTooltip,
      child: _isSingleChapter && !_isPublished
          ? FilledButton(
              style: _writerAppBarActionStyle(primary: true, iconOnly: true),
              onPressed: _isSaving
                  ? null
                  : () => _save(status: _statusForSave, allowUntitled: true),
              child: const Icon(Icons.save_rounded),
            )
          : OutlinedButton(
              style: _writerAppBarActionStyle(primary: false, iconOnly: true),
              onPressed: _isSaving ? null : () => _save(status: _statusForSave),
              child: const Icon(Icons.save_rounded),
            ),
    );

    return [
      if (_isSingleChapter && !_isPublished) ...[
        OutlinedButton(
          style: _writerAppBarActionStyle(primary: false),
          onPressed: _isSaving ? null : _goToDetails,
          child: Text(l10n.writerPublish),
        ),
        const SizedBox(width: 6),
        saveButton,
      ] else ...[
        saveButton,
        const SizedBox(width: 6),
        FilledButton(
          style: _writerAppBarActionStyle(primary: true),
          onPressed: _isSaving ? null : _goToDetails,
          child: Text(l10n.writerNext),
        ),
      ],
      _buildEditorMenu(l10n),
      const SizedBox(width: 4),
    ];
  }

  ButtonStyle _writerAppBarActionStyle({
    required bool primary,
    bool iconOnly = false,
  }) {
    final theme = Theme.of(context);
    final base = primary
        ? theme.filledButtonTheme.style
        : theme.outlinedButtonTheme.style;
    return (base ?? const ButtonStyle()).copyWith(
      minimumSize: WidgetStatePropertyAll(Size(iconOnly ? 40 : 58, 40)),
      fixedSize: iconOnly ? const WidgetStatePropertyAll(Size(40, 40)) : null,
      padding: WidgetStatePropertyAll(
        iconOnly ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEditorMenu(AppLocalizations l10n) {
    final actions = <_WriterMenuAction>[
      if (_isPublished) _WriterMenuAction.convertToDraft,
      if (_isSingleChapter) _WriterMenuAction.addToBook,
      if (!_isPublished) _WriterMenuAction.deleteBook,
      if (_isPublished && !_isSingleChapter) _WriterMenuAction.printBook,
    ];

    return PopupMenuButton<_WriterMenuAction>(
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      enabled: !_isSaving,
      onSelected: _handleWriterMenuAction,
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem<_WriterMenuAction>(
            value: action,
            child: Row(
              children: [
                Icon(
                  switch (action) {
                    _WriterMenuAction.addToBook => Icons.library_add_outlined,
                    _WriterMenuAction.deleteBook =>
                      Icons.delete_outline_rounded,
                    _WriterMenuAction.convertToDraft => Icons.edit_note_rounded,
                    _WriterMenuAction.printBook => Icons.print_outlined,
                  },
                  color: action == _WriterMenuAction.deleteBook
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    switch (action) {
                      _WriterMenuAction.addToBook => l10n.addToBook,
                      _WriterMenuAction.deleteBook => l10n.deleteBook,
                      _WriterMenuAction.convertToDraft =>
                        l10n.writerConvertToDraft,
                      _WriterMenuAction.printBook => l10n.printBook,
                    },
                    style: action == _WriterMenuAction.deleteBook
                        ? TextStyle(color: Theme.of(context).colorScheme.error)
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _goToDetails() {
    _populateSynopsisFromFirstLines();
    unawaited(_syncDraftCheckpoint());
    setState(() => _setStep(1));
  }

  Future<void> _handleWriterMenuAction(_WriterMenuAction action) async {
    switch (action) {
      case _WriterMenuAction.addToBook:
        await _addChapterDraftToBook();
        return;
      case _WriterMenuAction.deleteBook:
        await _confirmAndDeleteBook();
        return;
      case _WriterMenuAction.convertToDraft:
        await _save(status: 'draft');
        return;
      case _WriterMenuAction.printBook:
        await _openPrintPage();
        return;
    }
  }

  Future<void> _handleBack() async {
    if (_isHandlingBack) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == 1) {
      setState(() => _setStep(0));
      return;
    }

    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;
    _isHandlingBack = true;
    final localSaved = await _saveLocalDraft();
    final remoteSaved = await _syncDraftCheckpoint();
    if (!mounted) return;
    _isHandlingBack = false;
    if (!localSaved && !remoteSaved && _hasSavableContent) {
      _showSnack(AppLocalizations.of(context)!.couldNotSaveBeforeExit);
      return;
    }
    setState(() => _allowPop = true);
    navigator.pop();
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
                    child: _isFetchingAutoCover
                        ? const Center(
                            child: SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_coverUrl == null
                              ? Icon(
                                  Icons.auto_stories_outlined,
                                  color: _onWriterSurfaceColor(
                                    context,
                                  ).withValues(alpha: 0.42),
                                )
                              : null),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _isUploadingCover || _isFetchingAutoCover
                              ? null
                              : _pickCover,
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
                        if (_autoCoverUrls.length > 1)
                          OutlinedButton.icon(
                            onPressed: _isUploadingCover || _isFetchingAutoCover
                                ? null
                                : _cycleAutoCover,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Another Image'),
                          ),
                        if (_autoCoverUrls.isEmpty &&
                            !_isFetchingAutoCover &&
                            _autoCoverFetched)
                          OutlinedButton.icon(
                            onPressed: _isUploadingCover
                                ? null
                                : _retryAutoCoverFetch,
                            icon: const Icon(Icons.image_search_rounded),
                            label: const Text('Find Cover'),
                          ),
                        OutlinedButton.icon(
                          onPressed:
                              _coverUrl == null ||
                                  _isUploadingCover ||
                                  _isFetchingAutoCover
                              ? null
                              : () {
                                  setState(() {
                                    _coverUrl = null;
                                    _autoCoverFetched = false;
                                    _autoCoverUrls.clear();
                                  });
                                  _checkAndFetchAutoCover();
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
          onPressed: _isSaving ? null : () => _save(status: _statusForSave),
          icon: const Icon(Icons.save_rounded),
          label: Text(_isPublished ? l10n.save : l10n.saveDraft),
        ),
      ],
    );
  }

  Widget _buildToolbar(QuillController controller) {
    final l10n = AppLocalizations.of(context)!;
    final onToolbarColor = _onWriterSurfaceColor(context);
    return SafeArea(
      child: GlassSurface(
        strong: true,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            IconButton(
              tooltip: l10n.versionHistory,
              color: onToolbarColor,
              onPressed: _currentChapter.versions.isEmpty
                  ? null
                  : () => _showVersionHistory(_currentChapterIndex),
              icon: const Icon(Icons.history_rounded),
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
                  color: Colors.transparent,
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
    return GlassSurface(
      strong: true,
      borderRadius: BorderRadius.circular(16),
      padding: padding,
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
        final onSheetColor = _onWriterSurfaceColor(context);
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, modalSetState) {
              return SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.9,
                child: GlassSurface(
                  strong: true,
                  borderRadius: BorderRadius.circular(24),
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  padding: const EdgeInsets.only(top: 4),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: onSheetColor,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.chapterCount(_chapters.length),
                                    style: TextStyle(
                                      color: onSheetColor.withValues(
                                        alpha: 0.62,
                                      ),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        child: GlassSurface(
                          strong: true,
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            final imported = await _showImportDraftsPicker();
                            if (imported && context.mounted) {
                              modalSetState(() {});
                            }
                          },
                          semanticButton: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.file_download_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  l10n.importFromDrafts,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                              versionCount: chapter.versions.length,
                              isCurrent: isCurrent,
                              isHidden: chapter.isHidden,
                              canDelete: _chapters.length > 1,
                              textColor: onSheetColor,
                              onTap: () {
                                setState(() => _setCurrentChapterIndex(i));
                                unawaited(_syncDraftCheckpoint());
                                Navigator.of(context).pop();
                              },
                              onToggleVisibility: () {
                                if (_toggleChapterVisibility(i)) {
                                  unawaited(_syncDraftCheckpoint());
                                  modalSetState(() {});
                                }
                              },
                              onDelete: () async {
                                final moved = await _confirmDeleteChapter(i);
                                if (moved && context.mounted) {
                                  modalSetState(() {});
                                }
                              },
                              onHistory: chapter.versions.isEmpty
                                  ? null
                                  : () {
                                      setState(
                                        () => _setCurrentChapterIndex(i),
                                      );
                                      Navigator.of(context).pop();
                                      _showVersionHistory(i);
                                    },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: GlassSurface(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            _addChapter();
                            unawaited(_syncDraftCheckpoint());
                            modalSetState(() {});
                          },
                          semanticButton: true,
                          padding: const EdgeInsets.all(16),
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
                    ],
                  ),
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

  bool _toggleChapterVisibility(int index) {
    if (index < 0 || index >= _chapters.length) return false;
    final chapter = _chapters[index];
    if (_isPublished &&
        !chapter.isHidden &&
        _chapters.where((item) => !item.isHidden).length <= 1) {
      _showSnack(AppLocalizations.of(context)!.keepOneChapterVisible);
      return false;
    }
    setState(() {
      chapter.isHidden = !chapter.isHidden;
      _isDirty = true;
      _isLocalDirty = true;
      _saveStatus = AppLocalizations.of(context)!.unsavedChanges;
    });
    return true;
  }

  Future<bool> _confirmDeleteChapter(int index) async {
    if (_chapters.length <= 1) return false;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.moveChapterToDraftsTitle),
        content: Text(l10n.moveChapterToDraftsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.moveToDrafts),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    final user = await _currentUserOrNull();
    if (user == null) return false;
    final sourceStatus = _statusForChapterMove();
    final saved = await _save(
      status: sourceStatus,
      allowUntitled: true,
      showSnack: false,
    );
    if (!saved || !mounted) return false;
    final sourceBook = _buildBookForSave(user, status: sourceStatus);
    if (index < 0 ||
        index >= (sourceBook.chapters ?? const <Chapter>[]).length) {
      return false;
    }
    final chapters = List<Chapter>.from(sourceBook.chapters ?? const []);
    final chapter = chapters[index];
    final remaining = <Chapter>[
      for (var i = 0; i < chapters.length; i++)
        if (i != index) chapters[i].copyWith(index: i > index ? i - 1 : i),
    ];
    try {
      await ref
          .read(writerRepositoryProvider)
          .moveChapterToStandaloneDraft(
            sourceBook: sourceBook,
            chapter: chapter,
            remainingChapters: remaining,
            ownerUserId: user.id,
          );
      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
    } catch (error) {
      if (mounted) _showSnack(l10n.couldNotMoveChapterToDrafts('$error'));
      return false;
    }
    setState(() {
      final removed = _chapters.removeAt(index);
      removed.dispose();
      _setCurrentChapterIndex(
        _currentChapterIndex.clamp(0, _chapters.length - 1),
      );
      _isDirty = false;
      _isLocalDirty = false;
      _saveStatus = sourceStatus == 'published'
          ? l10n.writerPublishedStatus
          : l10n.writerDraft;
    });
    _showSnack(l10n.chapterMovedToDrafts);
    return true;
  }

  String _statusForChapterMove() {
    return widget.book?.status == 'published' ? 'published' : 'draft';
  }

  Future<bool> _showImportDraftsPicker() async {
    final l10n = AppLocalizations.of(context)!;
    final user = await _currentUserOrNull();
    if (user == null) return false;
    final excludeBookId = _bookId ?? widget.book?.id;
    final drafts = await ref
        .read(writerRepositoryProvider)
        .getImportableSingleChapterDrafts(
          user.id,
          excludeBookId: excludeBookId,
        );
    if (!mounted) return false;
    if (drafts.isEmpty) {
      _showSnack(l10n.noSingleChapterDraftsToImport);
      return false;
    }

    final selected = <String>{};
    final chosen = await showModalBottomSheet<List<Book>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetColor = _writerSurfaceColor(sheetContext);
        final textColor = _onWriterSurfaceColor(sheetContext);
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final selectedDrafts = drafts
                .where((draft) => selected.contains(draft.id))
                .toList();
            return Container(
              height: MediaQuery.sizeOf(context).height * 0.75,
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
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
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      itemCount: drafts.length,
                      itemBuilder: (context, i) {
                        final draft = drafts[i];
                        final chapter = draft.chapters!.first;
                        final checked = selected.contains(draft.id);
                        final preview = plainTextFromHtml(chapter.content);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (value) {
                            modalSetState(() {
                              if (value == true) {
                                selected.add(draft.id);
                              } else {
                                selected.remove(draft.id);
                              }
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                          checkColor: Theme.of(context).colorScheme.onPrimary,
                          title: Text(
                            draft.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            preview.isEmpty
                                ? l10n.noContentYet
                                : preview.length > 96
                                ? '${preview.substring(0, 96).trim()}...'
                                : preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.66),
                            ),
                          ),
                          secondary: Icon(
                            Icons.description_outlined,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: selectedDrafts.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(selectedDrafts),
                        icon: const Icon(Icons.download_done_rounded),
                        label: Text(
                          l10n.importSelectedDrafts(selectedDrafts.length),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (chosen == null || chosen.isEmpty || !mounted) return false;

    final targetStatus = _statusForChapterMove();
    final saved = await _save(
      status: targetStatus,
      allowUntitled: true,
      showSnack: false,
    );
    if (!saved || !mounted) return false;
    final targetBook = _buildBookForSave(user, status: targetStatus);
    try {
      final imported = await ref
          .read(writerRepositoryProvider)
          .importSingleDraftsToBook(
            targetBook: targetBook,
            sourceDrafts: chosen,
          );
      if (imported.isEmpty || !mounted) return false;
      setState(() {
        _chapters.addAll(
          imported.map(
            (chapter) => _ChapterDraft.fromChapter(chapter, _markDirty),
          ),
        );
        _setCurrentChapterIndex(_chapters.length - 1);
        _isDirty = false;
        _isLocalDirty = false;
        _saveStatus = targetStatus == 'published'
            ? l10n.writerPublishedStatus
            : l10n.writerDraft;
      });
      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
      _showSnack(l10n.draftsImportedAsChapters(imported.length));
      return true;
    } catch (error) {
      if (mounted) _showSnack(l10n.couldNotImportDrafts('$error'));
      return false;
    }
  }

  String _chapterPreview(_ChapterDraft chapter) {
    final text = plainTextFromHtml(
      htmlFromDocument(chapter.controller.document),
    );
    if (text.isEmpty) return AppLocalizations.of(context)!.noContentYet;
    if (text.length <= 96) return text;
    return '${text.substring(0, 96).trim()}...';
  }

  String _versionPreview(String html) {
    final text = plainTextFromHtml(html);
    if (text.isEmpty) return AppLocalizations.of(context)!.noContentYet;
    if (text.length <= 180) return text;
    return '${text.substring(0, 180).trim()}...';
  }

  String _formatVersionTimestamp(int timestamp) {
    if (timestamp <= 0) return AppLocalizations.of(context)!.unknownTime;
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_jm().format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  Future<void> _showVersionHistory(int chapterIndex) async {
    if (chapterIndex < 0 || chapterIndex >= _chapters.length) return;
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final chapter = _chapters[chapterIndex];
            final versions = chapter.versions.reversed.toList();
            final sheetColor = _writerSurfaceColor(context);
            final textColor = _onWriterSurfaceColor(context);
            final currentContent = htmlFromDocument(
              chapter.controller.document,
            );
            return Container(
              height: MediaQuery.sizeOf(context).height * 0.86,
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
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
                                l10n.versionHistory,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                chapter.title.text.trim().isEmpty
                                    ? l10n.chapterNumber(chapterIndex + 1)
                                    : chapter.title.text.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.62),
                                ),
                              ),
                            ],
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
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      children: [
                        _VersionHistoryTile(
                          title: l10n.currentVersion,
                          subtitle: l10n.wordCountLabel(
                            wordCountFromHtml(currentContent),
                          ),
                          preview: _versionPreview(currentContent),
                          textColor: textColor,
                        ),
                        const SizedBox(height: 10),
                        if (versions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              l10n.noChapterVersionsYet,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.62),
                              ),
                            ),
                          )
                        else
                          for (var i = 0; i < versions.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _VersionHistoryTile(
                                title: l10n.previousVersion(
                                  versions.length - i,
                                ),
                                subtitle:
                                    '${_formatVersionTimestamp(versions[i].timestamp)} • ${l10n.wordCountLabel(versions[i].wordCount)}',
                                preview: _versionPreview(versions[i].content),
                                textColor: textColor,
                                action: FilledButton.icon(
                                  onPressed: () async {
                                    final confirmed =
                                        await _confirmRestoreVersion();
                                    if (confirmed != true) return;
                                    if (!mounted) return;
                                    setState(() {
                                      chapter.restoreVersion(versions[i]);
                                      _isDirty = true;
                                      _isLocalDirty = true;
                                      _saveStatus = l10n.unsavedChanges;
                                    });
                                    modalSetState(() {});
                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                  },
                                  icon: const Icon(Icons.restore_rounded),
                                  label: Text(l10n.restoreVersion),
                                ),
                              ),
                            ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.versionHistoryHelp,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.56),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmRestoreVersion() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreVersionTitle),
        content: Text(l10n.restoreVersionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.restoreVersion),
          ),
        ],
      ),
    );
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

  Future<void> _addChapterDraftToBook() async {
    final l10n = AppLocalizations.of(context)!;
    final user = await _currentUserOrNull();
    if (user == null) return;

    final saved = await _save(
      status: _statusForSave,
      allowUntitled: true,
      showSnack: false,
    );
    if (!saved || !mounted) return;

    final draftId = _bookId ?? widget.book?.id;
    if (draftId == null || draftId.trim().isEmpty) return;

    final publishedBooks =
        (await ref
                .read(writerRepositoryProvider)
                .getUserBooks(user.id, status: 'published'))
            .where((book) => book.id != draftId)
            .toList();
    if (!mounted) return;
    if (publishedBooks.isEmpty) {
      _showSnack(l10n.noPublishedBooksToAddDraft);
      return;
    }

    final selectedBook = await _showPublishedBookPicker(publishedBooks);
    if (selectedBook == null || !mounted) return;

    var didNavigate = false;
    setState(() {
      _isSaving = true;
      _saveStatus = l10n.writerSavingDraft;
    });
    try {
      final sourceDraft = _buildBookForSave(
        user,
        status: 'draft',
      ).copyWith(id: draftId);
      final imported = await ref
          .read(writerRepositoryProvider)
          .importSingleDraftsToBook(
            targetBook: selectedBook,
            sourceDrafts: [sourceDraft],
          );
      if (imported.isEmpty || !mounted) return;

      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
      _showSnack(l10n.draftAddedToBook);

      final updatedChapters = <Chapter>[...?selectedBook.chapters, ...imported];
      final updatedBook = selectedBook.copyWith(
        chapters: updatedChapters,
        chapterCount: updatedChapters.length,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      didNavigate = true;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.writerPad,
        arguments: WriterPadArguments(book: updatedBook),
      );
    } catch (error) {
      if (mounted) {
        _showSnack(l10n.couldNotAddDraftToBook('$error'));
      }
    } finally {
      if (mounted && !didNavigate) {
        setState(() {
          _isSaving = false;
          _saveStatus = l10n.writerDraft;
        });
      }
    }
  }

  Future<void> _confirmAndDeleteBook() async {
    final l10n = AppLocalizations.of(context)!;
    final user = await _currentUserOrNull();
    if (user == null || !mounted) return;
    final book = widget.book;
    if (book != null && !canDeleteCollaborativeBook(book, user.id)) {
      _showSnack(l10n.removeCollabBeforeDelete);
      return;
    }

    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _isSingleChapter ? l10n.deleteDraftTitle : l10n.deleteBookTitle,
        ),
        content: Text(
          _isSingleChapter ? l10n.deleteDraftBody : l10n.deleteBookBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_isSingleChapter ? l10n.cancel : l10n.keepDraft),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_isSingleChapter ? l10n.delete : l10n.continueAction),
          ),
        ],
      ),
    );
    if (firstConfirmed != true || !mounted) return;

    if (!_isSingleChapter) {
      final finalConfirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.deleteBookFinalTitle),
          content: Text(l10n.deleteBookFinalBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.keepDraft),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteBook),
            ),
          ],
        ),
      );
      if (finalConfirmed != true || !mounted) return;
    }

    setState(() => _isSaving = true);

    try {
      final bookId = (_bookId ?? widget.book?.id)?.trim();
      if (bookId != null && bookId.isNotEmpty) {
        await ref.read(writerRepositoryProvider).deleteBook(bookId);
      }
      try {
        await ref
            .read(writerDraftServiceProvider)
            .deleteDraft(_draftKey(user.id));
      } catch (_) {
        // The remote deletion succeeded; stale recovery data should not make
        // the destructive action appear to have failed.
      }
      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
      if (!mounted) return;
      _isDirty = false;
      _isLocalDirty = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.bookDeleted)));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack(l10n.couldNotDeleteBook('$error'));
    }
  }

  Future<void> _openPrintPage() async {
    final uri = Uri.parse('https://publish.wreadom.in');
    var opened = false;
    try {
      opened =
          await (widget.openPrintPage?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.inAppBrowserView));
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      _showSnack(AppLocalizations.of(context)!.couldNotOpenPrintPage);
    }
  }

  Future<Book?> _showPublishedBookPicker(List<Book> books) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<Book>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetColor = _writerSurfaceColor(sheetContext);
        final textColor = _onWriterSurfaceColor(sheetContext);
        return Container(
          height: MediaQuery.sizeOf(sheetContext).height * 0.7,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(sheetContext).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.selectBookForDraft,
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.close,
                      color: textColor,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  itemCount: books.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return GlassSurface(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(book),
                      semanticButton: true,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  l10n.chapterCount(
                                    book.chapters?.length ??
                                        book.chapterCount ??
                                        0,
                                  ),
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.62),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: textColor),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
      _insertEmbed(BlockEmbed.image(uploaded));
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
          .uploadImage(
            file: file,
            folder: 'covers',
            userId: user.id,
            deliveryTransform: 'f_auto,q_auto,w_600,h_900,c_pad,b_auto',
          );
      setState(() => _coverUrl = uploaded);
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

  Future<bool> _save({
    required String status,
    bool closeAfterSave = false,
    bool allowUntitled = false,
    bool showSnack = true,
  }) async {
    if (_isSaving) return false;
    final l10n = AppLocalizations.of(context)!;
    final wasPublished = _isPublished;

    final title = _titleController.value.text.trim();

    if (title.isEmpty && !allowUntitled) {
      _showSnack(l10n.addTitleBeforeSaving);
      setState(() => _setStep(1));
      return false;
    }

    if (status == 'published' && !_hasVisibleSavableChapter) {
      _showSnack(l10n.keepOneChapterVisible);
      return false;
    }

    final user = await _currentUserOrNull();
    if (user == null) return false;
    if (_collabEnabled &&
        !isAcceptedCollaboration(widget.book ?? _emptyBookForCollabCheck()) &&
        (_selectedCollaboratorId == null ||
            _selectedCollaboratorId!.trim().isEmpty)) {
      _showSnack(l10n.selectCoAuthorBeforeSaving);
      setState(() => _setStep(1));
      return false;
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
      final shouldNotifyFollowers = status == 'published' && !_isPublished;

      if ((_bookId ?? widget.book?.id ?? '').isEmpty) {
        _bookId = await ref.read(writerRepositoryProvider).createBook(book);
      } else {
        await ref.read(writerRepositoryProvider).updateBook(_bookId!, book);
      }
      if (shouldNotifyFollowers && _bookId != null) {
        // Cloud Functions generate follower notifications for new publications.
        AnalyticsService.logBookPublish(bookId: _bookId!);
      }
      if (status == 'published') {
        unawaited(AppReviewHelper.incrementActionAndCheck());
      }
      _savedBookLeaves = book.leaves;
      _savedPublishedAt = book.publishedAt;
      _savedStatus = status;
      unawaited(
        ref
            .read(writerDraftServiceProvider)
            .deleteDraft(localDraftKey)
            .catchError((Object _) {}),
      );
      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
      if (!mounted) return true;
      setState(() {
        _isDirty = false;
        _isLocalDirty = false;
        _isSaving = false;
        _saveStatus = status == 'published'
            ? (wasPublished ? l10n.bookSaved : l10n.writerPublishedStatus)
            : l10n.draftSaved;
      });
      if (showSnack) {
        _showSnack(
          status == 'published'
              ? (wasPublished ? l10n.bookSaved : l10n.storyPublished)
              : l10n.draftSaved,
        );
      }
      if (closeAfterSave && mounted) {
        setState(() => _allowPop = true);
        Navigator.of(context).pop();
      }
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _isSaving = false;
        _saveStatus = l10n.writerSaveFailed;
      });
      if (showSnack) {
        _showSnack(l10n.couldNotSave('$error'));
      }
      return false;
    }
  }

  Future<bool> _syncDraftCheckpoint() async {
    if (!_isDirty || _isSaving || !_hasSavableContent) return true;
    return _save(status: _statusForSave, allowUntitled: true, showSnack: false);
  }

  Future<bool> _saveLocalDraft() async {
    if (!_hasSavableContent) return true;
    final user = await _currentUserOrNull();
    if (user == null) return false;

    try {
      final book = _buildBookForSave(user, status: 'draft');
      await ref
          .read(writerDraftServiceProvider)
          .saveDraft(draftKey: _draftKey(user.id), book: book);
      if (!mounted) return true;
      setState(() {
        _isLocalDirty = false;
        _saveStatus = AppLocalizations.of(context)!.savedOnDevice;
      });
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(
        () => _saveStatus = AppLocalizations.of(context)!.localSaveFailed,
      );
      return false;
    }
  }

  Book _buildBookForSave(UserModel user, {required String status}) {
    _syncBookTitleFromFirstChapter();
    final now = DateTime.now().millisecondsSinceEpoch;
    final bookTitle = _titleController.value.text.trim().isEmpty
        ? AppLocalizations.of(context)!.untitledStory
        : _titleController.value.text.trim();
    final chapters = <Chapter>[];
    for (var i = 0; i < _chapters.length; i++) {
      final draft = _chapters[i];
      final content = htmlFromDocument(draft.controller.document);
      final plainContent = plainTextFromHtml(content);
      if (!draft.isHidden &&
          draft.title.text.trim().isEmpty &&
          plainContent.isEmpty &&
          !hasMeaningfulWriterHtml(content)) {
        continue;
      }
      draft.lastSavedAt = now;
      draft.id ??= 'chapter_${now}_$i';
      chapters.add(
        Chapter(
          id: draft.id!,
          title: draft.title.text.trim().isEmpty
              ? AppLocalizations.of(context)!.chapterNumber(i + 1)
              : draft.title.text.trim(),
          content: content,
          index: i,
          status: status == 'published' ? 'published' : 'draft',
          lastSavedAt: now,
          versions: draft.versions,
          isTitleLocked: draft.original?.isTitleLocked,
          originalBookId: draft.original?.originalBookId,
          isHidden: draft.isHidden,
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
    final existingPublishedAt = _savedPublishedAt ?? existingBook?.publishedAt;
    final publishedAt = status == 'published'
        ? existingPublishedAt ?? now
        : existingPublishedAt;
    final leaves = _leavesForSave(
      existingBook: existingBook,
      user: user,
      status: status,
      issuedAt: publishedAt,
      now: now,
    );

    return Book(
      id: _bookId ?? widget.book?.id ?? '',
      title: bookTitle,
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
      publishedAt: publishedAt,
      optOutComplementary: _optOutComplementary,
      identifier: widget.book?.identifier,
      recommendationCount: widget.book?.recommendationCount,
      weightedScore: widget.book?.weightedScore,
      averageRating: widget.book?.averageRating,
      viewCount: widget.book?.viewCount,
      ratingsCount: widget.book?.ratingsCount,
      topics: topics,
      chapterCount: chapters.where((chapter) => !chapter.isHidden).length,
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
      leaves: leaves,
      leafCount: leaves.length,
      hasLeaves: leaves.isNotEmpty,
      leafUpdatedAt: leaves.isNotEmpty
          ? (existingBook?.leafUpdatedAt ?? now)
          : existingBook?.leafUpdatedAt,
    );
  }

  List<LeafAttachment> _leavesForSave({
    required Book? existingBook,
    required UserModel user,
    required String status,
    required int? issuedAt,
    required int now,
  }) {
    final leaves = List<LeafAttachment>.from(
      _savedBookLeaves ?? existingBook?.leaves ?? const <LeafAttachment>[],
    );
    final initialTopic = widget.initialTopic?.trim();
    final existingCertificateIndex = leaves.indexWhere(
      (leaf) => leaf.type == LeafType.certificate,
    );
    final existingCertificate = existingCertificateIndex == -1
        ? null
        : leaves[existingCertificateIndex];
    final topicName = initialTopic?.isNotEmpty == true
        ? initialTopic!
        : existingCertificate?.certificateTopicName?.trim();
    final isNewPublication =
        status == 'published' &&
        (_savedPublishedAt ?? existingBook?.publishedAt) == null;
    if ((initialTopic == null || initialTopic.isEmpty) &&
        existingCertificate == null) {
      return leaves;
    }
    if (topicName == null || topicName.isEmpty) {
      return leaves;
    }

    final normalizedTopic = topicName.toLowerCase();
    final matchingCertificateIndex = leaves.indexWhere((leaf) {
      if (leaf.type != LeafType.certificate) return false;
      final certificateTopic = (leaf.certificateTopicName ?? '')
          .trim()
          .toLowerCase();
      return certificateTopic == normalizedTopic ||
          certificateTopic.isEmpty && leaf == existingCertificate;
    });
    final participantName = (user.displayName ?? user.penName ?? user.username)
        .trim();
    final certificateIssuedAt = status == 'published'
        ? issuedAt ?? now
        : existingCertificate?.certificateIssuedAt;
    final certificate = LeafAttachment(
      id: matchingCertificateIndex == -1
          ? _certificateLeafId(topicName, certificateIssuedAt)
          : leaves[matchingCertificateIndex].id,
      type: LeafType.certificate,
      createdAt: matchingCertificateIndex == -1
          ? now
          : leaves[matchingCertificateIndex].createdAt,
      createdBy: user.id,
      createdByRole: 'app',
      title: 'Certificate',
      certificateTopicName: topicName,
      certificateIssuedAt: certificateIssuedAt,
      certificateParticipantName: participantName.isEmpty
          ? user.username
          : participantName,
      certificateParticipantPhotoUrl: user.photoURL,
    );
    if (matchingCertificateIndex == -1) {
      leaves.add(certificate);
    } else if (isNewPublication ||
        leaves[matchingCertificateIndex].certificateIssuedAt == null) {
      leaves[matchingCertificateIndex] = certificate;
    }
    return leaves;
  }

  String _certificateLeafId(String topicName, int? issuedAt) {
    final safeTopic = topicName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'certificate_${issuedAt ?? 'pending'}_${safeTopic.isEmpty ? 'topic' : safeTopic}';
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

  bool get _hasVisibleSavableChapter {
    return _chapters.any((chapter) {
      if (chapter.isHidden) return false;
      if (chapter.title.text.trim().isNotEmpty) return true;
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

class _VersionHistoryTile extends StatelessWidget {
  const _VersionHistoryTile({
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.textColor,
    this.action,
  });

  final String title;
  final String subtitle;
  final String preview;
  final Color textColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.58),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[const SizedBox(width: 10), action!],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            preview,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
        ],
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
    required this.versionCount,
    required this.isCurrent,
    required this.isHidden,
    required this.canDelete,
    required this.textColor,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onDelete,
    required this.onHistory,
  });

  final int index;
  final String title;
  final String preview;
  final int wordCount;
  final int versionCount;
  final bool isCurrent;
  final bool isHidden;
  final bool canDelete;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final borderColor = isCurrent
        ? Theme.of(context).colorScheme.primary
        : textColor.withValues(alpha: 0.18);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GlassSurface(
        strong: isCurrent,
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        semanticButton: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: isCurrent ? 0.08 : 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                            GlassSurface(
                              borderRadius: BorderRadius.circular(8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              child: Text(
                                l10n.editing,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (isHidden) ...[
                            const SizedBox(width: 6),
                            GlassSurface(
                              borderRadius: BorderRadius.circular(8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              child: Text(
                                l10n.hiddenChapter,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
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
                      if (versionCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.versionCount(versionCount),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: isHidden ? l10n.showChapter : l10n.hideChapter,
                  onPressed: onToggleVisibility,
                  color: textColor.withValues(alpha: 0.74),
                  icon: Icon(
                    isHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                if (onHistory != null)
                  IconButton(
                    tooltip: l10n.versionHistory,
                    onPressed: onHistory,
                    color: textColor.withValues(alpha: 0.74),
                    icon: const Icon(Icons.history_rounded),
                  ),
                IconButton(
                  tooltip: l10n.moveToDrafts,
                  onPressed: canDelete ? onDelete : null,
                  color: textColor.withValues(alpha: 0.74),
                  icon: const Icon(Icons.file_upload_outlined),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _WriterMenuAction { addToBook, deleteBook, convertToDraft, printBook }

class _ChapterDraft {
  _ChapterDraft({
    required this.title,
    required this.controller,
    required this.original,
    required this.id,
    required List<ChapterVersion> versions,
    required this.lastSavedAt,
    required this.isHidden,
    required VoidCallback onChanged,
  }) : versions = List<ChapterVersion>.from(versions),
       _lastVersionContent = original?.content ?? '',
       _lastVersionSavedAt = lastSavedAt ?? 0,
       _onChanged = onChanged {
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
      versions: chapter.versions ?? const <ChapterVersion>[],
      lastSavedAt: chapter.lastSavedAt,
      isHidden: chapter.isHidden,
      onChanged: onChanged,
    );
  }

  factory _ChapterDraft.empty(VoidCallback onChanged) {
    return _ChapterDraft(
      id: null,
      title: TextEditingController(),
      controller: QuillController.basic(),
      original: null,
      versions: const <ChapterVersion>[],
      lastSavedAt: null,
      isHidden: false,
      onChanged: onChanged,
    );
  }

  String? id;
  String get key => id ?? identityHashCode(this).toString();
  final TextEditingController title;
  final QuillController controller;
  final Chapter? original;
  final List<ChapterVersion> versions;
  int? lastSavedAt;
  bool isHidden;
  final VoidCallback _onChanged;
  late StreamSubscription<dynamic> _documentChanges;
  late int wordCount;
  String _lastVersionContent;
  int _lastVersionSavedAt;
  bool _replacingContent = false;

  void _handleDocumentChanged() {
    _refreshWordCount();
    if (!_replacingContent) _maybeCreateVersionSnapshot();
    _onChanged();
  }

  void _refreshWordCount() {
    wordCount = wordCountFromHtml(htmlFromDocument(controller.document));
  }

  void _maybeCreateVersionSnapshot() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentContent = htmlFromDocument(controller.document);
    if (!hasMeaningfulWriterHtml(_lastVersionContent) &&
        plainTextFromHtml(_lastVersionContent).isEmpty) {
      if (hasMeaningfulWriterHtml(currentContent) ||
          plainTextFromHtml(currentContent).isNotEmpty) {
        _lastVersionContent = currentContent;
        _lastVersionSavedAt = now;
      }
      return;
    }

    if (!shouldCreateChapterVersion(
      previousContent: _lastVersionContent,
      currentContent: currentContent,
      lastSavedAt: _lastVersionSavedAt,
      now: now,
    )) {
      return;
    }

    final next = addChapterVersionSnapshot(
      versions: versions,
      content: _lastVersionContent,
      timestamp: _lastVersionSavedAt == 0 ? now : _lastVersionSavedAt,
      wordCount: wordCountFromHtml(_lastVersionContent),
    );
    versions
      ..clear()
      ..addAll(next);
    _lastVersionContent = currentContent;
    _lastVersionSavedAt = now;
  }

  void restoreVersion(ChapterVersion version) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentContent = htmlFromDocument(controller.document);
    final next = restoreChapterVersionHistory(
      versions: versions,
      currentContent: currentContent,
      now: now,
    );
    versions
      ..clear()
      ..addAll(next);
    _replaceDocument(documentFromHtml(version.content));
    _lastVersionContent = version.content;
    _lastVersionSavedAt = now;
    lastSavedAt = now;
    _refreshWordCount();
    _onChanged();
  }

  void _replaceDocument(Document document) {
    _replacingContent = true;
    _documentChanges.cancel();
    controller.document = document;
    controller.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    _attachDocumentListener();
    _replacingContent = false;
  }

  void _attachListeners() {
    title.addListener(_onChanged);
    _refreshWordCount();
    _attachDocumentListener();
  }

  void _attachDocumentListener() {
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
