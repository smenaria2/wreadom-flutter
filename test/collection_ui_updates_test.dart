import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/book_collection.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/components/collections/collection_form_sheet.dart';

void main() {
  testWidgets('editing a collection exposes title and description fields', (
    tester,
  ) async {
    const collection = BookCollection(
      id: 'collection-1',
      ownerId: 'author-1',
      title: 'Selected works',
      description: 'A description',
      bookCount: 2,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CollectionFormSheet(collection: collection)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit collection'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Collection name'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Description (optional)'),
      findsOneWidget,
    );
    expect(find.text('Selected works'), findsOneWidget);
    expect(find.text('A description'), findsOneWidget);
  });

  test(
    'collection book counts are localized with singular and plural',
    () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));

      expect(en.collectionBookCount(1), '1 book');
      expect(en.collectionBookCount(2), '2 books');
      expect(hi.collectionBookCount(1), '1 पुस्तक');
      expect(hi.collectionBookCount(2), '2 पुस्तकें');
    },
  );

  test('collection detail keeps only the title edit affordance', () {
    final source = File(
      'lib/src/presentation/screens/collection_detail_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('Stories inside collection')));
    expect(source, isNot(contains('Content inside collection')));
    expect(source, isNot(contains('Add a description...')));
    expect('Icons.edit_outlined'.allMatches(source), hasLength(1));
    expect(source, contains('tooltip: l10n.addBooks'));
    expect(source, contains('tooltip: l10n.shareCollection'));
  });

  test('author works separator is conditional on real collections', () {
    final source = File(
      'lib/src/presentation/components/profile/user_content_tab.dart',
    ).readAsStringSync();

    expect(source, contains('maybeWhen(data: (items) => items.isNotEmpty'));
    expect(source, contains('if (hasCollections)'));
    expect(source, contains('l10n.authorsWorks'));

    final publicSource = File(
      'lib/src/presentation/screens/public_profile_screen.dart',
    ).readAsStringSync();
    expect(publicSource, contains('if (hasCollections)'));
    expect(publicSource, contains('l10n.authorsWorks'));
  });
}
