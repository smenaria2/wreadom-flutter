import 'package:flutter/widgets.dart';

/// Height of the main navigation bar content (padding + item) at 1.0 text
/// scale, excluding the system gesture/navigation inset.
const double kMainNavigationBarBaseHeight = 76;
const double kMiniAudioPlayerClearance = 76;
const double kBottomContentExtraPadding = 32;

/// Space the floating main navigation bar occupies at the bottom of the
/// screen. Unlike a fixed number this follows the real system navigation inset
/// (gesture bar vs 3-button) and the user's font scale.
double mainNavigationBarClearance(BuildContext context) {
  final inset = MediaQuery.viewPaddingOf(context).bottom;
  final labelGrowth = (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(
    0.0,
    3.6,
  );
  return kMainNavigationBarBaseHeight + inset + labelGrowth;
}

/// Offset used to float the mini player directly above the navigation bar.
double miniPlayerBottomOffset(BuildContext context) =>
    mainNavigationBarClearance(context);

double bottomOverlayContentPadding(
  BuildContext context, {
  required bool miniPlayerVisible,
}) {
  return mainNavigationBarClearance(context) +
      kBottomContentExtraPadding +
      (miniPlayerVisible ? kMiniAudioPlayerClearance : 0);
}

double bottomOverlayFabPadding(
  BuildContext context, {
  required bool miniPlayerVisible,
}) {
  return mainNavigationBarClearance(context) +
      (miniPlayerVisible ? kMiniAudioPlayerClearance : 0);
}
