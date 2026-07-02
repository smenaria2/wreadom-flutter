import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../presentation/components/create_post_sheet.dart';
import '../presentation/routing/app_routes.dart';
import '../presentation/routing/writer_pad_mode.dart';

class SharingIntentHandler {
  SharingIntentHandler._();
  static final SharingIntentHandler instance = SharingIntentHandler._();

  StreamSubscription<List<SharedMediaFile>>? _intentSub;
  bool _initialized = false;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    if (_initialized) return;
    _initialized = true;

    // 1. Handle sharing when app is running in background/foreground
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) {
        if (files.isNotEmpty) {
          _handleSharedFiles(navigatorKey, files);
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
              _handleSharedFiles(navigatorKey, files);
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
  ) async {
    final file = files.first;
    final path = file.path;

    // Check if it's text
    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      debugPrint("SharingIntentHandler: Handling shared text/url");
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushNamed(
        AppRoutes.writerPad,
        arguments: WriterPadArguments(initialText: path),
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
    final isAudio = _hasExtension(path, [
      '.mp3',
      '.m4a',
      '.wav',
      '.aac',
      '.ogg',
      '.flac',
      '.m4b',
    ]);

    if (isImage) {
      debugPrint("SharingIntentHandler: Handling shared image");
      final context = navigatorKey.currentContext;
      if (context == null) return;
      final xFile = XFile(path);
      showCreatePostSheet(context, initialImage: xFile);
    } else if (isAudio) {
      debugPrint("SharingIntentHandler: Handling shared audio");
      // 1. Get file size
      int sizeBytes = 0;
      try {
        sizeBytes = File(path).lengthSync();
      } catch (e) {
        debugPrint("SharingIntentHandler: Error getting size: $e");
      }

      // 2. Get duration via a temporary player
      int durationMs = 0;
      final player = AudioPlayer();
      try {
        final duration = await player.setAudioSource(AudioSource.file(path));
        durationMs = duration?.inMilliseconds ?? 0;
      } catch (e) {
        debugPrint("SharingIntentHandler: Error getting duration: $e");
      } finally {
        await player.dispose();
      }

      // 3. Guess MIME type from extension
      String mimeType = 'audio/mpeg';
      final lowerPath = path.toLowerCase();
      if (lowerPath.endsWith('.m4a')) {
        mimeType = 'audio/m4a';
      } else if (lowerPath.endsWith('.mp4')) {
        mimeType = 'audio/mp4';
      } else if (lowerPath.endsWith('.wav')) {
        mimeType = 'audio/wav';
      } else if (lowerPath.endsWith('.aac')) {
        mimeType = 'audio/aac';
      }

      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        debugPrint("SharingIntentHandler: Context is no longer mounted");
        return;
      }
      showCreatePostSheet(
        context,
        initialAudioPath: path,
        initialAudioDurationMs: durationMs,
        initialAudioSizeBytes: sizeBytes,
        initialAudioMimeType: mimeType,
      );
    } else {
      debugPrint(
        "SharingIntentHandler: Unsupported file type: ${file.type} or path: $path",
      );
    }
  }

  bool _hasExtension(String path, List<String> extensions) {
    final lowerPath = path.toLowerCase();
    return extensions.any((ext) => lowerPath.endsWith(ext));
  }
}
