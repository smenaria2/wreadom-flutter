import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appHapticsEnabledKey = 'app_haptics_enabled';

class AppHaptics {
  const AppHaptics._();

  static const MethodChannel _channel = MethodChannel('in.wreadom.app/haptics');
  static bool _enabled = true;

  static bool get enabled => _enabled;

  static Future<void> init(SharedPreferences prefs) async {
    _enabled = prefs.getBool(appHapticsEnabledKey) ?? true;
  }

  static Future<void> setEnabled(
    bool enabled, {
    SharedPreferences? preferences,
  }) async {
    _enabled = enabled;
    await preferences?.setBool(appHapticsEnabledKey, enabled);
  }

  static Future<void> selection() {
    return _safe('selection', HapticFeedback.selectionClick);
  }

  static Future<void> light() {
    return _safe('light', HapticFeedback.lightImpact);
  }

  static Future<void> medium() {
    return _safe('medium', HapticFeedback.mediumImpact);
  }

  static Future<void> _safe(
    String type,
    Future<void> Function() fallback,
  ) async {
    if (!_enabled) return;
    try {
      await _channel.invokeMethod<void>('impact', {'type': type});
      return;
    } catch (_) {
      try {
        await fallback();
      } catch (_) {
        // Haptics are best-effort and may be unavailable on some devices.
      }
    }
  }
}
