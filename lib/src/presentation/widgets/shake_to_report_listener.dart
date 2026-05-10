import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../providers/auth_providers.dart';
import '../providers/shake_report_provider.dart';
import 'submit_error_dialog.dart';

class ShakeToReportListener extends ConsumerStatefulWidget {
  const ShakeToReportListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<ShakeToReportListener> createState() =>
      _ShakeToReportListenerState();
}

class _ShakeToReportListenerState extends ConsumerState<ShakeToReportListener> {
  static const double _shakeThreshold = 27;
  static const Duration _shakeCooldown = Duration(seconds: 3);

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeAt;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSubscription());
  }

  @override
  void didUpdateWidget(covariant ShakeToReportListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSubscription();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(shakeToReportEnabledProvider, (previous, next) {
      _syncSubscription();
    });
    ref.listen(authStateProvider, (previous, next) {
      _syncSubscription();
    });
    return widget.child;
  }

  void _syncSubscription() {
    if (!mounted) return;
    final enabled = ref.read(shakeToReportEnabledProvider);
    final signedIn = ref.read(authStateProvider).asData?.value != null;
    final shouldListen = enabled && signedIn;
    if (shouldListen && _subscription == null) {
      _subscription = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(_handleAccelerometerEvent);
    } else if (!shouldListen && _subscription != null) {
      unawaited(_subscription?.cancel());
      _subscription = null;
    }
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final force = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (force < _shakeThreshold) return;

    final now = DateTime.now();
    final lastShakeAt = _lastShakeAt;
    if (_dialogOpen ||
        (lastShakeAt != null && now.difference(lastShakeAt) < _shakeCooldown)) {
      return;
    }
    _lastShakeAt = now;
    _openReportDialog();
  }

  Future<void> _openReportDialog() async {
    final context = widget.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.mustBeLoggedInToSubmitIssues)),
      );
      return;
    }

    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (context) => const SubmitErrorDialog(),
      );
    } finally {
      _dialogOpen = false;
    }
  }
}
