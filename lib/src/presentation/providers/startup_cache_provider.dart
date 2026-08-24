import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/startup_data_cache.dart';
import 'theme_provider.dart';

/// The app always overrides SharedPreferences. Returning null keeps isolated
/// provider tests and degraded bootstrap paths functional without disk cache.
final startupDataCacheProvider = Provider<StartupDataCache?>((ref) {
  try {
    return StartupDataCache(ref.watch(sharedPreferencesProvider));
  } catch (_) {
    return null;
  }
});
