enum WriterMediaType { youtube, instagram, spotify, unsupported }

class WriterMediaInfo {
  const WriterMediaInfo({
    required this.type,
    required this.originalUrl,
    required this.embedUrl,
    required this.label,
  });

  final WriterMediaType type;
  final String originalUrl;
  final String embedUrl;
  final String label;

  bool get isSupported => type != WriterMediaType.unsupported;
}

WriterMediaInfo classifyWriterMediaUrl(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) {
    return const WriterMediaInfo(
      type: WriterMediaType.unsupported,
      originalUrl: '',
      embedUrl: '',
      label: 'Unsupported link',
    );
  }

  final uri = _parseHttpUri(raw);
  if (uri == null) {
    return WriterMediaInfo(
      type: WriterMediaType.unsupported,
      originalUrl: raw,
      embedUrl: raw,
      label: 'Unsupported link',
    );
  }

  final host = _normalizedHost(uri);
  if (_hostMatches(host, const ['youtube.com', 'youtu.be'])) {
    final id = _youtubeId(uri);
    if (id != null) {
      return WriterMediaInfo(
        type: WriterMediaType.youtube,
        originalUrl: uri.toString(),
        embedUrl: 'https://www.youtube-nocookie.com/embed/$id',
        label: 'YouTube',
      );
    }
  }

  if (_hostMatches(host, const ['instagram.com'])) {
    final cleanPath = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    return WriterMediaInfo(
      type: WriterMediaType.instagram,
      originalUrl: uri.toString(),
      embedUrl: uri.replace(path: '$cleanPath/embed').toString(),
      label: 'Instagram',
    );
  }

  if (_hostMatches(host, const ['spotify.com'])) {
    final path = uri.path.startsWith('/embed/')
        ? uri.path
        : '/embed${uri.path}';
    return WriterMediaInfo(
      type: WriterMediaType.spotify,
      originalUrl: uri.toString(),
      embedUrl: uri.replace(path: path).toString(),
      label: 'Spotify',
    );
  }

  return WriterMediaInfo(
    type: WriterMediaType.unsupported,
    originalUrl: raw,
    embedUrl: raw,
    label: 'Unsupported link',
  );
}

bool isAllowedWriterLink(String? value) =>
    classifyWriterMediaUrl(value).isSupported;

bool isTrustedCloudinaryImageUrl(String? value) {
  final uri = _parseHttpUri(value?.trim());
  if (uri == null) return false;
  final host = _normalizedHost(uri);
  return host == 'res.cloudinary.com' && uri.path.contains('/image/upload/');
}

String optimizeCloudinaryImageUrl(
  String url, {
  String transform = 'f_auto,q_auto,w_1200,c_limit',
}) {
  if (!isTrustedCloudinaryImageUrl(url)) return url;
  if (url.contains('/upload/$transform/')) return url;
  return url.replaceFirst('/upload/', '/upload/$transform/');
}

bool hasMeaningfulWriterHtml(String html) {
  final normalized = html.trim();
  return normalized.contains('<img ') ||
      RegExp(r'<a\s+[^>]*href=', caseSensitive: false).hasMatch(normalized);
}

Uri? _parseHttpUri(String? value) {
  if (value == null || value.isEmpty) return null;
  final candidate = value.contains('://') ? value : 'https://$value';
  final uri = Uri.tryParse(candidate);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}

String _normalizedHost(Uri uri) {
  final host = uri.host.toLowerCase();
  return host.startsWith('www.') ? host.substring(4) : host;
}

bool _hostMatches(String host, List<String> allowed) {
  return allowed.any((domain) => host == domain || host.endsWith('.$domain'));
}

String? _youtubeId(Uri uri) {
  final host = _normalizedHost(uri);
  if (host == 'youtu.be') {
    return uri.pathSegments.isEmpty
        ? null
        : _sanitizeYouTubeId(uri.pathSegments.first);
  }
  if (uri.queryParameters['v'] case final id?) {
    return _sanitizeYouTubeId(id);
  }
  final segments = uri.pathSegments;
  final markerIndex = segments.indexWhere(
    (segment) => segment == 'embed' || segment == 'shorts',
  );
  if (markerIndex != -1 && markerIndex + 1 < segments.length) {
    return _sanitizeYouTubeId(segments[markerIndex + 1]);
  }
  return null;
}

String? _sanitizeYouTubeId(String value) {
  final id = value.trim();
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) return id;
  return null;
}
