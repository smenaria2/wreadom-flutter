import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/legal_document_service.dart';
import 'package:librebook_flutter/src/presentation/routing/app_router.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/presentation/screens/daily_topic_screen.dart';
import 'package:librebook_flutter/src/presentation/routing/writer_pad_mode.dart';

void main() {
  Future<void> pumpGeneratedRoute(
    WidgetTester tester,
    RouteSettings settings,
  ) async {
    final route = AppRouter.onGenerateRoute(settings);
    expect(route, isA<MaterialPageRoute>());
    final pageRoute = route as MaterialPageRoute;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legalDocumentServiceProvider.overrideWithValue(
            _FakeLegalDocumentService(),
          ),
        ],
        child: MaterialApp(home: Builder(builder: pageRoute.builder)),
      ),
    );
  }

  group('AppRouter', () {
    test('parses book deep link correctly', () {
      const settings = RouteSettings(name: 'https://wreadom.in/book/123');
      final route = AppRouter.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
    });

    test('converts chapter links to typed book detail arguments', () {
      final settings = AppRouter.routeSettingsForAppLink(
        'https://wreadom.in/?book=book123&mode=read&chapter=3',
      );

      expect(settings?.name, AppRoutes.bookDetail);
      final args = settings?.arguments;
      expect(args, isA<BookDetailArguments>());
      expect((args as BookDetailArguments).bookId, 'book123');
      expect(args.initialReaderChapterIndex, 2);
    });

    test('converts prefilled create-post links to typed arguments', () {
      final settings = AppRouter.routeSettingsForAppLink(
        'https://wreadom.in/create-post?text=%E0%A4%95%E0%A4%B9%E0%A4%BE%E0%A4%A8%E0%A5%80',
      );

      expect(settings?.name, AppRoutes.createPost);
      expect(settings?.arguments, isA<CreatePostArguments>());
      expect(
        (settings!.arguments as CreatePostArguments).initialText,
        '\u{0915}\u{0939}\u{093E}\u{0928}\u{0940}',
      );
    });

    test('converts question links to stable typed identifiers', () {
      final settings = AppRouter.routeSettingsForAppLink(
        'https://wreadom.in/questions?book=book-1&leaf=leaf-2',
      );

      expect(settings?.name, AppRoutes.questionAnswers);
      expect(settings?.arguments, isA<QuestionAnswersLinkArguments>());
      final args = settings!.arguments as QuestionAnswersLinkArguments;
      expect(args.bookId, 'book-1');
      expect(args.leafId, 'leaf-2');
    });

    test('safe app-page links produce their route settings', () {
      expect(
        AppRouter.routeSettingsForAppLink('https://wreadom.in/help')?.name,
        AppRoutes.help,
      );
      expect(
        AppRouter.routeSettingsForAppLink('/leaderboard')?.name,
        AppRoutes.leaderboard,
      );
    });
    test('parses user deep link correctly', () {
      const settings = RouteSettings(name: 'https://wreadom.in/user/456');
      final route = AppRouter.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
    });

    test('parses feed deep link correctly', () {
      const settings = RouteSettings(name: 'https://wreadom.in/p/789');
      final route = AppRouter.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
    });

    test('parses daily topic deep link correctly', () {
      const settings = RouteSettings(
        name: 'https://wreadom.in/daily-topic?id=today',
      );
      final route = AppRouter.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
    });

    test('preserves shared image create-post route arguments', () {
      const arguments = CreatePostArguments(initialImagePath: '/tmp/photo.jpg');
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.createPost, arguments: arguments),
      );

      expect(route, isA<MaterialPageRoute>());
      expect(route.settings.arguments, same(arguments));
    });

    test('preserves shared text writer-pad route arguments', () {
      const arguments = WriterPadArguments(initialText: 'Shared text');
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.writerPad, arguments: arguments),
      );

      expect(route, isA<MaterialPageRoute>());
      expect(route.settings.arguments, same(arguments));
    });

    test('preserves daily topic arguments for in-app navigation', () {
      const arguments = DailyTopicArguments(topicId: 'older-topic');
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.dailyTopic, arguments: arguments),
      );

      expect(route.settings.arguments, same(arguments));
    });

    test('preserves daily topic id from notification navigation', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: AppRoutes.dailyTopic,
          arguments: 'topic-from-notification',
        ),
      );

      expect(route.settings.arguments, 'topic-from-notification');
    });

    test('parses category deep link correctly', () {
      const settings = RouteSettings(
        name: 'https://wreadom.in/category/Fantasy',
      );
      final route = AppRouter.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
    });

    test('parses fragment deep link correctly', () {
      const settings = RouteSettings(name: 'https://wreadom.in/#/book/123');
      final route = AppRouter.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
    });

    test('handles malformed and relative query links safely', () {
      for (final name in [
        '/?page=feed&post=abc123',
        'https://wreadom.in/page=feed&post=abc123',
        'https://wreadom.in/feed?post=abc123',
      ]) {
        final route = AppRouter.onGenerateRoute(RouteSettings(name: name));

        expect(route, isA<MaterialPageRoute>());
      }
    });

    testWidgets('rejects missing public profile route arguments', (
      tester,
    ) async {
      await pumpGeneratedRoute(
        tester,
        const RouteSettings(name: AppRoutes.publicProfile),
      );

      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.text('Profile details are missing.'), findsOneWidget);
    });

    testWidgets('rejects missing category route arguments', (tester) async {
      await pumpGeneratedRoute(
        tester,
        const RouteSettings(name: AppRoutes.category),
      );

      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.text('Category details are missing.'), findsOneWidget);
      expect(find.text('Open in in-app browser'), findsNothing);
    });

    testWidgets('unsupported Wreadom web links can be opened in-app', (
      tester,
    ) async {
      await pumpGeneratedRoute(
        tester,
        const RouteSettings(
          name: 'https://wreadom.in/?page=profile&tab=achievements',
        ),
      );

      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.text('Open in in-app browser'), findsOneWidget);
    });

    testWidgets('unsupported Wreadom app links use explicit not found route', (
      tester,
    ) async {
      final settings = AppRouter.notFoundRouteSettingsForAppLink(
        'https://wreadom.in/?page=profile&tab=achievements',
      );

      expect(settings?.name, AppRoutes.notFound);
      expect(settings?.arguments, isA<NotFoundArguments>());

      await pumpGeneratedRoute(tester, settings!);

      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.text('Open in in-app browser'), findsOneWidget);
    });

    test('does not create not found routes for external links', () {
      final settings = AppRouter.notFoundRouteSettingsForAppLink(
        'https://example.com/missing',
      );

      expect(settings, isNull);
    });

    testWidgets('direct privacy route opens in-app legal browser', (
      tester,
    ) async {
      await pumpGeneratedRoute(
        tester,
        const RouteSettings(name: AppRoutes.privacy),
      );
      await tester.pump();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('direct terms route opens in-app legal browser', (
      tester,
    ) async {
      await pumpGeneratedRoute(
        tester,
        const RouteSettings(name: AppRoutes.terms),
      );
      await tester.pump();

      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('intercepted browser legal links open in-app legal browser', (
      tester,
    ) async {
      await pumpGeneratedRoute(
        tester,
        const RouteSettings(name: 'https://wreadom.in/privacy'),
      );
      await tester.pump();

      expect(find.text('Privacy Policy'), findsOneWidget);

      await pumpGeneratedRoute(
        tester,
        const RouteSettings(name: 'https://wreadom.in/terms'),
      );
      await tester.pump();

      expect(find.text('Terms of Use'), findsOneWidget);
    });
  });
}

class _FakeLegalDocumentService implements LegalDocumentService {
  @override
  Duration get timeout => const Duration(seconds: 1);

  @override
  Future<LegalDocument> fetch(String url, {required String title}) async {
    return LegalDocument(
      html: '<h1>$title</h1><p>Sanitized legal content</p>',
      sourceUrl: url,
      isFallback: false,
    );
  }
}
