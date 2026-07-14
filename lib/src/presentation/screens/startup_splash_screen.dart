import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class StartupSplashScreen extends StatefulWidget {
  const StartupSplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<StartupSplashScreen> createState() => _StartupSplashScreenState();
}

class _StartupSplashScreenState extends State<StartupSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _fallbackTimer;
  Timer? _finishTimer;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _scheduleFinish();
        }
      });
    _fallbackTimer = Timer(const Duration(seconds: 4), _finish);
  }

  void _play(LottieComposition composition) {
    if (!mounted || _controller.isAnimating || _controller.isCompleted) return;
    _controller.duration = composition.duration;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _scheduleFinish();
      return;
    }
    _controller.forward();
  }

  void _scheduleFinish() {
    if (_finishing || _finishTimer != null) return;
    _finishTimer = Timer(const Duration(milliseconds: 250), _finish);
  }

  void _finish() {
    if (!mounted || _finishing) return;
    _finishing = true;
    _fallbackTimer?.cancel();
    _finishTimer?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _finishTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final dimension = math.min(shortestSide, 560.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Semantics(
          label: 'Wreadom',
          image: true,
          child: SizedBox.square(
            dimension: dimension,
            child: Lottie.asset(
              'assets/animations/startup_splash.json',
              controller: _controller,
              fit: BoxFit.contain,
              repeat: false,
              onLoaded: _play,
              errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}
