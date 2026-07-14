bool shouldShowStartupSplash({
  required Uri? initialAppLink,
  required bool hasInitialShare,
}) => initialAppLink == null && !hasInitialShare;
