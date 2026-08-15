/// Normalizes a public Instagram username or profile URL to a username.
///
/// Returns null for invalid values and for URLs that point to posts, reels,
/// stories, or other non-profile destinations.
String? normalizeInstagramHandle(String? value) {
  final input = value?.trim();
  if (input == null || input.isEmpty) return null;

  var candidate = input;
  if (input.contains('://') ||
      input.toLowerCase().startsWith('instagram.com/') ||
      input.toLowerCase().startsWith('www.instagram.com/')) {
    final uri = Uri.tryParse(input.contains('://') ? input : 'https://$input');
    final host = uri?.host.toLowerCase();
    if (uri == null ||
        !const {
          'instagram.com',
          'www.instagram.com',
          'm.instagram.com',
        }.contains(host)) {
      return null;
    }
    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.length != 1) return null;
    candidate = segments.single;
  }

  if (candidate.startsWith('@')) candidate = candidate.substring(1);
  if (const {
    'accounts',
    'about',
    'developer',
    'direct',
    'explore',
    'p',
    'reel',
    'reels',
    'stories',
    'tv',
  }.contains(candidate.toLowerCase())) {
    return null;
  }
  if (candidate.isEmpty ||
      !RegExp(
        r'^[A-Za-z0-9](?:[A-Za-z0-9._]{0,28}[A-Za-z0-9])?$',
      ).hasMatch(candidate)) {
    return null;
  }
  return candidate;
}

String instagramProfileUrl(String handle) =>
    'https://www.instagram.com/$handle/';
