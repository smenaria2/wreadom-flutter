import 'package:flutter/material.dart';
import '../localization/generated/app_localizations.dart';

class TierInfo {
  const TierInfo({
    required this.tier,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.progressPercent,
    this.pointsToNext,
  });

  final int tier;
  final String label;
  final String icon;
  final LinearGradient gradient;
  final double progressPercent;
  final int? pointsToNext;
}

class _TierDef {
  const _TierDef({
    required this.minPoints,
    required this.readerTitle,
    required this.authorTitle,
    required this.icon,
    required this.readerGradient,
    required this.authorGradient,
  });
  final int minPoints;
  final String readerTitle;
  final String authorTitle;
  final String icon;
  final LinearGradient readerGradient;
  final LinearGradient authorGradient;
}

const _tiers = [
  _TierDef(
    minPoints: 0,
    readerTitle: 'Curious Mind',
    authorTitle: 'Aspiring Writer',
    icon: '🌱',
    readerGradient: LinearGradient(
      colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TierDef(
    minPoints: 500,
    readerTitle: 'Bookworm',
    authorTitle: 'Storyteller',
    icon: '📚',
    readerGradient: LinearGradient(
      colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFF9A825), Color(0xFFFFD54F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TierDef(
    minPoints: 5000,
    readerTitle: 'Story Seeker',
    authorTitle: 'Rising Author',
    icon: '⭐',
    readerGradient: LinearGradient(
      colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFF57F17), Color(0xFFFFCA28)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TierDef(
    minPoints: 25000,
    readerTitle: 'Page Turner',
    authorTitle: 'Published Voice',
    icon: '🔥',
    readerGradient: LinearGradient(
      colors: [Color(0xFF0097A7), Color(0xFF4DD0E1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFE65100), Color(0xFFFF8A65)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TierDef(
    minPoints: 50000,
    readerTitle: 'Literary Scholar',
    authorTitle: 'Master Wordsmith',
    icon: '💎',
    readerGradient: LinearGradient(
      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFC62828), Color(0xFFEF9A9A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TierDef(
    minPoints: 100000,
    readerTitle: 'Grand Reader',
    authorTitle: 'Grand Author',
    icon: '👑',
    readerGradient: LinearGradient(
      colors: [Color(0xFF283593), Color(0xFF7986CB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFB8860B), Color(0xFFFFD700)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TierDef(
    minPoints: 500000,
    readerTitle: 'Legend of Letters',
    authorTitle: 'Literary Legend',
    icon: '🌟',
    readerGradient: LinearGradient(
      colors: [Color(0xFF4A148C), Color(0xFFCE93D8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFF880E4F), Color(0xFFF48FB1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _TierDef(
    minPoints: 1000000,
    readerTitle: 'Eternal Reader',
    authorTitle: 'Eternal Scribe',
    icon: '✨',
    readerGradient: LinearGradient(
      colors: [Color(0xFF7C4DFF), Color(0xFF00BCD4), Color(0xFF69F0AE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFFF6D00), Color(0xFFFFD740), Color(0xFFFF4081)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];

TierInfo getTierInfo(int points, String category) {
  final isAuthor = category == 'author';
  int tierIndex = 0;
  for (int i = _tiers.length - 1; i >= 0; i--) {
    if (points >= _tiers[i].minPoints) {
      tierIndex = i;
      break;
    }
  }

  final def = _tiers[tierIndex];
  final isMaxTier = tierIndex == _tiers.length - 1;

  final int tierMin = def.minPoints;
  final int tierMax = isMaxTier ? -1 : _tiers[tierIndex + 1].minPoints;
  final double progress = isMaxTier
      ? 100.0
      : ((points - tierMin) / (tierMax - tierMin) * 100).clamp(0.0, 100.0);
  final int? toNext = isMaxTier ? null : (tierMax - points).clamp(0, tierMax);

  return TierInfo(
    tier: tierIndex + 1,
    label: isAuthor ? def.authorTitle : def.readerTitle,
    icon: def.icon,
    gradient: isAuthor ? def.authorGradient : def.readerGradient,
    progressPercent: progress,
    pointsToNext: toNext,
  );
}

/// Dynamically resolves the localized tier name using ARB file keys.
String getLocalizedTierTitle(BuildContext context, int tier, String category) {
  final l10n = AppLocalizations.of(context)!;
  final isAuthor = category == 'author';
  switch (tier) {
    case 1: return isAuthor ? l10n.tier1AuthorTitle : l10n.tier1ReaderTitle;
    case 2: return isAuthor ? l10n.tier2AuthorTitle : l10n.tier2ReaderTitle;
    case 3: return isAuthor ? l10n.tier3AuthorTitle : l10n.tier3ReaderTitle;
    case 4: return isAuthor ? l10n.tier4AuthorTitle : l10n.tier4ReaderTitle;
    case 5: return isAuthor ? l10n.tier5AuthorTitle : l10n.tier5ReaderTitle;
    case 6: return isAuthor ? l10n.tier6AuthorTitle : l10n.tier6ReaderTitle;
    case 7: return isAuthor ? l10n.tier7AuthorTitle : l10n.tier7ReaderTitle;
    case 8: return isAuthor ? l10n.tier8AuthorTitle : l10n.tier8ReaderTitle;
    default: return '';
  }
}
