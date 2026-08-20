bool shouldShowStartupSplash({
  required Uri? initialAppLink,
  required bool hasInitialShare,
  bool hasInitialNotification = false,
  bool hasSeenSplash = false,
  bool disableAnimations = false,
}) =>
    initialAppLink == null &&
    !hasInitialShare &&
    !hasInitialNotification &&
    !hasSeenSplash &&
    !disableAnimations;

