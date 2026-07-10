import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/presentation/providers/tier_progress_provider.dart';
import 'package:librebook_flutter/src/utils/tier_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first observation seeds active tracks without celebrating', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = TierProgressStore(prefs);

    expect(
      await store.observe(_user(authorPoints: 500, readerPoints: 0)),
      isNull,
    );
    expect(prefs.getInt('rank_tier_max_user-1_author'), 2);
    expect(prefs.containsKey('rank_tier_max_user-1_reader'), isFalse);
  });

  test('later tier increases are persisted and emitted together', () async {
    SharedPreferences.setMockInitialValues({
      'rank_tier_max_user-1_author': 1,
      'rank_tier_max_user-1_reader': 2,
    });
    final prefs = await SharedPreferences.getInstance();
    final store = TierProgressStore(prefs);

    final promotion = await store.observe(
      _user(authorPoints: 5000, readerPoints: 25000),
    );

    expect(promotion, isNotNull);
    expect(promotion!.tiers, {RankTrack.author: 3, RankTrack.reader: 4});
    expect(prefs.getInt('rank_tier_max_user-1_author'), 3);
    expect(prefs.getInt('rank_tier_max_user-1_reader'), 4);
    expect(
      await store.observe(_user(authorPoints: 5000, readerPoints: 25000)),
      isNull,
    );
  });

  test('decreases never lower the stored maximum or celebrate', () async {
    SharedPreferences.setMockInitialValues({'rank_tier_max_user-1_author': 5});
    final prefs = await SharedPreferences.getInstance();
    final store = TierProgressStore(prefs);

    expect(await store.observe(_user(authorPoints: 500)), isNull);
    expect(prefs.getInt('rank_tier_max_user-1_author'), 5);
  });
}

UserModel _user({int authorPoints = 0, int readerPoints = 0}) => UserModel(
  id: 'user-1',
  username: 'reader',
  email: 'reader@example.com',
  readingHistory: const [],
  savedBooks: const [],
  bookmarks: const [],
  authorPoints: authorPoints,
  readerPoints: readerPoints,
);
