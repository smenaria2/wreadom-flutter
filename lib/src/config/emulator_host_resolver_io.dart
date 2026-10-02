import 'dart:io';
import 'package:flutter/foundation.dart';

Future<String> resolvePlatformEmulatorHost(
  String configuredHost,
  int testPort,
) async {
  final trimmed = configuredHost.trim();
  final baseHost = trimmed.isEmpty ? '127.0.0.1' : trimmed;

  if (Platform.isAndroid) {
    if (baseHost == '127.0.0.1' || baseHost == 'localhost') {
      // FlutterFire rewrites localhost and 127.0.0.1 to 10.0.2.2, which only
      // exists on the stock Android emulator. 127.0.0.2 is still loopback, so
      // it reaches ports forwarded with adb reverse (devices, LDPlayer).
      // Set FIREBASE_EMULATOR_HOST to a LAN address to skip probing.
      const candidates = ['127.0.0.2', '10.0.2.2'];
      for (final candidate in candidates) {
        try {
          final socket = await Socket.connect(
            candidate,
            testPort,
            timeout: const Duration(milliseconds: 1000),
          );
          socket.destroy();
          debugPrint(
            '[EmulatorResolver] Successfully connected to emulator host: $candidate:$testPort',
          );
          return candidate;
        } catch (_) {}
      }
      debugPrint(
        '[EmulatorResolver] All candidate probes failed, using 10.0.2.2',
      );
      return '10.0.2.2';
    }
  }

  return baseHost;
}
