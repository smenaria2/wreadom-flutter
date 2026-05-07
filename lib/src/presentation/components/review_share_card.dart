import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/comment.dart';
import '../../domain/models/feed_post.dart';
import '../../utils/app_link_helper.dart';
import 'generated_book_cover.dart';

Future<void> shareReviewCard(
  BuildContext context, {
  required FeedPost post,
  required String bookTitle,
  required String bookAuthorName,
}) async {
  final postId = post.id;
  if (postId == null) return;

  final boundaryKey = GlobalKey();
  final overlay = Overlay.of(context);
  final l10n = AppLocalizations.of(context)!;
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -2400,
      top: 0,
      child: RepaintBoundary(
        key: boundaryKey,
        child: Material(
          color: Colors.transparent,
          child: ReviewShareCard(
            post: post,
            bookTitle: bookTitle,
            bookAuthorName: bookAuthorName,
          ),
        ),
      ),
    ),
  );

  final link = AppLinkHelper.post(postId);
  final fallbackText =
      '${l10n.reviewTitle(bookTitle)}\n\n${post.text}\n\n$link';

  try {
    overlay.insert(entry);
    await _precacheNetworkImage(context, post.bookCover);
    if (!context.mounted) {
      await Share.share(fallbackText, subject: l10n.reviewTitle(bookTitle));
      return;
    }
    await _precacheNetworkImage(context, post.userPhotoURL);
    if (!context.mounted) {
      await Share.share(fallbackText, subject: l10n.reviewTitle(bookTitle));
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: 2.0);
    final bytes = await image
        ?.toByteData(format: ui.ImageByteFormat.png)
        .then((data) => data?.buffer.asUint8List());
    if (bytes == null || bytes.isEmpty) {
      await Share.share(fallbackText, subject: l10n.reviewTitle(bookTitle));
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: '${_safeFilePart(bookTitle)}-review.png',
          mimeType: 'image/png',
        ),
      ],
      text: link,
      subject: l10n.reviewTitle(bookTitle),
    );
  } catch (_) {
    await Share.share(fallbackText, subject: l10n.reviewTitle(bookTitle));
  } finally {
    entry.remove();
  }
}

Future<void> shareReviewCommentCard(
  BuildContext context, {
  required Comment comment,
  required String bookId,
  required String bookTitle,
  required String bookAuthorName,
  required String? bookCover,
}) async {
  final commentId = comment.id;
  final boundaryKey = GlobalKey();
  final overlay = Overlay.of(context);
  final l10n = AppLocalizations.of(context)!;
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -2400,
      top: 0,
      child: RepaintBoundary(
        key: boundaryKey,
        child: Material(
          color: Colors.transparent,
          child: ReviewShareCard(
            post: _postFromComment(comment, bookCover),
            bookTitle: bookTitle,
            bookAuthorName: bookAuthorName,
          ),
        ),
      ),
    ),
  );

  final link = _bookReviewLink(bookId, commentId);
  final fallbackText =
      '${l10n.reviewTitle(bookTitle)}\n\n${comment.text}\n\n$link';

  try {
    overlay.insert(entry);
    await _precacheNetworkImage(context, bookCover);
    if (!context.mounted) {
      await Share.share(fallbackText, subject: l10n.reviewTitle(bookTitle));
      return;
    }
    await _precacheNetworkImage(context, comment.userPhotoURL);
    if (!context.mounted) {
      await Share.share(fallbackText, subject: l10n.reviewTitle(bookTitle));
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: 2.0);
    final bytes = await image
        ?.toByteData(format: ui.ImageByteFormat.png)
        .then((data) => data?.buffer.asUint8List());
    if (bytes == null || bytes.isEmpty) {
      await Share.share(fallbackText, subject: l10n.reviewTitle(bookTitle));
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: '${_safeFilePart(bookTitle)}-review.png',
          mimeType: 'image/png',
        ),
      ],
      text: link,
      subject: l10n.reviewTitle(bookTitle),
    );
  } catch (_) {
    await Share.share(fallbackText, subject: l10n.reviewTitle(bookTitle));
  } finally {
    entry.remove();
  }
}

Future<void> _precacheNetworkImage(BuildContext context, String? url) async {
  if (url == null || url.trim().isEmpty) return;
  await precacheImage(
    CachedNetworkImageProvider(url),
    context,
  ).timeout(const Duration(seconds: 2), onTimeout: () {});
}

class ReviewShareCard extends StatelessWidget {
  const ReviewShareCard({
    super.key,
    required this.post,
    required this.bookTitle,
    required this.bookAuthorName,
  });

  final FeedPost post;
  final String bookTitle;
  final String bookAuthorName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reviewer = _reviewerName(post);
    final rating = ((post.rating ?? 0).clamp(0, 5) as num).toDouble();
    final titleStyle = GoogleFonts.cormorantGaramond(
      color: const Color(0xFF0D2538),
      fontSize: 55,
      height: 1,
      fontWeight: FontWeight.w700,
      letterSpacing: 3,
    );
    final serifBody = GoogleFonts.cormorantGaramond(
      color: const Color(0xFF1A1612),
      fontSize: 38,
      height: 1.38,
      fontWeight: FontWeight.w500,
    );
    final labelStyle = GoogleFonts.inter(
      color: const Color(0xFF2B2520),
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 7,
    );

    return SizedBox(
      width: 1536,
      height: 960,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF6),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0x66B8862D),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 560,
              top: 26,
              bottom: 26,
              child: Container(width: 1, color: const Color(0x55B8862D)),
            ),
            Positioned(
              left: 88,
              top: 88,
              width: 410,
              height: 585,
              child: _BookCover(
                coverUrl: post.bookCover,
                title: bookTitle,
                author: bookAuthorName,
                seed: post.bookId?.toString() ?? bookTitle,
              ),
            ),
            Positioned(
              left: 88,
              right: 1038,
              top: 724,
              child: Column(
                children: [
                  const _GoldDivider(width: 190),
                  const SizedBox(height: 22),
                  Text(
                    bookTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 20),
                  const _GoldDivider(width: 64),
                  const SizedBox(height: 18),
                  Text(
                    bookAuthorName.isEmpty
                        ? l10n.unknownAuthor
                        : bookAuthorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB17A27),
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 7,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Icon(
                    Icons.local_florist_rounded,
                    color: const Color(0xFFB8862D).withValues(alpha: 0.88),
                    size: 36,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 655,
              right: 280,
              top: 98,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      index < rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFB8862D),
                      size: 66,
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              left: 820,
              right: 380,
              top: 190,
              child: Row(
                children: [
                  const Expanded(child: _GoldDivider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      l10n
                          .ratingOutOfFive(rating.toStringAsFixed(1))
                          .toUpperCase(),
                      style: labelStyle,
                    ),
                  ),
                  const Expanded(child: _GoldDivider()),
                ],
              ),
            ),
            Positioned(
              left: 624,
              right: 118,
              top: 270,
              height: 350,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: -30,
                    child: Text(
                      '"',
                      style: GoogleFonts.cormorantGaramond(
                        color: const Color(0xFFE2D2BD),
                        fontSize: 112,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 68,
                    bottom: 8,
                    child: Container(
                      width: 1.2,
                      color: const Color(0xFFB8862D),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: -22,
                    child: Text(
                      '"',
                      style: GoogleFonts.cormorantGaramond(
                        color: const Color(0xFFE2D2BD),
                        fontSize: 112,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(70, 20, 44, 0),
                    child: Text(
                      post.text.trim().isEmpty
                          ? l10n.feedTypeReview
                          : post.text.trim(),
                      maxLines: 7,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: serifBody,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 606,
              right: 86,
              bottom: 238,
              child: const _GoldDivider(withDiamond: true),
            ),
            Positioned(
              left: 660,
              right: 160,
              bottom: 78,
              child: Row(
                children: [
                  _ReviewerAvatar(post: post, reviewer: reviewer),
                  const SizedBox(width: 34),
                  Container(
                    height: 132,
                    width: 1.2,
                    color: const Color(0xFFB8862D),
                  ),
                  const SizedBox(width: 36),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reviewedBy,
                          style: GoogleFonts.caveat(
                            color: const Color(0xFFB8862D),
                            fontSize: 43,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reviewer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cormorantGaramond(
                            color: const Color(0xFF0D2538),
                            fontSize: 48,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/app_logo.png',
                              height: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.appTitle,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFB17A27),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider({this.width, this.withDiamond = false});

  final double? width;
  final bool withDiamond;

  @override
  Widget build(BuildContext context) {
    final line = Container(
      width: width,
      height: 1,
      color: const Color(0x66B8862D),
    );
    if (!withDiamond) return line;
    return Row(
      children: [
        Expanded(child: line),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            Icons.diamond_rounded,
            color: Color(0xFFB8862D),
            size: 16,
          ),
        ),
        Expanded(child: line),
      ],
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.coverUrl,
    required this.title,
    required this.author,
    required this.seed,
  });

  final String? coverUrl;
  final String title;
  final String author;
  final String seed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            coverUrl != null && coverUrl!.trim().isNotEmpty
                ? CachedNetworkImage(imageUrl: coverUrl!, fit: BoxFit.cover)
                : GeneratedBookCover(
                    title: title,
                    author: author,
                    seed: seed,
                    borderRadius: 12,
                    compact: true,
                  ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 38,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.42),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1,
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

class _ReviewerAvatar extends StatelessWidget {
  const _ReviewerAvatar({required this.post, required this.reviewer});

  final FeedPost post;
  final String reviewer;

  @override
  Widget build(BuildContext context) {
    final photoUrl = post.userPhotoURL;
    return Container(
      width: 142,
      height: 142,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB8862D), width: 2),
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFE8DDCE),
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImageProvider(photoUrl)
            : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? Text(
                reviewer.characters.first.toUpperCase(),
                style: GoogleFonts.cormorantGaramond(
                  color: const Color(0xFF8A5A20),
                  fontSize: 58,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
    );
  }
}

String _reviewerName(FeedPost post) {
  for (final value in [post.displayName, post.penName, post.username]) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return 'Wreadom';
}

FeedPost _postFromComment(Comment comment, String? bookCover) {
  return FeedPost(
    userId: comment.userId,
    username: comment.username,
    displayName: comment.displayName,
    penName: comment.penName,
    userPhotoURL: comment.userPhotoURL,
    type: 'review',
    text: comment.text,
    rating: comment.rating,
    bookId: comment.bookId?.toString(),
    bookTitle: comment.bookTitle,
    bookCover: bookCover,
    chapterTitle: comment.chapterTitle,
    chapterId: comment.chapterId,
    timestamp: comment.timestamp,
    likes: const [],
    visibility: 'public',
    privacy: 'public',
  );
}

String _bookReviewLink(String bookId, String? commentId) {
  final base = AppLinkHelper.book(bookId);
  if (commentId == null || commentId.trim().isEmpty) return base;
  return '$base&comment=${Uri.encodeComponent(commentId)}';
}

String _safeFilePart(String value) {
  final safe = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return safe.isEmpty ? 'wreadom' : safe;
}
