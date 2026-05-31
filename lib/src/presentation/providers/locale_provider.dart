import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart'; // To reuse sharedPreferencesProvider

const _localeKey = 'wreadom_locale';

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final languageCode = prefs.getString(_localeKey);
    // Default to 'en' if no preference is saved
    return languageCode != null ? Locale(languageCode) : const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, locale.languageCode);
    await _syncPreferredLanguage(locale.languageCode);
  }

  Future<void> syncPreferredLanguage() {
    return _syncPreferredLanguage(state.languageCode);
  }

  Future<void> _syncPreferredLanguage(String languageCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'preferredLanguage': languageCode,
      });
    } catch (_) {
      // The local preference is still saved; push localization catches up when
      // the profile write succeeds on a later language change.
    }
  }
}
