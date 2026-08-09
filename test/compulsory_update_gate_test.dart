// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/play_store_update_service.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/providers/app_update_provider.dart';
import 'package:librebook_flutter/src/presentation/screens/compulsory_update_gate.dart';
import 'package:url_launcher_platform_interface/method_channel_url_launcher.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUpdateService extends PlayStoreUpdateService {
  bool immediateResult = true;
  int immediateCalls = 0;

  @override
  Future<bool> performImmediateUpdate() async {
    immediateCalls++;
    return immediateResult;
  }
}

class _FakeUrlLauncher extends MethodChannelUrlLauncher {
  String? launchedUrl;
  LaunchOptions? launchOptions;
  bool throwOnLaunch = false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (throwOnLaunch) throw StateError('Cannot launch');
    launchedUrl = url;
    launchOptions = options;
    return true;
  }
}

AppUpdateAvailability _availability({
  int priority = 5,
  bool immediateAllowed = true,
}) {
  return AppUpdateAvailability(
    config: const AppUpdateConfig(
      androidDownloadUrl:
          'https://play.google.com/store/apps/details?id=in.wreadom.app',
      androidBuildNumber: 12,
    ),
    installedBuildNumber: 10,
    updatePriority: priority,
    immediateUpdateAllowed: immediateAllowed,
  );
}

Widget _app({
  required Future<AppUpdateAvailability?> Function() update,
  required PlayStoreUpdateService service,
}) {
  return ProviderScope(
    overrides: [
      appUpdateAvailabilityProvider.overrideWith((ref) => update()),
      playStoreUpdateServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CompulsoryUpdateGate(
        isAndroidOverride: true,
        child: Scaffold(body: Text('Authenticated app')),
      ),
    ),
  );
}

void main() {
  late UrlLauncherPlatform originalUrlLauncher;
  late _FakeUrlLauncher fakeUrlLauncher;

  setUp(() {
    originalUrlLauncher = UrlLauncherPlatform.instance;
    fakeUrlLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeUrlLauncher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalUrlLauncher;
  });

  testWidgets('priority five blocks child and cannot be popped', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(update: () async => _availability(), service: _FakeUpdateService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update App'), findsOneWidget);
    expect(find.text('Authenticated app'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Update App'), findsOneWidget);
  });

  testWidgets('non compulsory and failed checks fail open', (tester) async {
    await tester.pumpWidget(
      _app(
        update: () async => _availability(priority: 0),
        service: _FakeUpdateService(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Authenticated app'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        update: () async => throw StateError('Play unavailable'),
        service: _FakeUpdateService(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Authenticated app'), findsOneWidget);
  });

  testWidgets('uses immediate update when Play allows it', (tester) async {
    final service = _FakeUpdateService();
    await tester.pumpWidget(
      _app(update: () async => _availability(), service: service),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(service.immediateCalls, 1);
    expect(fakeUrlLauncher.launchedUrl, isNull);
  });

  testWidgets('falls back to external Play Store link', (tester) async {
    final service = _FakeUpdateService()..immediateResult = false;
    await tester.pumpWidget(
      _app(update: () async => _availability(), service: service),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(service.immediateCalls, 1);
    expect(
      fakeUrlLauncher.launchedUrl,
      'https://play.google.com/store/apps/details?id=in.wreadom.app',
    );
    expect(
      fakeUrlLauncher.launchOptions?.mode,
      PreferredLaunchMode.externalApplication,
    );
  });

  testWidgets('launcher failure keeps compulsory screen usable', (
    tester,
  ) async {
    fakeUrlLauncher.throwOnLaunch = true;
    await tester.pumpWidget(
      _app(
        update: () async => _availability(immediateAllowed: false),
        service: _FakeUpdateService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Could not open update link.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
      isTrue,
    );
    expect(find.text('Update App'), findsOneWidget);
  });

  testWidgets('rechecks update availability when the app resumes', (
    tester,
  ) async {
    var checks = 0;
    await tester.pumpWidget(
      _app(
        update: () async {
          checks++;
          return checks == 1 ? _availability() : null;
        },
        service: _FakeUpdateService(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update App'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(checks, 2);
    expect(find.text('Authenticated app'), findsOneWidget);
  });
}
