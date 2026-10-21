import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../localization/generated/app_localizations.dart';

const readerPageGestureGuideSeenKey = 'reader_page_gesture_guide_seen_v1';

/// An ancestor tap recognizer: descendants keep their own controls and the
/// scrollable wins drags. No invisible hit-test overlay covers the text.
class ReaderPageGestures extends StatefulWidget {
  const ReaderPageGestures({
    super.key,
    required this.controller,
    required this.preferences,
    required this.enabled,
    required this.ready,
    required this.child,
    this.blocked = false,
    this.obscuredInsets = EdgeInsets.zero,
    this.onTap,
    this.onTapUp,
    this.onTurningChanged,
    this.onToggleChrome,
    this.guideTheme,
    this.selectionWrapper,
  });

  final ScrollController controller;
  final SharedPreferences preferences;
  final bool enabled;
  final bool ready;
  final bool blocked;
  final EdgeInsets obscuredInsets;
  final Widget child;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onTapUp;
  final ValueChanged<bool>? onTurningChanged;
  final VoidCallback? onToggleChrome;
  final ThemeData? guideTheme;
  // Selection surrounds the content recognizer so it can still own long
  // presses; interactive content remains below both recognizers.
  final Widget Function(Widget child)? selectionWrapper;

  @override
  State<ReaderPageGestures> createState() => _ReaderPageGesturesState();
}

class _ReaderPageGesturesState extends State<ReaderPageGestures> {
  bool _turning = false;
  bool _resumeInterruptedTap = false;
  double? _pageTarget;
  bool _dismissed = false;

  bool get _contentTapsAvailable => widget.ready && !widget.blocked;
  bool get _available => widget.enabled && _contentTapsAvailable;
  bool get _uncovered =>
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      !(Scaffold.maybeOf(context)?.isDrawerOpen ?? false);

  @override
  void didUpdateWidget(ReaderPageGestures oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_available && _turning && widget.controller.hasClients) {
      // Scroll listeners update the parent reader's progress. Notify them after
      // its current build, rather than issuing setState during that build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_available &&
            _turning &&
            widget.controller.hasClients) {
          widget.controller.jumpTo(widget.controller.offset);
        }
      });
    }
  }

  Future<void> _turn(
    bool forward,
    double height, {
    double? resumeTarget,
  }) async {
    if (_turning || !widget.controller.hasClients) return;
    final position = widget.controller.position;
    final visibleHeight = height - widget.obscuredInsets.vertical;
    if (visibleHeight <= 0) return;
    final target =
        (resumeTarget ??
                (position.pixels + (forward ? 1 : -1) * visibleHeight * .9))
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    if (target == position.pixels) return;
    _pageTarget = target;
    _turning = true;
    widget.onTurningChanged?.call(true);
    try {
      if (MediaQuery.disableAnimationsOf(context)) {
        widget.controller.jumpTo(target);
      } else {
        await widget.controller.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } finally {
      _turning = false;
      if (mounted) widget.onTurningChanged?.call(false);
    }
  }

  void _dismissGuide() {
    setState(() => _dismissed = true);
    unawaited(widget.preferences.setBool(readerPageGestureGuideSeenKey, true));
  }

  @override
  Widget build(BuildContext context) {
    final showGuide =
        _available &&
        _uncovered &&
        !_dismissed &&
        widget.preferences.getBool(readerPageGestureGuideSeenKey) != true;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageContent = RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: {
            _ReaderTapRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  _ReaderTapRecognizer
                >(_ReaderTapRecognizer.new, (recognizer) {
                  recognizer.accepts = (event) {
                    // Scrollable cancels driven scrolling on pointer-down.
                    // A second tap resumes that target; a drag stays in charge.
                    _resumeInterruptedTap = _turning;
                    final point = event.localPosition;
                    return _contentTapsAvailable &&
                        _uncovered &&
                        point.dy >= widget.obscuredInsets.top &&
                        point.dy <
                            constraints.maxHeight -
                                widget.obscuredInsets.bottom &&
                        (widget.onToggleChrome != null ||
                            (widget.enabled &&
                                (point.dx < constraints.maxWidth * .15 ||
                                    point.dx >= constraints.maxWidth * .85)));
                  };
                  recognizer.onTapUp = (details) {
                    if (!_contentTapsAvailable || !_uncovered) return;
                    final x = details.localPosition.dx;
                    final isPageTap =
                        widget.enabled &&
                        (x < constraints.maxWidth * .15 ||
                            x >= constraints.maxWidth * .85);
                    if (!isPageTap) {
                      widget.onToggleChrome?.call();
                      return;
                    }
                    unawaited(
                      _turn(
                        details.localPosition.dx >= constraints.maxWidth * .85,
                        constraints.maxHeight,
                        resumeTarget: _resumeInterruptedTap
                            ? _pageTarget
                            : null,
                      ),
                    );
                  };
                }),
          },
          child: widget.child,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onTap,
              onTapUp: widget.onTapUp,
              child: widget.selectionWrapper?.call(pageContent) ?? pageContent,
            ),
            if (showGuide)
              Positioned.fill(
                top: widget.obscuredInsets.top,
                bottom: widget.obscuredInsets.bottom,
                child: Theme(
                  data: widget.guideTheme ?? Theme.of(context),
                  child: _GestureGuide(onDismiss: _dismissGuide),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GestureGuide extends StatelessWidget {
  const _GestureGuide({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label:
          '${l10n.readerPreviousScreen}. ${l10n.readerNextScreen}. '
          '${l10n.readerSwipeToScroll}. ${l10n.readerGestureDismiss}. '
          '${l10n.readerTapToToggleControls}. ${l10n.readerGestureSettingsHint}',
      onTap: onDismiss,
      child: ExcludeSemantics(
        child: GestureDetector(
          key: const Key('reader-gesture-guide'),
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          child: ColoredBox(
            color: colors.surface.withValues(alpha: .96),
            child: Row(
              children: [
                _edge(colors, Icons.arrow_back, l10n.readerPreviousScreen),
                Expanded(
                  flex: 70,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swipe_vertical,
                          color: colors.onSurface,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.readerSwipeToScroll,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.readerTapToToggleControls,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurface),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.readerGestureDismiss,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurface),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.readerGestureSettingsHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                _edge(colors, Icons.arrow_forward, l10n.readerNextScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _edge(ColorScheme colors, IconData icon, String label) => Expanded(
    flex: 15,
    child: ColoredBox(
      color: colors.primaryContainer,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.onPrimaryContainer),
            const SizedBox(height: 12),
            Flexible(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  label,
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReaderTapRecognizer extends TapGestureRecognizer {
  bool Function(PointerDownEvent event)? accepts;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      (accepts?.call(event) ?? false) && super.isPointerAllowed(event);
}
