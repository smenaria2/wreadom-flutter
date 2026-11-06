import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Route settings for a book detail screen opened with a plain
/// `MaterialPageRoute`.
///
/// On the web the Navigator reports each route's name to the browser, so an
/// unnamed route leaves the address bar showing the previous page after Back.
/// The `/?book=<id>` form is already understood by `AppLinkHelper.resolve`, so
/// a reload of that URL reopens the same book. Native apps keep unnamed
/// routes, which also keeps book ids out of analytics screen names.
RouteSettings bookDetailRouteSettings(String bookId, {bool? isWeb}) {
  final web = isWeb ?? kIsWeb;
  if (!web || bookId.trim().isEmpty) return const RouteSettings();
  return RouteSettings(name: '/?book=${Uri.encodeQueryComponent(bookId)}');
}
