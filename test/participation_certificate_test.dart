import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/book/participation_certificate.dart';

void main() {
  Widget certificateApp(Locale locale) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FittedBox(
          child: ParticipationCertificate(
            userName: '',
            userPhotoUrl: null,
            topicName: locale.languageCode == 'hi'
                ? 'दैनिक लेखन विषय'
                : 'Daily writing topic',
            date: formatCertificateDateFromMillis(
              DateTime(2026, 6, 22).millisecondsSinceEpoch,
              locale: locale,
            ),
          ),
        ),
      ),
    );
  }

  test('certificate date uses English and Hindi month names', () {
    final timestamp = DateTime(2026, 6, 22).millisecondsSinceEpoch;

    expect(
      formatCertificateDateFromMillis(timestamp, locale: const Locale('en')),
      '22 June 2026',
    );
    expect(
      formatCertificateDateFromMillis(timestamp, locale: const Locale('hi')),
      '22 जून 2026',
    );
  });

  testWidgets('certificate artwork is English for English app locale', (
    tester,
  ) async {
    await tester.pumpWidget(certificateApp(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('CERTIFICATE'), findsOneWidget);
    expect(find.text('OF PARTICIPATION'), findsOneWidget);
    expect(find.text('This is to certify that'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('has successfully participated in the'), findsOneWidget);
    expect(find.text('22 June 2026'), findsOneWidget);
    expect(find.text('AGAAZ ADMIN'), findsOneWidget);
    expect(find.text('WREADOM ADMIN'), findsOneWidget);
  });

  testWidgets('certificate artwork is Hindi for Hindi app locale', (
    tester,
  ) async {
    await tester.pumpWidget(certificateApp(const Locale('hi')));
    await tester.pumpAndSettle();

    expect(find.text('प्रमाणपत्र'), findsOneWidget);
    expect(find.text('भागीदारी का'), findsOneWidget);
    expect(find.text('यह प्रमाणित किया जाता है कि'), findsOneWidget);
    expect(find.text('उपयोगकर्ता'), findsOneWidget);
    expect(find.text('ने सफलतापूर्वक भाग लिया'), findsOneWidget);
    expect(find.text('22 जून 2026'), findsOneWidget);
    expect(find.text('आगाज़ व्यवस्थापक'), findsOneWidget);
    expect(find.text('रीडम व्यवस्थापक'), findsOneWidget);
    expect(find.text('CERTIFICATE'), findsNothing);
    expect(find.text('OF PARTICIPATION'), findsNothing);
  });
}
