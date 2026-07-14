import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../domain/models/book.dart';
import '../../widgets/glass_surface.dart';
import '../generated_book_cover.dart';
import '../../screens/book_detail_screen.dart';

class HistoryBookCard extends StatelessWidget {
  final Book book;
  final double width;

  const HistoryBookCard({super.key, required this.book, this.width = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                BookDetailScreen(bookId: book.id, preloadedBook: book),
          ),
        ),
        semanticButton: true,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _GeneratedCover(book: book, borderRadius: 12),
                    )
                  : _GeneratedCover(book: book, borderRadius: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratedCover extends StatelessWidget {
  const _GeneratedCover({required this.book, required this.borderRadius});

  final Book book;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GeneratedBookCover(
      title: book.title,
      author: book.authors.isNotEmpty ? book.authors.first.name : null,
      seed: book.id,
      borderRadius: borderRadius,
      compact: true,
    );
  }
}
