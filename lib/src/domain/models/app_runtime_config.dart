/// Server-controlled switches read from `settings/app_runtime`, shared by the
/// Android, Flutter web and React web apps.
class AppRuntimeConfig {
  const AppRuntimeConfig({
    this.maintenance = false,
    this.maintenanceMessage = '',
    this.minAndroidBuild = 0,
    this.minFlutterWebBuild = 0,
  });

  /// Blocks every non-admin user while data is being migrated.
  final bool maintenance;
  final String maintenanceMessage;

  /// Builds below these numbers must update before continuing.
  final int minAndroidBuild;
  final int minFlutterWebBuild;

  static const none = AppRuntimeConfig();

  factory AppRuntimeConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return none;
    return AppRuntimeConfig(
      maintenance: data['maintenance'] == true,
      maintenanceMessage: data['maintenanceMessage'] is String
          ? (data['maintenanceMessage'] as String).trim()
          : '',
      minAndroidBuild: _asInt(data['minAndroidBuild']),
      minFlutterWebBuild: _asInt(data['minFlutterWebBuild']),
    );
  }

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

enum AppRuntimeBlock { none, maintenance, updateRequired }

/// Decides whether the app may be used. An outdated build is always blocked;
/// admins pass maintenance so they can check the app during a cutover.
AppRuntimeBlock appRuntimeBlockFor({
  required AppRuntimeConfig config,
  required int installedBuild,
  required bool isAndroid,
  required bool isWeb,
  required bool isAdmin,
}) {
  final minimum = isAndroid
      ? config.minAndroidBuild
      : isWeb
      ? config.minFlutterWebBuild
      : 0;
  if (minimum > 0 && installedBuild > 0 && installedBuild < minimum) {
    return AppRuntimeBlock.updateRequired;
  }
  if (config.maintenance && !isAdmin) return AppRuntimeBlock.maintenance;
  return AppRuntimeBlock.none;
}
