import 'package:flutter/foundation.dart';

/// Privacy-safe checkpoints used to compare cold and warm startup behavior.
class StartupPerformance {
  StartupPerformance._();

  static final Stopwatch _session = Stopwatch()..start();
  static final String correlationId = DateTime.now().microsecondsSinceEpoch
      .toRadixString(36);
  static final Set<String> _once = <String>{};

  static void mark(
    String checkpoint, {
    String? page,
    String? outcome,
    Duration? elapsed,
    bool once = false,
  }) {
    final onceKey = '$checkpoint:${page ?? ''}';
    if (once && !_once.add(onceKey)) return;
    final measured = elapsed ?? _session.elapsed;
    final safeCheckpoint = _safeLabel(checkpoint);
    final safePage = page == null ? null : _safeLabel(page);
    final safeOutcome = outcome == null ? null : _safeLabel(outcome);
    debugPrint(
      '[startup_perf] correlation=$correlationId checkpoint=$safeCheckpoint '
      '${safePage == null ? '' : 'page=$safePage '}'
      '${safeOutcome == null ? '' : 'outcome=$safeOutcome '}'
      'elapsed_ms=${measured.inMilliseconds}',
    );
  }

  static String _safeLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (RegExp(r'^[a-z0-9_\-]{1,64}$').hasMatch(normalized)) {
      return normalized;
    }
    return 'redacted';
  }
}
