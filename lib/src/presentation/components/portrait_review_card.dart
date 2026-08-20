import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/feed_post.dart';
import 'review_share_card.dart';

/// Portrait review card designed for long reviews.
/// Features a centered book cover and metadata header, dynamic auto-adjusting
/// vertical height that tightly frames the review text without massive blank spaces,
/// and clean transparent wreadom.in footer branding.
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
      height: 1.42,
      fontWeight: FontWeight.w500,
    );

    return SizedBox(
      width: 1536,
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
            // Outer decorative gold border wrapping the dynamic height
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
            // Structured column layout with auto-adjusting content height
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Centered Top Header (Cover + Metadata stacked in center)
                  _buildCenteredHeader(context, l10n),
                  const SizedBox(height: 32),
                  const ReviewCardGoldDivider(withDiamond: true),
                  const SizedBox(height: 32),

                  // 2. Auto-sizing Review Text Section
                  _buildReviewBody(context, l10n, serifBody),
                  const SizedBox(height: 32),
                  const ReviewCardGoldDivider(withDiamond: true),
                  const SizedBox(height: 32),

                  // 3. Footer (Reviewer profile & clean unboxed wreadom.in branding)
                  _buildFooter(context, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Centered Book Cover
        SizedBox(
          width: 320,
          height: 460,
          child: ReviewCardBookCover(
            coverUrl: post.bookCover,
            title: bookTitle,
            author: bookAuthorName,
            seed: post.bookId?.toString() ?? bookTitle,
          ),
        ),
        const SizedBox(height: 24),

        // 2. Centered Book Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            bookTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cormorantGaramond(
              color: const Color(0xFF0D2538),
              fontSize: 54,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 3. Centered Author Name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            bookAuthorName.isEmpty ? l10n.unknownAuthor : bookAuthorName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFFB17A27),
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: 5,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 4. Centered Small Accent Divider
        const ReviewCardGoldDivider(width: 140),
        const SizedBox(height: 16),

        // 5. Centered Star Rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                index < rating.round()
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: const Color(0xFFB8862D),
                size: 46,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // 6. Centered Rating Text
        Text(
          l10n.ratingOutOfFive(rating.toStringAsFixed(1)).toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFF2B2520),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewBody(
    BuildContext context,
    AppLocalizations l10n,
    TextStyle serifBody,
  ) {
    final text =
        post.text.trim().isEmpty ? l10n.feedTypeReview : post.text.trim();

    return Stack(
      children: [
        // Opening quote mark
        Positioned(
          left: 0,
          top: -20,
          child: Text(
            '"',
            style: GoogleFonts.cormorantGaramond(
              color: const Color(0xFFE2D2BD),
              fontSize: 110,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Vertical gold accent bar on left
        Positioned(
          left: 24,
          top: 68,
          bottom: 8,
          child: Container(
            width: 1.4,
            color: const Color(0xFFB8862D),
          ),
        ),
        // Closing quote mark
        Positioned(
          right: 8,
          bottom: -24,
          child: Text(
            '"',
            style: GoogleFonts.cormorantGaramond(
              color: const Color(0xFFE2D2BD),
              fontSize: 110,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Main review text (auto-adjusts height, capped at 25 lines with ellipsis)
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 16, 44, 16),
          child: Text(
            text,
            maxLines: 25,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: serifBody,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // Reviewer Avatar
        ReviewCardAvatar(post: post, reviewer: reviewer),
        const SizedBox(width: 32),
        Container(
          height: 110,
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
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                reviewer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cormorantGaramond(
                  color: const Color(0xFF0D2538),
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Clean Wreadom.in Logo & Branding (no background box)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 48,
              width: 48,
            ),
            const SizedBox(width: 14),
            Text(
              'wreadom.in',
              style: GoogleFonts.inter(
                color: const Color(0xFF8A5A20),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
