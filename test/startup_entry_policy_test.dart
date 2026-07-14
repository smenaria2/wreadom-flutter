import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/routing/startup_entry_policy.dart';

void main() {
  group('shouldShowStartupSplash', () {
    test('shows for a normal direct launch', () {
      expect(
        shouldShowStartupSplash(initialAppLink: null, hasInitialShare: false),
        isTrue,
      );
    });

    test('skips for a cold-start deep link', () {
      expect(
        shouldShowStartupSplash(
          initialAppLink: Uri.parse('https://wreadom.com/book/123'),
          hasInitialShare: false,
        ),
        isFalse,
      );
    });

    test('skips for a cold-start share intent', () {
      expect(
        shouldShowStartupSplash(initialAppLink: null, hasInitialShare: true),
        isFalse,
      );
    });
  });
}
