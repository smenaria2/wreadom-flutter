import 'dart:async';

import 'package:flutter/material.dart';

/// Hosts transient feedback inside a modal route so it cannot be obscured by
/// the sheet itself. Outside a scope, [show] falls back to the page messenger.
class ModalFeedbackScope extends StatefulWidget {
  const ModalFeedbackScope({super.key, required this.child});

  final Widget child;

  static void show(BuildContext context, SnackBar snackBar) {
    final host = context
        .dependOnInheritedWidgetOfExactType<_ModalFeedbackHost>()
        ?.state;
    if (host != null) {
      host.show(snackBar);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  State<ModalFeedbackScope> createState() => _ModalFeedbackScopeState();
}

class _ModalFeedbackScopeState extends State<ModalFeedbackScope> {
  SnackBar? _snackBar;
  Timer? _dismissTimer;

  void show(SnackBar snackBar) {
    _dismissTimer?.cancel();
    setState(() => _snackBar = _withVisibleAnimation(snackBar));
    _dismissTimer = Timer(snackBar.duration, () {
      if (mounted) setState(() => _snackBar = null);
    });
  }

  SnackBar _withVisibleAnimation(SnackBar snackBar) {
    return SnackBar(
      key: snackBar.key,
      content: snackBar.content,
      backgroundColor: snackBar.backgroundColor,
      elevation: snackBar.elevation,
      margin: snackBar.margin,
      padding: snackBar.padding,
      width: snackBar.width,
      shape: snackBar.shape,
      hitTestBehavior: snackBar.hitTestBehavior,
      behavior: snackBar.behavior,
      action: snackBar.action,
      actionOverflowThreshold: snackBar.actionOverflowThreshold,
      showCloseIcon: snackBar.showCloseIcon,
      closeIconColor: snackBar.closeIconColor,
      duration: snackBar.duration,
      persist: snackBar.persist,
      animation: const AlwaysStoppedAnimation<double>(1),
      onVisible: snackBar.onVisible,
      dismissDirection: snackBar.dismissDirection,
      clipBehavior: snackBar.clipBehavior,
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return _ModalFeedbackHost(
      state: this,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_snackBar != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8 + bottomInset,
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey(_snackBar),
                    child: _snackBar!,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModalFeedbackHost extends InheritedWidget {
  const _ModalFeedbackHost({required this.state, required super.child});

  final _ModalFeedbackScopeState state;

  @override
  bool updateShouldNotify(_ModalFeedbackHost oldWidget) => false;
}
