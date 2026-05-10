import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  final snapshot = await FirebaseFirestore.instance
      .collection('settings')
      .doc('app_update')
      .get();
  final config = AppUpdateConfig.fromMap(snapshot.data());
  if (config == null) return null;

  final availability = AppUpdateAvailability(
    config: config,
    installedBuildNumber: installedBuildNumber,
  );
  return availability.isUpdateAvailable ? availability : null;
});
