import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Avatar and Profile Image Optimization Source Coverage', () {
    test('public profile screen uses optimized cover and avatar URLs', () {
      final source = File('lib/src/presentation/screens/public_profile_screen.dart').readAsStringSync();
      expect(source, contains('optimizedImageUrl('));
      expect(source, contains('width: 1600,'));
      expect(source, contains('height: 600,'));
      expect(source, contains('optimizedAvatarUrl('));
      expect(source, contains('width: 240,'));
      expect(source, contains('height: 240,'));
    });

    test('follow list screen uses optimized avatar URLs', () {
      final source = File('lib/src/presentation/screens/follow_list_screen.dart').readAsStringSync();
      expect(source, contains('optimizedAvatarUrl'));
    });

    test('messages screen uses optimized avatar URLs', () {
      final source = File('lib/src/presentation/screens/messages_screen.dart').readAsStringSync();
      expect(source, contains('optimizedAvatarUrl'));
    });

    test('notifications screen uses optimized avatar URLs', () {
      final source = File('lib/src/presentation/screens/notifications_screen.dart').readAsStringSync();
      expect(source, contains('optimizedAvatarUrl'));
    });

    test('writer dashboard header uses optimized avatar URLs', () {
      final source = File('lib/src/presentation/components/writer/writer_dashboard_header.dart').readAsStringSync();
      expect(source, contains('optimizedAvatarUrl'));
    });
  });
}
