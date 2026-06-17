import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GradientQuoteCard extends StatelessWidget {
  final String quote;
  final String bookTitle;
  final String? bookCover;
  final String? chapterTitle;
  final VoidCallback? onBookTap;

  const GradientQuoteCard({
    super.key,
    required this.quote,
    required this.bookTitle,
    this.bookCover,
    this.chapterTitle,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5), // Indigo 600
            Color(0xFF9333EA), // Purple 600
            Color(0xFFEC4899), // Pink 500
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white.withValues(alpha: 0.25),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quote,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBookTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        children: [
                          if (bookCover != null && bookCover!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: bookCover!,
                                width: 32,
                                height: 46,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 32,
                                  height: 46,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                errorWidget: (context, url, error) => const SizedBox(),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (chapterTitle != null && chapterTitle!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    chapterTitle!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
