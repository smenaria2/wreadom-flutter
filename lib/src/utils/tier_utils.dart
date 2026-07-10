import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../localization/generated/app_localizations.dart';

enum RankTrack {
  author,
  reader;

  String get value => name;

  static RankTrack fromValue(String value) =>
      value == reader.value ? reader : author;
}

@immutable
class TierDefinition {
  const TierDefinition({
    required this.tier,
    required this.minPoints,
    required this.readerIcon,
    required this.authorIcon,
    required this.readerGradient,
    required this.authorGradient,
  });

  final int tier;
  final int minPoints;
  final String readerIcon;
  final String authorIcon;
  final LinearGradient readerGradient;
  final LinearGradient authorGradient;

  LinearGradient gradientFor(RankTrack track) =>
      track == RankTrack.author ? authorGradient : readerGradient;

  String iconFor(RankTrack track) =>
      track == RankTrack.author ? authorIcon : readerIcon;
}

@immutable
class TierInfo {
  const TierInfo({
    required this.definition,
    required this.track,
    required this.points,
    required this.progressPercent,
    this.nextDefinition,
    this.pointsToNext,
  });

  final TierDefinition definition;
  final TierDefinition? nextDefinition;
  final RankTrack track;
  final int points;
  final double progressPercent;
  final int? pointsToNext;

  int get tier => definition.tier;
  String get icon => definition.iconFor(track);
  LinearGradient get gradient => definition.gradientFor(track);
  bool get isMaxTier => nextDefinition == null;
}

const List<TierDefinition> tierDefinitions = [
  TierDefinition(
    tier: 1,
    minPoints: 0,
    readerIcon: '\u{1F331}',
    authorIcon: '\u{1F331}',
    readerGradient: LinearGradient(
      colors: [Color(0xFF757575), Color(0xFFBDBDBD)],
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFF757575), Color(0xFFBDBDBD)],
    ),
  ),
  TierDefinition(
    tier: 2,
    minPoints: 500,
    readerIcon: '\u{1F4D6}',
    authorIcon: '\u{270D}\u{FE0F}',
    readerGradient: LinearGradient(
      colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFF9A825), Color(0xFFFFD54F)],
    ),
  ),
  TierDefinition(
    tier: 3,
    minPoints: 5000,
    readerIcon: '\u{1F647}\u{200D}\u{2642}\u{FE0F}',
    authorIcon: '\u{2712}\u{FE0F}',
    readerGradient: LinearGradient(
      colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFF57F17), Color(0xFFFFCA28)],
    ),
  ),
  TierDefinition(
    tier: 4,
    minPoints: 25000,
    readerIcon: '\u{1F60D}',
    authorIcon: '\u{1F4DC}',
    readerGradient: LinearGradient(
      colors: [Color(0xFF00838F), Color(0xFF4DD0E1)],
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFE65100), Color(0xFFFF8A65)],
    ),
  ),
  TierDefinition(
    tier: 5,
    minPoints: 50000,
    readerIcon: '\u{1FA94}',
    authorIcon: '\u{1FA94}',
    readerGradient: LinearGradient(
      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFC62828), Color(0xFFEF9A9A)],
    ),
  ),
  TierDefinition(
    tier: 6,
    minPoints: 100000,
    readerIcon: '\u{1F451}',
    authorIcon: '\u{1F451}',
    readerGradient: LinearGradient(
      colors: [Color(0xFF283593), Color(0xFF7986CB)],
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFF9A6B00), Color(0xFFFFD700)],
    ),
  ),
  TierDefinition(
    tier: 7,
    minPoints: 500000,
    readerIcon: '\u{2B50}',
    authorIcon: '\u{2B50}',
    readerGradient: LinearGradient(
      colors: [Color(0xFF4A148C), Color(0xFFCE93D8)],
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFF880E4F), Color(0xFFF48FB1)],
    ),
  ),
  TierDefinition(
    tier: 8,
    minPoints: 1000000,
    readerIcon: '\u{1F3C6}',
    authorIcon: '\u{1F3C6}',
    readerGradient: LinearGradient(
      colors: [Color(0xFF7C4DFF), Color(0xFF00ACC1), Color(0xFF00A86B)],
    ),
    authorGradient: LinearGradient(
      colors: [Color(0xFFFF6D00), Color(0xFFFFC400), Color(0xFFD81B60)],
    ),
  ),
];

TierInfo tierInfoFor(int points, RankTrack track) {
  final safePoints = points < 0 ? 0 : points;
  var index = 0;
  for (var i = tierDefinitions.length - 1; i >= 0; i--) {
    if (safePoints >= tierDefinitions[i].minPoints) {
      index = i;
      break;
    }
  }
  final definition = tierDefinitions[index];
  final next = index + 1 < tierDefinitions.length
      ? tierDefinitions[index + 1]
      : null;
  final span = next == null ? 0 : next.minPoints - definition.minPoints;
  final progress = next == null
      ? 1.0
      : ((safePoints - definition.minPoints) / span).clamp(0.0, 1.0);
  return TierInfo(
    definition: definition,
    nextDefinition: next,
    track: track,
    points: safePoints,
    progressPercent: progress * 100,
    pointsToNext: next == null ? null : next.minPoints - safePoints,
  );
}

@Deprecated('Use tierInfoFor with RankTrack.')
TierInfo getTierInfo(int points, String category) =>
    tierInfoFor(points, RankTrack.fromValue(category));

String localizedTierTitle(BuildContext context, int tier, RankTrack track) {
  final l10n = AppLocalizations.of(context)!;
  final author = track == RankTrack.author;
  return switch (tier) {
    1 => author ? l10n.tier1AuthorTitle : l10n.tier1ReaderTitle,
    2 => author ? l10n.tier2AuthorTitle : l10n.tier2ReaderTitle,
    3 => author ? l10n.tier3AuthorTitle : l10n.tier3ReaderTitle,
    4 => author ? l10n.tier4AuthorTitle : l10n.tier4ReaderTitle,
    5 => author ? l10n.tier5AuthorTitle : l10n.tier5ReaderTitle,
    6 => author ? l10n.tier6AuthorTitle : l10n.tier6ReaderTitle,
    7 => author ? l10n.tier7AuthorTitle : l10n.tier7ReaderTitle,
    8 => author ? l10n.tier8AuthorTitle : l10n.tier8ReaderTitle,
    _ => '',
  };
}

@Deprecated('Use localizedTierTitle with RankTrack.')
String getLocalizedTierTitle(BuildContext context, int tier, String category) =>
    localizedTierTitle(context, tier, RankTrack.fromValue(category));

String formatRankPoints(BuildContext context, num points) =>
    NumberFormat.compact(
      locale: Localizations.localeOf(context).toLanguageTag(),
    ).format(points);

String formatRankPointsExact(BuildContext context, num points) =>
    NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(points);

String tierRangeLabel(BuildContext context, TierDefinition definition) {
  final index = tierDefinitions.indexOf(definition);
  final next = index >= 0 && index + 1 < tierDefinitions.length
      ? tierDefinitions[index + 1]
      : null;
  final start = formatRankPoints(context, definition.minPoints);
  return next == null
      ? '$start+'
      : '$start–${formatRankPoints(context, next.minPoints - 1)}';
}
