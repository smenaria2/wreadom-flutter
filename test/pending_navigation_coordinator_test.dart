import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/presentation/routing/pending_navigation_coordinator.dart';

void main() {
  test('pending target drains only when every readiness gate is true', () {
    final coordinator = PendingNavigationCoordinator();
    const target = RouteSettings(
      name: AppRoutes.bookDetail,
      arguments: 'book-1',
    );

    coordinator.setTarget(target);
    coordinator.updateReadiness(
      firebaseReady: true,
      authenticated: true,
      emailVerified: true,
      onboardingReady: false,
      navigatorReady: true,
    );

    expect(coordinator.takeReadyTarget(), isNull);
    expect(coordinator.hasPendingTarget, isTrue);

    coordinator.updateReadiness(onboardingReady: true);

    expect(coordinator.takeReadyTarget(), same(target));
    expect(coordinator.takeReadyTarget(), isNull);
  });

  test('logout clear prevents a protected target from reopening', () {
    final coordinator = PendingNavigationCoordinator();
    coordinator
      ..setTarget(const RouteSettings(name: AppRoutes.writerDashboard))
      ..updateReadiness(
        firebaseReady: true,
        authenticated: true,
        emailVerified: true,
        onboardingReady: true,
        navigatorReady: false,
      )
      ..clear()
      ..updateReadiness(navigatorReady: true);

    expect(coordinator.takeReadyTarget(), isNull);
  });

  test('disposed coordinator rejects future targets', () {
    final coordinator = PendingNavigationCoordinator()..dispose();

    coordinator
      ..setTarget(const RouteSettings(name: AppRoutes.discovery))
      ..updateReadiness(
        firebaseReady: true,
        authenticated: true,
        emailVerified: true,
        onboardingReady: true,
        navigatorReady: true,
      );

    expect(coordinator.hasPendingTarget, isFalse);
    expect(coordinator.takeReadyTarget(), isNull);
  });
}
