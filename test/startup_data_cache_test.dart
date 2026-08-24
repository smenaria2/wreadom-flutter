import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/startup_data_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('round trips public and UID-scoped values', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = StartupDataCache(prefs);

    await cache.write(scope: 'public_feed', value: ['post-1']);
    await cache.write(scope: 'profile', userId: 'user-a', value: {'name': 'A'});

    expect(
      cache.read<List<Object?>>(
        scope: 'public_feed',
        decode: (value) => List<Object?>.from(value! as List),
      ),
      ['post-1'],
    );
    expect(
      cache.read<Map<String, dynamic>>(
        scope: 'profile',
        userId: 'user-a',
        decode: (value) => Map<String, dynamic>.from(value! as Map),
      ),
      {'name': 'A'},
    );
    expect(
      cache.read<Map<String, dynamic>>(
        scope: 'profile',
        userId: 'user-b',
        decode: (value) => Map<String, dynamic>.from(value! as Map),
      ),
      isNull,
    );
  });

  test('discards malformed and unsupported envelopes', () async {
    const corruptKey = 'startup_data_cache_v1_corrupt_public';
    const oldKey = 'startup_data_cache_v1_old_public';
    SharedPreferences.setMockInitialValues({
      corruptKey: '{bad json',
      oldKey: jsonEncode({
        'schemaVersion': 0,
        'savedAt': 1,
        'userId': null,
        'value': {'stale': true},
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final cache = StartupDataCache(prefs);

    expect(
      cache.read<Object?>(scope: 'corrupt', decode: (value) => value),
      isNull,
    );
    expect(cache.read<Object?>(scope: 'old', decode: (value) => value), isNull);
    expect(prefs.containsKey(corruptKey), isFalse);
    expect(prefs.containsKey(oldKey), isFalse);
  });

  test('logout clears only the selected user scope', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = StartupDataCache(prefs);
    await cache.write(scope: 'feed', value: ['public']);
    await cache.write(scope: 'feed', userId: 'user-a', value: ['a']);
    await cache.write(scope: 'feed', userId: 'user-b', value: ['b']);

    await cache.clearUser('user-a');

    List<Object?>? read(String? userId) => cache.read<List<Object?>>(
      scope: 'feed',
      userId: userId,
      decode: (value) => List<Object?>.from(value! as List),
    );

    expect(read('user-a'), isNull);
    expect(read('user-b'), ['b']);
    expect(read(null), ['public']);
  });

  test(
    'logout does not clear an account whose UID only shares a suffix',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final cache = StartupDataCache(prefs);
      cache.activateUser('abc');
      cache.activateUser('x_abc');
      await cache.write(scope: 'profile', userId: 'abc', value: {'name': 'A'});
      await cache.write(
        scope: 'profile',
        userId: 'x_abc',
        value: {'name': 'B'},
      );

      await cache.clearUser('abc');

      expect(
        cache.read<Map<String, dynamic>>(
          scope: 'profile',
          userId: 'x_abc',
          decode: (value) => Map<String, dynamic>.from(value! as Map),
        ),
        {'name': 'B'},
      );
    },
  );

  test('blocked users cannot resurrect cache writes after logout', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = StartupDataCache(prefs);
    const userId = 'write-race-user';
    cache.activateUser(userId);
    await cache.clearUser(userId);

    expect(
      await cache.write(scope: 'feed', userId: userId, value: ['stale']),
      isFalse,
    );

    cache.activateUser(userId);
    expect(
      await cache.write(scope: 'feed', userId: userId, value: ['fresh']),
      isTrue,
    );
  });

  test('discards a current envelope with invalid savedAt metadata', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = StartupDataCache(prefs);
    await cache.write(scope: 'invalid-time', value: {'ok': true});
    final key = prefs.getKeys().single;
    final envelope = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
    envelope['savedAt'] = 'not-a-timestamp';
    await prefs.setString(key, jsonEncode(envelope));

    expect(
      cache.read<Object?>(scope: 'invalid-time', decode: (value) => value),
      isNull,
    );
    expect(prefs.containsKey(key), isFalse);
  });
}
