import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/providers/animation_settings_provider.dart';

class LowPowerNoticeService {
  static const String _keyNoticeShown = 'has_shown_low_power_notice_v1';
  static const String _keyUserPref = 'disable_animations_user_preference';

  /// Returns true if animations were auto-disabled for low-power device on first boot
  /// and notice has not been shown yet.
  static bool shouldShowNotice(SharedPreferences prefs) {
    if (prefs.getBool(_keyNoticeShown) ?? false) {
      return false;
    }
    // If user has explicitly configured preference, don't show auto-disable notice
    if (prefs.containsKey(_keyUserPref)) {
      return false;
    }
    // Check if auto-detection enabled disableAnimations by default
    return DisableAnimationsNotifier.isAnimationsDisabled(prefs);
  }

  static Future<void> markNoticeShown(SharedPreferences prefs) async {
    await prefs.setBool(_keyNoticeShown, true);
  }
}
