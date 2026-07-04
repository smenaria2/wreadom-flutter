import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';

import '../presentation/routing/app_router.dart';
import '../presentation/routing/app_routes.dart';
import '../presentation/routing/writer_pad_mode.dart';

typedef SharedRouteTargetHandler = void Function(RouteSettings target);

class SharingIntentHandler {
  SharingIntentHandler._();
  static final SharingIntentHandler instance = SharingIntentHandler._();

  StreamSubscription<List<SharedMediaFile>>? _intentSub;
  bool _initialized = false;

  void init(
    GlobalKey<NavigatorState> navigatorKey, {
    SharedRouteTargetHandler? onSharedTarget,
  }) {
    if (_initialized) return;
    _initialized = true;

    // 1. Handle sharing when app is running in background/foreground
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) {
        if (files.isNotEmpty) {
          _handleSharedFiles(navigatorKey, files, onSharedTarget);
        }
      },
      onError: (err) {
        debugPrint(
          "SharingIntentHandler: Error receiving share intent stream: $err",
        );
      },
    );

    // 2. Handle sharing when app is opened from terminated state
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> files) {
          if (files.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 800), () {
              _handleSharedFiles(navigatorKey, files, onSharedTarget);
            });
          }
        })
        .catchError((err) {
          debugPrint(
            "SharingIntentHandler: Error receiving initial share intent: $err",
          );
        });
  }

  void dispose() {
    _intentSub?.cancel();
    _intentSub = null;
    _initialized = false;
  }

  Future<void> _handleSharedFiles(
    GlobalKey<NavigatorState> navigatorKey,
    List<SharedMediaFile> files,
    SharedRouteTargetHandler? onSharedTarget,
  ) async {
    final file = files.first;
    final path = file.path;

    // Check if it's text
    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      debugPrint("SharingIntentHandler: Handling shared text/url");
      _openTarget(
        navigatorKey,
        RouteSettings(
          name: AppRoutes.writerPad,
          arguments: WriterPadArguments(initialText: path),
        ),
        onSharedTarget,
      );
      return;
    }

    // Check if image
    final isImage =
        file.type == SharedMediaType.image ||
        _hasExtension(path, [
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
          '.heic',
        ]);

    // Check if audio
    final mimeTypeLower = file.mimeType?.toLowerCase();
    final isAudio = (mimeTypeLower != null && mimeTypeLower.startsWith('audio/')) ||
        _hasExtension(path, [
          '.mp3',
          '.m4a',
          '.wav',
          '.aac',
          '.ogg',
          '.flac',
          '.m4b',
          '.opus',
          '.amr',
        ]) ||
        (path.startsWith('content://') &&
            (path.toLowerCase().contains('audio') ||
                path.toLowerCase().contains('music') ||
                path.toLowerCase().contains('sound')));

    if (isImage) {
      debugPrint("SharingIntentHandler: Handling shared image");
      _openTarget(
        navigatorKey,
        RouteSettings(
          name: AppRoutes.createPost,
          arguments: CreatePostArguments(initialImagePath: path),
        ),
        onSharedTarget,
      );
    } else if (isAudio) {
      debugPrint("SharingIntentHandler: Handling shared audio");
      String resolvedPath = path;
      if (path.startsWith('content://')) {
        resolvedPath = await _copyToTempFile(path, file.mimeType);
      }

      // 1. Get file size
      int sizeBytes = 0;
      try {
        sizeBytes = File(resolvedPath).lengthSync();
      } catch (e) {
        debugPrint("SharingIntentHandler: Error getting size: $e");
      }

      // 2. Get duration via a temporary player
      int durationMs = 0;
      final player = AudioPlayer();
      try {
        final duration = await player.setAudioSource(AudioSource.file(resolvedPath));
        durationMs = duration?.inMilliseconds ?? 0;
      } catch (e) {
        debugPrint("SharingIntentHandler: Error getting duration: $e");
      } finally {
        await player.dispose();
      }

      // 3. Guess MIME type from extension or file metadata
      String mimeType = file.mimeType ?? 'audio/mpeg';
      if (file.mimeType == null) {
        final lowerPath = resolvedPath.toLowerCase();
        if (lowerPath.endsWith('.m4a')) {
          mimeType = 'audio/m4a';
        } else if (lowerPath.endsWith('.mp4')) {
          mimeType = 'audio/mp4';
        } else if (lowerPath.endsWith('.wav')) {
          mimeType = 'audio/wav';
        } else if (lowerPath.endsWith('.aac')) {
          mimeType = 'audio/aac';
        } else if (lowerPath.endsWith('.opus')) {
          mimeType = 'audio/opus';
        } else if (lowerPath.endsWith('.amr')) {
          mimeType = 'audio/amr';
        }
      }

      _openTarget(
        navigatorKey,
        RouteSettings(
          name: AppRoutes.createPost,
          arguments: CreatePostArguments(
            initialAudioPath: resolvedPath,
            initialAudioDurationMs: durationMs,
            initialAudioSizeBytes: sizeBytes,
            initialAudioMimeType: mimeType,
          ),
        ),
        onSharedTarget,
      );
    } else {
      debugPrint(
        "SharingIntentHandler: Unsupported file type: ${file.type} or path: $path",
      );
    }
  }

  void _openTarget(
    GlobalKey<NavigatorState> navigatorKey,
    RouteSettings target,
    SharedRouteTargetHandler? onSharedTarget,
  ) {
    if (onSharedTarget != null) {
      onSharedTarget(target);
      return;
    }
    final name = target.name;
    if (name == null || name.trim().isEmpty) return;
    navigatorKey.currentState?.pushNamed(name, arguments: target.arguments);
  }

  bool _hasExtension(String path, List<String> extensions) {
    final lowerPath = path.toLowerCase();
    return extensions.any((ext) => lowerPath.endsWith(ext));
  }

  Future<String> _copyToTempFile(String path, String? mimeType) async {
    if (!path.startsWith('content://')) return path;

    try {
      final xfile = XFile(path);
      final bytes = await xfile.readAsBytes();
      if (bytes.isEmpty) return path;

      final tempDir = await getTemporaryDirectory();

      // Determine extension
      String ext = '.mp3';
      if (mimeType != null) {
        if (mimeType.contains('m4a')) {
          ext = '.m4a';
        } else if (mimeType.contains('wav')) {
          ext = '.wav';
        } else if (mimeType.contains('aac')) {
          ext = '.aac';
        } else if (mimeType.contains('ogg')) {
          ext = '.ogg';
        } else if (mimeType.contains('flac')) {
          ext = '.flac';
        } else if (mimeType.contains('opus')) {
          ext = '.opus';
        } else if (mimeType.contains('amr')) {
          ext = '.amr';
        }
      } else {
        // Try to guess from content URI if it contains an extension
        final lowerPath = path.toLowerCase();
        for (final possibleExt in [
          '.mp3',
          '.m4a',
          '.wav',
          '.aac',
          '.ogg',
          '.flac',
          '.m4b',
          '.opus',
          '.amr',
        ]) {
          if (lowerPath.contains(possibleExt)) {
            ext = possibleExt;
            break;
          }
        }
      }

      final fileName =
          'shared_audio_${DateTime.now().millisecondsSinceEpoch}$ext';
      final tempFile = File(p.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(bytes);
      debugPrint(
        "SharingIntentHandler: Copied content:// to temp file: ${tempFile.path}",
      );
      return tempFile.path;
    } catch (e) {
      debugPrint("SharingIntentHandler: Error copying content:// URI: $e");
      return path;
    }
  }
}
