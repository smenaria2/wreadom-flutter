import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// A service that interacts directly with the Google Play Store to check
/// for available updates using the official Android Play Core library.
class PlayStoreUpdateService {
  PlayStoreUpdateService._();

  /// Checks if there is an update available on the Google Play Store.
  /// 
  /// Returns [AppUpdateInfo] if the check succeeds, or `null` if the check
  /// fails (e.g. during local development or on non-Android platforms).
  static Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      return updateInfo;
    } catch (e) {
      // In development or sideloaded builds, the Play Core API throws a PlatformException.
      // We catch it here to prevent app crashes and log it for diagnostics.
      debugPrint('PlayStoreUpdateService: Failed to check for Play Store update (expected in debug/sideloaded environment): $e');
      return null;
    }
  }
}
