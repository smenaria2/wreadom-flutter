import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme provider falls back to light mode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(appThemeControllerProvider), ThemeMode.light);
  });

  test('theme provider restores and persists dark mode', () async {
    SharedPreferences.setMockInitialValues({'wreadom_theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(appThemeControllerProvider), ThemeMode.dark);

    await container
        .read(appThemeControllerProvider.notifier)
        .setThemeMode(ThemeMode.light);

    expect(container.read(appThemeControllerProvider), ThemeMode.light);
    expect(prefs.getString('wreadom_theme_mode'), 'light');
  });
}
