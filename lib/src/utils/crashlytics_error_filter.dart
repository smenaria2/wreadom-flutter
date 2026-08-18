import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Classifies error severity to keep Firebase Crashlytics accurate and
/// filter out known framework teardown race conditions and transient network glitches.
enum ErrorSeverity {
  /// Harmless framework teardown race conditions (e.g. Firestore transaction cancel
  /// channel cleanup) that should be logged locally only without polluting Crashlytics.
  ignore,

  /// Transient network timeouts, image/font loading errors, or non-breaking background
  /// issues that should be reported as non-fatal events to Crashlytics.
  nonFatal,

  /// Uncaught critical errors that break application flow or UI state.
  fatal,
}

class CrashlyticsErrorFilter {
  CrashlyticsErrorFilter._();

  /// Classifies a [FlutterErrorDetails] instance.
  static ErrorSeverity classifyFlutterError(FlutterErrorDetails details) {
    final exception = details.exception;
    final stackString = details.stack?.toString() ?? '';
    final exceptionString = details.exceptionAsString();

    if (_isIgnorableTeardown(exception, exceptionString, stackString)) {
      return ErrorSeverity.ignore;
    }

    if (_isTransientNetworkOrAssetError(
      exception,
      exceptionString,
      stackString,
    )) {
      return ErrorSeverity.nonFatal;
    }

    return ErrorSeverity.fatal;
  }

  /// Classifies an uncaught error from Zone or PlatformDispatcher.
  static ErrorSeverity classifyUncaughtError(
    Object error, [
    StackTrace? stack,
  ]) {
    final stackString = stack?.toString() ?? '';
    final errorString = error.toString();

    if (_isIgnorableTeardown(error, errorString, stackString)) {
      return ErrorSeverity.ignore;
    }

    if (_isTransientNetworkOrAssetError(error, errorString, stackString)) {
      return ErrorSeverity.nonFatal;
    }

    return ErrorSeverity.fatal;
  }

  /// Detects known benign platform channel teardown race conditions.
  static bool _isIgnorableTeardown(
    Object error,
    String errorStr,
    String stackStr,
  ) {
    // MissingPluginException on Firestore transaction cancel teardown (FlutterFire #18546)
    if (error is MissingPluginException ||
        errorStr.contains('MissingPluginException')) {
      if (errorStr.contains('firebase_firestore/transaction') &&
          errorStr.contains('cancel')) {
        return true;
      }
      if (stackStr.contains('EventChannel.receiveBroadcastStream') &&
          errorStr.contains('cancel')) {
        return true;
      }
    }

    // Harmless stream controller close race condition after transaction completion
    if (errorStr.contains('Cannot add new events after calling close') &&
        (stackStr.contains('transaction') ||
            stackStr.contains('firestore') ||
            stackStr.contains('receiveBroadcastStream'))) {
      return true;
    }

    // DiagnosticsProperty flutter error formatting artifact during teardown
    if (errorStr.contains("Instance of 'DiagnosticsProperty<void>'") ||
        errorStr.contains('DiagnosticsProperty')) {
      return true;
    }

    return false;
  }

  /// Detects transient optional-asset fetch errors that should not crash the app.
  static bool _isTransientNetworkOrAssetError(
    Object error,
    String errorStr,
    String stackStr,
  ) {
    final isImageLoad =
        stackStr.contains('ImageStreamCompleter') ||
        stackStr.contains('MultiFrameImageStreamCompleter') ||
        stackStr.contains('NetworkImage') ||
        stackStr.contains('CachedNetworkImage') ||
        errorStr.contains('ImageStreamCompleter');
    final isFontLoad =
        stackStr.contains('google_fonts') ||
        stackStr.contains('_httpFetchFontAndSaveToDevice') ||
        errorStr.contains('Failed to load font with url');
    final isNetworkFailure =
        error is SocketException ||
        error is HttpException ||
        errorStr.contains('SocketException') ||
        errorStr.contains('HttpException') ||
        errorStr.contains('Failed host lookup') ||
        errorStr.contains('ClientException with SocketException') ||
        errorStr.contains('statusCode: 404') ||
        errorStr.contains('statusCode: 524') ||
        errorStr.toLowerCase().contains('timed out');

    // Only optional image/font fetches are demoted. Network failures from
    // startup, persistence, or another critical flow remain fatal.
    if ((isImageLoad || isFontLoad) && isNetworkFailure) {
      return true;
    }

    return false;
  }
}
