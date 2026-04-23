import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/book.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/message.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/message_repository.dart';
import '../../utils/app_link_helper.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/message_providers.dart';
import '../providers/profile_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../widgets/comment_widgets.dart';
import '../widgets/follow_button.dart';
import '../widgets/report_dialog.dart';
import '../components/book/comment_reply_sheet.dart';
import '../components/generated_book_cover.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.preloadedBook,
    this.heroTag,
    this.initialReaderChapterIndex,
  });

  final String bookId;
  final Book? preloadedBook;
  final String? heroTag;
  final int? initialReaderChapterIndex;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  final Set<String> _preloadedBookIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final bookAsync = widget.preloadedBook != null
        ? AsyncValue.data(widget.preloadedBook)
        : ref.watch(bookDetailProvider(widget.bookId));

    return Scaffold(
      body: bookAsync.when(
        data: (book) {
          if (book == null) return const Center(child: Text('Book not found'));
          if (widget.initialReaderChapterIndex != null) {
            return _ReaderDeepLinkLauncher(
              book: book,
              initialChapterIndex: widget.initialReaderChapterIndex!,
            );
          }
          _preloadChapters(book.id);
          return _BookDetailBody(book: book, heroTag: widget.heroTag);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _preloadChapters(String bookId) {
    if (!_preloadedBookIds.add(bookId)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(bookChaptersProvider(bookId).future));
      unawaited(ref.read(offlineChaptersProvider(bookId).future));
    });
  }
}

class _ReaderDeepLinkLauncher extends ConsumerStatefulWidget {
  const _ReaderDeepLinkLauncher({
    required this.book,
    required this.initialChapterIndex,
  });

  final Book book;
  final int initialChapterIndex;

  @override
  ConsumerState<_ReaderDeepLinkLauncher> createState() =>
      _ReaderDeepLinkLauncherState();
}

class _ReaderDeepLinkLauncherState
    extends ConsumerState<_ReaderDeepLinkLauncher> {
  bool _hasLaunchedReader = false;

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(bookChaptersProvider(widget.book.id));

    return chaptersAsync.when(
      data: (chapters) {
        final maxIndex = chapters.isEmpty ? 0 : chapters.length - 1;
        final clampedIndex = widget.initialChapterIndex
            .clamp(0, maxIndex)
            .toInt();
        _launchReaderOnce(clampedIndex);
        return const Center(child: CircularProgressIndicator());
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) {
        final fallbackMax = (widget.book.chapters?.length ?? 0) - 1;
        final clampedIndex = widget.initialChapterIndex
            .clamp(0, fallbackMax < 0 ? 0 : fallbackMax)
            .toInt();
        _launchReaderOnce(clampedIndex);
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _launchReaderOnce(int initialChapterIndex) {
    if (_hasLaunchedReader) return;
    _hasLaunchedReader = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.reader,
        arguments: ReaderArguments(
          book: widget.book,
          initialChapterIndex: initialChapterIndex,
        ),
      );
    });
  }
}

class _BookDetailBody extends ConsumerWidget {
  const _BookDetailBody({required this.book, this.heroTag});

  final Book book;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authors = book.authors
        .map((a) => a.name)
        .where((n) => n.isNotEmpty)
        .join(', ');
    final userAsync = ref.watch(currentUserProvider);
    final currentUser = userAsync.asData?.value;
    final authorId = (book.isOriginal ?? false) ? book.authorId?.trim() : null;
    final authorAsync = authorId == null || authorId.isEmpty
        ? null
        : ref.watch(publicProfileProvider(authorId));
    final canEdit =
        currentUser != null &&
        (book.isOriginal ?? false) &&
        authorId == currentUser.id;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 330,
          pinned: true,
          actions: [
            if (canEdit)
              IconButton(
                tooltip: 'Edit book',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.writerPad,
                  arguments: WriterPadArguments(book: book),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Share.share(
                'Read "${book.title}" on Wreadom: ${AppLinkHelper.book(book.id)}',
                subject: book.title,
              ),
            ),
            if (!canEdit)
              IconButton(
                tooltip: 'Report book',
                icon: const Icon(Icons.report_problem_outlined),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) =>
                      ReportDialog(targetId: book.id, targetType: 'book'),
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                        theme.colorScheme.surface,
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: heroTag == null
                        ? _DetailCover(book: book)
                        : Hero(
                            tag: heroTag!,
                            child: _DetailCover(book: book),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                book.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _AuthorLine(
                authors: authors.isNotEmpty ? authors : 'Unknown Author',
                authorAsync: authorAsync,
                authorId: authorId,
              ),
              const SizedBox(height: 16),
              _StatsRow(book: book),
              if (book.subjects.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: book.subjects.take(5).map((subject) {
                    return ActionChip(
                      label: Text(
                        subject,
                        style: const TextStyle(fontSize: 12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      side: BorderSide.none,
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.discovery,
                        arguments: {'query': 'topic:$subject'},
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(
                        _hasProgress(userAsync, book.id)
                            ? 'Continue Reading'
                            : 'Start Reading',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _openReader(context, ref, userAsync),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SaveDownloadButton(book: book),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showSendToChatSheet(context, ref, book),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if ((book.description ?? '').isNotEmpty) ...[
                Text(
                  'About this Book',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _ExpandableText(text: book.description!),
              ],
              const SizedBox(height: 28),
              _LatestDiscussionSection(book: book),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  static bool _hasProgress(AsyncValue<dynamic> userAsync, String bookId) {
    return userAsync.maybeWhen(
      data: (u) => _progressForBook(u?.readingProgress, bookId) != null,
      orElse: () => false,
    );
  }

  static Map<String, dynamic>? _progressForBook(
    Map<String, dynamic>? readingProgress,
    String bookId,
  ) {
    final rawProgress = readingProgress?[bookId];
    if (rawProgress is Map<String, dynamic>) return rawProgress;
    if (rawProgress is Map) return Map<String, dynamic>.from(rawProgress);
    return null;
  }

  Future<void> _openReader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> userAsync,
  ) async {
    final progress = userAsync.maybeWhen<Map<String, dynamic>?>(
      data: (u) => _progressForBook(u?.readingProgress, book.id),
      orElse: () => null,
    );
    var startChapter = 0;
    startChapter = (progress?['chapterIndex'] as num?)?.toInt() ?? 0;
    await Navigator.of(context).pushNamed(
      AppRoutes.reader,
      arguments: ReaderArguments(book: book, initialChapterIndex: startChapter),
    );
    ref.invalidate(currentUserProvider);
  }

  Future<void> _showSendToChatSheet(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final authors = book.authors
        .map((author) => author.name)
        .where((name) => name.isNotEmpty)
        .join(', ');
    final rootContext = context;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final conversationsAsync = ref.watch(conversationsProvider);
            final currentUser = ref.watch(currentUserProvider).asData?.value;

            return SafeArea(
              child: conversationsAsync.when(
                data: (conversations) {
                  if (conversations.isEmpty || currentUser == null) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No recent conversations yet.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final otherId = conversation.participants.firstWhere(
                        (id) => id != currentUser.id,
                        orElse: () => conversation.participants.first,
                      );
                      final other = conversation.participantDetails[otherId];
                      final title =
                          conversation.name ??
                          other?.displayName ??
                          other?.username ??
                          'Conversation';
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(title.characters.first.toUpperCase()),
                        ),
                        title: Text(title),
                        subtitle: Text(
                          conversation.lastMessage?.text ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          final sender = await ref.read(
                            currentUserProvider.future,
                          );
                          if (sender == null) return;
                          try {
                            await ref
                                .read(messageRepositoryProvider)
                                .sendStoryMessage(
                                  conversationId: conversation.id,
                                  sender: sender,
                                  storyData: MessageStoryData(
                                    id: book.id,
                                    title: book.title,
                                    coverUrl: book.coverUrl,
                                    authorNames: authors.isEmpty
                                        ? 'Unknown Author'
                                        : authors,
                                  ),
                                );
                          } on MessageLimitException catch (error) {
                            if (!rootContext.mounted) return;
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                            return;
                          }
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                          if (!rootContext.mounted) return;
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(content: Text('Sent "${book.title}".')),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('Failed to load chats: $error')),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({
    required this.authors,
    required this.authorAsync,
    required this.authorId,
  });

  final String authors;
  final AsyncValue<UserModel?>? authorAsync;
  final String? authorId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authorAsync?.asData?.value;
    final targetUserId = authorId?.trim();
    final canOpenProfile = targetUserId != null && targetUserId.isNotEmpty;
    final displayName = _displayName(user, authors);
    final authorContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (user?.photoURL != null && user!.photoURL!.isNotEmpty) ...[
          CircleAvatar(
            radius: 12,
            backgroundImage: CachedNetworkImageProvider(user.photoURL!),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: canOpenProfile
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: canOpenProfile ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );

    return Row(
      children: [
        Expanded(
          child: canOpenProfile
              ? InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.publicProfile,
                    arguments: PublicProfileArguments(userId: targetUserId),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: authorContent,
                  ),
                )
              : authorContent,
        ),
        if (canOpenProfile) ...[
          const SizedBox(width: 8),
          FollowButton(targetUserId: targetUserId, compact: true),
        ],
      ],
    );
  }

  static String _displayName(UserModel? user, String fallback) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final penName = user?.penName?.trim();
    if (penName != null && penName.isNotEmpty) {
      return penName;
    }

    final username = user?.username.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }

    return fallback;
  }
}

class _LatestDiscussionSection extends ConsumerStatefulWidget {
  const _LatestDiscussionSection({required this.book});

  final Book book;

  @override
  ConsumerState<_LatestDiscussionSection> createState() =>
      _LatestDiscussionSectionState();
}

class _LatestDiscussionSectionState
    extends ConsumerState<_LatestDiscussionSection> {
  int _visibleCount = 5;

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(bookCommentsProvider(widget.book.id));
    final theme = Theme.of(context);

    return commentsAsync.when(
      data: (comments) {
        if (comments.isEmpty) return const SizedBox.shrink();
        final visible = comments.take(_visibleCount).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest discussion',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final comment in visible)
              CommentTile(
                comment: comment,
                bookId: widget.book.id,
                bookAuthorId: widget.book.authorId,
                onReply: () => _showReplySheet(comment),
              ),
            if (_visibleCount < comments.length)
              TextButton.icon(
                onPressed: () => setState(() => _visibleCount += 5),
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Show more'),
              ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _showReplySheet(Comment comment) async {
    if (comment.id == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          CommentReplySheet(comment: comment, bookId: widget.book.id),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = Colors.grey[600];
    final commentsAsync = ref.watch(bookCommentsProvider(book.id));
    final rating = commentsAsync.maybeWhen(
      data: (comments) => _ratingSummary(book, comments),
      orElse: () => _ratingSummary(book, const <Comment>[]),
    );
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _RatingStat(summary: rating),
        _Stat(
          icon: Icons.visibility_outlined,
          label: '${_formatCount(book.viewCount ?? 0)} reads',
          color: textColor,
        ),
        if (book.chapterCount != null || (book.chapters?.isNotEmpty ?? false))
          _Stat(
            icon: Icons.menu_book_outlined,
            label: '${book.chapterCount ?? book.chapters!.length} chapters',
            color: textColor,
          ),
      ],
    );
  }

  _RatingSummary _ratingSummary(Book book, List<Comment> comments) {
    final ratings = <double>[
      if (book.averageRating != null && book.averageRating! > 0)
        book.averageRating!,
      ...comments
          .where((comment) => comment.rating != null && comment.rating! > 0)
          .map((comment) => comment.rating!.toDouble()),
    ];
    if (ratings.isEmpty) return const _RatingSummary.none();
    final average =
        ratings.reduce((sum, rating) => sum + rating) / ratings.length;
    final storedCount = book.ratingsCount ?? 0;
    final count = storedCount > ratings.length ? storedCount : ratings.length;
    return _RatingSummary(average: average, count: count);
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _RatingSummary {
  const _RatingSummary({required this.average, required this.count});
  const _RatingSummary.none() : average = null, count = 0;

  final double? average;
  final int count;
}

class _RatingStat extends StatelessWidget {
  const _RatingStat({required this.summary});

  final _RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final average = summary.average;
    if (average == null) {
      return _Stat(
        icon: Icons.star_border_rounded,
        label: 'No ratings',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }

    final countLabel = summary.count > 0 ? ' (${summary.count})' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < average.round()
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: 16,
            color: Colors.amber,
          );
        }),
        const SizedBox(width: 4),
        Text(
          '${average.toStringAsFixed(1)}$countLabel',
          style: const TextStyle(color: Colors.amber, fontSize: 13),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return GeneratedBookCover(
      width: 150,
      height: 220,
      title: book.title,
      author: book.authors.isNotEmpty ? book.authors.first.name : null,
      seed: book.id,
      borderRadius: 12,
    );
  }
}

class _DetailCover extends StatelessWidget {
  const _DetailCover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: book.coverUrl != null
          ? CachedNetworkImage(
              imageUrl: book.coverUrl!,
              height: 220,
              width: 150,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                height: 220,
                width: 150,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, _, _) => _PlaceholderCover(book: book),
            )
          : _PlaceholderCover(book: book),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Show less' : 'Read more'),
        ),
      ],
    );
  }
}

class _SaveDownloadButton extends ConsumerStatefulWidget {
  const _SaveDownloadButton({required this.book});

  final Book book;

  @override
  ConsumerState<_SaveDownloadButton> createState() =>
      _SaveDownloadButtonState();
}

class _SaveDownloadButtonState extends ConsumerState<_SaveDownloadButton> {
  bool _isDownloading = false;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final downloaded = await ref
        .read(offlineServiceProvider)
        .isBookDownloaded(widget.book.id);
    if (mounted) setState(() => _isDownloaded = downloaded);
  }

  Future<void> _handleSaveDownload() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    if (!mounted) return;

    final idStr = widget.book.id.toString();
    final savedBooks = List<dynamic>.from(user.savedBooks);
    final isSaved = savedBooks.any((id) => id?.toString() == idStr);

    if (isSaved && _isDownloaded) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove saved book?'),
          content: const Text(
            'The offline download will stay available unless you remove it separately.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unsave', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        savedBooks.removeWhere((id) => id?.toString() == idStr);
        await ref
            .read(authRepositoryProvider)
            .updateUserSavedBooks(user.id, savedBooks);
        ref.invalidate(currentUserProvider);
        ref.invalidate(savedBooksProvider);
      }
      return;
    }

    setState(() => _isDownloading = true);
    try {
      if (!isSaved) {
        savedBooks.add(widget.book.id);
        await ref
            .read(authRepositoryProvider)
            .updateUserSavedBooks(user.id, savedBooks);
      }
      final chapters = await ref.read(
        bookChaptersProvider(widget.book.id).future,
      );
      await ref
          .read(offlineServiceProvider)
          .downloadBook(widget.book, chapters);

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
        ref.invalidate(currentUserProvider);
        ref.invalidate(savedBooksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book saved and downloaded for offline reading.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: _isDownloaded
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      onPressed: _isDownloading ? null : _handleSaveDownload,
      child: _isDownloading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isDownloaded
                  ? Icons.bookmark_added_rounded
                  : Icons.bookmark_add_outlined,
              color: _isDownloaded
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
    );
  }
}
