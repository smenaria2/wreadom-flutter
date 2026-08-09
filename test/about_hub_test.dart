import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';
import 'package:librebook_flutter/src/presentation/providers/theme_provider.dart';
import 'package:librebook_flutter/src/presentation/routing/app_router.dart';
import 'package:librebook_flutter/src/presentation/screens/about_hub_screen.dart';
import 'package:librebook_flutter/src/presentation/screens/attributions_screen.dart';
import 'package:librebook_flutter/src/presentation/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _mockPrefs;

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
  List<dynamic> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_mockPrefs),
      for (final o in overrides) o,
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _mockPrefs = await SharedPreferences.getInstance();
  });

  final testUser = UserModel(
    id: 'user-123',
    username: 'testuser',
    email: 'test@example.com',
    displayName: 'Test User',
    readingHistory: const [],
    savedBooks: const [],
    bookmarks: const [],
  );

  group('Profile Drawer About Item Tests', () {
    testWidgets(
      'profile drawer contains one About item and no Legal section or direct policy items',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  child: const Text('Open'),
                ),
              ),
              drawer: const ProfileSideMenu(),
            ),
            overrides: [
              currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Verify Legal section label and direct policy titles are gone from drawer
        expect(find.text('Legal'), findsNothing);
        expect(find.text('Terms of Use'), findsNothing);
        expect(find.text('Privacy Policy'), findsNothing);

        // The drawer list is lazy; scroll until the lower Support items exist.
        await tester.scrollUntilVisible(
          find.text('About'),
          240,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('About'), findsOneWidget);
      },
    );
  });

  group('About Hub Structure & Content Tests', () {
    testWidgets(
      'renders Wreadom logo, description, creator link, and 3 hub tiles',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(child: const AboutHubScreen()));
        await tester.pumpAndSettle();

        // Check Wreadom image logo exists
        expect(find.byType(Image), findsOneWidget);

        // Check description text
        expect(
          find.text(
            'Read classic books and original stories, discover independent writers, and publish your own work.',
          ),
          findsOneWidget,
        );

        // Check creator link text
        expect(find.text('Proudly created by Sumit Menaria'), findsOneWidget);

        // Check the 3 hub tiles below it
        final listTiles = find.byType(ListTile);
        expect(listTiles, findsNWidgets(3));

        final tile1 = tester.widget<ListTile>(listTiles.at(0));
        final tile2 = tester.widget<ListTile>(listTiles.at(1));
        final tile3 = tester.widget<ListTile>(listTiles.at(2));

        expect((tile1.title as Text).data, 'Terms of Use');
        expect((tile2.title as Text).data, 'Privacy Policy');
        expect((tile3.title as Text).data, 'Attributions');
      },
    );

    testWidgets('tapping Attributions navigates to AttributionsScreen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(child: const AboutHubScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Attributions'));
      await tester.pumpAndSettle();

      expect(find.byType(AttributionsScreen), findsOneWidget);
    });
  });

  group('About Localization Tests', () {
    testWidgets('renders English body and creator text correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const AboutHubScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Read classic books and original stories, discover independent writers, and publish your own work.',
        ),
        findsOneWidget,
      );
      expect(find.text('Proudly created by Sumit Menaria'), findsOneWidget);
    });

    testWidgets('renders Hindi body and creator text correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const AboutHubScreen(),
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'क्लासिक पुस्तकें और मौलिक कहानियाँ पढ़ें, स्वतंत्र लेखकों की खोज करें, और अपनी रचनाएँ प्रकाशित करें।',
        ),
        findsOneWidget,
      );
      expect(find.text('सुमित मेनारिया द्वारा सृजित'), findsOneWidget);
    });
  });

  group('Attributions Screen Tests', () {
    testWidgets('renders all curated entries and open-source software row', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(child: const AttributionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Dictionary & Word Definitions'), findsOneWidget);
      expect(find.text('Hindi Transliteration Dataset'), findsOneWidget);
      expect(find.text('Devlipi Transliteration Engine'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Typography & Typefaces'), findsOneWidget);
      expect(find.text('Media & Content Discovery'), findsOneWidget);
      expect(find.text('Open-source software licenses'), findsOneWidget);
    });

    testWidgets('tapping Open-source software licenses opens LicensePage', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(child: const AttributionsScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open-source software licenses'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
