import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key, required this.userId, required this.child});

  final String userId;
  final Widget child;

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  bool _checked = false;
  bool _showGuide = false;

  String get _prefsKey => 'onboarding_seen_${widget.userId}_v1';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void didUpdateWidget(covariant OnboardingGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _checked = false;
      _showGuide = false;
      _loadState();
    }
  }

  Future<void> _loadState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final seen = prefs.getBool(_prefsKey) ?? false;
    if (!mounted) return;
    setState(() {
      _checked = true;
      _showGuide = !seen;
    });
  }

  Future<void> _complete() async {
    await ref.read(sharedPreferencesProvider).setBool(_prefsKey, true);
    if (!mounted) return;
    setState(() => _showGuide = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showGuide) {
      return _OnboardingGuide(onComplete: _complete);
    }
    return widget.child;
  }
}

class _OnboardingGuide extends StatefulWidget {
  const _OnboardingGuide({required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<_OnboardingGuide> createState() => _OnboardingGuideState();
}

class _OnboardingGuideState extends State<_OnboardingGuide> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _closing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_closing) return;
    setState(() => _closing = true);
    await widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final slides = _slides(l10n);
    final isLast = _index == slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF101828), Color(0xFF3D2C8D), Color(0xFF0F766E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Text(
                      l10n.appTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _closing ? null : _finish,
                      child: Text(
                        l10n.skip,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) =>
                      _SlideView(slide: slides[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _index ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.32),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _index == 0 || _closing
                                ? null
                                : () => _controller.previousPage(
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOut,
                                  ),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(l10n.back),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.42),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _closing
                                ? null
                                : isLast
                                ? _finish
                                : () => _controller.nextPage(
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOut,
                                  ),
                            icon: Icon(
                              isLast
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                            label: Text(isLast ? l10n.done : l10n.next),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_OnboardingSlide> _slides(AppLocalizations l10n) => [
    _OnboardingSlide(
      icon: Icons.explore_rounded,
      title: l10n.onboardingDiscoverTitle,
      body: l10n.onboardingDiscoverBody,
      accent: const Color(0xFF38BDF8),
    ),
    _OnboardingSlide(
      icon: Icons.offline_bolt_rounded,
      title: l10n.onboardingOfflineTitle,
      body: l10n.onboardingOfflineBody,
      accent: const Color(0xFFFACC15),
    ),
    _OnboardingSlide(
      icon: Icons.edit_note_rounded,
      title: l10n.onboardingWriteTitle,
      body: l10n.onboardingWriteBody,
      accent: const Color(0xFFF97316),
    ),
    _OnboardingSlide(
      icon: Icons.forum_rounded,
      title: l10n.onboardingCommunityTitle,
      body: l10n.onboardingCommunityBody,
      accent: const Color(0xFFA78BFA),
    ),
    _OnboardingSlide(
      icon: Icons.person_pin_rounded,
      title: l10n.onboardingProfileTitle,
      body: l10n.onboardingProfileBody,
      accent: const Color(0xFF34D399),
    ),
  ];
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: slide.accent.withValues(alpha: 0.34),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(slide.icon, color: slide.accent, size: 64),
          ),
          const SizedBox(height: 34),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
}
