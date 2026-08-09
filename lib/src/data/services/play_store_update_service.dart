import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class PlayStoreUpdateResult {
  const PlayStoreUpdateResult({
    required this.updateAvailable,
    this.availableVersionCode,
    this.updatePriority = 0,
    this.immediateUpdateAllowed = false,
  });

  final bool updateAvailable;
  final int? availableVersionCode;
  final int updatePriority;
  final bool immediateUpdateAllowed;
}

/// A service that interacts directly with the Google Play Store to check
/// for available updates using the official Android Play Core library.
class PlayStoreUpdateService {
  const PlayStoreUpdateService();

  /// Checks if there is an update available on the Google Play Store.
  ///
  /// Returns [PlayStoreUpdateResult] if the check succeeds, or `null` if the check
  /// fails (e.g. during local development or on non-Android platforms).
  Future<PlayStoreUpdateResult?> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      return PlayStoreUpdateResult(
        updateAvailable:
            updateInfo.updateAvailability == UpdateAvailability.updateAvailable,
        availableVersionCode: updateInfo.availableVersionCode,
        updatePriority: updateInfo.updatePriority,
        immediateUpdateAllowed: updateInfo.immediateUpdateAllowed,
      );
    } catch (e) {
      // In development or sideloaded builds, the Play Core API throws a PlatformException.
      // We catch it here to prevent app crashes and log it for diagnostics.
      debugPrint(
        'PlayStoreUpdateService: Failed to check for Play Store update '
        '(expected in debug/sideloaded environment): $e',
      );
      return null;
    }
  }

  /// Starts Google Play's full-screen immediate update flow.
  ///
  /// Returns `true` only when Play reports that the update completed. A denied
  /// or failed update returns `false` so callers can fall back to the Store.
  Future<bool> performImmediateUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final result = await InAppUpdate.performImmediateUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      debugPrint(
        'PlayStoreUpdateService: Immediate update could not start: $e',
      );
      return false;
    }
  }
}
