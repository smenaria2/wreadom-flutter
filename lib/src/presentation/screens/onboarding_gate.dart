import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_surface.dart';
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

  String get _prefsKey => 'onboarding_seen_${widget.userId}_v2';

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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        width: 34,
                        height: 34,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.appTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _closing ? null : _finish,
                        child: Text(
                          l10n.skip,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.32),
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
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      curve: Curves.easeOut,
                                    ),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: Text(l10n.back),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
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
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
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
        ],
      ),
    );
  }

  List<_OnboardingSlide> _slides(AppLocalizations l10n) => [
    _OnboardingSlide(
      logoAsset: 'assets/images/app_logo.png',
      title: l10n.onboardingWelcomeTitle,
      tagline: l10n.onboardingWelcomeTagline,
      body: l10n.onboardingWelcomeBody,
      bullets: [
        l10n.onboardingWelcomeBulletRead,
        l10n.onboardingWelcomeBulletWrite,
        l10n.onboardingWelcomeBulletConnect,
      ],
      accent: const Color(0xFF38BDF8),
    ),
    _OnboardingSlide(
      icon: Icons.auto_stories_rounded,
      title: l10n.onboardingReadersTitle,
      body: l10n.onboardingReadersBody,
      bullets: [
        l10n.onboardingReadersBulletDiscover,
        l10n.onboardingReadersBulletListen,
        l10n.onboardingReadersBulletOffline,
        l10n.onboardingReadersBulletVoice,
      ],
      accent: const Color(0xFFFACC15),
    ),
    _OnboardingSlide(
      icon: Icons.edit_note_rounded,
      title: l10n.onboardingAuthorsTitle,
      body: l10n.onboardingAuthorsBody,
      bullets: [
        l10n.onboardingAuthorsBulletTools,
        l10n.onboardingAuthorsBulletCollab,
        l10n.onboardingAuthorsBulletInspiration,
        l10n.onboardingAuthorsBulletDashboard,
      ],
      accent: const Color(0xFFF97316),
    ),
    _OnboardingSlide(
      icon: Icons.forum_rounded,
      title: l10n.onboardingCommunityTitle,
      body: l10n.onboardingCommunityBody,
      bullets: [
        l10n.onboardingCommunityBulletReact,
        l10n.onboardingCommunityBulletFollow,
        l10n.onboardingCommunityBulletMessage,
        l10n.swipeHintBookComments,
        l10n.swipeHintMessages,
      ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 560;
        final circleSize = compact ? 104.0 : 128.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, compact ? 10 : 18, 28, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 30
                  ? constraints.maxHeight - 30
                  : 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: circleSize,
                  child: ClipOval(
                    child: GlassSurface(
                      strong: true,
                      borderRadius: BorderRadius.circular(circleSize / 2),
                      child: Center(
                        child: slide.logoAsset == null
                            ? Icon(
                                slide.icon,
                                color: slide.accent,
                                size: compact ? 50 : 60,
                              )
                            : Padding(
                                padding: EdgeInsets.all(compact ? 18 : 22),
                                child: Image.asset(
                                  slide.logoAsset!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 18 : 24),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                if (slide.tagline != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    slide.tagline!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: slide.accent,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
                SizedBox(height: compact ? 10 : 14),
                Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.36,
                  ),
                ),
                if (slide.bullets.isNotEmpty) ...[
                  SizedBox(height: compact ? 14 : 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        for (final bullet in slide.bullets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: slide.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    this.icon,
    this.logoAsset,
    required this.title,
    this.tagline,
    required this.body,
    this.bullets = const [],
    required this.accent,
  }) : assert(icon != null || logoAsset != null);

  final IconData? icon;
  final String? logoAsset;
  final String title;
  final String? tagline;
  final String body;
  final List<String> bullets;
  final Color accent;
}
