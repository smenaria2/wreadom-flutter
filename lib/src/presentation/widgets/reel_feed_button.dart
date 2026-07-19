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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: l10n.openReelFeed,
      child: Tooltip(
        message: l10n.openReelFeed,
        child: SizedBox.square(
          dimension: 44,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (!reduceMotion)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final progress = Curves.easeOutCubic.transform(
                      _controller.value,
                    );
                    return Opacity(
                      opacity: .58 * (1 - progress),
                      child: Transform.scale(
                        scale: .76 + (.72 * progress),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 34),
                        ),
                      ),
                    );
                  },
                ),
              Material(
                color: Colors.transparent,
                child: InkResponse(
                  onTap: widget.onPressed,
                  radius: 22,
                  containedInkWell: true,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary,
                          Color.lerp(scheme.primary, scheme.tertiary, .55)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.onPrimary.withValues(alpha: .48),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: .42),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 24,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
