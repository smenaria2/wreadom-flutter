import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/utils/app_link_helper.dart';

void main() {
  test('builds canonical singular collection URL', () {
    expect(
      AppLinkHelper.collection('a b'),
      'https://wreadom.in/collection/a%20b',
    );
  });

  for (final path in ['/collection/abc', '/collections/abc']) {
    test('resolves $path', () {
      final result = AppLinkHelper.resolve(path);
      expect(result?.route, AppRoutes.collectionDetail);
      expect(result?.payload, 'abc');
    });
  }

  test('rejects collection path without id', () {
    expect(AppLinkHelper.resolve('/collection'), isNull);
  });
}
