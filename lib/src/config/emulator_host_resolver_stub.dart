Future<String> resolvePlatformEmulatorHost(String configuredHost, int testPort) async {
  final trimmed = configuredHost.trim();
  return trimmed.isEmpty ? '127.0.0.1' : trimmed;
}
