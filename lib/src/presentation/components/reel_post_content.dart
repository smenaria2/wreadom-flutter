import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/models/feed_post.dart';
import '../../localization/generated/app_localizations.dart';
import '../../utils/image_proxy_utils.dart';
import '../utils/writer_media_utils.dart';
import '../widgets/audio_post_player.dart';
import '../widgets/feed_media_playable_card.dart';

/// Renders only a post's content for the fullscreen reel surface.
/// Creator identity and social controls intentionally belong to the reel shell.
class ReelPostContent extends StatelessWidget {
  const ReelPostContent({
    super.key,
    required this.post,
    required this.isActive,
    required this.onDoubleTapLike,
    required this.onBookTap,
    required this.onQuestionTap,
  });

  final FeedPost post;
  final bool isActive;
  final VoidCallback onDoubleTapLike;
  final VoidCallback? onBookTap;
  final VoidCallback? onQuestionTap;

  @override
  Widget build(BuildContext context) {
    final preview = firstSupportedWriterMediaInfoInText(post.text);
    final visibleText = _withoutPreviewUrl(post.text, preview?.originalUrl);
    final images = _postImages(post);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentHeight = (constraints.maxHeight - 196).clamp(280.0, 900.0);
        return SingleChildScrollView(
          key: PageStorageKey('reel-content-${post.id}'),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 214),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: contentHeight),
            child: Column(
              mainAxisAlignment: images.isEmpty
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (post.question?.trim().isNotEmpty == true)
                  _QuestionContent(
                    question: post.question!.trim(),
                    onTap: onQuestionTap,
                  ),
                if (images.isNotEmpty) ...[
                  _ReelImageGallery(images: images),
                  if (_hasTextForType(visibleText, post))
                    const SizedBox(height: 22),
                ],
                _PostTypeContent(
                  post: post,
                  text: visibleText,
                  onDoubleTapLike: onDoubleTapLike,
                  onBookTap: onBookTap,
                ),
                if (post.audioUrl?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 18),
                  KeyedSubtree(
                    key: ValueKey('reel-audio-${post.id}-$isActive'),
                    child: AudioPostPlayer(post: post),
                  ),
                ],
                if (preview != null) ...[
                  const SizedBox(height: 18),
                  KeyedSubtree(
                    key: ValueKey('reel-media-${post.id}-$isActive'),
                    child: FeedMediaPlayableCard(url: preview.originalUrl),
                  ),
                ],
                if (_hasBookReference(post) &&
                    post.type.toLowerCase() != 'review') ...[
                  const SizedBox(height: 18),
                  _BookReference(post: post, onTap: onBookTap),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostTypeContent extends StatelessWidget {
  const _PostTypeContent({
    required this.post,
    required this.text,
    required this.onDoubleTapLike,
    required this.onBookTap,
  });

  final FeedPost post;
  final String text;
  final VoidCallback onDoubleTapLike;
  final VoidCallback? onBookTap;

  @override
  Widget build(BuildContext context) {
    final type = post.type.toLowerCase();
    if (type == 'quote') {
      final quote = (post.quote?.trim().isNotEmpty == true ? post.quote : text)
          ?.trim();
      return _QuoteContent(
        quote: quote ?? '',
        supportingText: post.quote?.trim() == text ? '' : text,
        bookTitle: post.bookTitle,
        chapterTitle: post.chapterTitle,
        onDoubleTap: onDoubleTapLike,
      );
    }
    if (type == 'review') {
      return _ReviewContent(
        post: post,
        text: text,
        onDoubleTap: onDoubleTapLike,
        onBookTap: onBookTap,
      );
    }
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return _EditorialText(text: text, onDoubleTap: onDoubleTapLike);
  }
}

class _EditorialText extends StatelessWidget {
  const _EditorialText({required this.text, required this.onDoubleTap});
  final String text;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final length = text.runes.length;
    final size = length < 90
        ? 30.0
        : length < 220
        ? 24.0
        : 19.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Text(
          text,
          textAlign: length < 120 ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white,
            fontSize: size,
            height: 1.55,
            fontWeight: length < 90 ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: .1,
          ),
        ),
      ),
    );
  }
}

class _QuoteContent extends StatelessWidget {
  const _QuoteContent({
    required this.quote,
    required this.supportingText,
    required this.bookTitle,
    required this.chapterTitle,
    required this.onDoubleTap,
  });
  final String quote;
  final String supportingText;
  final String? bookTitle;
  final String? chapterTitle;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '“',
                style: TextStyle(
                  color: Colors.white38,
                  fontFamily: 'Georgia',
                  fontSize: 78,
                  height: .65,
                ),
              ),
            ),
            Text(
              quote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Georgia',
                fontSize: 27,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            if (supportingText.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                supportingText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
            ],
            if (bookTitle?.trim().isNotEmpty == true ||
                chapterTitle?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 18),
              Text(
                [
                  if (bookTitle?.trim().isNotEmpty == true) bookTitle!.trim(),
                  if (chapterTitle?.trim().isNotEmpty == true)
                    chapterTitle!.trim(),
                ].join(' · '),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({
    required this.post,
    required this.text,
    required this.onDoubleTap,
    required this.onBookTap,
  });
  final FeedPost post;
  final String text;
  final VoidCallback onDoubleTap;
  final VoidCallback? onBookTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Icon(
              index < (post.rating ?? 0)
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        if (text.trim().isNotEmpty) ...[
          const SizedBox(height: 15),
          _EditorialText(text: text, onDoubleTap: onDoubleTap),
        ],
        if (_hasBookReference(post)) ...[
          const SizedBox(height: 18),
          _BookReference(post: post, onTap: onBookTap),
        ],
      ],
    );
  }
}

class _QuestionContent extends StatelessWidget {
  const _QuestionContent({required this.question, required this.onTap});
  final String question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: .06),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline_rounded, color: Colors.white70),
              const SizedBox(height: 10),
              Text(
                question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.viewAllAnswers,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BookReference extends StatelessWidget {
  const _BookReference({required this.post, required this.onTap});
  final FeedPost post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = Color(0xFFFFC857);
    return Semantics(
      button: onTap != null,
      label: post.bookTitle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF30220F), Color(0xFF17120B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withValues(alpha: .78),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'reel-book-${post.id ?? post.bookId ?? post.bookTitle}',
                child: Material(
                  color: Colors.transparent,
                  child: post.bookCover?.trim().isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: CachedNetworkImage(
                            imageUrl: optimizedImageUrl(
                              post.bookCover!,
                              width: 160,
                              height: 230,
                              fit: 'cover',
                            ),
                            width: 66,
                            height: 92,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const _BookFallback(),
                          ),
                        )
                      : const _BookFallback(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        l10n.openBook,
                        style: const TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      post.bookTitle?.trim().isNotEmpty == true
                          ? post.bookTitle!.trim()
                          : l10n.books,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1.16,
                      ),
                    ),
                    if (post.bookAuthorName?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        post.bookAuthorName!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.arrow_forward_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookFallback extends StatelessWidget {
  const _BookFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white24),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: Color(0xFFFFC857),
        size: 30,
      ),
    );
  }
}

class _ReelImageGallery extends StatelessWidget {
  const _ReelImageGallery({required this.images});
  final List<_ReelImage> images;

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return _AdaptiveImage(
        image: images.first,
        height: MediaQuery.sizeOf(context).height * .52,
        onTap: () => _showGallery(context, images, 0),
      );
    }

    return Column(
      children: [
        _AdaptiveImage(
          image: images.first,
          height: MediaQuery.sizeOf(context).height * .40,
          onTap: () => _showGallery(context, images, 0),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 1; index < images.length; index++)
                  SizedBox(
                    width: width,
                    child: _AdaptiveImage(
                      image: images[index],
                      height: 150,
                      onTap: () => _showGallery(context, images, index),
                      countLabel: index == images.length - 1
                          ? '${images.length} photos'
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AdaptiveImage extends StatelessWidget {
  const _AdaptiveImage({
    required this.image,
    required this.height,
    required this.onTap,
    this.countLabel,
  });
  final _ReelImage image;
  final double height;
  final VoidCallback onTap;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final url = optimizedImageUrl(image.url, width: 1400, quality: 88);
    return Semantics(
      button: true,
      label: image.caption,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: .42),
                  colorBlendMode: BlendMode.darken,
                  errorWidget: (_, _, _) => const _ImageFallback(),
                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, _, _) => const _ImageFallback(),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black45],
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                if (image.caption?.trim().isNotEmpty == true)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Text(
                      image.caption!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (countLabel != null)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        countLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF171717),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 42,
        ),
      ),
    );
  }
}

class _ReelImage {
  const _ReelImage(this.url, this.caption);
  final String url;
  final String? caption;
}

List<_ReelImage> _postImages(FeedPost post) {
  final result = <_ReelImage>[];
  final seen = <String>{};
  void add(String? value, String? caption) {
    final url = value?.trim();
    if (url == null || url.isEmpty || !seen.add(url)) return;
    result.add(_ReelImage(url, caption));
  }

  add(post.imageUrl, null);
  for (final image in post.images ?? const <StoryImage>[]) {
    add(image.url, image.caption);
  }
  return result;
}

void _showGallery(BuildContext context, List<_ReelImage> images, int initial) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (context) => _FullscreenGallery(images: images, initial: initial),
  );
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({required this.images, required this.initial});
  final List<_ReelImage> images;
  final int initial;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initial;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: .8,
                maxScale: 4,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index].url,
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) => const _ImageFallback(),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Positioned(
              top: 18,
              left: 80,
              right: 80,
              child: Text(
                '${_index + 1} / ${widget.images.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _withoutPreviewUrl(String text, String? url) {
  if (url == null || url.isEmpty) return text.trim();
  return text.replaceFirst(url, '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

bool _hasBookReference(FeedPost post) =>
    post.bookId != null ||
    post.bookTitle?.trim().isNotEmpty == true ||
    post.bookCover?.trim().isNotEmpty == true;

bool _hasTextForType(String text, FeedPost post) =>
    text.trim().isNotEmpty || post.quote?.trim().isNotEmpty == true;
