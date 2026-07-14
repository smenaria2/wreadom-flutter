import 'package:flutter/material.dart';

typedef SharedRouteTargetHandler = void Function(RouteSettings target);

class SharingIntentHandler {
  SharingIntentHandler._();
  static final SharingIntentHandler instance = SharingIntentHandler._();

  Future<bool> hasInitialShare() async => false;

  void init(
    GlobalKey<NavigatorState> navigatorKey, {
    SharedRouteTargetHandler? onSharedTarget,
  }) {}

  void dispose() {}
}
