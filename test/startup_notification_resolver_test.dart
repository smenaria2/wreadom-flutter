import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/routing/startup_entry_policy.dart';
import 'package:librebook_flutter/src/presentation/routing/startup_notification_resolver.dart';

void main() {
  test('shouldShowStartupSplash skips splash when initial notification is present', () {
    expect(
      shouldShowStartupSplash(
        initialAppLink: null,
        hasInitialShare: false,
        hasInitialNotification: true,
        hasSeenSplash: false,
        disableAnimations: false,
      ),
      isFalse,
    );

    expect(
      shouldShowStartupSplash(
        initialAppLink: null,
        hasInitialShare: false,
        hasInitialNotification: false,
        hasSeenSplash: false,
        disableAnimations: false,
      ),
      isTrue,
    );
  });

  test('StartupNotificationResolver inspects web environment as false', () async {
    final result = await StartupNotificationResolver.inspectInitialNotification();
    expect(result.hasInitialNotification, isFalse);
  });
}
