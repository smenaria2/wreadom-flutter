import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:librebook_flutter/src/utils/cloudflare_audio_resolver.dart';

void main() {
  const proxy = 'https://wreadom-audio.smenaria2.workers.dev';

  group('resolveCloudflareAudioRequest', () {
    test('mobile uses a Bearer header and keeps token out of URL', () async {
      final request = await resolveCloudflareAudioRequest(
        objectKey: 'audio-reviews/user1/book1/clip.m4a',
        customProxyUrl: proxy,
        useQueryToken: false,
        tokenLoader: ({required forceRefresh}) async => 'mobile-token',
      );

      expect(
        request?.uri.toString(),
        '$proxy/audio-reviews/user1/book1/clip.m4a',
      );
      expect(request?.uri.queryParameters, isEmpty);
      expect(request?.headers, {
        'Accept': '*/*',
        'Authorization': 'Bearer mobile-token',
      });
      expect(request?.mediaId, 'audio-reviews/user1/book1/clip.m4a');
    });

    test('web retains the Worker query credential', () async {
      final request = await resolveCloudflareAudioRequest(
        objectKey: 'audio-reviews/user/clip.m4a',
        customProxyUrl: proxy,
        useQueryToken: true,
        tokenLoader: ({required forceRefresh}) async => 'web token',
      );

      expect(request?.uri.queryParameters['token'], 'web token');
      expect(request?.headers, {'Accept': '*/*'});
    });

    test('passes forced refresh to the injected token loader', () async {
      bool? observedForceRefresh;

      await resolveCloudflareAudioRequest(
        objectKey: 'audio-reviews/user/clip.m4a',
        customProxyUrl: proxy,
        forceRefreshToken: true,
        useQueryToken: false,
        tokenLoader: ({required forceRefresh}) async {
          observedForceRefresh = forceRefresh;
          return 'fresh-token';
        },
      );

      expect(observedForceRefresh, isTrue);
    });

    test('safely encodes individual object-key path segments', () async {
      final request = await resolveCloudflareAudioRequest(
        objectKey: 'audio reviews/user/clip #1.m4a',
        customProxyUrl: proxy,
        useQueryToken: false,
        tokenLoader: ({required forceRefresh}) async => null,
      );

      expect(request?.uri.pathSegments, [
        'audio reviews',
        'user',
        'clip #1.m4a',
      ]);
      expect(request?.uri.toString(), contains('audio%20reviews'));
      expect(request?.uri.toString(), contains('clip%20%231.m4a'));
    });

    test(
      'raw non-Worker URL is preserved without requesting a token',
      () async {
        var tokenCalls = 0;
        final request = await resolveCloudflareAudioRequest(
          url: 'https://example.com/audio/sample.m4a?quality=high',
          customProxyUrl: proxy,
          tokenLoader: ({required forceRefresh}) async {
            tokenCalls += 1;
            return 'unused';
          },
        );

        expect(
          request?.uri.toString(),
          'https://example.com/audio/sample.m4a?quality=high',
        );
        expect(request?.headers, {'Accept': '*/*'});
        expect(tokenCalls, 0);
      },
    );

    test('mobile strips a stored Worker query token', () async {
      final request = await resolveCloudflareAudioRequest(
        url: '$proxy/audio-reviews/user/clip.m4a?token=legacy&quality=high',
        customProxyUrl: proxy,
        useQueryToken: false,
        tokenLoader: ({required forceRefresh}) async => 'fresh-mobile-token',
      );

      expect(request?.uri.queryParameters['token'], isNull);
      expect(request?.uri.queryParameters['quality'], 'high');
      expect(request?.headers['Authorization'], 'Bearer fresh-mobile-token');
    });

    test('empty input produces no request', () async {
      final request = await resolveCloudflareAudioRequest(
        objectKey: ' ',
        url: '',
        customProxyUrl: proxy,
      );

      expect(request, isNull);
    });
  });

  group('audio source and playback helpers', () {
    test('creates UriAudioSource with headers and MediaItem metadata', () {
      final request = CloudflareAudioRequest(
        uri: Uri(
          scheme: 'https',
          host: 'wreadom-audio.smenaria2.workers.dev',
          path: '/audio-reviews/test.m4a',
        ),
        headers: {'Accept': '*/*', 'Authorization': 'Bearer token'},
        mediaId: 'review-1',
      );
      final source = createCloudflareAudioSource(
        request: request,
        title: 'Review Audio',
        album: 'Test Album',
        duration: const Duration(seconds: 45),
      );

      expect(source, isA<UriAudioSource>());
      final uriSource = source as UriAudioSource;
      expect(uriSource.uri, request.uri);
      expect(uriSource.headers, request.headers);
      final mediaItem = uriSource.tag as MediaItem;
      expect(mediaItem.id, 'review-1');
      expect(mediaItem.title, 'Review Audio');
      expect(mediaItem.album, 'Test Album');
      expect(mediaItem.duration, const Duration(seconds: 45));
    });

    test('creates a tagged source for a local path', () {
      final source = createCloudflareAudioSource(
        localPath: '/tmp/test_recording.m4a',
        title: 'Local Recording',
      );

      expect(source, isA<AudioSource>());
      expect((source as dynamic).tag, isA<MediaItem>());
      expect(((source as dynamic).tag as MediaItem).title, 'Local Recording');
    });

    test('refreshes credentials and retries one failed source load', () async {
      final refreshes = <bool>[];
      var setAttempts = 0;

      final request = await setCloudflareAudioSourceWithRetry(
        resolveRequest: (forceRefresh) async {
          refreshes.add(forceRefresh);
          return CloudflareAudioRequest(
            uri: Uri.parse('$proxy/audio-reviews/test.m4a'),
            headers: {
              'Authorization': forceRefresh ? 'Bearer fresh' : 'Bearer stale',
            },
            mediaId: 'review-1',
          );
        },
        setAudioSource: (source) async {
          setAttempts += 1;
          if (setAttempts == 1) throw StateError('HTTP 401');
          return null;
        },
        createSource: (request) =>
            createCloudflareAudioSource(request: request),
      );

      expect(refreshes, [false, true]);
      expect(setAttempts, 2);
      expect(request.headers['Authorization'], 'Bearer fresh');
    });

    test('surfaces rejected play futures through the error callback', () async {
      Object? observedError;

      await runAudioPlayback(
        play: () async => throw StateError('stream failed'),
        onError: (error, stack) => observedError = error,
      );

      expect(observedError, isA<StateError>());
    });

    test('redacts query and Bearer credentials from errors', () {
      final sanitized = sanitizeAudioPlaybackError(
        'GET https://worker/audio?token=secret-token '
        'Authorization: Bearer secret.jwt.value',
      );

      expect(sanitized, isNot(contains('secret-token')));
      expect(sanitized, isNot(contains('secret.jwt.value')));
      expect(sanitized, contains('token=<redacted>'));
      expect(sanitized, contains('Bearer <redacted>'));
    });

    test('implementation has no Firebase callable signing fallback', () {
      final source = File(
        'lib/src/utils/cloudflare_audio_resolver.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('FirebaseFunctions')));
      expect(source, isNot(contains('createAudioReviewDownloadUrl')));
    });
  });
}
