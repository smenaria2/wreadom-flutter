import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/routing/web_route_settings.dart';
import 'package:librebook_flutter/src/presentation/screens/main_navigation_shell.dart';

void main() {
  group('bookDetailRouteSettings', () {
    test('names the route with a resolvable book link on web only', () {
      expect(
        bookDetailRouteSettings('abc123', isWeb: true).name,
        '/?book=abc123',
      );
      expect(bookDetailRouteSettings('a b', isWeb: true).name, '/?book=a+b');
    });

    test('keeps native routes unnamed so ids stay out of analytics', () {
      expect(bookDetailRouteSettings('abc123', isWeb: false).name, isNull);
      expect(bookDetailRouteSettings('', isWeb: true).name, isNull);
    });
  });

  group('web back guard wiring', () {
    test('shell and login only change behaviour behind webBackGuardEnabled', () {
      final shell = File(
        'lib/src/presentation/screens/main_navigation_shell.dart',
      ).readAsStringSync();
      final login = File(
        'lib/src/presentation/screens/login_screen.dart',
      ).readAsStringSync();
      expect(shell, contains('bool webBackGuardEnabled = kIsWeb;'));
      expect(
        shell,
        contains(
          'canPop: selectedIndex == 0 && (!webBackGuardEnabled || _exitArmed)',
        ),
      );
      expect(login, contains('canPop: _isLogin || !webBackGuardEnabled'));
    });

    test('analytics keeps web entity route names out of screen names', () {
      final analytics = File(
        'lib/src/data/services/analytics_service.dart',
      ).readAsStringSync();
      expect(analytics, contains("name.startsWith('/?')"));
    });

    testWidgets('second Back is required to leave when the guard is on', (
      tester,
    ) async {
      // A tiny harness with the same PopScope contract as the shell: first
      // Back is swallowed (and shows the hint), second Back pops.
      final original = webBackGuardEnabled;
      webBackGuardEnabled = true;
      addTearDown(() => webBackGuardEnabled = original);

      var armed = false;
      late StateSetter setHarnessState;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StatefulBuilder(
                          builder: (context, setState) {
                            setHarnessState = setState;
                            return PopScope(
                              canPop: !webBackGuardEnabled || armed,
                              onPopInvokedWithResult: (didPop, _) {
                                if (!didPop) setState(() => armed = true);
                              },
                              child: const Scaffold(body: Text('inner')),
                            );
                          },
                        ),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('inner'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.text('inner'),
        findsOneWidget,
        reason: 'first Back swallowed',
      );
      expect(armed, isTrue);
      setHarnessState(() {});

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('inner'), findsNothing, reason: 'second Back pops');
    });
  });
}
