import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_haptics.dart';
import 'theme_provider.dart';

final hapticsEnabledProvider = NotifierProvider<HapticsEnabledController, bool>(
  HapticsEnabledController.new,
);

class HapticsEnabledController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final enabled = prefs.getBool(appHapticsEnabledKey) ?? true;
    AppHaptics.setEnabled(enabled);
    return enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await AppHaptics.setEnabled(
      enabled,
      preferences: ref.read(sharedPreferencesProvider),
    );
  }
}
