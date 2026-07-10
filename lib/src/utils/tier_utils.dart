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
    required this.mainColor,
    required this.lightColor,
  });

  final int tier;
  final int minPoints;
  final String readerIcon;
  final String authorIcon;
  final Color mainColor;
  final Color lightColor;

  LinearGradient gradientFor(RankTrack track) => LinearGradient(
    colors: [mainColor, Color.lerp(mainColor, lightColor, 0.55)!],
  );

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
    mainColor: Color(0xFF22C55E),
    lightColor: Color(0xFFDCFCE7),
  ),
  TierDefinition(
    tier: 2,
    minPoints: 500,
    readerIcon: '\u{1F4D6}',
    authorIcon: '\u{270D}\u{FE0F}',
    mainColor: Color(0xFF14B8A6),
    lightColor: Color(0xFFCCFBF1),
  ),
  TierDefinition(
    tier: 3,
    minPoints: 5000,
    readerIcon: '\u{1F647}\u{200D}\u{2642}\u{FE0F}',
    authorIcon: '\u{2712}\u{FE0F}',
    mainColor: Color(0xFF0EA5E9),
    lightColor: Color(0xFFE0F2FE),
  ),
  TierDefinition(
    tier: 4,
    minPoints: 25000,
    readerIcon: '\u{1F60D}',
    authorIcon: '\u{1F4DC}',
    mainColor: Color(0xFF8B5CF6),
    lightColor: Color(0xFFEDE9FE),
  ),
  TierDefinition(
    tier: 5,
    minPoints: 50000,
    readerIcon: '\u{1FA94}',
    authorIcon: '\u{1FA94}',
    mainColor: Color(0xFFF59E0B),
    lightColor: Color(0xFFFEF3C7),
  ),
  TierDefinition(
    tier: 6,
    minPoints: 100000,
    readerIcon: '\u{1F451}',
    authorIcon: '\u{1F451}',
    mainColor: Color(0xFFF97316),
    lightColor: Color(0xFFFFEDD5),
  ),
  TierDefinition(
    tier: 7,
    minPoints: 500000,
    readerIcon: '\u{2B50}',
    authorIcon: '\u{2B50}',
    mainColor: Color(0xFF4F46E5),
    lightColor: Color(0xFFE0E7FF),
  ),
  TierDefinition(
    tier: 8,
    minPoints: 1000000,
    readerIcon: '\u{1F3C6}',
    authorIcon: '\u{1F3C6}',
    mainColor: Color(0xFFD4AF37),
    lightColor: Color(0xFFFFF7D6),
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
