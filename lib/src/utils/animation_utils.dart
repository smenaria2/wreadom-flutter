import 'package:flutter/material.dart';

extension AnimationContextX on BuildContext {
  /// Whether animations are disabled globally in the app or system.
  bool get disableAnimations => MediaQuery.of(this).disableAnimations;

  /// Returns [Duration.zero] if animations are disabled, otherwise returns [standard].
  Duration duration(Duration standard) =>
      disableAnimations ? Duration.zero : standard;
}
