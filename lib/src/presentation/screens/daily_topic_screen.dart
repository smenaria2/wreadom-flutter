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
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/daily_topic_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

class DailyTopicArguments {
  const DailyTopicArguments({this.topicId, this.topic});

  final String? topicId;
  final DailyTopic? topic;
}

final dailyTopicByIdProvider = FutureProvider.family<DailyTopic?, String?>((
  ref,
  topicId,
) async {
  final topics = await ref.watch(dailyTopicsProvider.future);
  if (topics.isEmpty) return null;
  if (topicId == null || topicId.isEmpty) return topics.first;
  for (final topic in topics) {
    if (topic.id == topicId) return topic;
  }
  return null;
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

    return Scaffold(
      body: topicAsync.when(
        data: (topic) {
          if (topic == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.dailyTopic)),
              body: Center(child: Text(l10n.dailyTopicNotFound)),
            );
          }
          return _DailyTopicBody(topic: topic);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: Text(l10n.dailyTopic)),
          body: Center(child: Text(l10n.failedToLoadTopic(error.toString()))),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final topic = widget.topic;
    final booksAsync = ref.watch(dailyTopicBooksProvider(topic));
    final userAsync = ref.watch(currentUserProvider);

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
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.82),
                            ],
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
                              child: Text(
                                l10n.dailyTopic,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
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
                      Text(
                        l10n.aboutThisTopic,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.writerPad,
                          arguments: WriterPadArguments(
                            initialTopic: topic.topicName,
                          ),
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
                              child: OutlinedButton.icon(
                                icon: _isGeneratingCertificate
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.download_rounded),
                                label: Text(
                                  _isGeneratingCertificate
                                      ? 'Preparing certificate...'
                                      : 'Download Participation Certificate',
                                ),
                                onPressed: _isGeneratingCertificate
                                    ? null
                                    : () => _downloadCertificate(
                                        userName:
                                            user.displayName ??
                                            user.penName ??
                                            user.username,
                                        userPhotoUrl: user.photoURL,
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
                    Row(
                      children: [
                        Text(
                          l10n.submissionsReceived,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        booksAsync.maybeWhen(
                          data: (books) => Chip(
                            label: Text('${books.length}'),
                            visualDensity: VisualDensity.compact,
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              booksAsync.when(
                data: (books) {
                  if (books.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l10n.noSubmissionsYet)),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.56,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 18,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => BookCard(book: books[index]),
                        childCount: books.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(l10n.failedToLoadSubmissions(error.toString())),
                  ),
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
            child: _ParticipationCertificate(
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
              date: _certificateDate(),
            ),
          ),
        ),
      ],
    );
  }

  String _certificateDate() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _downloadCertificate({
    required String userName,
    required String? userPhotoUrl,
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

      await Share.shareXFiles([
        XFile.fromData(
          jpgBytes,
          name: filename,
          mimeType: 'image/jpeg',
          path: savedPath,
        ),
      ], text: 'My Wreadom participation certificate');

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

class _ParticipationCertificate extends StatelessWidget {
  const _ParticipationCertificate({
    required this.userName,
    required this.userPhotoUrl,
    required this.topicName,
    required this.date,
  });

  final String userName;
  final String? userPhotoUrl;
  final String topicName;
  final String date;

  @override
  Widget build(BuildContext context) {
    final displayName = userName.trim().isEmpty ? 'User' : userName.trim();
    return Material(
      color: Colors.white,
      child: Container(
        width: 842,
        height: 595,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFC5A059), width: 16),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: GridPaper(
                  color: const Color(0xFFC5A059),
                  interval: 32,
                  subdivisions: 1,
                  child: Container(),
                ),
              ),
            ),
            for (final alignment in const [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              Align(
                alignment: alignment,
                child: Container(
                  width: 128,
                  height: 128,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: alignment.y < 0
                          ? const BorderSide(color: Color(0xFFC5A059), width: 8)
                          : BorderSide.none,
                      bottom: alignment.y > 0
                          ? const BorderSide(color: Color(0xFFC5A059), width: 8)
                          : BorderSide.none,
                      left: alignment.x < 0
                          ? const BorderSide(color: Color(0xFFC5A059), width: 8)
                          : BorderSide.none,
                      right: alignment.x > 0
                          ? const BorderSide(color: Color(0xFFC5A059), width: 8)
                          : BorderSide.none,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(72, 32, 72, 104),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/app_logo.png',
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CERTIFICATE',
                      style: TextStyle(
                        color: Color(0xFF8B6B23),
                        fontSize: 34,
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const Text(
                      'OF PARTICIPATION',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'This is to certify that',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: const Color(0xFFFF8A65),
                      backgroundImage:
                          userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(userPhotoUrl!)
                          : null,
                      child: userPhotoUrl == null || userPhotoUrl!.isEmpty
                          ? Text(
                              displayName.characters.first.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(42, 0, 42, 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0x55C5A059),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 30,
                          fontFamily: 'Serif',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'has successfully participated in the',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      topicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SizedBox(
                      width: 500,
                      child: Text(
                        '"We appreciate your participation and your contribution to the spirit of literature through your writing."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 104,
              right: 104,
              bottom: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _CertificateFooterLabel(label: 'DATE', value: date),
                  const _CertificateSignature(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateSignature extends StatelessWidget {
  const _CertificateSignature();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: -0.1,
            child: const Text(
              'Sumit',
              style: TextStyle(
                color: Color(0xCC4338CA),
                fontSize: 30,
                fontFamily: 'Serif',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(
            width: 150,
            child: Divider(color: Color(0xFFE2E8F0), height: 12),
          ),
          const Text(
            'ADMIN SIGNATURE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateFooterLabel extends StatelessWidget {
  const _CertificateFooterLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(
          width: 130,
          child: Divider(color: Color(0xFFF1F5F9), height: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
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
