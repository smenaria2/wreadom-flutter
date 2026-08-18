import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../config/env_config.dart';

typedef AudioAuthTokenLoader =
    Future<String?> Function({required bool forceRefresh});

typedef AudioSourceSetter = Future<Duration?> Function(AudioSource source);

@immutable
class CloudflareAudioRequest {
  const CloudflareAudioRequest({
    required this.uri,
    required this.headers,
    required this.mediaId,
  });

  final Uri uri;
  final Map<String, String> headers;
  final String mediaId;
}

Future<String?> _loadFirebaseToken({required bool forceRefresh}) async {
  try {
    return FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);
  } catch (error) {
    debugPrint(
      'Unable to load the audio authentication token: '
      '${sanitizeAudioPlaybackError(error)}',
    );
    return null;
  }
}

/// Builds an authenticated request to the Cloudflare audio Worker.
///
/// Attaches the identity token as a URL query parameter (`?token=...`) across all
/// platforms (mobile and web) for reliable ExoPlayer, AVPlayer, and browser streaming.
Future<CloudflareAudioRequest?> resolveCloudflareAudioRequest({
  String? objectKey,
  String? url,
  String? customProxyUrl,
  AudioAuthTokenLoader tokenLoader = _loadFirebaseToken,
  bool forceRefreshToken = false,
  bool? useQueryToken,
}) async {
  final normalizedKey = objectKey?.trim();
  final normalizedUrl = url?.trim();
  final proxyBase = (customProxyUrl ?? EnvConfig.cloudflareAudioProxyUrl)
      .trim()
      .replaceAll(RegExp(r'/+$'), '');
  final proxyUri = Uri.tryParse(proxyBase);

  Uri? uri;
  String? mediaId;
  var isWorkerRequest = false;

  if (normalizedKey != null && normalizedKey.isNotEmpty && proxyUri != null) {
    uri = proxyUri.replace(
      pathSegments: <String>[
        ...proxyUri.pathSegments.where((segment) => segment.isNotEmpty),
        ...normalizedKey
            .split('/')
            .map((segment) => segment.trim())
            .where((segment) => segment.isNotEmpty),
      ],
    );
    mediaId = normalizedKey;
    isWorkerRequest = true;
  } else if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
    uri = Uri.tryParse(normalizedUrl);
    if (uri == null || !uri.hasScheme) return null;
    mediaId = normalizedKey?.isNotEmpty == true ? normalizedKey : normalizedUrl;
    isWorkerRequest =
        proxyUri != null &&
        uri.host.toLowerCase() == proxyUri.host.toLowerCase();
  }

  if (uri == null || mediaId == null) return null;

  final headers = <String, String>{'Accept': '*/*'};
  if (isWorkerRequest) {
    final queryAuthentication = useQueryToken ?? true;
    if (!queryAuthentication && uri.queryParameters.containsKey('token')) {
      final query = Map<String, String>.from(uri.queryParameters)
        ..remove('token');
      uri = uri.replace(queryParameters: query);
    }
    final token = await tokenLoader(forceRefresh: forceRefreshToken);
    if (token != null && token.isNotEmpty) {
      if (queryAuthentication) {
        final query = Map<String, String>.from(uri.queryParameters);
        query['token'] = token;
        uri = uri.replace(queryParameters: query);
      } else {
        headers['Authorization'] = 'Bearer $token';
      }
    }
  }

  return CloudflareAudioRequest(
    uri: uri,
    headers: Map<String, String>.unmodifiable(headers),
    mediaId: mediaId,
  );
}

AudioSource createCloudflareAudioSource({
  CloudflareAudioRequest? request,
  String? localPath,
  MediaItem? mediaItem,
  String? id,
  String? title,
  String? album,
  Duration? duration,
}) {
  final cleanLocal = localPath?.trim();
  final mediaId =
      id ??
      request?.mediaId ??
      cleanLocal ??
      'audio_${DateTime.now().millisecondsSinceEpoch}';
  final resolvedMediaItem =
      mediaItem ??
      MediaItem(
        id: mediaId,
        album: album ?? 'Wreadom Audio',
        title: title ?? 'Audio',
        duration: duration,
      );

  if (cleanLocal != null && cleanLocal.isNotEmpty) {
    if (kIsWeb) {
      return AudioSource.uri(Uri.parse(cleanLocal), tag: resolvedMediaItem);
    }
    return AudioSource.file(cleanLocal, tag: resolvedMediaItem);
  }

  if (request == null) {
    throw ArgumentError('An audio request or local path is required.');
  }
  return AudioSource.uri(
    request.uri,
    headers: request.headers,
    tag: resolvedMediaItem,
  );
}

/// Resolves and loads a Worker source, refreshing credentials once when the
/// initial load fails. Direct Backblaze and Firebase callable fallbacks are
/// intentionally not used.
Future<CloudflareAudioRequest> setCloudflareAudioSourceWithRetry({
  required Future<CloudflareAudioRequest?> Function(bool forceRefresh)
  resolveRequest,
  required AudioSourceSetter setAudioSource,
  required AudioSource Function(CloudflareAudioRequest request) createSource,
}) async {
  Object? firstError;
  StackTrace? firstStack;
  for (var attempt = 0; attempt < 2; attempt++) {
    try {
      final request = await resolveRequest(attempt > 0);
      if (request == null) {
        throw StateError('Resolved audio request is empty.');
      }
      await setAudioSource(createSource(request));
      return request;
    } catch (error, stack) {
      firstError ??= error;
      firstStack ??= stack;
      if (attempt > 0) {
        Error.throwWithStackTrace(error, stack);
      }
    }
  }
  Error.throwWithStackTrace(
    firstError ?? StateError('Unable to load audio.'),
    firstStack ?? StackTrace.current,
  );
}

Future<void> runAudioPlayback({
  required Future<void> Function() play,
  required void Function(Object error, StackTrace stack) onError,
}) async {
  try {
    await play();
  } catch (error, stack) {
    onError(error, stack);
  }
}

String sanitizeAudioPlaybackError(Object error) {
  return error
      .toString()
      .replaceAllMapped(
        RegExp(r'([?&]token=)[^&\s)]+', caseSensitive: false),
        (match) => '${match.group(1)}<redacted>',
      )
      .replaceAllMapped(
        RegExp(r'(Bearer\s+)[^\s,;}]+', caseSensitive: false),
        (match) => '${match.group(1)}<redacted>',
      );
}
