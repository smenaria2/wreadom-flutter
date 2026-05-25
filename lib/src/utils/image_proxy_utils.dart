import 'package:flutter/foundation.dart';

/// Intercepts and proxies image URLs (like archive.org) that lack proper CORS headers
/// when running on web platforms.
String? proxyImageUrl(String? url) {
  if (url == null || url.isEmpty) return url;
  if (kIsWeb && url.contains('archive.org') && !url.contains('images.weserv.nl')) {
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
  }
  return url;
}
