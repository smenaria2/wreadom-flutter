import 'package:flutter/material.dart';

class GeneratedBookCover extends StatelessWidget {
  const GeneratedBookCover({
    super.key,
    required this.title,
    this.author,
    this.seed,
    this.borderRadius = 12,
    this.width,
    this.height,
    this.compact = false,
  });

  final String title;
  final String? author;
  final String? seed;
  final double borderRadius;
  final double? width;
  final double? height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(seed ?? '$title-${author ?? ''}');
    final resolvedTitle = title.trim().isEmpty ? 'Untitled' : title.trim();
    final resolvedAuthor = author?.trim();
    final showAuthor =
        !compact && resolvedAuthor != null && resolvedAuthor.isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.28),
            blurRadius: compact ? 8 : 14,
            offset: Offset(compact ? 2 : 4, compact ? 4 : 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.primary, palette.secondary, palette.tertiary],
                stops: const [0, 0.58, 1],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.34),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.16, 0.45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: compact ? 8 : 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.24),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: compact ? -24 : -34,
            top: compact ? -18 : -26,
            child: Icon(
              Icons.auto_stories_rounded,
              size: compact ? 62 : 92,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 10 : 18,
              compact ? 8 : 18,
              compact ? 8 : 14,
              compact ? 8 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 22 : 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                Text(
                  resolvedTitle,
                  maxLines: compact ? 3 : 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 9 : 14,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showAuthor) ...[
                  const SizedBox(height: 8),
                  Text(
                    resolvedAuthor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 10,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPalette {
  const _CoverPalette(this.primary, this.secondary, this.tertiary, this.shadow);

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color shadow;
}

_CoverPalette _paletteFor(String input) {
  const palettes = [
    _CoverPalette(
      Color(0xFF1D3557),
      Color(0xFFE63946),
      Color(0xFFF1FAEE),
      Color(0xFF1D3557),
    ),
    _CoverPalette(
      Color(0xFF2A9D8F),
      Color(0xFF264653),
      Color(0xFFE9C46A),
      Color(0xFF264653),
    ),
    _CoverPalette(
      Color(0xFF5A189A),
      Color(0xFF006D77),
      Color(0xFFFFB703),
      Color(0xFF240046),
    ),
    _CoverPalette(
      Color(0xFF0B132B),
      Color(0xFF3A506B),
      Color(0xFF6FFFE9),
      Color(0xFF0B132B),
    ),
    _CoverPalette(
      Color(0xFF7F5539),
      Color(0xFF9C6644),
      Color(0xFFEDE0D4),
      Color(0xFF432818),
    ),
    _CoverPalette(
      Color(0xFF14213D),
      Color(0xFFFCA311),
      Color(0xFFE5E5E5),
      Color(0xFF14213D),
    ),
    _CoverPalette(
      Color(0xFF31572C),
      Color(0xFF90A955),
      Color(0xFFECF39E),
      Color(0xFF132A13),
    ),
    _CoverPalette(
      Color(0xFF3D405B),
      Color(0xFFE07A5F),
      Color(0xFF81B29A),
      Color(0xFF3D405B),
    ),
  ];
  return palettes[_stableHash(input) % palettes.length];
}

int _stableHash(String input) {
  var hash = 2166136261;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash;
}
