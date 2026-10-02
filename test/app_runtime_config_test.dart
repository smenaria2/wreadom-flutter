import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/app_runtime_config.dart';

void main() {
  AppRuntimeBlock blockFor(
    Map<String, dynamic>? data, {
    int build = 100,
    bool android = true,
    bool web = false,
    bool admin = false,
  }) => appRuntimeBlockFor(
    config: AppRuntimeConfig.fromMap(data),
    installedBuild: build,
    isAndroid: android,
    isWeb: web,
    isAdmin: admin,
  );

  test('a missing document never blocks', () {
    expect(blockFor(null), AppRuntimeBlock.none);
    expect(blockFor({}), AppRuntimeBlock.none);
  });

  test('maintenance blocks users but lets admins through', () {
    expect(blockFor({'maintenance': true}), AppRuntimeBlock.maintenance);
    expect(
      blockFor({'maintenance': true}, admin: true),
      AppRuntimeBlock.none,
    );
  });

  test('an outdated build must update, even for admins', () {
    expect(
      blockFor({'minAndroidBuild': 200}, admin: true),
      AppRuntimeBlock.updateRequired,
    );
    expect(blockFor({'minAndroidBuild': 100}), AppRuntimeBlock.none);
    expect(blockFor({'minAndroidBuild': '200'}), AppRuntimeBlock.updateRequired);
  });

  test('each platform uses its own minimum', () {
    expect(
      blockFor({'minAndroidBuild': 200}, android: false, web: true),
      AppRuntimeBlock.none,
    );
    expect(
      blockFor({'minFlutterWebBuild': 200}, android: false, web: true),
      AppRuntimeBlock.updateRequired,
    );
  });

  test('an unknown installed build is not blocked', () {
    expect(blockFor({'minAndroidBuild': 200}, build: 0), AppRuntimeBlock.none);
  });
}
