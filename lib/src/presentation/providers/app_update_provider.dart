import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import '../../data/services/play_store_update_service.dart';

class AppUpdateConfig {
  const AppUpdateConfig({
    required this.androidDownloadUrl,
    required this.androidBuildNumber,
    this.updatedAt,
  });

  final String androidDownloadUrl;
  final int androidBuildNumber;
  final int? updatedAt;

  static AppUpdateConfig? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final url = (data['androidDownloadUrl'] as String?)?.trim() ?? '';
    final buildNumber = _asInt(data['androidBuildNumber']);
    if (url.isEmpty || buildNumber == null) return null;
    return AppUpdateConfig(
      androidDownloadUrl: url,
      androidBuildNumber: buildNumber,
      updatedAt: _asInt(data['updatedAt']),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class AppUpdateAvailability {
  const AppUpdateAvailability({
    required this.config,
    required this.installedBuildNumber,
  });

  final AppUpdateConfig config;
  final int installedBuildNumber;

  bool get isUpdateAvailable =>
      config.androidBuildNumber > installedBuildNumber;
}

final appUpdateAvailabilityProvider = FutureProvider<AppUpdateAvailability?>((
  ref,
) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return null;
  }

  final packageInfo = await PackageInfo.fromPlatform();
  final installedBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

  final updateInfo = await PlayStoreUpdateService.checkForUpdate();
  if (updateInfo == null) return null;

  if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
    final availableVersion = updateInfo.availableVersionCode;
    if (availableVersion == null) return null;

    final config = AppUpdateConfig(
      androidDownloadUrl: 'https://play.google.com/store/apps/details?id=${packageInfo.packageName}',
      androidBuildNumber: availableVersion,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final availability = AppUpdateAvailability(
      config: config,
      installedBuildNumber: installedBuildNumber,
    );
    return availability.isUpdateAvailable ? availability : null;
  }

  return null;
});
