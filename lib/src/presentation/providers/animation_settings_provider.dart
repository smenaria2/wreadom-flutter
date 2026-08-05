import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_provider.dart';

const String _keyDisableAnimationsUserPref = 'disable_animations_user_preference';

final disableAnimationsProvider =
    NotifierProvider<DisableAnimationsNotifier, bool>(
  DisableAnimationsNotifier.new,
);

class DisableAnimationsNotifier extends Notifier<bool> {
  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  static bool isAnimationsDisabled(SharedPreferences? prefs) {
    if (prefs != null && prefs.containsKey(_keyDisableAnimationsUserPref)) {
      return prefs.getBool(_keyDisableAnimationsUserPref) ?? false;
    }
    return _detectLowPowerDefault();
  }

  static bool _detectLowPowerDefault() {
    try {
      final accessibilityDisabled =
          WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
      if (accessibilityDisabled) return true;
    } catch (_) {}

    if (kIsWeb) return false;
    return false;
  }

  @override
  bool build() {
    return isAnimationsDisabled(_prefs);
  }

  Future<void> setDisabled(bool value) async {
    state = value;
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setBool(_keyDisableAnimationsUserPref, value);
    }
  }

  Future<void> toggle() async {
    await setDisabled(!state);
  }
}
