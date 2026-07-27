import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/screens/reader_screen.dart';

void main() {
  Widget app(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('chapter progress details clamp chapter and percent values', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const ReaderChapterProgressDetails(
          currentChapterNumber: 9,
          totalChapters: 3,
          progress: 1.4,
          color: Colors.grey,
        ),
      ),
    );

    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.pumpWidget(
      app(
        const ReaderChapterProgressDetails(
          currentChapterNumber: 0,
          totalChapters: 0,
          progress: -0.2,
          color: Colors.grey,
        ),
      ),
    );

    expect(find.text('0/0'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(readerProgressPercent(double.nan), 0);
  });

  testWidgets('chapter word count uses localized HTML-derived text', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const ReaderChapterWordCount(
          content: '<p>One <strong>two</strong> three</p>',
          color: Colors.grey,
        ),
      ),
    );

    expect(find.text('3 words'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reader-chapter-word-count')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
