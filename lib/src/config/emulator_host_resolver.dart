import 'emulator_host_resolver_stub.dart'
    if (dart.library.io) 'emulator_host_resolver_io.dart';

class EmulatorHostResolver {
  static Future<String> resolve({
    required String configuredHost,
    required int testPort,
  }) {
    return resolvePlatformEmulatorHost(configuredHost, testPort);
  }
}
