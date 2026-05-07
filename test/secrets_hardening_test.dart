import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('secrets hardening', () {
    test('Dart config files do not contain hardcoded secret defaults', () {
      const configPaths = [
        'lib/src/config/env_config.dart',
        'lib/src/core/constants/cloudinary_constants.dart',
      ];

      final secretPatterns = <RegExp>[
        RegExp(r"defaultValue:\s*'AIza[0-9A-Za-z_-]{20,}'"),
        RegExp(
          r"defaultValue:\s*'[^']*(secret|token|password|preset)[^']*'",
          caseSensitive: false,
        ),
        RegExp(r"defaultValue:\s*'df05bobcq'"),
        RegExp(r"defaultValue:\s*'ml_default'"),
      ];

      for (final path in configPaths) {
        final contents = File(path).readAsStringSync();
        for (final pattern in secretPatterns) {
          expect(
            pattern.hasMatch(contents),
            isFalse,
            reason: '$path contains a hardcoded secret-like default.',
          );
        }
      }
    });

    test('ignored local secret files stay out of source control', () {
      final gitignore = File('.gitignore').readAsStringSync();

      expect(gitignore, contains('android/key.properties'));
      expect(gitignore, contains('android/app/upload-keystore.jks'));
      expect(gitignore, contains('**/*.jks'));
      expect(gitignore, contains('.env*.local'));
      expect(gitignore, contains('dart_defines.local.json'));
    });
  });
}
