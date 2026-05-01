import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/book.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/feed_post.dart';
import '../../domain/models/message.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/message_repository.dart';
import '../../utils/app_link_helper.dart';
import '../../utils/book_collaboration_utils.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/feed_providers.dart';
import '../providers/homepage_providers.dart';
import '../providers/message_providers.dart';
import '../providers/profile_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../utils/book_author_utils.dart';
import '../utils/swipe_hint.dart';
import '../widgets/comment_widgets.dart';
import '../widgets/follow_button.dart';
import '../widgets/report_dialog.dart';
import '../components/book/comment_reply_sheet.dart';
import '../components/generated_book_cover.dart';
import 'static_info_screen.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.preloadedBook,
    this.heroTag,
    this.initialReaderChapterIndex,
    this.targetCommentId,
    this.targetReplyId,
  });

  final String bookId;
  final Book? preloadedBook;
  final String? heroTag;
  final int? initialReaderChapterIndex;
  final String? targetCommentId;
  final String? targetReplyId;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  final Set<String> _preloadedBookIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showSwipeHintOnce(
        context: context,
        key: 'swipe_hint_seen_book_comments_v1',
        message: l10n.swipeHintBookComments,
        actionLabel: l10n.gotIt,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = widget.preloadedBook != null
        ? AsyncValue.data(widget.preloadedBook)
        : ref.watch(bookDetailProvider(widget.bookId));

    return Scaffold(
      body: bookAsync.when(
        data: (book) {
          if (book == null) {
            return StaticInfoScreen(
              title: 'Content Not Found',
              body:
                  'This book may have been deleted or is no longer available.',
              actionLabel: AppLocalizations.of(context)!.searchBooks,
              onAction: () => Navigator.of(context).pushNamed(
                AppRoutes.discovery,
                arguments: {'query': widget.bookId},
              ),
            );
          }
          if (widget.initialReaderChapterIndex != null) {
            return _ReaderDeepLinkLauncher(
              book: book,
              initialChapterIndex: widget.initialReaderChapterIndex!,
            );
          }
          _preloadChapters(book.id);
          return _BookDetailBody(
            book: book,
            heroTag: widget.heroTag,
            targetCommentId: widget.targetCommentId,
            targetReplyId: widget.targetReplyId,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            '${AppLocalizations.of(context)!.somethingWentWrong}: $err',
          ),
        ),
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

bool _isArchiveBook(Book book) {
  return book.source == 'archive' ||
      (book.source == null &&
          !(book.id.length == 20 &&
              RegExp(r'^[a-zA-Z0-9]{20}$').hasMatch(book.id)));
}

bool _hasArchivePdfViewer(Book book) {
  return _isArchiveBook(book) && (book.identifier?.trim().isNotEmpty == true);
}

void _openArchivePdf(BuildContext context, Book book) {
  Navigator.of(context).pushNamed(AppRoutes.archiveReader, arguments: book);
}

class _BookDetailBody extends ConsumerWidget {
  const _BookDetailBody({
    required this.book,
    this.heroTag,
    this.targetCommentId,
    this.targetReplyId,
  });

  final Book book;
  final String? heroTag;
  final String? targetCommentId;
  final String? targetReplyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final currentUser = userAsync.asData?.value;
    final authorId = (book.isOriginal ?? false) ? book.authorId?.trim() : null;
    final authorAsync = authorId == null || authorId.isEmpty
        ? null
        : ref.watch(publicProfileProvider(authorId));
    final collaboratorId = isAcceptedCollaboration(book)
        ? book.collaboratorId?.trim()
        : null;
    final collaboratorAsync = collaboratorId == null || collaboratorId.isEmpty
        ? null
        : ref.watch(publicProfileProvider(collaboratorId));
    final canEdit =
        currentUser != null &&
        (book.isOriginal ?? false) &&
        canEditCollaborativeBook(book, currentUser.id);

    Future<void> refresh() async {
      ref.invalidate(bookDetailProvider(book.id));
      ref.invalidate(bookChaptersProvider(book.id));
      ref.invalidate(bookCommentsProvider(book.id));
      ref.invalidate(currentUserProvider);
      await Future.wait([
        ref.read(bookDetailProvider(book.id).future).catchError((_) => null),
        ref
            .read(bookChaptersProvider(book.id).future)
            .catchError((_) => <Chapter>[]),
        ref
            .read(bookCommentsProvider(book.id).future)
            .catchError((_) => <Comment>[]),
      ]);
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            actions: [
              if (canEdit)
                IconButton(
                  tooltip: AppLocalizations.of(context)!.editBook,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.writerPad,
                    arguments: WriterPadArguments(book: book),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => Share.share(
                  AppLocalizations.of(
                    context,
                  )!.shareBookMessage(book.title, AppLinkHelper.book(book.id)),
                  subject: book.title,
                ),
              ),
              if (!canEdit)
                IconButton(
                  tooltip: AppLocalizations.of(context)!.reportBook,
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
                  book: book,
                  fallback: AppLocalizations.of(context)!.unknownAuthor,
                  authorAsync: authorAsync,
                  authorId: authorId,
                  collaboratorAsync: collaboratorAsync,
                  collaboratorId: collaboratorId,
                ),
                if (isAcceptedCollaboration(book)) ...[
                  const SizedBox(height: 10),
                  const _CollabChip(),
                ],
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
                              ? AppLocalizations.of(context)!.continueReading
                              : AppLocalizations.of(context)!.startReading,
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
                if (_hasArchivePdfViewer(book)) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _openArchivePdf(context, book),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(AppLocalizations.of(context)!.viewPdf),
                  ),
                ],
                const SizedBox(height: 28),
                if ((book.description ?? '').isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.aboutThisBook,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ExpandableText(text: book.description!),
                ],
                const SizedBox(height: 28),
                _LatestDiscussionSection(
                  book: book,
                  targetCommentId: targetCommentId,
                  targetReplyId: targetReplyId,
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
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
    final l10n = AppLocalizations.of(context)!;
    final feedMessageController = TextEditingController(
      text: l10n.defaultShareMessage(book.title),
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final conversationsAsync = ref.watch(conversationsProvider);
            final currentUser = ref.watch(currentUserProvider).asData?.value;

            Future<void> shareToFeed() async {
              final sender = await ref.read(currentUserProvider.future);
              if (sender == null) return;
              final text = feedMessageController.text.trim();
              if (text.isEmpty) return;
              await ref
                  .read(feedRepositoryProvider)
                  .createFeedPost(
                    FeedPost(
                      userId: sender.id,
                      username: sender.username,
                      displayName: sender.displayName,
                      penName: sender.penName,
                      userPhotoURL: sender.photoURL,
                      type: 'post',
                      text: text,
                      bookId: book.id,
                      bookTitle: book.title,
                      bookAuthorName: bookAuthorName(book),
                      bookCover: book.coverUrl,
                      timestamp: DateTime.now().millisecondsSinceEpoch,
                      likes: const [],
                      visibility: 'public',
                      privacy: 'public',
                    ),
                  );
              ref.invalidate(feedPostsProvider);
              ref.invalidate(filteredFeedPostsProvider(FeedFilter.public));
              ref.invalidate(filteredFeedPostsProvider(FeedFilter.mine));
              ref.invalidate(pagedFeedPostsProvider(FeedFilter.public));
              ref.invalidate(pagedFeedPostsProvider(FeedFilter.mine));
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (!rootContext.mounted) return;
              ScaffoldMessenger.of(
                rootContext,
              ).showSnackBar(SnackBar(content: Text(l10n.sharedToFeed)));
            }

            return SafeArea(
              child: conversationsAsync.when(
                data: (conversations) {
                  if (currentUser == null) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l10n.signInToShare)),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: conversations.isEmpty
                        ? 3
                        : conversations.length + 2,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: feedMessageController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: l10n.shareToFeed,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: shareToFeed,
                                icon: const Icon(Icons.dynamic_feed_outlined),
                                label: Text(l10n.shareToFeed),
                              ),
                            ],
                          ),
                        );
                      }
                      if (index == 1) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: Text(
                            l10n.sendToChat,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        );
                      }
                      if (conversations.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                          child: Text(l10n.noRecentConversations),
                        );
                      }
                      final conversation = conversations[index - 2];
                      final otherId = conversation.participants.firstWhere(
                        (id) => id != currentUser.id,
                        orElse: () => conversation.participants.first,
                      );
                      final other = conversation.participantDetails[otherId];
                      final title =
                          conversation.name ??
                          other?.displayName ??
                          other?.username ??
                          l10n.conversation;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(title.characters.first.toUpperCase()),
                        ),
                        title: Text(title),
                        subtitle: Text(
                          conversation.lastMessage?.text ?? l10n.noMessagesYet,
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
                                        ? l10n.unknownAuthor
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
                            SnackBar(
                              content: Text(l10n.sentBookSnack(book.title)),
                            ),
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
                  child: Center(
                    child: Text(l10n.failedToLoadChats(error.toString())),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    feedMessageController.dispose();
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({
    required this.book,
    required this.fallback,
    required this.authorAsync,
    required this.authorId,
    required this.collaboratorAsync,
    required this.collaboratorId,
  });

  final Book book;
  final String fallback;
  final AsyncValue<UserModel?>? authorAsync;
  final String? authorId;
  final AsyncValue<UserModel?>? collaboratorAsync;
  final String? collaboratorId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryUser = authorAsync?.asData?.value;
    final collaboratorUser = collaboratorAsync?.asData?.value;
    final primaryName = primaryAuthorDisplayName(book, primaryUser);
    final coAuthorName = collaboratorDisplayName(book, collaboratorUser);

    if (!isAcceptedCollaboration(book)) {
      return Row(
        children: [
          Expanded(
            child: _AuthorPill(
              userId: authorId,
              user: primaryUser,
              label: primaryName.isEmpty ? fallback : primaryName,
            ),
          ),
          if (authorId?.trim().isNotEmpty == true) ...[
            const SizedBox(width: 8),
            FollowButton(targetUserId: authorId!.trim(), compact: true),
          ],
        ],
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        _AuthorPill(
          userId: authorId,
          user: primaryUser,
          label: primaryName.isEmpty ? fallback : primaryName,
        ),
        Tooltip(
          message: AppLocalizations.of(context)!.collaboration,
          child: Icon(
            Icons.handshake_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        _AuthorPill(
          userId: collaboratorId,
          user: collaboratorUser,
          label: coAuthorName.isEmpty ? fallback : coAuthorName,
        ),
      ],
    );
  }
}

class _AuthorPill extends StatelessWidget {
  const _AuthorPill({
    required this.userId,
    required this.user,
    required this.label,
  });

  final String? userId;
  final UserModel? user;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetUserId = userId?.trim();
    final canOpenProfile = targetUserId != null && targetUserId.isNotEmpty;
    final photoURL = user?.photoURL?.trim();
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (photoURL != null && photoURL.isNotEmpty) ...[
          CircleAvatar(
            radius: 12,
            backgroundImage: CachedNetworkImageProvider(photoURL),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
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

    if (!canOpenProfile) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.publicProfile,
        arguments: PublicProfileArguments(userId: targetUserId),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: content,
      ),
    );
  }
}

class _CollabChip extends StatelessWidget {
  const _CollabChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: const Icon(Icons.group_outlined, size: 16),
      label: const Text('Collab'),
      visualDensity: VisualDensity.compact,
      backgroundColor: scheme.secondaryContainer.withValues(alpha: 0.7),
      labelStyle: TextStyle(
        color: scheme.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: scheme.outlineVariant),
    );
  }
}

class _LatestDiscussionSection extends ConsumerStatefulWidget {
  const _LatestDiscussionSection({
    required this.book,
    this.targetCommentId,
    this.targetReplyId,
  });

  final Book book;
  final String? targetCommentId;
  final String? targetReplyId;

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
        final targetComment = _targetComment(comments);
        final visible =
            (targetComment == null
                    ? comments
                    : comments
                          .where((comment) => comment.id != targetComment.id)
                          .toList())
                .take(_visibleCount)
                .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.latestDiscussion,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (targetComment != null) ...[
              _BookTargetCommentHeader(
                label: AppLocalizations.of(context)!.fromNotifications,
              ),
              CommentTile(
                key: ValueKey(
                  'book-target-comment-${targetComment.id ?? targetComment.timestamp}',
                ),
                comment: targetComment,
                bookId: widget.book.id,
                bookAuthorId: widget.book.authorId,
                onReply: () => _showReplySheet(targetComment),
                isTargetComment: true,
                targetReplyId: widget.targetReplyId,
              ),
              const SizedBox(height: 8),
            ],
            for (final comment in visible)
              CommentTile(
                key: ValueKey(
                  'book-comment-${comment.id ?? comment.timestamp}',
                ),
                comment: comment,
                bookId: widget.book.id,
                bookAuthorId: widget.book.authorId,
                onReply: () => _showReplySheet(comment),
              ),
            if (_visibleCount < comments.length)
              TextButton.icon(
                onPressed: () => setState(() => _visibleCount += 5),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(AppLocalizations.of(context)!.showMore),
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

  Comment? _targetComment(List<Comment> comments) {
    final targetId = widget.targetCommentId?.trim();
    if (targetId == null || targetId.isEmpty) return null;
    for (final comment in comments) {
      if (comment.id == targetId) return comment;
    }
    return null;
  }
}

class _BookTargetCommentHeader extends StatelessWidget {
  const _BookTargetCommentHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveVoteButton extends StatelessWidget {
  const _ArchiveVoteButton({
    required this.icon,
    required this.selectedIcon,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final IconData selectedIcon;
  final int count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(selected ? selectedIcon : icon, size: 18),
      label: Text(_formatVoteCount(count)),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        foregroundColor: selected ? theme.colorScheme.primary : null,
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }

  static String _formatVoteCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
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
        if (_isArchiveBook(book)) _ArchiveVotesInline(book: book),
        _Stat(
          icon: Icons.visibility_outlined,
          label: AppLocalizations.of(
            context,
          )!.readsStat(_formatCount(book.viewCount ?? 0)),
          color: textColor,
        ),
        if (book.chapterCount != null || (book.chapters?.isNotEmpty ?? false))
          _Stat(
            icon: Icons.menu_book_outlined,
            label: AppLocalizations.of(context)!.chaptersStat(
              (book.chapterCount ?? book.chapters!.length).toString(),
            ),
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

class _ArchiveVotesInline extends ConsumerWidget {
  const _ArchiveVotesInline({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(bookVoteStatsProvider(book.id));
    final userVoteAsync = ref.watch(userBookVoteProvider(book.id));
    final currentVote = userVoteAsync.asData?.value;

    return statsAsync.maybeWhen(
      data: (stats) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArchiveVoteButton(
            icon: Icons.thumb_up_alt_outlined,
            selectedIcon: Icons.thumb_up_alt,
            count: stats.upvotes,
            selected: currentVote == 'up',
            onPressed: () => ref
                .read(bookVoteControllerProvider)
                .vote(book.id, currentVote == 'up' ? null : 'up'),
          ),
          const SizedBox(width: 6),
          _ArchiveVoteButton(
            icon: Icons.thumb_down_alt_outlined,
            selectedIcon: Icons.thumb_down_alt,
            count: stats.downvotes,
            selected: currentVote == 'down',
            onPressed: () => ref
                .read(bookVoteControllerProvider)
                .vote(book.id, currentVote == 'down' ? null : 'down'),
          ),
        ],
      ),
      orElse: () => const SizedBox.shrink(),
    );
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
    final l10n = AppLocalizations.of(context)!;
    final average = summary.average;
    if (average == null) {
      return _Stat(
        icon: Icons.star_border_rounded,
        label: l10n.noRatings,
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
          child: Text(
            _expanded
                ? AppLocalizations.of(context)!.showLess
                : AppLocalizations.of(context)!.readMore,
          ),
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

    final l10n = AppLocalizations.of(context)!;
    final idStr = widget.book.id.toString();
    final savedBooks = List<dynamic>.from(user.savedBooks);
    final isSaved = savedBooks.any((id) => id?.toString() == idStr);

    if (isSaved) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.removeSavedBookTitle),
          content: Text(l10n.removeSavedBookBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.unsave,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        savedBooks.removeWhere((id) => id?.toString() == idStr);
        await ref
            .read(authRepositoryProvider)
            .updateUserSavedBooks(user.id, savedBooks);
        if (_isDownloaded && mounted) {
          final removeDownload = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.removeDownloadedBookTitle),
              content: Text(l10n.removeDownloadedBookBody(widget.book.title)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.keep),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.remove),
                ),
              ],
            ),
          );
          if (removeDownload == true) {
            await ref.read(offlineServiceProvider).deleteBook(widget.book.id);
            if (mounted) setState(() => _isDownloaded = false);
            ref.invalidate(downloadedBooksProvider);
            ref.invalidate(downloadedBookEntriesProvider);
            ref.invalidate(homepageDownloadedBooksProvider);
          }
        }
        ref.invalidate(currentUserProvider);
        ref.invalidate(savedBooksProvider);
      }
      return;
    }

    try {
      savedBooks.add(widget.book.id);
      await ref
          .read(authRepositoryProvider)
          .updateUserSavedBooks(user.id, savedBooks);
      ref.invalidate(currentUserProvider);
      ref.invalidate(savedBooksProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.bookSaved)));
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.downloadSavedBookTitle),
          content: Text(l10n.downloadSavedBookBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.notNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.download),
            ),
          ],
        ),
      );
      if (shouldDownload != true) return;
      setState(() => _isDownloading = true);
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
        ref.invalidate(downloadedBooksProvider);
        ref.invalidate(downloadedBookEntriesProvider);
        ref.invalidate(homepageDownloadedBooksProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.bookSavedDownloaded)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.saveFailed(e.toString()))));
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
