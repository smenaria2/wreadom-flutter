import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/utils/crashlytics_error_filter.dart';

void main() {
  group('CrashlyticsErrorFilter', () {
    test('filters MissingPluginException on Firestore transaction cancel', () {
      final error = MissingPluginException(
        'No implementation found for method cancel on channel plugins.flutter.io/firebase_firestore/transaction/4d2fdb05-b1a4-4ea3-a9db-b1b9ffd0ff63',
      );
      final stack = StackTrace.fromString(
        '#0 MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart:364)\n'
        '#1 EventChannel.receiveBroadcastStream.<anonymous closure> (package:flutter/src/services/platform_channel.dart:726)',
      );

      final severity = CrashlyticsErrorFilter.classifyUncaughtError(
        error,
        stack,
      );
      expect(severity, ErrorSeverity.ignore);

      final flutterDetails = FlutterErrorDetails(
        exception: error,
        stack: stack,
      );
      expect(
        CrashlyticsErrorFilter.classifyFlutterError(flutterDetails),
        ErrorSeverity.ignore,
      );
    });

    test('classifies ImageStreamCompleter HttpException 524 as nonFatal', () {
      final error = HttpException(
        'Invalid statusCode: 524, uri = https://wreadom-images.smenaria2.workers.dev/images/profile_covers/test.jpg',
      );
      final stack = StackTrace.fromString(
        '#0 ImageStreamCompleter.reportError (package:flutter/src/painting/image_stream.dart:827)\n'
        '#1 MultiFrameImageStreamCompleter.<anonymous closure> (package:flutter/src/painting/image_stream.dart:980)',
      );

      final flutterDetails = FlutterErrorDetails(
        exception: error,
        stack: stack,
      );

      expect(
        CrashlyticsErrorFilter.classifyFlutterError(flutterDetails),
        ErrorSeverity.nonFatal,
      );
      expect(
        CrashlyticsErrorFilter.classifyUncaughtError(error, stack),
        ErrorSeverity.nonFatal,
      );
    });

    test('classifies image host lookup failures as nonFatal', () {
      const errorStr =
          "ClientException with SocketException: Failed host lookup: 'wreadom-images.smenaria2.workers.dev' (OS Error: No address associated with hostname, errno = 7)";
      final error = Exception(errorStr);
      final stack = StackTrace.fromString(
        '#0 CachedNetworkImageProvider._loadImageAsync '
        '(package:cached_network_image/src/image_provider/cached_network_image_provider.dart:166)\n'
        '#1 MultiFrameImageStreamCompleter.<anonymous closure> '
        '(package:flutter/src/painting/image_stream.dart:980)',
      );

      expect(
        CrashlyticsErrorFilter.classifyUncaughtError(error, stack),
        ErrorSeverity.nonFatal,
      );
    });

    test('keeps network failures fatal outside optional asset loading', () {
      final error = const SocketException('Connection failed during startup');
      final stack = StackTrace.fromString(
        '#0 AuthBootstrap.initialize '
        '(package:librebook_flutter/src/data/services/auth_bootstrap.dart:42)',
      );

      expect(
        CrashlyticsErrorFilter.classifyUncaughtError(error, stack),
        ErrorSeverity.fatal,
      );
    });

    test('keeps image pipeline programming errors fatal', () {
      final error = StateError('Invalid image state');
      final stack = StackTrace.fromString(
        '#0 ImageStreamCompleter.reportError '
        '(package:flutter/src/painting/image_stream.dart:827)',
      );

      expect(
        CrashlyticsErrorFilter.classifyUncaughtError(error, stack),
        ErrorSeverity.fatal,
      );
    });

    test('classifies genuine application errors as fatal', () {
      final stateError = StateError('Unexpected null user session');
      final stack = StackTrace.fromString(
        '#0 ProfileScreenState._load (package:librebook_flutter/src/presentation/screens/profile_screen.dart:120)',
      );

      expect(
        CrashlyticsErrorFilter.classifyUncaughtError(stateError, stack),
        ErrorSeverity.fatal,
      );

      final flutterError = FlutterErrorDetails(
        exception: stateError,
        stack: stack,
      );
      expect(
        CrashlyticsErrorFilter.classifyFlutterError(flutterError),
        ErrorSeverity.fatal,
      );
    });

    test('classifies generic missing plugin exception on camera as fatal', () {
      final error = MissingPluginException(
        'No implementation found for method takePicture on channel plugins.flutter.io/camera',
      );
      final stack = StackTrace.fromString(
        '#0 CameraController.takePicture (package:camera/camera.dart:50)',
      );

      expect(
        CrashlyticsErrorFilter.classifyUncaughtError(error, stack),
        ErrorSeverity.fatal,
      );
    });
  });
}
