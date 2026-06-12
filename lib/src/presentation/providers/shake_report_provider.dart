import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_provider.dart';

const shakeToReportEnabledKey = 'shake_to_report_enabled';

final shakeToReportEnabledProvider =
    NotifierProvider<ShakeToReportEnabledController, bool>(
      ShakeToReportEnabledController.new,
    );

class ShakeToReportEnabledController extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(shakeToReportEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(shakeToReportEnabledKey, enabled);
  }
}
