import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/routing/app_router.dart';

void main() {
  group('AppRouter', () {
    test('parses book deep link correctly', () {
      const settings = RouteSettings(name: 'https://wreadom.in/book/123');
      final route = AppRouter.onGenerateRoute(settings);
      
      expect(route, isA<MaterialPageRoute>());
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
      const settings = RouteSettings(name: 'https://wreadom.in/daily-topic?id=today');
      final route = AppRouter.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
    });

    test('parses category deep link correctly', () {
      const settings = RouteSettings(name: 'https://wreadom.in/category/Fantasy');
      final route = AppRouter.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
    });
  });
}
