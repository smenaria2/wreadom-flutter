import 'dart:async';

/// Maximum time an optimistic UI mutation may remain unresolved before it is
/// treated as failed and surfaced to the user.
const optimisticMutationTimeout = Duration(seconds: 8);

/// Avoids flashing a failure toast in the same instant as the optimistic UI
/// update while still surfacing genuine failures promptly.
const optimisticFailureFeedbackDelay = Duration(milliseconds: 700);

Future<T> runOptimisticMutation<T>(Future<T> mutation) async {
  final stopwatch = Stopwatch()..start();
  try {
    return await mutation.timeout(optimisticMutationTimeout);
  } catch (_) {
    final remaining = optimisticFailureFeedbackDelay - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    rethrow;
  }
}
