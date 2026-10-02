import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/homepage/homepage_metadata.dart';
import 'package:librebook_flutter/src/presentation/providers/daily_topic_providers.dart';
import 'package:librebook_flutter/src/presentation/providers/homepage_providers.dart';
import 'package:librebook_flutter/src/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'cached topics show without waiting for the homepage documents',
    () async {
      SharedPreferences.setMockInitialValues({
        'daily_topics_cache_v1': jsonEncode([
          {'id': 't1', 'topicName': 'Today', 'isEnabled': true, 'timestamp': 2},
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      // Simulates the slow compiled homepage fetch on Android.
      final metadata = Completer<HomepageMetadata>();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          homepageMetadataProvider.overrideWith((ref) => metadata.future),
        ],
      );
      addTearDown(container.dispose);

      final topics = await container
          .read(dailyTopicsProvider.future)
          .timeout(const Duration(seconds: 2));

      expect(topics.map((topic) => topic.id), ['t1']);
    },
  );
}
