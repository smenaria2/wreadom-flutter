import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/feed_post.dart';
import 'review_share_card.dart';

/// Portrait review card designed for long reviews.
/// Consolidates book details into a compact top header to allocate
/// maximum height (>55%) to the review text with clean ellipsis truncation.
class PortraitReviewCard extends StatelessWidget {
  const PortraitReviewCard({
    super.key,
    required this.post,
    required this.bookTitle,
    required this.bookAuthorName,
    required this.reviewer,
    required this.rating,
  });

  final FeedPost post;
  final String bookTitle;
  final String bookAuthorName;
  final String reviewer;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final serifBody = GoogleFonts.cormorantGaramond(
      color: const Color(0xFF1A1612),
      fontSize: 38,
      height: 1.38,
      fontWeight: FontWeight.w500,
    );

    return SizedBox(
      width: 1536,
      height: 2172,
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
            // Outer decorative gold border
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
            // Structured column layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Compact Top Header (Cover + Details side-by-side)
                  _buildHeader(context, l10n),
                  const SizedBox(height: 30),
                  const ReviewCardGoldDivider(withDiamond: true),
                  const SizedBox(height: 30),

                  // 2. Middle Review Text Section (takes all remaining space)
                  Expanded(
                    child: _buildReviewBody(context, l10n, serifBody),
                  ),
                  const SizedBox(height: 30),
                  const ReviewCardGoldDivider(withDiamond: true),
                  const SizedBox(height: 30),

                  // 3. Footer (Reviewer profile & prominent wreadom.in branding)
                  _buildFooter(context, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 420,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Book Cover
          SizedBox(
            width: 290,
            height: 420,
            child: ReviewCardBookCover(
              coverUrl: post.bookCover,
              title: bookTitle,
              author: bookAuthorName,
              seed: post.bookId?.toString() ?? bookTitle,
            ),
          ),
          const SizedBox(width: 48),
          // Book Metadata & Rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bookTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    color: const Color(0xFF0D2538),
                    fontSize: 52,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  bookAuthorName.isEmpty
                      ? l10n.unknownAuthor
                      : bookAuthorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB17A27),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 22),
                const ReviewCardGoldDivider(width: 140),
                const SizedBox(height: 20),
                // Star Rating
                Row(
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        index < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFB8862D),
                        size: 48,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n
                      .ratingOutOfFive(rating.toStringAsFixed(1))
                      .toUpperCase(),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2B2520),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBody(
    BuildContext context,
    AppLocalizations l10n,
    TextStyle serifBody,
  ) {
    final text = post.text.trim().isEmpty ? l10n.feedTypeReview : post.text.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate max lines that safely fit the available vertical height
        // Line height is fontSize (38) * height (1.38) ≈ 52.4px
        final availableHeight = constraints.maxHeight;
        final approxLineHeight = 38.0 * 1.38;
        // Leave room for padding & quotes (approx 60px)
        final maxFittingLines = ((availableHeight - 60) / approxLineHeight).floor().clamp(1, 25);

        return Stack(
          children: [
            // Opening quote mark
            Positioned(
              left: 0,
              top: -24,
              child: Text(
                '"',
                style: GoogleFonts.cormorantGaramond(
                  color: const Color(0xFFE2D2BD),
                  fontSize: 120,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Vertical gold accent bar on left
            Positioned(
              left: 26,
              top: 72,
              bottom: 12,
              child: Container(
                width: 1.4,
                color: const Color(0xFFB8862D),
              ),
            ),
            // Closing quote mark
            Positioned(
              right: 12,
              bottom: -28,
              child: Text(
                '"',
                style: GoogleFonts.cormorantGaramond(
                  color: const Color(0xFFE2D2BD),
                  fontSize: 120,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Main text with strict bounds and ellipsis
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(76, 24, 48, 24),
                child: Center(
                  child: Text(
                    text,
                    maxLines: maxFittingLines,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: serifBody,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // Reviewer Avatar
        ReviewCardAvatar(post: post, reviewer: reviewer),
        const SizedBox(width: 32),
        Container(
          height: 120,
          width: 1.4,
          color: const Color(0xFFB8862D),
        ),
        const SizedBox(width: 32),
        // Reviewer Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.reviewedBy,
                style: GoogleFonts.caveat(
                  color: const Color(0xFFB8862D),
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
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
            ],
          ),
        ),
        // Prominent Wreadom.in Logo & Branding
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F1E6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/app_logo.png',
                height: 44,
                width: 44,
              ),
              const SizedBox(width: 16),
              Text(
                'wreadom.in',
                style: GoogleFonts.inter(
                  color: const Color(0xFF8A5A20),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
