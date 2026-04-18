import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/feed_post.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/feed_providers.dart';
import '../widgets/comment_widgets.dart';
import '../../domain/repositories/book_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/app_link_helper.dart';

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
  ReaderTheme _readerTheme = ReaderTheme.dark;
  ReaderFont _readerFont = ReaderFont.serif;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  Comment? _replyingTo;
  int _chapterRating = 0;
  String? _selectedQuote;
  String _selectedText = "";
  late BookRepository _bookRepository;
  String? _currentUserId;
  double _scrollProgress = 0.0;
  double _lastScrollOffset = 0.0;
  bool _showReaderChrome = true;
  bool _isDiscussionOpen = false;
  Timer? _progressSaveDebounce;

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.initialChapterIndex;
    _bookRepository = ref.read(bookRepositoryProvider);
    _loadReaderSettings();
    _incrementView();
    _saveHistory();
    _restoreScrollPosition();
    _scrollController.addListener(_onScroll);
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
      final hasScrollableContent = position.maxScrollExtent > 0;
      final progress = hasScrollableContent
          ? currentOffset / position.maxScrollExtent
          : 0.0;
      if ((progress - _scrollProgress).abs() > 0.01 ||
          shouldShowChrome != _showReaderChrome ||
          (currentOffset - _lastScrollOffset).abs() > 0.5) {
        setState(() {
          _scrollProgress = progress.clamp(0.0, 1.0);
          _showReaderChrome = shouldShowChrome;
          _lastScrollOffset = currentOffset;
        });
        _scheduleProgressSave();
      }
    }
  }

  Future<void> _incrementView() async {
    try {
      await _bookRepository.incrementViewCount(widget.book.id);
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> _loadReaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
      final themeIndex = prefs.getInt('reader_theme_index');
      if (themeIndex != null) {
        _readerTheme = ReaderTheme.values[themeIndex];
      }
      final fontIndex = prefs.getInt('reader_font_index');
      if (fontIndex != null) {
        _readerFont = ReaderFont.values[fontIndex];
      }
    });
  }

  Future<void> _saveReaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_font_size', _fontSize);
    await prefs.setInt('reader_theme_index', _readerTheme.index);
    await prefs.setInt('reader_font_index', _readerFont.index);
  }

  Future<void> _restoreScrollPosition() async {
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
      _currentUserId = user.id;
      await _bookRepository.updateReadingHistory(
        user.id,
        widget.book.id.toString(),
      );
      await _saveProgressForUser(user.id);
    }
  }

  Future<void> _saveProgress() async {
    final user = ref.read(currentUserProvider).value;
    final userId = user?.id ?? _currentUserId;

    if (userId != null) await _saveProgressForUser(userId);
  }

  Future<void> _saveProgressForUser(String userId) async {
    _currentUserId = userId;
    double position = 0.0;
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      position =
          _scrollController.offset / _scrollController.position.maxScrollExtent;
    }

    await _bookRepository.updateReadingProgress(
      userId,
      widget.book.id.toString(),
      chapterIndex: _chapterIndex,
      position: position,
    );
    if (mounted) ref.invalidate(currentUserProvider);
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
    _goToChapter(currentChapterIndex + 1);
  }

  void _scheduleProgressSave() {
    if (_currentUserId == null) return;
    _progressSaveDebounce?.cancel();
    _progressSaveDebounce = Timer(const Duration(seconds: 2), () {
      final userId = _currentUserId;
      if (userId != null) unawaited(_saveProgressForUser(userId));
    });
  }

  void _goToChapter(int index) {
    setState(() {
      _chapterIndex = index;
      _scrollProgress = 0.0;
      _lastScrollOffset = 0.0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    _saveProgress();
  }

  @override
  void dispose() {
    _progressSaveDebounce?.cancel();
    final userId = _currentUserId;
    if (userId != null) unawaited(_saveProgressForUser(userId));
    _scrollController.removeListener(_onScroll);
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(bookChaptersProvider(widget.book.id));
    final commentsAsync = ref.watch(bookCommentsProvider(widget.book.id));
    final userAsync = ref.watch(currentUserProvider);
    final offline = ref.watch(offlineServiceProvider);

    // Keep current user ID updated
    ref.listen(currentUserProvider, (previous, next) {
      if (next.value != null) {
        _currentUserId = next.value!.id;
      }
    });

    return FutureBuilder<List<Chapter>>(
      future: offline.getDownloadedChapters(widget.book.id.toString()),
      builder: (context, snapshot) {
        final offlineChapters = snapshot.data;

        // If we have offline chapters, use them immediately
        if (offlineChapters != null && offlineChapters.isNotEmpty) {
          return _buildReader(
            context,
            offlineChapters,
            commentsAsync,
            userAsync,
            isOffline: true,
          );
        }

        // Otherwise, fallback to network provider
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
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Failed to load book content: $err')),
          ),
        );
      },
    );
  }

  Widget _buildReader(
    BuildContext context,
    List<Chapter> chapters,
    AsyncValue<List<Comment>> commentsAsync,
    AsyncValue<dynamic> userAsync, {
    required bool isOffline,
  }) {
    final chapter = chapters.isEmpty
        ? null
        : chapters[_chapterIndex.clamp(0, chapters.length - 1)];
    final completedChapterIndexes = _completedChapterIndexes(userAsync);
    final commentCounts = commentsAsync.maybeWhen(
      data: (comments) => _commentCountsByChapter(chapters, comments),
      orElse: () => const <int, int>{},
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_showReaderChrome ? kToolbarHeight : 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: _showReaderChrome ? kToolbarHeight : 0,
          child: ClipRect(
            child: AppBar(
              title: Text(
                widget.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        onSelect: (index) {
          _goToChapter(index);
          Navigator.of(context).pop();
        },
        onOpenComments: (index) {
          Navigator.of(context).pop();
          _showDiscussion(chapters[index], chapterIndex: index);
        },
      ),
      body: Container(
        color: _getBackgroundColor(),
        child: Column(
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
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      chapter?.title ?? widget.book.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SelectionArea(
                      onSelectionChanged: (content) {
                        setState(() {
                          _selectedText = content?.plainText ?? "";
                        });
                      },
                      contextMenuBuilder: (context, selectableRegionState) {
                        final selected = _selectedText.trim();
                        final buttonItems = <ContextMenuButtonItem>[
                          ContextMenuButtonItem(
                            label: 'Quote & Comment',
                            onPressed: selected.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      _selectedQuote = selected;
                                      _replyingTo = null;
                                    });
                                    selectableRegionState.hideToolbar();
                                    _scrollController.animateTo(
                                      _scrollController
                                          .position
                                          .maxScrollExtent,
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  },
                          ),
                          ContextMenuButtonItem(
                            label: 'Share Quote',
                            onPressed: selected.isEmpty
                                ? null
                                : () {
                                    selectableRegionState.hideToolbar();
                                    _shareSelectedQuote(chapter, selected);
                                  },
                          ),
                        ];
                        return AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: selectableRegionState.contextMenuAnchors,
                          buttonItems: buttonItems,
                        );
                      },
                      child: HtmlWidget(
                        chapter?.content ??
                            widget.book.description ??
                            'No readable content available yet.',
                        textStyle: TextStyle(
                          fontSize: _fontSize,
                          height: 1.8,
                          color: _getTextColor(),
                          fontFamily: _readerFont == ReaderFont.serif
                              ? 'Serif'
                              : null,
                        ),
                        // Custom styles for images and links if needed
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ChapterEndActions(
                      hasNextChapter: _chapterIndex < chapters.length - 1,
                      onNextChapter: _chapterIndex < chapters.length - 1
                          ? _markChapterCompleteAndGoNext
                          : null,
                      onViewComments: () => _showDiscussion(chapter),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
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
        theme: _readerTheme,
      ),
    );
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

  Future<void> _shareSelectedQuote(dynamic chapter, String selected) async {
    final authors = widget.book.authors
        .map((a) => a.name)
        .where((n) => n.isNotEmpty)
        .join(', ');
    final chapterTitle = chapter?.title?.toString();
    final parts = [
      '"$selected"',
      '',
      'From ${widget.book.title}${chapterTitle != null && chapterTitle.isNotEmpty ? ', $chapterTitle' : ''}',
      if (authors.isNotEmpty) 'by $authors',
      AppLinkHelper.book(widget.book.id),
    ];
    await Share.share(
      parts.join('\n'),
      subject: 'Quote from ${widget.book.title}',
    );
  }

  Future<void> _submitComment(dynamic chapter, {int? chapterIndex}) async {
    final text = _commentController.text.trim();
    final user = await ref.read(currentUserProvider.future);
    if (text.isEmpty || user == null) return;

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
      final comment = Comment(
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        userId: user.id,
        username: user.username,
        displayName: user.displayName,
        penName: user.penName,
        text: text,
        rating: _chapterRating > 0 ? _chapterRating : null,
        quote: _selectedQuote,
        chapterTitle: chapter?.title,
        chapterIndex: chapterIndex ?? _chapterIndex,
        chapterId: chapter?.id?.toString(),
        timestamp: now,
        userPhotoURL: user.photoURL,
      );

      await ref.read(commentRepositoryProvider).addComment(comment);

      // If it's a review (has rating), also cross-post to feed
      if (_chapterRating > 0) {
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
        _chapterRating = 0;
      });
    }
    _commentController.clear();
    ref.invalidate(bookCommentsProvider(widget.book.id));
  }

  void _showDiscussion(dynamic chapter, {int? chapterIndex}) {
    if (_isDiscussionOpen) {
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
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _getSecondaryTextColor().withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          () => _chapterRating =
                                              (_chapterRating == index + 1)
                                              ? 0
                                              : index + 1,
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
                              controller: _commentController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: _replyingTo != null
                                    ? 'Add a reply...'
                                    : 'Add a comment about this chapter',
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
                                                color: _getSecondaryTextColor()
                                                    .withValues(alpha: 0.3),
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
    ).whenComplete(() {
      _isDiscussionOpen = false;
      _commentFocusNode.unfocus();
    });
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
                  onChangeEnd: (value) => _saveReaderSettings(),
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
                    _saveReaderSettings();
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
                      label: 'Light',
                      color: Colors.white,
                      selected: _readerTheme == ReaderTheme.light,
                      onTap: () {
                        setState(() => _readerTheme = ReaderTheme.light);
                        _saveReaderSettings();
                        setModalState(() {});
                      },
                    ),
                    _ThemeOption(
                      label: 'Sepia',
                      color: const Color(0xFFF4ECD8),
                      selected: _readerTheme == ReaderTheme.sepia,
                      onTap: () {
                        setState(() => _readerTheme = ReaderTheme.sepia);
                        _saveReaderSettings();
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
                        _saveReaderSettings();
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

  Color _getSecondaryTextColor() {
    switch (_readerTheme) {
      case ReaderTheme.light:
      case ReaderTheme.sepia:
        return const Color(0xFF5F5447);
      case ReaderTheme.dark:
        return const Color(0xFFB8B8B8);
    }
  }

  Color _getInputFillColor() {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return const Color(0xFFF4F4F4);
      case ReaderTheme.sepia:
        return const Color(0xFFE9DCC0);
      case ReaderTheme.dark:
        return const Color(0xFF1F1F1F);
    }
  }
}

class _ChapterDrawer extends StatelessWidget {
  final List<Chapter> chapters;
  final int currentIndex;
  final Set<int> completedChapterIndexes;
  final Map<int, int> commentCounts;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onOpenComments;

  const _ChapterDrawer({
    required this.chapters,
    required this.currentIndex,
    required this.completedChapterIndexes,
    required this.commentCounts,
    required this.onSelect,
    required this.onOpenComments,
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
                final isComplete = completedChapterIndexes.contains(index);
                final commentCount = commentCounts[index] ?? 0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isComplete
                        ? Colors.green
                        : isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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

class _ChapterEndActions extends StatelessWidget {
  const _ChapterEndActions({
    required this.hasNextChapter,
    required this.onNextChapter,
    required this.onViewComments,
  });

  final bool hasNextChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback onViewComments;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('View Comments'),
            onPressed: onViewComments,
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

class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar({
    required this.progress,
    required this.visible,
    required this.onSwipeUp,
    required this.onTap,
    required this.theme,
  });

  final double progress;
  final bool visible;
  final VoidCallback onSwipeUp;
  final VoidCallback onTap;
  final ReaderTheme theme;

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
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 24,
                      color: textColor.withValues(alpha: 0.5),
                    ),
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
