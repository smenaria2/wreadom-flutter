import 'package:flutter/foundation.dart';

class AppLogEntry {
  const AppLogEntry({
    required this.type,
    required this.message,
    required this.time,
  });

  final String type;
  final String message;
  final DateTime time;

  String format() =>
      '[${type.toUpperCase()}] ${time.toIso8601String()}: $message';
}

class AppLogCollector {
  AppLogCollector._();

  static const int _maxEntries = 100;
  static final List<AppLogEntry> _entries = <AppLogEntry>[];
  static DebugPrintCallback? _originalDebugPrint;
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    _originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      add('log', message ?? '');
      _originalDebugPrint?.call(message, wrapWidth: wrapWidth);
    };
  }

  static void add(String type, String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    _entries.add(
      AppLogEntry(type: type, message: trimmed, time: DateTime.now()),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
  }

  static List<String> formattedLogs() {
    return _entries.map((entry) => entry.format()).toList(growable: false);
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    add('error', '${details.exceptionAsString()}\n${details.stack ?? ''}');
  }

  static void recordZoneError(Object error, StackTrace stackTrace) {
    add('error', '$error\n$stackTrace');
  }
}
