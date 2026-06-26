import 'package:flutter/foundation.dart';

import '../config/env_config.dart';

/// Intercepts and proxies image URLs (like archive.org) that lack proper CORS headers
/// when running on web platforms.
String? proxyImageUrl(String? url) {
  if (url == null || url.isEmpty) return url;
  if (kIsWeb &&
      url.contains('archive.org') &&
      !url.contains('images.weserv.nl')) {
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
  }
  return url;
}

bool isBackblazeImageWorkerUrl(String? url) {
  final uri = Uri.tryParse(url?.trim() ?? '');
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return false;
  }
  final worker = Uri.tryParse(EnvConfig.cloudflareImageProxyUrl);
  if (worker != null && worker.host.isNotEmpty) {
    return uri.host.toLowerCase() == worker.host.toLowerCase();
  }
  return uri.host.toLowerCase() == 'wreadom-images.smenaria2.workers.dev';
}

String optimizedImageUrl(
  String url, {
  int? width,
  int? height,
  int quality = 85,
  String fit = 'cover',
  String format = 'auto',
}) {
  if (!isBackblazeImageWorkerUrl(url)) return url;

  final uri = Uri.tryParse(url.trim());
  if (uri == null) return url;

  final params = Map<String, String>.from(uri.queryParameters);
  if (width != null && width > 0) params['width'] = '$width';
  if (height != null && height > 0) params['height'] = '$height';
  params['quality'] = '${quality.clamp(1, 100)}';
  if (fit.trim().isNotEmpty) params['fit'] = fit.trim();
  if (format.trim().isNotEmpty) params['format'] = format.trim();

  return uri.replace(queryParameters: params).toString();
}
