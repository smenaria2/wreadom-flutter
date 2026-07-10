import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user_model.dart';
import '../../utils/tier_utils.dart';
import 'theme_provider.dart';

class TierPromotion {
  const TierPromotion(this.tiers);

  final Map<RankTrack, int> tiers;

  bool get isEmpty => tiers.isEmpty;
}

class TierProgressStore {
  TierProgressStore(this._preferences);

  final SharedPreferences _preferences;
  bool _checking = false;

  Future<TierPromotion?> observe(UserModel user) async {
    if (_checking) return null;
    _checking = true;
    try {
      final promoted = <RankTrack, int>{};
      for (final track in RankTrack.values) {
        final points = track == RankTrack.author
            ? (user.authorPoints ?? 0)
            : (user.readerPoints ?? 0);
        if (points <= 0) continue;

        final currentTier = tierInfoFor(points, track).tier;
        final key = _key(user.id, track);
        final storedTier = _preferences.getInt(key);
        if (storedTier == null) {
          await _preferences.setInt(key, currentTier);
          continue;
        }
        if (currentTier > storedTier) {
          await _preferences.setInt(key, currentTier);
          promoted[track] = currentTier;
        }
      }
      return promoted.isEmpty ? null : TierPromotion(promoted);
    } finally {
      _checking = false;
    }
  }

  static String _key(String userId, RankTrack track) =>
      'rank_tier_max_${userId}_${track.value}';
}

final tierProgressStoreProvider = Provider<TierProgressStore>((ref) {
  return TierProgressStore(ref.watch(sharedPreferencesProvider));
});
