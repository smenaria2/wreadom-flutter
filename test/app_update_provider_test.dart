import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/play_store_update_service.dart';
import 'package:librebook_flutter/src/presentation/providers/app_update_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Wreadom',
      packageName: 'in.wreadom.app',
      version: '1.0.0',
      buildNumber: '10',
      buildSignature: '',
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'returns update availability when Android Play version is newer',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final container = _containerWith(_FakeUpdateService(versionCode: 12));
      addTearDown(container.dispose);

      final availability = await container.read(
        appUpdateAvailabilityProvider.future,
      );

      expect(availability, isNotNull);
      expect(availability!.installedBuildNumber, 10);
      expect(availability.config.androidBuildNumber, 12);
      expect(
        availability.config.androidDownloadUrl,
        'https://play.google.com/store/apps/details?id=in.wreadom.app',
      );
    },
  );

  test('returns null when available Android build is not newer', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final container = _containerWith(_FakeUpdateService(versionCode: 10));
    addTearDown(container.dispose);

    expect(await container.read(appUpdateAvailabilityProvider.future), isNull);
  });

  test('returns null on non Android platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final container = _containerWith(_FakeUpdateService(versionCode: 99));
    addTearDown(container.dispose);

    expect(await container.read(appUpdateAvailabilityProvider.future), isNull);
  });

  test('returns null when Play update check throws', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final container = _containerWith(_ThrowingUpdateService());
    addTearDown(container.dispose);

    expect(await container.read(appUpdateAvailabilityProvider.future), isNull);
  });
}

ProviderContainer _containerWith(PlayStoreUpdateService service) {
  return ProviderContainer(
    overrides: [playStoreUpdateServiceProvider.overrideWithValue(service)],
  );
}

class _FakeUpdateService extends PlayStoreUpdateService {
  const _FakeUpdateService({required this.versionCode});

  final int versionCode;

  @override
  Future<PlayStoreUpdateResult?> checkForUpdate() async {
    return PlayStoreUpdateResult(
      updateAvailable: true,
      availableVersionCode: versionCode,
    );
  }
}

class _ThrowingUpdateService extends PlayStoreUpdateService {
  @override
  Future<PlayStoreUpdateResult?> checkForUpdate() async {
    throw StateError('Play Core failed');
  }
}
