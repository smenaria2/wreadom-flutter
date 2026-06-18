import 'package:flutter/material.dart';

class PendingNavigationCoordinator {
  RouteSettings? _target;
  bool _firebaseReady = false;
  bool _authenticated = false;
  bool _emailVerified = false;
  bool _onboardingReady = false;
  bool _navigatorReady = false;
  bool _disposed = false;

  bool get hasPendingTarget => _target != null;

  void setTarget(RouteSettings target) {
    if (_disposed) return;
    _target = target;
  }

  void updateReadiness({
    bool? firebaseReady,
    bool? authenticated,
    bool? emailVerified,
    bool? onboardingReady,
    bool? navigatorReady,
  }) {
    if (_disposed) return;
    _firebaseReady = firebaseReady ?? _firebaseReady;
    _authenticated = authenticated ?? _authenticated;
    _emailVerified = emailVerified ?? _emailVerified;
    _onboardingReady = onboardingReady ?? _onboardingReady;
    _navigatorReady = navigatorReady ?? _navigatorReady;
  }

  RouteSettings? takeReadyTarget() {
    if (_disposed ||
        !_firebaseReady ||
        !_authenticated ||
        !_emailVerified ||
        !_onboardingReady ||
        !_navigatorReady) {
      return null;
    }
    final target = _target;
    _target = null;
    return target;
  }

  void clear() {
    _target = null;
  }

  void dispose() {
    _disposed = true;
    clear();
  }
}
