import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author_support.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/support/support_author_sheet.dart';
import 'package:librebook_flutter/src/utils/upi_launcher.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

const _support = AuthorSupport(
  authorId: 'author-1',
  upiId: 'writer@okbank',
  enabled: true,
);

void main() {
  testWidgets('support sheet is a stepped flow with a close button', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Clipboard.setData(const ClipboardData(text: ''));

    await tester.pumpWidget(
      _host(
        const SupportAuthorSheet(
          authorId: 'author-1',
          authorName: 'Writer',
          support: _support,
        ),
      ),
    );

    // Step 1: amount only. No pay options, no "I've paid".
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Pay with UPI app'), findsNothing);
    expect(find.text("I've paid"), findsNothing);
    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    // A preset chip fills the amount field and enables Continue.
    await tester.tap(find.text('₹50'));
    await tester.pump();
    expect(find.widgetWithText(TextField, '50'), findsOneWidget);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

    // Step 2: pay options, UPI id is never shown as text, no "I've paid" yet.
    await tester.tap(continueButton);
    await tester.pump();
    expect(find.text('Pay with UPI app'), findsOneWidget);
    expect(find.text('Show QR code'), findsOneWidget);
    expect(find.text('Copy UPI ID'), findsOneWidget);
    expect(find.textContaining('writer@okbank'), findsNothing);
    expect(find.text("I've paid"), findsNothing);

    // Using an option (here: QR) reveals "I've paid".
    await tester.tap(find.text('Show QR code'));
    await tester.pump();
    expect(find.text("I've paid"), findsOneWidget);
    expect(find.textContaining('writer@okbank'), findsNothing);
  });

  test('UpiLauncher on non-web reports noApp when launching fails', () async {
    final original = UpiLauncher.launch;
    addTearDown(() => UpiLauncher.launch = original);
    UpiLauncher.launch = (uri, {webWindowName}) async => false;
    final result = await UpiLauncher.pay('upi://pay?pa=a@b');
    expect(result, UpiLaunchResult.noApp);
  });
}
