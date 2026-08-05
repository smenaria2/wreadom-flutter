import 'package:shared_preferences/shared_preferences.dart';

class SplashPreferencesService {
  static const String _keyHasSeenSplash = 'has_seen_startup_splash_v1';

  static bool hasSeenSplash(SharedPreferences prefs) {
    return prefs.getBool(_keyHasSeenSplash) ?? false;
  }

  static Future<void> markSplashSeen(SharedPreferences prefs) async {
    await prefs.setBool(_keyHasSeenSplash, true);
  }
}
