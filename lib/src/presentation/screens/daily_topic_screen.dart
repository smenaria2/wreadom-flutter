import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image_codec;
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/book.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import '../../utils/app_link_helper.dart';
import '../../utils/certificate_file_saver.dart';
import '../components/book_card.dart';
import '../components/book/participation_certificate.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/daily_topic_providers.dart';
import '../routing/app_routes.dart';
import '../routing/writer_pad_mode.dart';
import '../widgets/agaaz_topic_info_dialog.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';

class DailyTopicArguments {
  const DailyTopicArguments({this.topicId, this.topic});

  final String? topicId;
  final DailyTopic? topic;
}

final dailyTopicByIdProvider = FutureProvider.family<DailyTopic?, String?>((
  ref,
  topicId,
) async {
  await ref.watch(dailyTopicsProvider.future);
  return ref.read(dailyTopicsProvider.notifier).findTopicById(topicId);
});

final dailyTopicBooksProvider = FutureProvider.family<List<Book>, DailyTopic>((
  ref,
  topic,
) async {
  if (topic.topicName.trim().isEmpty) return [];
  final repo = ref.watch(bookRepositoryProvider);
  final topicName = topic.topicName.trim();
  return (await repo.getOriginalBooksByTopic(topicName, limit: 40))..sort(
    (a, b) => (b.updatedAt ?? b.createdAt ?? 0).compareTo(
      a.updatedAt ?? a.createdAt ?? 0,
    ),
  );
});

class DailyTopicScreen extends ConsumerWidget {
  const DailyTopicScreen({super.key, this.topicId, this.preloadedTopic});

  final String? topicId;
  final DailyTopic? preloadedTopic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final topicAsync = preloadedTopic != null
        ? AsyncValue.data(preloadedTopic)
        : ref.watch(dailyTopicByIdProvider(topicId));

    return GlassScaffold(
      body: topicAsync.when(
        data: (topic) {
          if (topic == null) {
            return _DailyTopicMessage(message: l10n.dailyTopicNotFound);
          }
          return _DailyTopicBody(topic: topic);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DailyTopicMessage(
          message: l10n.failedToLoadTopic(error.toString()),
        ),
      ),
    );
  }
}

class _DailyTopicMessage extends StatelessWidget {
  const _DailyTopicMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassSurface(
          strong: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 42,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyTopicBody extends ConsumerStatefulWidget {
  const _DailyTopicBody({required this.topic});

  final DailyTopic topic;

  @override
  ConsumerState<_DailyTopicBody> createState() => _DailyTopicBodyState();
}

class _DailyTopicBodyState extends ConsumerState<_DailyTopicBody> {
  final GlobalKey _certificateKey = GlobalKey();
  bool _isGeneratingCertificate = false;
  bool _optOutComplementary = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final topic = widget.topic;
    final booksAsync = ref.watch(dailyTopicBooksProvider(topic));
    final userAsync = ref.watch(currentUserProvider);
    final currentUser = userAsync.asData?.value;
    final submittedBooks = booksAsync.asData?.value ?? const <Book>[];
    final participantBook = currentUser == null
        ? null
        : submittedBooks.cast<Book?>().firstWhere(
            (book) => book?.authorId == currentUser.id,
            orElse: () => null,
          );
    final certificateDate = formatCertificateDateFromMillis(
      participantBook?.publishedAt ??
          participantBook?.createdAt ??
          participantBook?.updatedAt,
    );

    Future<void> refresh() async {
      ref.invalidate(dailyTopicsProvider);
      ref.invalidate(dailyTopicByIdProvider(topic.id));
      ref.invalidate(dailyTopicBooksProvider(topic));
      ref.invalidate(currentUserProvider);
      await Future.wait([
        ref.read(dailyTopicsProvider.future).catchError((_) => <DailyTopic>[]),
        ref
            .read(dailyTopicBooksProvider(topic).future)
            .catchError((_) => <Book>[]),
      ]);
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                title: Text(l10n.dailyTopic),
                foregroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Colors.white),
                actionsIconTheme: const IconThemeData(color: Colors.white),
                titleTextStyle: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                actions: [
                  IconButton(
                    tooltip: l10n.sharePost,
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      final id = topic.id.isNotEmpty
                          ? topic.id
                          : topic.topicName;
                      Share.share(
                        l10n.writeOnDailyTopic(
                          topic.topicName,
                          AppLinkHelper.dailyTopic(id),
                        ),
                        subject: topic.topicName,
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (topic.coverImageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: topic.coverImageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              _TopicFallback(topic: topic),
                        )
                      else
                        _TopicFallback(topic: topic),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.58),
                              Colors.black.withValues(alpha: 0.24),
                              Colors.black.withValues(alpha: 0.82),
                            ],
                            stops: const [0, 0.42, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipOval(
                                    child: Image.asset(
                                      'assets/images/agaaz_logo.jpg',
                                      width: 14,
                                      height: 14,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.dailyTopic,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              topic.topicName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              topic.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                height: 1.35,
                              ),
                            ),
                          ],
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
                    if (topic.fullDescription.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            l10n.aboutThisTopic,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () => showAgaazTopicInfoDialog(
                              context: context,
                              optOutComplementary: _optOutComplementary,
                              onOptOutChanged: (val) {
                                setState(() {
                                  _optOutComplementary = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.fullDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(l10n.participateNow),
                        onPressed: () async {
                          await Navigator.of(context).pushNamed(
                            AppRoutes.writerPad,
                            arguments: WriterPadArguments(
                              initialTopic: topic.topicName,
                              optOutComplementary: _optOutComplementary,
                            ),
                          );
                          if (!context.mounted) return;
                          await refresh();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => showAgaazTopicInfoDialog(
                          context: context,
                          optOutComplementary: _optOutComplementary,
                          onOptOutChanged: (val) {
                            setState(() {
                              _optOutComplementary = val;
                            });
                          },
                        ),
                        icon: Icon(
                          !_optOutComplementary
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: !_optOutComplementary
                              ? Colors.green
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        label: Text(
                          !_optOutComplementary
                              ? l10n.recreateEnabled
                              : l10n.recreateDisabled,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: !_optOutComplementary
                                ? Colors.green
                                : theme.colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    booksAsync.maybeWhen(
                      data: (books) => userAsync.maybeWhen(
                        data: (user) {
                          final hasParticipated =
                              user != null &&
                              books.any((book) => book.authorId == user.id);
                          if (!hasParticipated) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isGeneratingCertificate
                                    ? null
                                    : () => _downloadCertificate(
                                        userName:
                                            user.displayName ??
                                            user.penName ??
                                            user.username,
                                        userPhotoUrl: user.photoURL,
                                        userBook: participantBook,
                                      ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (_isGeneratingCertificate)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.download_rounded),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _isGeneratingCertificate
                                            ? 'Preparing certificate...'
                                            : 'Download Participation Certificate',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    GlassSurface(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.submissionsReceived,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Refresh submissions',
                                icon: const Icon(Icons.refresh_rounded),
                                onPressed: refresh,
                              ),
                              booksAsync.maybeWhen(
                                data: (books) => Chip(
                                  label: Text('${books.length}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                                orElse: () => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          booksAsync.when(
                            data: (books) {
                              if (books.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32.0,
                                    ),
                                    child: Text(
                                      l10n.noSubmissionsYet,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.56,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 18,
                                    ),
                                itemCount: books.length,
                                itemBuilder: (context, index) =>
                                    BookCard(book: books[index]),
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (error, _) => Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32.0,
                                ),
                                child: Text(
                                  l10n.failedToLoadSubmissions(
                                    error.toString(),
                                  ),
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: -2000,
          top: -2000,
          child: RepaintBoundary(
            key: _certificateKey,
            child: ParticipationCertificate(
              userName: userAsync.maybeWhen(
                data: (user) =>
                    user?.displayName ?? user?.penName ?? user?.username ?? '',
                orElse: () => '',
              ),
              userPhotoUrl: userAsync.maybeWhen(
                data: (user) => user?.photoURL,
                orElse: () => null,
              ),
              topicName: topic.topicName,
              date: certificateDate,
              bookCoverUrl: participantBook?.coverUrl,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadCertificate({
    required String userName,
    required String? userPhotoUrl,
    required Book? userBook,
  }) async {
    setState(() => _isGeneratingCertificate = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final boundary =
          _certificateKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) return;

      final jpgBytes = _pngToJpg(pngBytes);
      final safeTopic = widget.topic.topicName.replaceAll(RegExp(r'\s+'), '_');
      final safeUser = userName.replaceAll(RegExp(r'\s+'), '_');
      final filename = 'Wreadom_Certificate_${safeTopic}_$safeUser.jpg';
      final savedPath = await saveCertificateBytes(jpgBytes, filename);

      final String shareText;
      if (userBook != null) {
        final authorName = userBook.authors.firstOrNull?.name ?? '';
        shareText =
            'wreadom participation certificate for "${userBook.title}" by "$authorName" ${AppLinkHelper.book(userBook.id)}';
      } else {
        shareText = 'My Wreadom participation certificate';
      }

      await Share.shareXFiles([
        XFile.fromData(
          jpgBytes,
          name: filename,
          mimeType: 'image/jpeg',
          path: savedPath,
        ),
      ], text: shareText);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath == null
                ? 'Certificate ready to share.'
                : 'Certificate saved and ready to share.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingCertificate = false);
    }
  }

  Uint8List _pngToJpg(Uint8List pngBytes) {
    final decoded = image_codec.decodePng(pngBytes);
    if (decoded == null) return pngBytes;
    return Uint8List.fromList(image_codec.encodeJpg(decoded, quality: 95));
  }
}

class _TopicFallback extends StatelessWidget {
  const _TopicFallback({required this.topic});

  final DailyTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.auto_stories_rounded,
        size: 72,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
