import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/feed_post.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/feed_providers.dart';
import '../providers/reader_settings_provider.dart';
import '../utils/writer_media_utils.dart';
import '../widgets/comment_widgets.dart';
import '../widgets/writer_media_embed.dart';
import '../../domain/repositories/book_repository.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/app_link_helper.dart';
import '../providers/theme_provider.dart';

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

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with RestorationMixin, WidgetsBindingObserver {
  late int _chapterIndex;
  double _fontSize = 18;
  ReaderTheme _readerTheme = ReaderTheme.system;
  ReaderFont _readerFont = ReaderFont.serif;
  final RestorableTextEditingController _commentController =
      RestorableTextEditingController();
  final RestorableInt _restorableChapterIndex = RestorableInt(0);
  final RestorableDouble _restorableScrollProgress = RestorableDouble(0.0);
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _chapterContentEndKey = GlobalKey();
  final FocusNode _commentFocusNode = FocusNode();
  Comment? _replyingTo;
  int _chapterRating = 5;
  String? _selectedQuote;
  String _selectedText = "";
  late BookRepository _bookRepository;
  String? _currentUserId;
  double _scrollProgress = 0.0;
  double _lastScrollOffset = 0.0;
  bool _showReaderChrome = true;
  bool _isDiscussionOpen = false;
  bool _isTtsPlaying = false;
  bool _isTtsPreparing = false;
  bool _isTtsSequencing = false;
  bool _stopTtsRequested = false;
  bool _isSelectionTtsPlaying = false;
  int _ttsSession = 0;
  late final FlutterTts _tts;
  List<String> _ttsChunkList = const [];
  int _ttsChunkIndex = 0;
  int _activeTtsBlockIndex = -1;
  final GlobalKey _quoteImageKey = GlobalKey();
  _QuoteSharePayload? _quoteSharePayload;
  Timer? _progressSaveDebounce;
  bool _initialScrollRestored = false;
  double? _pendingSavedScrollProgress;

  @override
  String? get restorationId => 'reader_comment_${widget.book.id}';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_commentController, 'comment_text');
    registerForRestoration(_restorableChapterIndex, 'chapter_index');
    registerForRestoration(_restorableScrollProgress, 'scroll_progress');

    // If this is the first time the screen is loading and no state was restored,
    // use the initial chapter index provided to the widget.
    if (oldBucket == null && initialRestore) {
      _restorableChapterIndex.value = widget.initialChapterIndex;
    }

    _chapterIndex = _restorableChapterIndex.value;
    _scrollProgress = _restorableScrollProgress.value;
    _pendingSavedScrollProgress = _scrollProgress > 0 ? _scrollProgress : null;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _chapterIndex = widget.initialChapterIndex;
    WidgetsBinding.instance.addObserver(this);
    _bookRepository = ref.read(bookRepositoryProvider);
    _tts = FlutterTts();
    _configureTts();
    _applyReaderSettings(ref.read(readerSettingsControllerProvider));
    _incrementView();
    _saveHistorySilently('initial_history_save');
    unawaited(
      _loadSavedScrollPosition().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logBackgroundSaveError('initial_scroll_restore', error, stackTrace);
      }),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _flushProgressSave('lifecycle_${state.name}');
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final currentOffset = _scrollController.offset;
      final direction = position.userScrollDirection;
      final shouldShowChrome = direction == ScrollDirection.reverse
          ? false
          : direction == ScrollDirection.forward
          ? true
          : _showReaderChrome;
      final progress = _currentProgressPosition();
      if ((progress - _scrollProgress).abs() > 0.01 ||
          shouldShowChrome != _showReaderChrome ||
          (currentOffset - _lastScrollOffset).abs() > 0.5) {
        setState(() {
          _scrollProgress = progress.clamp(0.0, 1.0);
          _restorableScrollProgress.value = _scrollProgress;
          _showReaderChrome = shouldShowChrome;
          _lastScrollOffset = currentOffset;
        });
        _scheduleProgressSave();
      }
    }
  }

  Future<void> _incrementView() async {
    try {
      await _bookRepository.recordBookView(
        widget.book.id,
        await _viewerKeyForViewCount(),
      );
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<String> _viewerKeyForViewCount() async {
    try {
      final user = await ref.read(currentUserProvider.future);
      final userId = user?.id.trim();
      if (userId != null && userId.isNotEmpty) return 'user:$userId';
    } catch (_) {}

    const prefsKey = 'anonymous_reader_viewer_id';
    final prefs = ref.read(sharedPreferencesProvider);
    var anonymousId = prefs.getString(prefsKey)?.trim();
    if (anonymousId == null || anonymousId.isEmpty) {
      anonymousId =
          '${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(this)}';
      await prefs.setString(prefsKey, anonymousId);
    }
    return 'anon:$anonymousId';
  }

  void _applyReaderSettings(ReaderSettings settings) {
    if (!mounted) {
      _fontSize = settings.fontSize;
      _readerTheme = settings.theme;
      _readerFont = settings.font;
      return;
    }
    setState(() {
      _fontSize = settings.fontSize;
      _readerTheme = settings.theme;
      _readerFont = settings.font;
    });
  }

  Future<void> _loadSavedScrollPosition() async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null &&
        user.readingProgress?.containsKey(widget.book.id.toString()) == true) {
      final rawProgress = user.readingProgress![widget.book.id.toString()];
      if (rawProgress is! Map) return;

      final progress = Map<String, dynamic>.from(rawProgress);
      final savedChapterIndex =
          (progress['chapterIndex'] as num?)?.toInt() ?? 0;
      final savedPosition = (progress['position'] as num?)?.toDouble() ?? 0.0;

      if (savedChapterIndex == _chapterIndex && savedPosition > 0) {
        _pendingSavedScrollProgress = savedPosition.clamp(0.0, 1.0).toDouble();
        _restorePendingScrollPosition();
      }
    }
  }

  void _restorePendingScrollPosition() {
    if (_initialScrollRestored) return;
    final progress = _pendingSavedScrollProgress;
    if (progress == null || progress <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || _initialScrollRestored) {
        return;
      }
      final maxScroll = _progressScrollExtent();
      if (maxScroll <= 0) {
        _initialScrollRestored = true;
        _pendingSavedScrollProgress = null;
        setState(() {
          _scrollProgress = 1.0;
          _restorableScrollProgress.value = 1.0;
        });
        return;
      }

      _scrollController.jumpTo(
        (progress * maxScroll).clamp(0.0, maxScroll).toDouble(),
      );
      _initialScrollRestored = true;
      _pendingSavedScrollProgress = null;
    });
  }

  Future<void> _saveHistory() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _currentUserId = user.id;
      await _bookRepository.updateReadingHistory(
        user.id,
        widget.book.id.toString(),
      );
      await _saveProgressForUser(user.id, chapterIndex: _chapterIndex);
    }
  }

  void _saveHistorySilently(String operationName) {
    unawaited(
      _saveHistory().catchError((Object error, StackTrace stackTrace) {
        _logBackgroundSaveError(operationName, error, stackTrace);
      }),
    );
  }

  double _currentProgressPosition() {
    if (!_scrollController.hasClients) return _scrollProgress;
    final extent = _progressScrollExtent();
    if (extent <= 0) return 1.0;
    return (_scrollController.offset / extent).clamp(0.0, 1.0).toDouble();
  }

  double _progressScrollExtent() {
    if (!_scrollController.hasClients) return 0.0;
    final position = _scrollController.position;
    final markerContext = _chapterContentEndKey.currentContext;
    final marker = markerContext?.findRenderObject();
    if (marker != null) {
      final viewport = RenderAbstractViewport.maybeOf(marker);
      if (viewport != null) {
        final revealOffset = viewport.getOffsetToReveal(marker, 1.0).offset;
        return revealOffset.clamp(0.0, position.maxScrollExtent).toDouble();
      }
    }
    return position.maxScrollExtent;
  }

  bool get _useLegacyTtsTapSeeking => false;

  Future<void> _saveProgressForUser(
    String userId, {
    required int chapterIndex,
    double? position,
  }) async {
    _currentUserId = userId;
    final resolvedPosition = position ?? _currentProgressPosition();

    await _bookRepository.updateReadingProgress(
      userId,
      widget.book.id.toString(),
      chapterIndex: chapterIndex,
      position: resolvedPosition,
    );
    if (mounted) ref.invalidate(currentUserProvider);
  }

  void _saveProgressSilently(String operationName, {String? userId}) {
    final targetUserId =
        userId ?? ref.read(currentUserProvider).value?.id ?? _currentUserId;
    if (targetUserId == null) return;

    final chapterIndex = _chapterIndex;
    final position = _currentProgressPosition();
    unawaited(
      _saveProgressForUser(
        targetUserId,
        chapterIndex: chapterIndex,
        position: position,
      ).catchError((Object error, StackTrace stackTrace) {
        _logBackgroundSaveError(
          operationName,
          error,
          stackTrace,
          chapterIndex: chapterIndex,
        );
      }),
    );
  }

  void _logBackgroundSaveError(
    String operationName,
    Object error,
    StackTrace stackTrace, {
    int? chapterIndex,
  }) {
    debugPrint(
      'Reader background save failed during $operationName '
      '(bookId: ${widget.book.id}, '
      'chapterIndex: ${chapterIndex ?? _chapterIndex}): $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  Future<void> _markChapterCompleteAndGoNext() async {
    final currentChapterIndex = _chapterIndex;
    final user = ref.read(currentUserProvider).value;
    final userId = user?.id ?? _currentUserId;
    if (userId != null) {
      await _bookRepository.updateReadingProgress(
        userId,
        widget.book.id.toString(),
        chapterIndex: currentChapterIndex,
        position: 1.0,
        completedChapterIndex: currentChapterIndex,
      );
      if (mounted) ref.invalidate(currentUserProvider);
    }
    await HapticFeedback.selectionClick();
    _goToChapter(currentChapterIndex + 1);
  }

  void _scheduleProgressSave() {
    if (_currentUserId == null) return;
    _progressSaveDebounce?.cancel();
    _progressSaveDebounce = Timer(const Duration(seconds: 2), () {
      _progressSaveDebounce = null;
      _saveProgressSilently('debounced_progress_save', userId: _currentUserId);
    });
  }

  void _flushProgressSave(
    String operationName, {
    String? userId,
    bool readCurrentUser = true,
  }) {
    _progressSaveDebounce?.cancel();
    _progressSaveDebounce = null;
    if (userId != null) {
      _saveProgressSilently(operationName, userId: userId);
    } else if (readCurrentUser) {
      _saveProgressSilently(operationName);
    }
  }

  void _goToChapter(int index) {
    _flushProgressSave('chapter_change');
    unawaited(_stopTts());
    setState(() {
      _chapterIndex = index;
      _restorableChapterIndex.value = index;
      _scrollProgress = 0.0;
      _restorableScrollProgress.value = 0.0;
      _lastScrollOffset = 0.0;
      _initialScrollRestored = true;
      _pendingSavedScrollProgress = null;
      // Reset TTS position for new chapter
      _ttsChunkIndex = 0;
      _activeTtsBlockIndex = -1;
      _ttsChunkList = const [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    _saveProgressSilently('chapter_change_after_navigation');
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    WidgetsBinding.instance.removeObserver(this);
    _flushProgressSave(
      'dispose',
      userId: _currentUserId,
      readCurrentUser: false,
    );
    _scrollController.removeListener(_onScroll);
    _commentController.dispose();
    _restorableChapterIndex.dispose();
    _restorableScrollProgress.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(bookChaptersProvider(widget.book.id));
    final offlineChaptersAsync = ref.watch(
      offlineChaptersProvider(widget.book.id),
    );
    final commentsAsync = ref.watch(bookCommentsProvider(widget.book.id));
    final userAsync = ref.watch(currentUserProvider);
    ref.watch(appThemeControllerProvider);

    ref.listen(readerSettingsControllerProvider, (previous, next) {
      if (previous != next) _applyReaderSettings(next);
    });

    // Keep current user ID updated
    ref.listen(currentUserProvider, (previous, next) {
      if (next.value != null) {
        _currentUserId = next.value!.id;
      }
    });

    return offlineChaptersAsync.when(
      data: (offlineChapters) {
        if (offlineChapters.isNotEmpty) {
          return _buildReader(
            context,
            offlineChapters,
            commentsAsync,
            userAsync,
            isOffline: true,
          );
        }

        return chaptersAsync.when(
          data: (chapters) => _buildReader(
            context,
            chapters,
            commentsAsync,
            userAsync,
            isOffline: false,
          ),
          loading: () => Scaffold(
            appBar: AppBar(title: Text(widget.book.title)),
            body: _buildLoadingBody(),
          ),
          error: (err, stack) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Failed to load book content: $err')),
          ),
        );
      },
      loading: () => chaptersAsync.when(
        data: (chapters) => _buildReader(
          context,
          chapters,
          commentsAsync,
          userAsync,
          isOffline: false,
        ),
        loading: () => Scaffold(
          appBar: AppBar(title: Text(widget.book.title)),
          body: _buildLoadingBody(),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Failed to load book content: $err')),
        ),
      ),
      error: (_, _) => chaptersAsync.when(
        data: (chapters) => _buildReader(
          context,
          chapters,
          commentsAsync,
          userAsync,
          isOffline: false,
        ),
        loading: () => Scaffold(
          appBar: AppBar(title: Text(widget.book.title)),
          body: _buildLoadingBody(),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Failed to load book content: $err')),
        ),
      ),
    );
  }

  Widget _buildLoadingBody() {
    final isArchiveBook =
        widget.book.source == 'archive' ||
        (widget.book.source == null &&
            !(widget.book.id.length == 20 &&
                RegExp(r'^[a-zA-Z0-9]{20}$').hasMatch(widget.book.id)));
    if (!isArchiveBook) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Fetching public-domain text...',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Internet Archive books can take a moment to prepare.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReader(
    BuildContext context,
    List<Chapter> chapters,
    AsyncValue<List<Comment>> commentsAsync,
    AsyncValue<dynamic> userAsync, {
    required bool isOffline,
  }) {
    _restorePendingScrollPosition();
    if (chapters.isNotEmpty) {
      final clampedIndex = _chapterIndex.clamp(0, chapters.length - 1).toInt();
      if (clampedIndex != _chapterIndex) {
        _chapterIndex = clampedIndex;
        _restorableChapterIndex.value = clampedIndex;
      }
    }
    final chapter = chapters.isEmpty
        ? null
        : chapters[_chapterIndex.clamp(0, chapters.length - 1).toInt()];
    final completedChapterIndexes = _completedChapterIndexes(userAsync);
    final commentCounts = commentsAsync.maybeWhen(
      data: (comments) => _commentCountsByChapter(chapters, comments),
      orElse: () => const <int, int>{},
    );

    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight + topPadding;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_showReaderChrome ? appBarHeight : 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: _showReaderChrome ? appBarHeight : 0,
          child: ClipRect(
            child: AppBar(
              backgroundColor: _getAppBarBackgroundColor(),
              foregroundColor: _getAppBarForegroundColor(),
              iconTheme: IconThemeData(color: _getAppBarForegroundColor()),
              actionsIconTheme: IconThemeData(
                color: _getAppBarForegroundColor(),
              ),
              title: Text(
                widget.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _getAppBarForegroundColor()),
              ),
              actions: [
                if (isOffline)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: const Text(
                        'Offline',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: Colors.green.withValues(alpha: 0.7),
                      padding: EdgeInsets.zero,
                      side: BorderSide.none,
                    ),
                  ),
                IconButton(
                  icon: _isTtsPreparing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isTtsPlaying
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_outlined,
                        ),
                  tooltip: _isTtsPlaying
                      ? (_ttsChunkList.isNotEmpty
                            ? 'Stop (block ${_ttsChunkIndex + 1}/${_ttsChunkList.length})'
                            : 'Stop reading aloud')
                      : 'Read aloud',
                  onPressed: chapter == null || _isTtsPreparing
                      ? null
                      : () => _toggleTts(chapter),
                ),
                IconButton(
                  icon: const Icon(Icons.format_size_rounded),
                  onPressed: _showSettings,
                  tooltip: 'Reader Settings',
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: _ChapterDrawer(
        chapters: chapters,
        currentIndex: _chapterIndex,
        completedChapterIndexes: completedChapterIndexes,
        commentCounts: commentCounts,
        backgroundColor: _getBackgroundColor(),
        headerColor: _getAppBarBackgroundColor(),
        textColor: _getTextColor(),
        secondaryTextColor: _getSecondaryTextColor(),
        accentColor: Theme.of(context).colorScheme.primary,
        onSelect: (index) {
          _goToChapter(index);
          Navigator.of(context).pop();
        },
        onOpenComments: (index) {
          Navigator.of(context).pop();
          _showDiscussion(chapters[index], chapterIndex: index);
        },
        onBack: () {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
        },
      ),
      body: Container(
        color: _getBackgroundColor(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                // Removed horizontal chips - now in Drawer
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_isDiscussionOpen) {
                        Navigator.of(context).maybePop();
                      }
                    },
                    onTapUp:
                        _useLegacyTtsTapSeeking &&
                            (_isTtsPlaying || _isTtsPreparing) &&
                            !_isSelectionTtsPlaying
                        ? (details) {
                            // TTS is active — seek to the tapped position.
                            if (chapter == null) return;
                            if (!_scrollController.hasClients) return;
                            final position = _scrollController.position;
                            final tapY =
                                details.localPosition.dy +
                                _scrollController.offset;
                            final totalHeight =
                                position.viewportDimension +
                                position.maxScrollExtent;
                            final fraction = totalHeight > 0
                                ? (tapY / totalHeight).clamp(0.0, 1.0)
                                : 0.0;
                            unawaited(_seekTtsToFraction(chapter, fraction));
                          }
                        : null,
                    child:
                        (_isTtsPlaying || _isTtsPreparing) &&
                            !_isSelectionTtsPlaying
                        // When TTS is active, disable text selection so
                        // taps are handled cleanly for seeking.
                        ? _buildTtsListView(chapter, chapters, commentCounts)
                        : SelectionArea(
                            onSelectionChanged: (content) {
                              setState(() {
                                _selectedText = content?.plainText ?? "";
                              });
                            },
                            contextMenuBuilder: (context, selectableRegionState) {
                              final selected = _selectedText.trim();
                              final ctxChapter =
                                  _chapterIndex >= 0 &&
                                      _chapterIndex < chapters.length
                                  ? chapters[_chapterIndex]
                                  : null;
                              final buttonItems = <ContextMenuButtonItem>[
                                ContextMenuButtonItem(
                                  label: 'Read selected',
                                  onPressed: selected.isEmpty
                                      ? null
                                      : () {
                                          selectableRegionState.hideToolbar();
                                          _speakSelectedText(selected);
                                        },
                                ),
                                ContextMenuButtonItem(
                                  label: 'Quote & Comment',
                                  onPressed: selected.isEmpty
                                      ? null
                                      : () {
                                          final restoredQuote =
                                              _restoreLineBreaks(
                                                selected,
                                                ctxChapter?.content,
                                              );
                                          setState(() {
                                            _selectedQuote = restoredQuote;
                                            _replyingTo = null;
                                          });
                                          selectableRegionState.hideToolbar();
                                          _showDiscussion(
                                            ctxChapter,
                                            focusComposer: true,
                                          );
                                        },
                                ),
                                ContextMenuButtonItem(
                                  label: 'Share Quote',
                                  onPressed: selected.isEmpty
                                      ? null
                                      : () {
                                          selectableRegionState.hideToolbar();
                                          _shareSelectedQuote(
                                            ctxChapter,
                                            selected,
                                          );
                                        },
                                ),
                              ];
                              return AdaptiveTextSelectionToolbar.buttonItems(
                                anchors:
                                    selectableRegionState.contextMenuAnchors,
                                buttonItems: buttonItems,
                              );
                            },
                            child: _buildListView(
                              chapter,
                              chapters,
                              commentCounts,
                            ),
                          ),
                  ), // GestureDetector
                ), // Expanded
              ],
            ), // Column
            if (_quoteSharePayload != null)
              Positioned(
                left: -2000,
                top: 0,
                child: RepaintBoundary(
                  key: _quoteImageKey,
                  child: _QuoteImage(payload: _quoteSharePayload!),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _ReaderBottomBar(
        progress: _scrollProgress,
        visible: _showReaderChrome,
        onSwipeUp: () => _showDiscussion(chapter),
        onTap: () => _showDiscussion(chapter),
        theme: _getEffectiveTheme(),
        hasPrevious: _chapterIndex > 0,
        hasNext: _chapterIndex < chapters.length - 1,
        onPrevious: () => _goToChapter(_chapterIndex - 1),
        onNext: () => _goToChapter(_chapterIndex + 1),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Builds the scrollable chapter reading content.
  /// Used by both TTS mode (no selection) and normal mode (wrapped in SelectionArea).
  Widget _buildListView(
    Chapter? chapter,
    List<Chapter> chapters,
    Map<int, int> commentCounts,
  ) {
    final isPoem = widget.book.contentType?.toLowerCase() == 'poem';

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          chapter?.title ?? widget.book.title,
          textAlign: isPoem ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: _getTextColor(),
          ),
        ),
        const SizedBox(height: 16),
        HtmlWidget(
          chapter?.content ??
              widget.book.description ??
              'No readable content available yet.',
          textStyle: TextStyle(
            color: _getTextColor(),
            fontSize: _fontSize,
            height: 1.8,
            fontFamily: _readerFont == ReaderFont.serif ? 'Serif' : null,
          ),
          customStylesBuilder: (element) {
            if (isPoem) {
              return {'text-align': 'center'};
            }
            return null;
          },
          customWidgetBuilder: (element) {
            final tag = element.localName?.toLowerCase();
            if (tag == 'a') {
              final href = element.attributes['href'];
              if (isAllowedWriterLink(href)) {
                return WriterMediaPreview(
                  url: href!,
                  textColor: _getTextColor(),
                );
              }
              return Text(
                element.text,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.8,
                  color: _getTextColor(),
                  fontStyle: isPoem ? FontStyle.italic : null,
                ),
              );
            }
            if (tag == 'img') {
              final src = element.attributes['src'];
              if (isTrustedCloudinaryImageUrl(src)) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      src!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }
            return null;
          },
          onTapUrl: (url) async => isAllowedWriterLink(url),
        ),
        SizedBox(key: _chapterContentEndKey, height: 1),
        const SizedBox(height: 24),
        _ChapterEndActions(
          hasNextChapter: _chapterIndex < chapters.length - 1,
          hasComments: (commentCounts[_chapterIndex] ?? 0) > 0,
          onNextChapter: _chapterIndex < chapters.length - 1
              ? _markChapterCompleteAndGoNext
              : null,
          onViewComments: () => _showDiscussion(chapter),
          onShare: () => _handleShareChapter(chapter),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTtsListView(
    Chapter? chapter,
    List<Chapter> chapters,
    Map<int, int> commentCounts,
  ) {
    final isPoem = widget.book.contentType?.toLowerCase() == 'poem';
    final blocks = _readerBlocksForChapter(chapter);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        for (final block in blocks)
          _ReaderTtsBlockView(
            block: block,
            textColor: _getTextColor(),
            mutedColor: _getSecondaryTextColor(),
            accentColor: Theme.of(context).colorScheme.primary,
            fontSize: _fontSize,
            fontFamily: _readerFont == ReaderFont.serif ? 'Serif' : null,
            isPoem: isPoem,
            isActive: block.ttsIndex == _activeTtsBlockIndex,
            onTap: block.ttsIndex == null || chapter == null
                ? null
                : () => unawaited(_startTtsFromBlock(chapter, block.ttsIndex!)),
          ),
        SizedBox(key: _chapterContentEndKey, height: 1),
        const SizedBox(height: 24),
        _ChapterEndActions(
          hasNextChapter: _chapterIndex < chapters.length - 1,
          hasComments: (commentCounts[_chapterIndex] ?? 0) > 0,
          onNextChapter: _chapterIndex < chapters.length - 1
              ? _markChapterCompleteAndGoNext
              : null,
          onViewComments: () => _showDiscussion(chapter),
          onShare: () => _handleShareChapter(chapter),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  void _configureTts() {
    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _isTtsPreparing = false;
        _isTtsPlaying = true;
      });
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      if (_isTtsSequencing) return;
      setState(() {
        _isTtsPreparing = false;
        _isTtsPlaying = false;
        _isSelectionTtsPlaying = false;
      });
    });
    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() {
        _isTtsPreparing = false;
        _isTtsPlaying = false;
        _isSelectionTtsPlaying = false;
      });
    });
    _tts.setErrorHandler((message) {
      if (!mounted) return;

      // On web, 'interrupted' errors are common and expected when we manually
      // call stop() to seek or change chapters. We ignore them to avoid
      // showing annoying snackbars during normal interactions.
      final msg = message.toString();
      if (msg.toLowerCase().contains('interrupted') ||
          msg.contains('[object SpeechSynthesisErrorEvent]')) {
        return;
      }

      _stopTtsRequested = true;
      _ttsSession++;
      setState(() {
        _isTtsPreparing = false;
        _isTtsPlaying = false;
        _isSelectionTtsPlaying = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Read aloud failed: $message')));
    });
  }

  Future<void> _toggleTts(Chapter chapter) async {
    if (_isTtsPlaying) {
      await _stopTts();
      return;
    }

    final blocks = _ttsBlocksForChapter(chapter);
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No readable text in this chapter.')),
      );
      return;
    }

    // Always start from beginning when explicitly toggled on
    final startIndex = 0;
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : null;
    setState(() {
      _isSelectionTtsPlaying = false;
      _ttsChunkList = blocks;
      _ttsChunkIndex = startIndex;
      _activeTtsBlockIndex = startIndex;
      _isTtsPreparing = true;
    });
    _restoreScrollOffsetAfterModeSwitch(scrollOffset);

    await _runTtsFromIndex(chapter, startIndex);
  }

  /// Seek TTS to a position based on scroll fraction [0.0–1.0].
  /// Stops current speech and restarts from the nearest chunk.
  Future<void> _startTtsFromBlock(Chapter chapter, int blockIndex) async {
    final blocks = _ttsBlocksForChapter(chapter);
    if (blocks.isEmpty || blockIndex < 0 || blockIndex >= blocks.length) return;

    _stopTtsRequested = true;
    _ttsSession++;
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : null;
    setState(() {
      _isSelectionTtsPlaying = false;
      _ttsChunkList = blocks;
      _ttsChunkIndex = blockIndex;
      _activeTtsBlockIndex = blockIndex;
      _isTtsPlaying = false;
      _isTtsPreparing = true;
    });
    _restoreScrollOffsetAfterModeSwitch(scrollOffset);

    await _runTtsFromIndex(chapter, blockIndex);
  }

  void _restoreScrollOffsetAfterModeSwitch(double? scrollOffset) {
    if (scrollOffset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(scrollOffset.clamp(0.0, maxScroll).toDouble());
    });
  }

  Future<void> _speakSelectedText(String selected) async {
    final chunks = _ttsChunks(selected);
    if (chunks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No readable text selected.')),
      );
      return;
    }

    _stopTtsRequested = true;
    _ttsSession++;
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : null;
    setState(() {
      _isSelectionTtsPlaying = true;
      _ttsChunkList = chunks;
      _ttsChunkIndex = 0;
      _activeTtsBlockIndex = -1;
      _isTtsPlaying = false;
      _isTtsPreparing = true;
    });
    _restoreScrollOffsetAfterModeSwitch(scrollOffset);
    await _runTtsFromIndex(
      Chapter(
        id: 'selection',
        title: '',
        content: selected,
        index: _chapterIndex,
      ),
      0,
    );
  }

  Future<void> _seekTtsToFraction(Chapter chapter, double fraction) async {
    if (!_isTtsPlaying && !_isTtsPreparing) return;

    // Build chunk list if not yet available
    if (_ttsChunkList.isEmpty) {
      final text = _plainTextForTts(chapter);
      if (text.isEmpty) return;
      final chunks = _ttsChunks(text);
      setState(() => _ttsChunkList = chunks);
    }

    if (_ttsChunkList.isEmpty) return;

    final targetIndex = (fraction * _ttsChunkList.length).floor().clamp(
      0,
      _ttsChunkList.length - 1,
    );

    // Stop current playback
    _stopTtsRequested = true;
    _ttsSession++;
    await _tts.stop();

    // Small delay helps browser Speech API stabilize after stop()
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    setState(() {
      _ttsChunkIndex = targetIndex;
      _activeTtsBlockIndex = targetIndex;
      _isTtsPlaying = false;
      _isTtsPreparing = true;
    });

    await _runTtsFromIndex(chapter, targetIndex);
  }

  Future<void> _runTtsFromIndex(Chapter chapter, int startIndex) async {
    final chunks = _ttsChunkList.isNotEmpty
        ? _ttsChunkList
        : _ttsChunks(_plainTextForTts(chapter));

    if (chunks.isEmpty) {
      if (mounted) {
        setState(() {
          _isTtsPreparing = false;
          _isTtsPlaying = false;
        });
      }
      return;
    }

    try {
      final session = ++_ttsSession;
      _stopTtsRequested = false;
      _isTtsSequencing = true;
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage(_ttsLanguageForBook());
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      for (int i = startIndex; i < chunks.length; i++) {
        if (_stopTtsRequested || session != _ttsSession) break;
        setState(() {
          _ttsChunkIndex = i;
          _activeTtsBlockIndex = i;
        });
        await _tts.speak(chunks[i]);
      }

      if (!mounted || session != _ttsSession) return;
      setState(() {
        _isTtsPreparing = false;
        _isTtsPlaying = false;
        // Reset chunk index so next play starts from beginning
        _ttsChunkIndex = 0;
        _activeTtsBlockIndex = -1;
        _isSelectionTtsPlaying = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isTtsPreparing = false;
        _isTtsPlaying = false;
        _activeTtsBlockIndex = -1;
        _isSelectionTtsPlaying = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Read aloud failed: $error')));
    } finally {
      _isTtsSequencing = false;
    }
  }

  Future<void> _stopTts() async {
    _stopTtsRequested = true;
    _ttsSession++;
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _isTtsPreparing = false;
      _isTtsPlaying = false;
      _activeTtsBlockIndex = -1;
      _isSelectionTtsPlaying = false;
    });
  }

  String _plainTextForTts(Chapter chapter) {
    final title = chapter.title.trim();
    final content = _looksLikeHtml(chapter.content)
        ? html_parser
              .parse(chapter.content)
              .documentElement
              ?.text
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
        : chapter.content
              .replaceAll(RegExp(r'\r\n?'), '\n')
              .replaceAll(RegExp(r'\n{3,}'), '\n\n')
              .trim();
    return [
      title,
      content,
    ].where((part) => part != null && part.isNotEmpty).join('. ');
  }

  List<String> _ttsBlocksForChapter(Chapter chapter) {
    return _readerBlocksForChapter(chapter)
        .where(
          (block) => block.ttsIndex != null && block.text.trim().isNotEmpty,
        )
        .map((block) => block.text.trim())
        .toList();
  }

  List<_ReaderContentBlock> _readerBlocksForChapter(Chapter? chapter) {
    final blocks = <_ReaderContentBlock>[];
    var nextTtsIndex = 0;

    void addText(String text, {_ReaderBlockKind kind = _ReaderBlockKind.text}) {
      final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalized.isEmpty) return;
      blocks.add(
        _ReaderContentBlock(
          kind: kind,
          text: normalized,
          ttsIndex: nextTtsIndex++,
        ),
      );
    }

    final title = chapter?.title.trim();
    addText(
      title?.isNotEmpty == true ? title! : widget.book.title,
      kind: _ReaderBlockKind.heading,
    );

    final html = chapter?.content ?? widget.book.description ?? '';
    if (html.trim().isEmpty) return blocks;
    if (!_looksLikeHtml(html)) {
      _appendPlainReaderBlocks(html, addText);
      return blocks;
    }

    final doc = html_parser.parse(html);
    for (final node in doc.body?.nodes ?? const <dom.Node>[]) {
      _appendReaderBlocks(node, blocks, addText);
    }
    return blocks;
  }

  bool _looksLikeHtml(String value) {
    return RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(value);
  }

  void _appendPlainReaderBlocks(
    String value,
    void Function(String text, {_ReaderBlockKind kind}) addText,
  ) {
    final normalized = value
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (normalized.isEmpty) return;
    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    for (final paragraph in paragraphs) {
      for (final chunk in _splitLongPlainTextBlock(paragraph)) {
        addText(chunk);
      }
    }
  }

  List<String> _splitLongPlainTextBlock(String text) {
    const maxBlockLength = 900;
    final normalized = text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
    if (normalized.length <= maxBlockLength) return [normalized];

    final chunks = <String>[];
    var remaining = normalized;
    while (remaining.length > maxBlockLength) {
      var splitAt = remaining.lastIndexOf(RegExp(r'[.!?।]\s+'), maxBlockLength);
      if (splitAt < maxBlockLength * 0.45) {
        splitAt = remaining.lastIndexOf(' ', maxBlockLength);
      }
      if (splitAt < maxBlockLength * 0.45) splitAt = maxBlockLength;
      chunks.add(remaining.substring(0, splitAt).trim());
      remaining = remaining.substring(splitAt).trim();
    }
    if (remaining.isNotEmpty) chunks.add(remaining);
    return chunks;
  }

  void _appendReaderBlocks(
    dom.Node node,
    List<_ReaderContentBlock> blocks,
    void Function(String text, {_ReaderBlockKind kind}) addText,
  ) {
    if (node is dom.Text) {
      addText(node.text);
      return;
    }
    if (node is! dom.Element) return;

    final tag = node.localName?.toLowerCase();
    if (tag == 'img') {
      final src = node.attributes['src'];
      if (isTrustedCloudinaryImageUrl(src)) {
        blocks.add(_ReaderContentBlock(kind: _ReaderBlockKind.image, url: src));
      }
      return;
    }
    if (tag == 'a') {
      final href = node.attributes['href'];
      if (isAllowedWriterLink(href)) {
        blocks.add(
          _ReaderContentBlock(kind: _ReaderBlockKind.media, url: href),
        );
        return;
      }
    }

    const blockTags = {
      'p',
      'div',
      'li',
      'blockquote',
      'pre',
      'section',
      'article',
    };
    const headingTags = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};

    if (headingTags.contains(tag)) {
      addText(node.text, kind: _ReaderBlockKind.heading);
      return;
    }
    if (blockTags.contains(tag)) {
      addText(
        node.text,
        kind: tag == 'blockquote'
            ? _ReaderBlockKind.quote
            : _ReaderBlockKind.text,
      );
      return;
    }

    for (final child in node.nodes) {
      _appendReaderBlocks(child, blocks, addText);
    }
  }

  String _ttsLanguageForBook() {
    final language = widget.book.languages.firstOrNull?.toLowerCase().trim();
    if (language == null || language.isEmpty) return 'en-US';
    if (language == 'hi' || language == 'hin' || language.contains('hindi')) {
      return 'hi-IN';
    }
    if (language == 'en' || language == 'eng' || language.contains('english')) {
      return 'en-US';
    }
    return language.length == 2 ? language : 'en-US';
  }

  List<String> _ttsChunks(String text) {
    final normalized = text
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return const [];

    const maxChunkLength = 3200;
    final chunks = <String>[];
    var remaining = normalized;
    while (remaining.length > maxChunkLength) {
      var splitAt = remaining.lastIndexOf(RegExp(r'[.!?।]\s+'), maxChunkLength);
      if (splitAt < maxChunkLength * 0.5) {
        splitAt = remaining.lastIndexOf(' ', maxChunkLength);
      }
      if (splitAt < maxChunkLength * 0.5) splitAt = maxChunkLength;
      chunks.add(remaining.substring(0, splitAt).trim());
      remaining = remaining.substring(splitAt).trim();
    }
    if (remaining.isNotEmpty) chunks.add(remaining);
    return chunks;
  }

  Set<int> _completedChapterIndexes(AsyncValue<dynamic> userAsync) {
    return userAsync.maybeWhen(
      data: (user) {
        final progressRaw = user?.readingProgress?[widget.book.id.toString()];
        if (progressRaw is! Map) return <int>{};
        final completedRaw = progressRaw['completedChapterIndexes'];
        if (completedRaw is! List) return <int>{};
        return completedRaw
            .whereType<num>()
            .map((index) => index.toInt())
            .toSet();
      },
      orElse: () => <int>{},
    );
  }

  Map<int, int> _commentCountsByChapter(
    List<Chapter> chapters,
    List<Comment> comments,
  ) {
    final counts = <int, int>{};
    for (final comment in comments) {
      final index = _chapterIndexForComment(chapters, comment);
      if (index == null) continue;
      counts[index] = (counts[index] ?? 0) + 1;
    }
    return counts;
  }

  int? _chapterIndexForComment(List<Chapter> chapters, Comment comment) {
    final chapterId = comment.chapterId;
    if (chapterId != null && chapterId.isNotEmpty) {
      final index = chapters.indexWhere((chapter) => chapter.id == chapterId);
      if (index >= 0) return index;
    }
    final index = comment.chapterIndex;
    if (index != null && index >= 0 && index < chapters.length) return index;
    return null;
  }

  /// Restores line breaks lost during text selection by matching the flat
  /// selected text against the block-level segments extracted from the raw HTML.
  String _restoreLineBreaks(String flat, String? htmlContent) {
    if (htmlContent == null || htmlContent.isEmpty) return flat;
    try {
      if (!_looksLikeHtml(htmlContent)) {
        return _restoreLineBreaksFromPlainText(flat, htmlContent);
      }
      final doc = html_parser.parse(htmlContent);
      // Collect text of every block-level element in document order.
      // These are the segments HtmlWidget renders as separate Flutter widgets,
      // causing the selection system to join them without any separator.
      const blockTags = {
        'p',
        'div',
        'br',
        'li',
        'h1',
        'h2',
        'h3',
        'h4',
        'h5',
        'h6',
        'blockquote',
        'pre',
        'section',
        'article',
      };
      final segments = <String>[];
      void walk(dynamic node) {
        final tag = node.localName?.toLowerCase();
        if (tag == 'br') {
          segments.add('');
          return;
        }
        if (tag != null && blockTags.contains(tag)) {
          final text = node.text?.trim() ?? '';
          if (text.isNotEmpty) segments.add(text);
          return;
        }
        // recurse into inline/unknown nodes
        for (final child in (node.nodes ?? [])) {
          walk(child);
        }
      }

      for (final child in doc.body?.nodes ?? []) {
        walk(child);
      }
      if (segments.isEmpty) return flat;

      // Build a reconstructed string by joining segments with newlines and
      // try to find the flat selection within it (ignoring whitespace/newlines).
      final full = segments.join('\n');
      // Normalise both to compare
      final normFlat = flat.replaceAll(RegExp(r'\s+'), ' ').trim();
      final normFull = full.replaceAll(RegExp(r'\s+'), ' ').trim();
      final idx = normFull.indexOf(normFlat);
      if (idx < 0) return flat; // couldn't locate — return original

      // Map the character offset back to the newline-restored string.
      // We walk character-by-character through `full`, skipping whitespace
      // the same way normalisation did, and collect the matching window.
      int matchStart = -1, matchEnd = -1;
      int normPos = 0;
      for (int i = 0; i < full.length; i++) {
        final ch = full[i];
        final isWs = ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';
        if (isWs) {
          // collapsed to single space in normFull — advance normPos only if
          // previous normFull char wasn't also a space
          if (normPos > 0 && normFull[normPos - 1] != ' ') normPos++;
          if (normPos == idx && matchStart < 0) matchStart = i;
          if (normPos == idx + normFlat.length && matchEnd < 0) matchEnd = i;
        } else {
          if (normPos == idx && matchStart < 0) matchStart = i;
          normPos++;
          if (normPos == idx + normFlat.length && matchEnd < 0) {
            matchEnd = i + 1;
          }
        }
      }
      if (matchStart >= 0 && matchEnd > matchStart) {
        return full.substring(matchStart, matchEnd).trim();
      }
      return flat;
    } catch (_) {
      return flat;
    }
  }

  String _restoreLineBreaksFromPlainText(String flat, String source) {
    final normalizedFlat = flat.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalizedFlat.isEmpty) return flat;
    final normalizedSource = source.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (!normalizedSource.contains(normalizedFlat)) return flat;

    final lines = source
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final matches = <String>[];
    var remaining = normalizedFlat;
    for (final line in lines) {
      final normalizedLine = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalizedLine.isEmpty) continue;
      if (remaining.startsWith(normalizedLine)) {
        matches.add(line);
        remaining = remaining.substring(normalizedLine.length).trimLeft();
      } else if (normalizedLine.contains(remaining)) {
        matches.add(remaining);
        remaining = '';
      } else if (remaining.contains(normalizedLine)) {
        matches.add(line);
        remaining = remaining.replaceFirst(normalizedLine, '').trimLeft();
      }
      if (remaining.isEmpty) break;
    }
    return matches.length > 1 ? matches.join('\n') : flat;
  }

  Future<void> _shareSelectedQuote(dynamic chapter, String selected) async {
    // Restore line breaks that SelectionArea strips out when extracting plainText
    // from HtmlWidget's multi-widget layout.
    final htmlContent = chapter?.content as String?;
    final quoteWithBreaks = _restoreLineBreaks(selected, htmlContent);

    final authors = widget.book.authors
        .map((a) => a.name)
        .where((n) => n.isNotEmpty)
        .join(', ');
    final chapterTitle = chapter?.title?.toString();
    final shareText = _quoteShareText(quoteWithBreaks, chapterTitle, authors);

    try {
      final coverUrl = widget.book.coverUrl;
      if (coverUrl != null && coverUrl.isNotEmpty && mounted) {
        await precacheImage(
          NetworkImage(coverUrl),
          context,
        ).timeout(const Duration(seconds: 2), onTimeout: () {});
      }
      setState(() {
        _quoteSharePayload = _QuoteSharePayload(
          quote: quoteWithBreaks,
          bookTitle: widget.book.title,
          chapterTitle: chapterTitle,
          authors: authors,
          coverUrl: coverUrl,
        );
      });
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _quoteImageKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      final image = await boundary?.toImage(pixelRatio: 3);
      final bytes = await image
          ?.toByteData(format: ui.ImageByteFormat.png)
          .then((data) => data?.buffer.asUint8List());

      final chapterIndex = _chapterIndex;
      final chapterLink = AppLinkHelper.chapter(
        widget.book.id,
        chapterIndex + 1,
      );

      if (bytes == null || bytes.isEmpty) {
        await Share.share(
          shareText,
          subject: 'Quote from ${widget.book.title}',
        );
      } else {
        await Share.shareXFiles(
          [
            XFile.fromData(
              bytes,
              name: '${_safeFilePart(widget.book.title)}-quote.png',
              mimeType: 'image/png',
            ),
          ],
          text: chapterLink,
          subject: 'Quote from ${widget.book.title}',
        );
      }
    } catch (_) {
      await Share.share(shareText, subject: 'Quote from ${widget.book.title}');
    } finally {
      if (mounted) {
        setState(() => _quoteSharePayload = null);
      }
    }
  }

  String _quoteShareText(
    String selected,
    String? chapterTitle,
    String authors,
  ) {
    final chapterLink = AppLinkHelper.chapter(
      widget.book.id,
      _chapterIndex + 1,
    );
    final parts = [
      '"$selected"',
      '',
      'From ${widget.book.title}${chapterTitle != null && chapterTitle.isNotEmpty ? ', $chapterTitle' : ''}',
      if (authors.isNotEmpty) 'by $authors',
      chapterLink,
    ];
    return parts.join('\n');
  }

  Future<void> _handleShareChapter(Chapter? chapter) async {
    if (chapter == null) return;

    final chapterNumber = _chapterIndex + 1;
    final url = AppLinkHelper.chapter(widget.book.id, chapterNumber);
    final chapterTitle = chapter.title.trim();

    final authors = widget.book.authors
        .map((a) => a.name)
        .where((n) => n.isNotEmpty)
        .join(', ');

    final shareText =
        'Read "${widget.book.title}" - $chapterTitle ${authors.isNotEmpty ? 'by $authors' : ''}\n\n$url';

    await Share.share(
      shareText,
      subject: '${widget.book.title} - $chapterTitle',
    );
  }

  String _safeFilePart(String value) {
    final safe = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return safe.isEmpty ? 'wreadom' : safe;
  }

  String? get _bookAuthorId {
    final authorId = widget.book.authorId?.trim();
    return authorId == null || authorId.isEmpty ? null : authorId;
  }

  bool _isOwnOriginalBook(String userId) {
    return (widget.book.isOriginal ?? false) && _bookAuthorId == userId;
  }

  void _prepareReviewComposer() {
    if (_replyingTo != null) return;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null || _isOwnOriginalBook(user.id)) {
      _chapterRating = 5;
      return;
    }

    final comments = ref
        .read(bookCommentsProvider(widget.book.id))
        .asData
        ?.value;
    final existingReview = comments
        ?.where(
          (comment) =>
              comment.userId == user.id &&
              comment.bookId?.toString() == widget.book.id &&
              (comment.rating ?? 0) > 0,
        )
        .firstOrNull;
    if (existingReview == null) {
      _chapterRating = 5;
      return;
    }

    _chapterRating = existingReview.rating ?? 5;
    if (_commentController.value.text.trim().isEmpty) {
      _commentController.value.text = existingReview.text;
    }
    _selectedQuote ??= existingReview.quote;
  }

  Future<void> _submitComment(dynamic chapter, {int? chapterIndex}) async {
    final text = _commentController.value.text.trim();
    final user = await ref.read(currentUserProvider.future);
    if (text.isEmpty || user == null) return;
    if (!mounted) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    if (_replyingTo != null) {
      await ref
          .read(commentRepositoryProvider)
          .addReply(
            _replyingTo!.id!,
            CommentReply(
              userId: user.id,
              username: user.username,
              displayName: user.displayName,
              penName: user.penName,
              text: text,
              timestamp: now,
              userPhotoURL: user.photoURL,
            ),
          );
      setState(() => _replyingTo = null);
    } else {
      if (_isOwnOriginalBook(user.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authors cannot review their own book.'),
          ),
        );
        return;
      }
      if (_chapterRating <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a rating.')),
        );
        return;
      }
      final existingReview = await ref
          .read(commentRepositoryProvider)
          .getUserBookReview(widget.book.id, user.id);
      final comment = Comment(
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        userId: user.id,
        username: user.username,
        displayName: user.displayName,
        penName: user.penName,
        text: text,
        rating: _chapterRating,
        quote: _selectedQuote,
        chapterTitle: chapter?.title,
        chapterIndex: chapterIndex ?? _chapterIndex,
        chapterId: chapter?.id?.toString(),
        timestamp: now,
        userPhotoURL: user.photoURL,
      );

      await ref.read(commentRepositoryProvider).upsertBookReview(comment);

      if (existingReview == null) {
        await ref
            .read(feedRepositoryProvider)
            .createFeedPost(
              FeedPost(
                userId: user.id,
                username: user.username,
                displayName: user.displayName,
                penName: user.penName,
                userPhotoURL: user.photoURL,
                type: 'review',
                text: text,
                rating: _chapterRating,
                bookId: widget.book.id,
                bookTitle: widget.book.title,
                bookCover: widget.book.coverUrl,
                chapterTitle: chapter?.title,
                chapterId: chapter?.id?.toString(),
                timestamp: now,
                likes: const [],
                visibility: 'public',
                privacy: 'public',
              ),
            );
        ref.invalidate(feedPostsProvider);
      }

      setState(() {
        _selectedQuote = null;
        _chapterRating = 5;
      });
    }
    await HapticFeedback.lightImpact();
    _commentController.value.clear();
    ref.invalidate(bookCommentsProvider(widget.book.id));
  }

  void _showDiscussion(
    dynamic chapter, {
    int? chapterIndex,
    bool focusComposer = false,
  }) {
    _prepareReviewComposer();
    if (_isDiscussionOpen) {
      if (focusComposer) {
        _commentFocusNode.requestFocus();
      }
      Navigator.of(context).maybePop();
      return;
    }

    _isDiscussionOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.01),
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: focusComposer ? 0.88 : 0.68,
        minChildSize: 0.4,
        maxChildSize: 0.98,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _getSecondaryTextColor().withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      StatefulBuilder(
                        builder: (context, setModalState) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedQuote != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.format_quote,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Quote',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              setState(
                                                () => _selectedQuote = null,
                                              );
                                              setModalState(() {});
                                            },
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedQuote!,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 13,
                                          color: _getSecondaryTextColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_replyingTo != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Replying to ${_replyingTo!.displayName ?? _replyingTo!.username}',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              fontSize: 13,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() => _replyingTo = null);
                                            setModalState(() {});
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else ...[
                                Row(
                                  children: [
                                    Text(
                                      'Your Rating:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _getSecondaryTextColor(),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ...List.generate(5, (index) {
                                      final active = index < _chapterRating;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(
                                            () => _chapterRating = index + 1,
                                          );
                                          setModalState(() {});
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: Icon(
                                            active
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            color: active
                                                ? Colors.amber
                                                : _getSecondaryTextColor(),
                                            size: 24,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextField(
                                controller: _commentController.value,
                                focusNode: _commentFocusNode,
                                minLines: 2,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: _replyingTo != null
                                      ? 'Add a reply...'
                                      : 'Add your review about this chapter',
                                  hintStyle: TextStyle(
                                    color: _getSecondaryTextColor(),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: _getInputFillColor(),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.send_rounded,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      onPressed: () async {
                                        await _submitComment(
                                          chapter,
                                          chapterIndex: chapterIndex,
                                        );
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                ),
                                style: TextStyle(color: _getTextColor()),
                              ),
                              const SizedBox(height: 24),
                              Consumer(
                                builder: (context, ref, _) {
                                  final commentsAsync = ref.watch(
                                    bookCommentsProvider(widget.book.id),
                                  );
                                  return commentsAsync.when(
                                    data: (items) {
                                      final chapterId = chapter?.id.toString();
                                      final chapterComments = items.where((
                                        comment,
                                      ) {
                                        if (chapterId != null &&
                                            chapterId.isNotEmpty &&
                                            comment.chapterId == chapterId) {
                                          return true;
                                        }
                                        return comment.chapterIndex ==
                                            (chapterIndex ?? _chapterIndex);
                                      }).toList();

                                      if (chapterComments.isEmpty) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .chat_bubble_outline_rounded,
                                                  size: 48,
                                                  color:
                                                      _getSecondaryTextColor()
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No comments for this chapter yet.',
                                                  style: TextStyle(
                                                    color:
                                                        _getSecondaryTextColor(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: [
                                          for (final comment in chapterComments)
                                            CommentTile(
                                              comment: comment,
                                              bookId: widget.book.id,
                                              bookAuthorId: _bookAuthorId,
                                              textColor: _getTextColor(),
                                              metadataColor:
                                                  _getSecondaryTextColor(),
                                              onReply: () {
                                                setState(
                                                  () => _replyingTo = comment,
                                                );
                                                setModalState(() {});
                                              },
                                            ),
                                        ],
                                      );
                                    },
                                    loading: () => const Center(
                                      child: LinearProgressIndicator(),
                                    ),
                                    error: (error, _) => Text('Error: $error'),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      _isDiscussionOpen = false;
      _commentFocusNode.unfocus();
    });
    if (focusComposer) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _isDiscussionOpen) {
          _commentFocusNode.requestFocus();
        }
      });
    }
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
                const Text(
                  'Reader Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                  onChangeEnd: (value) => ref
                      .read(readerSettingsControllerProvider.notifier)
                      .setFontSize(value),
                ),
                SwitchListTile(
                  value: _readerFont == ReaderFont.serif,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Serif Font'),
                  onChanged: (value) {
                    setState(
                      () => _readerFont = value
                          ? ReaderFont.serif
                          : ReaderFont.sans,
                    );
                    ref
                        .read(readerSettingsControllerProvider.notifier)
                        .setFont(_readerFont);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Theme',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ThemeOption(
                      label: 'Auto',
                      color: Theme.of(context).colorScheme.surface,
                      icon: Icons.brightness_auto_rounded,
                      selected: _readerTheme == ReaderTheme.system,
                      onTap: () {
                        setState(() => _readerTheme = ReaderTheme.system);
                        ref
                            .read(readerSettingsControllerProvider.notifier)
                            .setTheme(_readerTheme);
                        setModalState(() {});
                      },
                    ),
                    _ThemeOption(
                      label: 'Light',
                      color: Colors.white,
                      selected: _readerTheme == ReaderTheme.light,
                      onTap: () {
                        setState(() => _readerTheme = ReaderTheme.light);
                        ref
                            .read(readerSettingsControllerProvider.notifier)
                            .setTheme(_readerTheme);
                        setModalState(() {});
                      },
                    ),
                    _ThemeOption(
                      label: 'Sepia',
                      color: const Color(0xFFF4ECD8),
                      selected: _readerTheme == ReaderTheme.sepia,
                      onTap: () {
                        setState(() => _readerTheme = ReaderTheme.sepia);
                        ref
                            .read(readerSettingsControllerProvider.notifier)
                            .setTheme(_readerTheme);
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
                        ref
                            .read(readerSettingsControllerProvider.notifier)
                            .setTheme(_readerTheme);
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

  ReaderTheme _getEffectiveTheme() {
    if (_readerTheme != ReaderTheme.system) return _readerTheme;
    final themeMode = ref.read(appThemeControllerProvider);
    return themeMode == ThemeMode.dark ? ReaderTheme.dark : ReaderTheme.light;
  }

  Color _getBackgroundColor() {
    switch (_getEffectiveTheme()) {
      case ReaderTheme.light:
        return Colors.white;
      case ReaderTheme.sepia:
        return const Color(0xFFF4ECD8);
      case ReaderTheme.dark:
        return const Color(0xFF121212);
      case ReaderTheme.system:
        return Colors.white; // Should not happen with _getEffectiveTheme
    }
  }

  Color _getAppBarBackgroundColor() {
    switch (_getEffectiveTheme()) {
      case ReaderTheme.light:
        return Colors.white;
      case ReaderTheme.sepia:
        return _getBackgroundColor();
      case ReaderTheme.dark:
        return Colors.black;
      case ReaderTheme.system:
        return Colors.white;
    }
  }

  Color _getAppBarForegroundColor() {
    switch (_getEffectiveTheme()) {
      case ReaderTheme.light:
      case ReaderTheme.sepia:
        return const Color(0xFF2E261B);
      case ReaderTheme.dark:
        return Colors.white;
      case ReaderTheme.system:
        return const Color(0xFF2E261B);
    }
  }

  Color _getTextColor() {
    switch (_getEffectiveTheme()) {
      case ReaderTheme.light:
      case ReaderTheme.sepia:
        return const Color(0xFF2E261B);
      case ReaderTheme.dark:
        return const Color(0xFFE0E0E0);
      case ReaderTheme.system:
        return const Color(0xFF2E261B);
    }
  }

  Color _getSecondaryTextColor() {
    switch (_getEffectiveTheme()) {
      case ReaderTheme.light:
      case ReaderTheme.sepia:
        return const Color(0xFF5F5447);
      case ReaderTheme.dark:
        return const Color(0xFFB8B8B8);
      case ReaderTheme.system:
        return const Color(0xFF5F5447);
    }
  }

  Color _getInputFillColor() {
    switch (_getEffectiveTheme()) {
      case ReaderTheme.light:
        return const Color(0xFFF4F4F4);
      case ReaderTheme.sepia:
        return const Color(0xFFE9DCC0);
      case ReaderTheme.dark:
        return const Color(0xFF1F1F1F);
      case ReaderTheme.system:
        return const Color(0xFFF4F4F4);
    }
  }
}

enum _ReaderBlockKind { text, heading, quote, image, media }

class _ReaderContentBlock {
  const _ReaderContentBlock({
    required this.kind,
    this.text = '',
    this.url,
    this.ttsIndex,
  });

  final _ReaderBlockKind kind;
  final String text;
  final String? url;
  final int? ttsIndex;
}

class _ReaderTtsBlockView extends StatelessWidget {
  const _ReaderTtsBlockView({
    required this.block,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.fontSize,
    required this.fontFamily,
    required this.isPoem,
    required this.isActive,
    required this.onTap,
  });

  final _ReaderContentBlock block;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final double fontSize;
  final String? fontFamily;
  final bool isPoem;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (block.kind == _ReaderBlockKind.image) {
      final url = block.url;
      if (url == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      );
    }

    if (block.kind == _ReaderBlockKind.media) {
      final url = block.url;
      if (url == null) return const SizedBox.shrink();
      return WriterMediaPreview(url: url, textColor: textColor);
    }

    final isHeading = block.kind == _ReaderBlockKind.heading;
    final isQuote = block.kind == _ReaderBlockKind.quote;
    return Padding(
      padding: EdgeInsets.only(bottom: isHeading ? 16 : 10),
      child: Material(
        color: isActive
            ? accentColor.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: isActive
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                : EdgeInsets.zero,
            decoration: isActive
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: accentColor, width: 4),
                    ),
                  )
                : null,
            child: Text(
              block.text,
              textAlign: isPoem ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                color: isQuote ? mutedColor : textColor,
                fontSize: isHeading ? 22 : fontSize,
                height: isHeading ? 1.35 : 1.8,
                fontWeight: isHeading ? FontWeight.bold : FontWeight.normal,
                fontStyle: isQuote || isPoem ? FontStyle.italic : null,
                fontFamily: fontFamily,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterDrawer extends StatelessWidget {
  final List<Chapter> chapters;
  final int currentIndex;
  final Set<int> completedChapterIndexes;
  final Map<int, int> commentCounts;
  final Color backgroundColor;
  final Color headerColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onOpenComments;
  final VoidCallback onBack;

  const _ChapterDrawer({
    required this.chapters,
    required this.currentIndex,
    required this.completedChapterIndexes,
    required this.commentCounts,
    required this.backgroundColor,
    required this.headerColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.onSelect,
    required this.onOpenComments,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: headerColor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Chapters',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: textColor.withValues(alpha: 0.45)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final isSelected = index == currentIndex;
                final isComplete = completedChapterIndexes.contains(index);
                final commentCount = commentCounts[index] ?? 0;
                return ListTile(
                  selectedTileColor: accentColor.withValues(alpha: 0.12),
                  leading: CircleAvatar(
                    backgroundColor: isComplete
                        ? Colors.green
                        : isSelected
                        ? accentColor
                        : secondaryTextColor.withValues(alpha: 0.14),
                    child: isComplete
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : secondaryTextColor,
                            ),
                          ),
                  ),
                  title: Text(
                    chapters[index].title.trim().isNotEmpty
                        ? chapters[index].title
                        : 'Chapter ${index + 1}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: commentCount > 0
                      ? IconButton(
                          tooltip: 'View chapter comments',
                          icon: Badge(
                            label: Text('$commentCount'),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                            ),
                          ),
                          color: secondaryTextColor,
                          onPressed: () => onOpenComments(index),
                        )
                      : null,
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

class _QuoteSharePayload {
  const _QuoteSharePayload({
    required this.quote,
    required this.bookTitle,
    required this.chapterTitle,
    required this.authors,
    required this.coverUrl,
  });

  final String quote;
  final String bookTitle;
  final String? chapterTitle;
  final String authors;
  final String? coverUrl;
}

class _QuoteImage extends StatelessWidget {
  const _QuoteImage({required this.payload});

  final _QuoteSharePayload payload;

  @override
  Widget build(BuildContext context) {
    final coverUrl = payload.coverUrl;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 420,
        height: 580,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl != null && coverUrl.isNotEmpty)
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Image.network(coverUrl, fit: BoxFit.cover),
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF33395F),
                      Color(0xFF61647E),
                      Color(0xFF284B63),
                    ],
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2F315B).withValues(alpha: 0.72),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white.withValues(alpha: 0.16),
                    size: 38,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        payload.quote,
                        maxLines: 20,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (coverUrl != null && coverUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            coverUrl,
                            width: 44,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payload.bookTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (payload.authors.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'by ${payload.authors}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'WREADOM\nwreadom.in',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterEndActions extends StatelessWidget {
  const _ChapterEndActions({
    required this.hasNextChapter,
    required this.hasComments,
    required this.onNextChapter,
    required this.onViewComments,
    required this.onShare,
  });

  final bool hasNextChapter;
  final bool hasComments;
  final VoidCallback? onNextChapter;
  final VoidCallback onViewComments;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (hasNextChapter) ...[
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.navigate_next_rounded),
                  label: const Text('Next Chapter'),
                  onPressed: onNextChapter,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(
                  hasComments
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.rate_review_outlined,
                ),
                label: Text(hasComments ? 'View Comments' : 'Write Review'),
                onPressed: onViewComments,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Chapter'),
            onPressed: onShare,
          ),
        ),
      ],
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
    this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData? icon;

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
                color: selected
                    ? Colors.blue
                    : Colors.grey.withValues(alpha: 0.5),
                width: selected ? 3 : 1,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.blue)
                : (icon != null
                      ? Icon(icon, color: textColor ?? Colors.grey)
                      : null),
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

class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar({
    required this.progress,
    required this.visible,
    required this.onSwipeUp,
    required this.onTap,
    required this.theme,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  final double progress;
  final bool visible;
  final VoidCallback onSwipeUp;
  final VoidCallback onTap;
  final ReaderTheme theme;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bgColor = theme == ReaderTheme.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final textColor = theme == ReaderTheme.dark
        ? Colors.white70
        : Colors.black54;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: visible ? 50 : 0,
      child: ClipRect(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -100) {
              onSwipeUp();
            }
          },
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: textColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 2,
                ),
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          hasPrevious
                              ? Icons.navigate_before_rounded
                              : Icons.close_rounded,
                        ),
                        onPressed: hasPrevious ? onPrevious : onClose,
                        color: textColor.withValues(alpha: 0.5),
                        tooltip: hasPrevious
                            ? 'Previous Chapter'
                            : 'Close Reader',
                      ),
                      const Spacer(),
                      GestureDetector(
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! < -100) {
                            onSwipeUp();
                          }
                        },
                        onTap: onTap,
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 24,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const Spacer(),
                      if (hasNext)
                        IconButton(
                          icon: const Icon(Icons.navigate_next_rounded),
                          onPressed: onNext,
                          color: textColor.withValues(alpha: 0.5),
                          tooltip: 'Next Chapter',
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
