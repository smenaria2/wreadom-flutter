const double kMainNavigationBarClearance = 86;
const double kMiniAudioPlayerClearance = 76;
const double kBottomContentExtraPadding = 32;

const double kBottomNavigationContentPadding =
    kMainNavigationBarClearance + kBottomContentExtraPadding;

const double kMiniPlayerBottomOffset = kMainNavigationBarClearance;

double bottomOverlayContentPadding({required bool miniPlayerVisible}) {
  return kBottomNavigationContentPadding +
      (miniPlayerVisible ? kMiniAudioPlayerClearance : 0);
}

double bottomOverlayFabPadding({required bool miniPlayerVisible}) {
  return kMainNavigationBarClearance +
      (miniPlayerVisible ? kMiniAudioPlayerClearance : 0);
}
