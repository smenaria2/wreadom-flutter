import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/routing/app_router.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';

void main() {
  Future<void> pumpGeneratedRoute(
    WidgetTester tester,
    RouteSettings settings,
  ) async {
    final route = AppRouter.onGenerateRoute(settings);
    expect(route, isA<MaterialPageRoute>());
    final pageRoute = route as MaterialPageRoute;
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: pageRoute.builder)),
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
    });

    testWidgets('direct privacy route shows browser fallback screen', (
      tester,
    ) async {
      await pumpGeneratedRoute(
        tester,
        const RouteSettings(name: AppRoutes.privacy),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('direct terms route shows browser fallback screen', (
      tester,
    ) async {
      await pumpGeneratedRoute(
        tester,
        const RouteSettings(name: AppRoutes.terms),
      );

      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
