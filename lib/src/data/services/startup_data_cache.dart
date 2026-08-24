import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'startup_performance.dart';

class CacheEnvelope<T> {
  const CacheEnvelope({
    required this.savedAt,
    required this.value,
    this.userId,
  });

  static const schemaVersion = 2;
  final int savedAt;
  final String? userId;
  final T value;
}

/// Small, versioned startup cache for first-page display data.
class StartupDataCache {
  StartupDataCache(this._prefs);

  final SharedPreferences _prefs;
  static const _prefix = 'startup_data_cache_v2_';
  static const _legacyPrefix = 'startup_data_cache_v1_';
  static final Map<String, int> _userGenerations = <String, int>{};
  static final Set<String> _blockedUsers = <String>{};

  T? read<T>({
    required String scope,
    String? userId,
    required T Function(Object? json) decode,
  }) {
    if (userId != null && _blockedUsers.contains(userId)) return null;
    final key = _key(scope, userId);
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      unawaited(_removeSafely(_legacyKey(scope, userId)));
      StartupPerformance.mark('cache_restore', page: scope, outcome: 'miss');
      return null;
    }
    try {
      final envelope = jsonDecode(raw);
      if (envelope is! Map) throw const FormatException();
      if (envelope['schemaVersion'] != CacheEnvelope.schemaVersion) {
        throw const FormatException();
      }
      final savedAt = envelope['savedAt'];
      if (savedAt is! int || savedAt <= 0) throw const FormatException();
      final cachedUserId = envelope['userId']?.toString();
      if (cachedUserId != userId) throw const FormatException();
      final value = decode(envelope['value']);
      StartupPerformance.mark('cache_restore', page: scope, outcome: 'hit');
      return value;
    } catch (_) {
      unawaited(_removeSafely(key));
      StartupPerformance.mark(
        'cache_restore',
        page: scope,
        outcome: 'discarded',
      );
      return null;
    }
  }

  Future<bool> write({
    required String scope,
    String? userId,
    required Object? value,
  }) async {
    if (userId != null && _blockedUsers.contains(userId)) return false;
    final generation = userId == null ? 0 : (_userGenerations[userId] ?? 0);
    final key = _key(scope, userId);
    final encodedEnvelope = jsonEncode({
      'schemaVersion': CacheEnvelope.schemaVersion,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'userId': userId,
      'value': value,
    });
    try {
      final written = await _prefs.setString(key, encodedEnvelope);
      if (userId != null &&
          (_blockedUsers.contains(userId) ||
              (_userGenerations[userId] ?? 0) != generation)) {
        if (_prefs.getString(key) == encodedEnvelope) {
          await _removeSafely(key);
        }
        return false;
      }
      return written;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearUser(String userId) async {
    _userGenerations[userId] = (_userGenerations[userId] ?? 0) + 1;
    _blockedUsers.add(userId);
    final ownerPrefix = '$_prefix${_ownerToken(userId)}_';
    final keys = <String>{
      ..._prefs.getKeys().where((key) => key.startsWith(ownerPrefix)),
      ..._legacyKeysForUser(userId),
    };
    await Future.wait(keys.map(_removeSafely));
  }

  void activateUser(String userId) {
    _blockedUsers.remove(userId);
  }

  Future<void> remove({required String scope, String? userId}) async {
    await Future.wait([
      _removeSafely(_key(scope, userId)),
      _removeSafely(_legacyKey(scope, userId)),
    ]);
  }

  String _key(String scope, String? userId) {
    final safeScope = Uri.encodeComponent(scope);
    return '$_prefix${_ownerToken(userId)}_$safeScope';
  }

  String _legacyKey(String scope, String? userId) {
    final safeScope = Uri.encodeComponent(scope);
    final owner = userId == null ? 'public' : Uri.encodeComponent(userId);
    return '$_legacyPrefix${safeScope}_$owner';
  }

  String _ownerToken(String? userId) {
    if (userId == null) return 'public';
    final encoded = Uri.encodeComponent(userId);
    return 'user${encoded.length}_$encoded';
  }

  Iterable<String> _legacyKeysForUser(String userId) sync* {
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_legacyPrefix)) continue;
      try {
        final raw = _prefs.getString(key);
        final envelope = raw == null ? null : jsonDecode(raw);
        if (envelope is Map && envelope['userId']?.toString() == userId) {
          yield key;
        }
      } catch (_) {
        // A corrupt legacy entry cannot be safely attributed to an account.
      }
    }
  }

  Future<void> _removeSafely(String key) async {
    try {
      await _prefs.remove(key);
    } catch (_) {
      // Cache cleanup must never affect the user-facing flow.
    }
  }
}
