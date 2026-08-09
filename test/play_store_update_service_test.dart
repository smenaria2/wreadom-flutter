import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/play_store_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('de.ffuf.in_app_update/methods');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps Play Core priority and immediate update support', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'checkForUpdate');
          return <String, Object?>{
            'updateAvailability': 2,
            'immediateAllowed': true,
            'immediateAllowedPreconditions': <int>[],
            'flexibleAllowed': true,
            'flexibleAllowedPreconditions': <int>[],
            'availableVersionCode': 42,
            'installStatus': 0,
            'packageName': 'in.wreadom.app',
            'clientVersionStalenessDays': 1,
            'updatePriority': 5,
          };
        });

    final result = await const PlayStoreUpdateService().checkForUpdate();

    expect(result, isNotNull);
    expect(result!.updateAvailable, isTrue);
    expect(result.availableVersionCode, 42);
    expect(result.updatePriority, 5);
    expect(result.immediateUpdateAllowed, isTrue);
  });

  test('reports immediate update success and denial', () async {
    var denied = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'performImmediateUpdate');
          if (denied) {
            throw PlatformException(code: 'USER_DENIED_UPDATE');
          }
          return null;
        });

    final service = const PlayStoreUpdateService();
    expect(await service.performImmediateUpdate(), isTrue);

    denied = true;
    expect(await service.performImmediateUpdate(), isFalse);
  });
}
