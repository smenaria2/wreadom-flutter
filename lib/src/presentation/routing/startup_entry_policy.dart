bool shouldShowStartupSplash({
  required Uri? initialAppLink,
  required bool hasInitialShare,
  bool hasSeenSplash = false,
  bool disableAnimations = false,
}) =>
    initialAppLink == null &&
    !hasInitialShare &&
    !hasSeenSplash &&
    !disableAnimations;

