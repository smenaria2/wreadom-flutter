import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

class ReelFeedButton extends StatefulWidget {
  const ReelFeedButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<ReelFeedButton> createState() => _ReelFeedButtonState();
}

class _ReelFeedButtonState extends State<ReelFeedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _zoom;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _zoom = Tween<double>(begin: .98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final topBarColor = IconTheme.of(context).color ?? scheme.onSurface;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: l10n.openReelFeed,
      child: Tooltip(
        message: l10n.openReelFeed,
        child: SizedBox.square(
          dimension: 34,
          child: AnimatedBuilder(
            animation: _zoom,
            builder: (context, child) => Transform.scale(
              scale: reduceMotion ? 1 : _zoom.value,
              child: child,
            ),
            child: Material(
              color: topBarColor.withValues(alpha: .10),
              shape: CircleBorder(
                side: BorderSide(color: scheme.primary.withValues(alpha: .38)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkResponse(
                onTap: widget.onPressed,
                radius: 17,
                containedInkWell: true,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 21,
                    color: topBarColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
