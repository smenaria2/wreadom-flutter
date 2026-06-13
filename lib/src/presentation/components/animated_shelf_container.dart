import 'package:flutter/material.dart';

class AnimatedShelfContainer extends StatefulWidget {
  final Widget child;
  final bool visible;
  final Duration duration;

  const AnimatedShelfContainer({
    super.key,
    required this.child,
    required this.visible,
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  State<AnimatedShelfContainer> createState() => _AnimatedShelfContainerState();
}

class _AnimatedShelfContainerState extends State<AnimatedShelfContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (widget.visible) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedShelfContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28.0),
          child: widget.child,
        ),
      ),
    );
  }
}
