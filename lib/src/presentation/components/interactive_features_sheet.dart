import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/glass_surface.dart';

class InteractiveFeaturesSheet extends StatefulWidget {
  const InteractiveFeaturesSheet({super.key, this.prominent = false});

  final bool prominent;

  @override
  State<InteractiveFeaturesSheet> createState() => _InteractiveFeaturesSheetState();
}

class _InteractiveFeaturesSheetState extends State<InteractiveFeaturesSheet> {
  late final PageController _pageController;
  late int _currentPage;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = math.Random().nextInt(18);
    _pageController = PageController(initialPage: _currentPage);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % 18;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final slides = [
      _SlideData(
        title: "Swipe to Reply",
        description: "Swipe right on any review to quickly reply to that review.",
        animation: const _SwipeToReplyAnimation(),
      ),
      _SlideData(
        title: "Double-Tap to Like",
        description: "Double-tap a post or comment to like that post or comment  .",
        animation: const _DoubleTapToLikeAnimation(),
      ),
      _SlideData(
        title: "Share Review Card",
        description: "Share reviews as a beautifully formatted review card.",
        animation: const _ShareCommentCardAnimation(),
      ),
      _SlideData(
        title: "Share Profile Card",
        description: "Generate and export a personalized visiting card for your profile.",
        animation: const _ShareProfileCardAnimation(),
      ),
      _SlideData(
        title: "Answer Post Questions",
        description: "Tap the reply icon next to any question to submit your response.",
        animation: const _AnswerQuestionAnimation(),
      ),
      _SlideData(
        title: "Import from Drafts",
        description: "Import single-chapter draft directly into your book.",
        animation: const _ImportDraftsAnimation(),
      ),
      _SlideData(
        title: "Attach Book Leaves",
        description: "Tap the 'leaf icon' on book page to attach notes, questions, links and media.",
        animation: const _AddLeafAnimation(),
      ),
      _SlideData(
        title: "Invite Co-Authors",
        description: "Enable collaboration on book detail page and invite a co-author.",
        animation: const _InviteCoAuthorAnimation(),
      ),
      _SlideData(
        title: "Ebook PDF Mode",
        description: "Tap the PDF icon in the reader bar on internet archieve book to switch to pdf mode.",
        animation: const _PdfModeAnimation(),
      ),
      _SlideData(
        title: "Text Selection Menu",
        description: "Drag text pins in the reader to prompt options like Share Quote, Read Aloud or Quote.",
        animation: const _TextSelectionAnimation(),
      ),
      _SlideData(
        title: "TTS Tap-to-Seek",
        description: "Tap any paragraph during TTS playback to jump narration to that sentence.",
        animation: const _TtsTapToSeekAnimation(),
      ),
      _SlideData(
        title: "Save & Download Book",
        description: "Tap the bookmark icon to save books offline and read them anywhere.",
        animation: const _DownloadBookAnimation(),
      ),
      _SlideData(
        title: "Record Voice Comments",
        description: "Hold the microphone icon in comment field to send audio review/reply.",
        animation: const _VoiceCommentAnimation(),
      ),
      _SlideData(
        title: "Audio Post Playback",
        description: "Play audio reviews, adjust progress, and listen to voice posts.",
        animation: const _AudioPlayerAnimation(),
      ),
      _SlideData(
        title: "Swipe to Delete Message",
        description: "Swipe your sent chat message bubbles to the left to delete them.",
        animation: const _SwipeToDeleteMessageAnimation(),
      ),
      _SlideData(
        title: "Make Profile Private",
        description: "Change your privacy level in settings to restrict profile visibility.",
        animation: const _MakePrivateAnimation(),
      ),
      _SlideData(
        title: "Theme Selection Dialog",
        description: "Tap theme in your preferences and choose between Light and Dark mode.",
        animation: const _ThemeSelectionAnimation(),
      ),
      _SlideData(
        title: "Change App Language",
        description: "Switch your app localization dynamically between English and Hindi.",
        animation: const _LanguageSwitcherAnimation(),
      ),
      _SlideData(
        title: "Create Collections",
        description: "Group your favorite books into public or private collections on your profile.",
        animation: const _CollectionAnimation(),
      ),
      _SlideData(
        title: "Earn & Compete",
        description: "Gain reading and writing points to rise up the rank tiers on the leaderboard.",
        animation: const _LeaderboardAnimation(),
      ),
    ];

    return GlassSurface(
      strong: true,
      borderRadius: BorderRadius.circular(widget.prominent ? 20 : 24),
      margin: EdgeInsets.fromLTRB(16, widget.prominent ? 16 : 8, 16, 8),
      padding: EdgeInsets.all(widget.prominent ? 18 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Interactive Features Guide",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Carousel Area
          SizedBox(
            height: widget.prominent ? 188 : 160,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
                _startAutoPlay(); // Reset autoplay timer
              },
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Row(
                  children: [
                    // Animation View
                    Container(
                      width: 140,
                      height: 130,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.15),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: slide.animation,
                    ),
                    const SizedBox(width: 16),
                    // Copy Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slide.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            slide.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.4,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Control Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Slide Numbers indicator
              Text(
                "${_currentPage + 1} / 18",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Navigation Buttons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: _currentPage == 0
                        ? null
                        : () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: _currentPage == slides.length - 1
                        ? null
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String title;
  final String description;
  final Widget animation;

  _SlideData({
    required this.title,
    required this.description,
    required this.animation,
  });
}

// Helper Widget for Tap Indicator
class _FingerTapIndicator extends StatelessWidget {
  final double opacity;
  final double scale;
  final Color color;

  const _FingerTapIndicator({
    required this.opacity,
    required this.scale,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            color: color.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}

// ─── Animation 1: Swipe to Reply ───
class _SwipeToReplyAnimation extends StatefulWidget {
  const _SwipeToReplyAnimation();

  @override
  State<_SwipeToReplyAnimation> createState() => _SwipeToReplyAnimationState();
}

class _SwipeToReplyAnimationState extends State<_SwipeToReplyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fingerOpacity;
  late Animation<double> _fingerSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _slideAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 50.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(50.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 50.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
    ]).animate(_controller);
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.6), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.6), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
    ]).animate(_controller);
    _fingerSlide = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(15.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 15.0, end: 65.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(65.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 14,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.reply_rounded, color: Colors.white, size: 12),
          ),
        ),
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_slideAnimation.value, 0),
              child: Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 5, backgroundColor: scheme.primary),
                        const SizedBox(width: 4),
                        Container(width: 32, height: 3, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(width: 80, height: 2.5, color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 3),
                    Container(width: 50, height: 2.5, color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _fingerSlide,
          builder: (context, child) {
            return Positioned(
              left: _fingerSlide.value,
              child: Opacity(
                opacity: _fingerOpacity.value,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 2: Double-Tap to Like ───
class _DoubleTapToLikeAnimation extends StatefulWidget {
  const _DoubleTapToLikeAnimation();

  @override
  State<_DoubleTapToLikeAnimation> createState() => _DoubleTapToLikeAnimationState();
}

class _DoubleTapToLikeAnimationState extends State<_DoubleTapToLikeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  late Animation<double> _fingerTapOpacity;
  late Animation<double> _fingerTapScale;
  late Animation<int> _likeCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.2), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
    ]).animate(_controller);
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.95), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.95), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
    ]).animate(_controller);
    _fingerTapOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 69),
    ]).animate(_controller);
    _fingerTapScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.6), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 1.0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 8),
      TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 1.0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 77),
    ]).animate(_controller);
    _likeCount = IntTween(begin: 14, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.40, 0.45, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 5, backgroundColor: scheme.tertiary),
                  const SizedBox(width: 4),
                  Container(width: 32, height: 3, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 10),
              Container(width: 90, height: 30, decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 10),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _likeCount,
                    builder: (context, child) {
                      final hasLiked = _likeCount.value == 15;
                      return Icon(
                        hasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: hasLiked ? Colors.red : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        size: 11,
                      );
                    },
                  ),
                  const SizedBox(width: 3),
                  AnimatedBuilder(
                    animation: _likeCount,
                    builder: (context, child) {
                      return Text('${_likeCount.value}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: scheme.onSurfaceVariant.withValues(alpha: 0.8)));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _heartScale.value,
              child: Opacity(
                opacity: _heartOpacity.value,
                child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 38),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _fingerTapOpacity,
          builder: (context, child) {
            return Opacity(
              opacity: _fingerTapOpacity.value,
              child: Transform.scale(
                scale: _fingerTapScale.value,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.primary, width: 2)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 3: Share Comment Card ───
class _ShareCommentCardAnimation extends StatefulWidget {
  const _ShareCommentCardAnimation();

  @override
  State<_ShareCommentCardAnimation> createState() => _ShareCommentCardAnimationState();
}

class _ShareCommentCardAnimationState extends State<_ShareCommentCardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sheetY;
  late Animation<double> _fingerOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _sheetY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(100.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 100.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 100.0).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(100.0), weight: 5),
    ]).animate(_controller);
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 80),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Base Review Card
        Container(
          width: 110,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 80, height: 4, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 6),
              Container(width: 90, height: 30, color: scheme.surfaceContainerLow),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 30, height: 4, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  Icon(Icons.share_outlined, size: 10, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
        // Share Preview Bottom Sheet
        AnimatedBuilder(
          animation: _sheetY,
          builder: (context, child) {
            return Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Transform.translate(
                offset: Offset(0, _sheetY.value),
                child: Container(
                  height: 74,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                  ),
                  child: Column(
                    children: [
                      Container(width: 32, height: 3, color: scheme.outlineVariant, margin: const EdgeInsets.only(bottom: 6)),
                      Text("Share Preview", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: scheme.primary)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(6)),
                            child: Text("Feed", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(6)),
                            child: const Text("External", style: TextStyle(fontSize: 8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Tap Indicator over Share Icon
        Positioned(
          right: 12,
          bottom: 12,
          child: AnimatedBuilder(
            animation: _fingerOpacity,
            builder: (context, child) {
              return _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Animation 4: Share Profile Card ───
class _ShareProfileCardAnimation extends StatefulWidget {
  const _ShareProfileCardAnimation();

  @override
  State<_ShareProfileCardAnimation> createState() => _ShareProfileCardAnimationState();
}

class _ShareProfileCardAnimationState extends State<_ShareProfileCardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fingerOpacity;
  late Animation<double> _spinnerOpacity;
  late Animation<double> _trayY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 82),
    ]).animate(_controller);
    _spinnerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 12),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.8), weight: 5),
      TweenSequenceItem(tween: ConstantTween(0.8), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 0.0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 53),
    ]).animate(_controller);
    _trayY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(80.0), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 80.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 80.0), weight: 10),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Profile Page mockup
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 40, height: 5, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                    Icon(Icons.share_outlined, size: 12, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: 14),
                CircleAvatar(radius: 14, backgroundColor: scheme.primary),
                const SizedBox(height: 8),
                Container(width: 50, height: 3, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 4),
                Container(width: 80, height: 2.5, color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
        // Generation Spinner Overlay
        AnimatedBuilder(
          animation: _spinnerOpacity,
          builder: (context, child) {
            return Opacity(
              opacity: _spinnerOpacity.value,
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                ),
              ),
            );
          },
        ),
        // Share System Sheet
        AnimatedBuilder(
          animation: _trayY,
          builder: (context, child) {
            return Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Transform.translate(
                offset: Offset(0, _trayY.value),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6)],
                  ),
                  child: Column(
                    children: [
                      Container(width: 32, height: 2.5, color: scheme.outlineVariant, margin: const EdgeInsets.only(bottom: 6)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(Icons.message_rounded, size: 16, color: Colors.green[600]),
                          Icon(Icons.mail_rounded, size: 16, color: Colors.red[600]),
                          Icon(Icons.copy_rounded, size: 16, color: Colors.grey[700]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Tap Pointer over Share Icon
        Positioned(
          right: 8,
          top: 8,
          child: AnimatedBuilder(
            animation: _fingerOpacity,
            builder: (context, child) {
              return _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Animation 5: Answer Question ───
class _AnswerQuestionAnimation extends StatefulWidget {
  const _AnswerQuestionAnimation();

  @override
  State<_AnswerQuestionAnimation> createState() => _AnswerQuestionAnimationState();
}

class _AnswerQuestionAnimationState extends State<_AnswerQuestionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fingerOpacity;
  late Animation<double> _dialogOpacity;
  late Animation<int> _textCharacters;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 82),
    ]).animate(_controller);
    _dialogOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 12),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 2),
    ]).animate(_controller);
    _textCharacters = IntTween(begin: 0, end: 14).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.75, curve: Curves.linear)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Question Card
        Container(
          width: 110,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Question of Day", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: scheme.primary)),
              const SizedBox(height: 4),
              Container(width: 80, height: 3, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 60, height: 10, decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(4))),
                  Icon(Icons.reply_rounded, size: 12, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
        // Overlay Dialog
        AnimatedBuilder(
          animation: _dialogOpacity,
          builder: (context, child) {
            return Opacity(
              opacity: _dialogOpacity.value,
              child: Transform.scale(
                scale: _dialogOpacity.value > 0.0 ? 0.8 + (_dialogOpacity.value * 0.2) : 0.8,
                child: child,
              ),
            );
          },
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Your Answer", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 24,
                  padding: const EdgeInsets.all(4),
                  color: scheme.surfaceContainerLow,
                  alignment: Alignment.topLeft,
                  child: AnimatedBuilder(
                    animation: _textCharacters,
                    builder: (context, child) {
                      const text = "Great thoughts!";
                      final currentText = text.substring(0, math.min(_textCharacters.value, text.length));
                      return Text(currentText, style: const TextStyle(fontSize: 7));
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(4)),
                  child: Text("Send", style: TextStyle(fontSize: 6, color: scheme.onPrimary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        // Tap Finger over reply icon
        Positioned(
          right: 12,
          bottom: 12,
          child: AnimatedBuilder(
            animation: _fingerOpacity,
            builder: (context, child) {
              return _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Animation 6: Import Drafts ───
class _ImportDraftsAnimation extends StatefulWidget {
  const _ImportDraftsAnimation();

  @override
  State<_ImportDraftsAnimation> createState() => _ImportDraftsAnimationState();
}

class _ImportDraftsAnimationState extends State<_ImportDraftsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fingerOpacity;
  late Animation<double> _dialogY;
  late Animation<bool> _checkboxChecked;
  late Animation<bool> _chaptersImported;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 8),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Tap Import Menu
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 6),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Tap Checkbox
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 6),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Tap Import Button
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 6),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 39),
    ]).animate(_controller);
    _dialogY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(90.0), weight: 14),
      TweenSequenceItem(tween: Tween<double>(begin: 90.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 12),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 90.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(90.0), weight: 14),
    ]).animate(_controller);
    _checkboxChecked = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(false), weight: 31),
      TweenSequenceItem(tween: ConstantTween(true), weight: 69),
    ]).animate(_controller);
    _chaptersImported = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(false), weight: 59),
      TweenSequenceItem(tween: ConstantTween(true), weight: 41),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Manuscript Page list
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 44, height: 4, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    Icon(Icons.get_app_rounded, size: 10, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: 10),
                // Chapter tiles
                Container(width: 100, height: 16, decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _chaptersImported,
                  builder: (context, child) {
                    if (!_chaptersImported.value) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4), border: Border.all(color: scheme.primary.withValues(alpha: 0.2))),
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          Icon(Icons.check_rounded, size: 8, color: scheme.primary),
                          const SizedBox(width: 4),
                          Container(width: 40, height: 3, color: scheme.primary.withValues(alpha: 0.6)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Import Dialog Drawer sliding up
        AnimatedBuilder(
          animation: _dialogY,
          builder: (context, child) {
            return Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Transform.translate(
                offset: Offset(0, _dialogY.value),
                child: Container(
                  height: 74,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Column(
                    children: [
                      Container(width: 32, height: 2, color: scheme.outlineVariant, margin: const EdgeInsets.only(bottom: 6)),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _checkboxChecked,
                            builder: (context, child) {
                              return Icon(
                                _checkboxChecked.value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                size: 11,
                                color: scheme.primary,
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Container(width: 50, height: 3, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        ],
                      ),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: _checkboxChecked,
                        builder: (context, child) {
                          final active = _checkboxChecked.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: active ? scheme.primary : scheme.outlineVariant, borderRadius: BorderRadius.circular(4)),
                            child: Text("Import Draft", style: TextStyle(fontSize: 7, color: active ? scheme.onPrimary : scheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Tap pointer
        AnimatedBuilder(
          animation: _fingerOpacity,
          builder: (context, child) {
            final double val = _controller.value;
            double x = 110;
            double y = 10;
            if (val > 0.20 && val < 0.40) {
              x = 10;
              y = 20;
            } else if (val > 0.45) {
              x = 44;
              y = 52;
            }
            return Positioned(
              left: x,
              top: y,
              child: _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 7: Add Leaf ───
class _AddLeafAnimation extends StatefulWidget {
  const _AddLeafAnimation();

  @override
  State<_AddLeafAnimation> createState() => _AddLeafAnimationState();
}

class _AddLeafAnimationState extends State<_AddLeafAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sheetY;
  late Animation<double> _fingerTap;
  late Animation<double> _fingerOpacity;
  late Animation<double> _selectedIconHighlight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _sheetY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(90.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 90.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 90.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(90.0), weight: 5),
    ]).animate(_controller);
    _fingerTap = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
    ]).animate(_controller);
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 3),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 33),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 46),
    ]).animate(_controller);
    _selectedIconHighlight = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 52),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 60, height: 4, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                const SizedBox(height: 6),
                Container(width: 100, height: 3, color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 4),
                Container(width: 80, height: 3, color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: scheme.primary.withValues(alpha: 0.22))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 10, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text("Leaf", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: scheme.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _sheetY,
          builder: (context, child) {
            return Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Transform.translate(
                offset: Offset(0, _sheetY.value),
                child: Container(
                  height: 66,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 50, height: 3, margin: const EdgeInsets.only(bottom: 6), color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          AnimatedBuilder(
                            animation: _selectedIconHighlight,
                            builder: (context, child) {
                              final active = _selectedIconHighlight.value > 0.5;
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: active ? scheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.edit_note_rounded, size: 16, color: active ? scheme.onPrimary : scheme.primary),
                              );
                            },
                          ),
                          Icon(Icons.question_mark_rounded, size: 16, color: scheme.secondary),
                          Icon(Icons.image_outlined, size: 16, color: scheme.tertiary),
                          Icon(Icons.link_rounded, size: 16, color: Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _fingerTap,
          builder: (context, child) {
            final isTap2 = _controller.value > 0.45;
            return Positioned(
              left: isTap2 ? 26 : 28,
              top: isTap2 ? 96 : 38,
              child: _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 8: Invite Co-Author ───
class _InviteCoAuthorAnimation extends StatefulWidget {
  const _InviteCoAuthorAnimation();

  @override
  State<_InviteCoAuthorAnimation> createState() => _InviteCoAuthorAnimationState();
}

class _InviteCoAuthorAnimationState extends State<_InviteCoAuthorAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fingerOpacity;
  late Animation<bool> _switchOn;
  late Animation<double> _drawerY;
  late Animation<double> _coauthorOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Toggle Switch
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Select Author
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 34),
    ]).animate(_controller);
    _switchOn = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(false), weight: 10),
      TweenSequenceItem(tween: ConstantTween(true), weight: 90),
    ]).animate(_controller);
    _drawerY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(60.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 60.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 75),
    ]).animate(_controller);
    _coauthorOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 58),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Settings Row
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 60, height: 4, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                    AnimatedBuilder(
                      animation: _switchOn,
                      builder: (context, child) {
                        final val = _switchOn.value;
                        return Container(
                          width: 22,
                          height: 12,
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(color: val ? scheme.primary : scheme.outlineVariant, borderRadius: BorderRadius.circular(6)),
                          alignment: val ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(width: 9, height: 9, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Invite search drawer
                AnimatedBuilder(
                  animation: _drawerY,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _drawerY.value),
                      child: Opacity(
                        opacity: _switchOn.value ? 1.0 : 0.0,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4),
                          color: scheme.surfaceContainerHigh,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 80, height: 12, decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(height: 4),
                              // Selected co-author card
                              AnimatedBuilder(
                                animation: _coauthorOpacity,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _coauthorOpacity.value,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                      child: Row(
                                        children: [
                                          CircleAvatar(radius: 4, backgroundColor: scheme.primary),
                                          const SizedBox(width: 4),
                                          Container(width: 32, height: 2, color: scheme.primary),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Tap Finger pointer
        AnimatedBuilder(
          animation: _fingerOpacity,
          builder: (context, child) {
            final val = _controller.value;
            double x = 110;
            double y = 6;
            if (val > 0.45) {
              x = 22;
              y = 44;
            }
            return Positioned(
              left: x,
              top: y,
              child: _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 9: PDF Mode ───
class _PdfModeAnimation extends StatefulWidget {
  const _PdfModeAnimation();

  @override
  State<_PdfModeAnimation> createState() => _PdfModeAnimationState();
}

class _PdfModeAnimationState extends State<_PdfModeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pdfOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _fingerTapOpacity;
  late Animation<bool> _isPdfActive;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 5),
    ]).animate(_controller);
    _pdfOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
    ]).animate(_controller);
    _fingerTapOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(_controller);
    _isPdfActive = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(false), weight: 30),
      TweenSequenceItem(tween: ConstantTween(true), weight: 50),
      TweenSequenceItem(tween: ConstantTween(false), weight: 20),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 110,
          decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2))),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                color: scheme.surfaceContainerHigh,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 32, height: 3, color: scheme.onSurface.withValues(alpha: 0.6)),
                    AnimatedBuilder(
                      animation: _isPdfActive,
                      builder: (context, child) {
                        return Icon(Icons.picture_as_pdf_outlined, size: 11, color: _isPdfActive.value ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.7));
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FadeTransition(
                      opacity: _textOpacity,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 90, height: 3, color: scheme.onSurface.withValues(alpha: 0.6)),
                            const SizedBox(height: 4),
                            Container(width: 100, height: 3, color: scheme.onSurface.withValues(alpha: 0.6)),
                            const SizedBox(height: 4),
                            Container(width: 70, height: 3, color: scheme.onSurface.withValues(alpha: 0.6)),
                          ],
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _pdfOpacity,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(color: const Color(0xFFF9F7EE), border: Border.all(color: const Color(0xFFE3DCB9), width: 1.5)),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_rounded, size: 18, color: Colors.grey[700]),
                                const SizedBox(height: 3),
                                Container(width: 32, height: 2, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _fingerTapOpacity,
          builder: (context, child) {
            return Positioned(
              right: 14,
              top: 15,
              child: _FingerTapIndicator(opacity: _fingerTapOpacity.value, scale: 1.0, color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 10: Text Selection & Menu ───
class _TextSelectionAnimation extends StatefulWidget {
  const _TextSelectionAnimation();

  @override
  State<_TextSelectionAnimation> createState() => _TextSelectionAnimationState();
}

class _TextSelectionAnimationState extends State<_TextSelectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pinsOpacity;
  late Animation<double> _menuScale;
  late Animation<double> _rightPinX;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _pinsOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(_controller);
    _rightPinX = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(24.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 24.0, end: 94.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(94.0), weight: 50),
    ]).animate(_controller);
    _menuScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 52),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 18),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Reader text paragraph
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 4, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 6),
                // Sentence with animated highlight overlay
                Stack(
                  children: [
                    Container(width: 110, height: 8, color: Colors.transparent),
                    AnimatedBuilder(
                      animation: _rightPinX,
                      builder: (context, child) {
                        return Positioned(
                          left: 16,
                          width: _rightPinX.value - 16,
                          child: Opacity(
                            opacity: _pinsOpacity.value * 0.25,
                            child: Container(height: 8, color: scheme.primary),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: 16,
                      child: Container(width: 80, height: 4, color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(width: 60, height: 4, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
        // Custom Toolbar Menu Overlay
        AnimatedBuilder(
          animation: _menuScale,
          builder: (context, child) {
            return Positioned(
              top: 24,
              child: Opacity(
                opacity: _menuScale.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _menuScale.value,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.volume_up_rounded, size: 10, color: Colors.white),
                SizedBox(width: 4),
                Text("Read Aloud", style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        // Selection handle pins
        AnimatedBuilder(
          animation: _rightPinX,
          builder: (context, child) {
            return Positioned(
              left: _rightPinX.value - 4,
              top: 22,
              child: Opacity(
                opacity: _pinsOpacity.value,
                child: Column(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: scheme.primary),
                    Container(width: 1.5, height: 10, color: scheme.primary),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 11: TTS Tap-to-Seek ───
class _TtsTapToSeekAnimation extends StatefulWidget {
  const _TtsTapToSeekAnimation();

  @override
  State<_TtsTapToSeekAnimation> createState() => _TtsTapToSeekAnimationState();
}

class _TtsTapToSeekAnimationState extends State<_TtsTapToSeekAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fingerOpacity;
  late Animation<bool> _isParagraph1Active;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Tap Paragraph 2
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 67),
    ]).animate(_controller);
    _isParagraph1Active = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(true), weight: 22),
      TweenSequenceItem(tween: ConstantTween(false), weight: 78),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Paragraph Block list
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Paragraph 1
                AnimatedBuilder(
                  animation: _isParagraph1Active,
                  builder: (context, child) {
                    final active = _isParagraph1Active.value;
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: active ? scheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 80, height: 4, color: active ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                          const SizedBox(height: 3),
                          Container(width: 100, height: 4, color: active ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Paragraph 2
                AnimatedBuilder(
                  animation: _isParagraph1Active,
                  builder: (context, child) {
                    final active = !_isParagraph1Active.value;
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: active ? scheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 90, height: 4, color: active ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                          const SizedBox(height: 3),
                          Container(width: 60, height: 4, color: active ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Tap indicator over Paragraph 2
        Positioned(
          left: 32,
          bottom: 30,
          child: AnimatedBuilder(
            animation: _fingerOpacity,
            builder: (context, child) {
              return _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Animation 12: Save & Download Book ───
class _DownloadBookAnimation extends StatefulWidget {
  const _DownloadBookAnimation();

  @override
  State<_DownloadBookAnimation> createState() => _DownloadBookAnimationState();
}

class _DownloadBookAnimationState extends State<_DownloadBookAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  late Animation<double> _bookmarkScale;
  late Animation<bool> _isCompleted;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _progress = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    ]).animate(_controller);
    _bookmarkScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)), weight: 12),
      TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 6),
    ]).animate(_controller);
    _isCompleted = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(false), weight: 70),
      TweenSequenceItem(tween: ConstantTween(true), weight: 30),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 66,
          height: 94,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary.withValues(alpha: 0.8), scheme.tertiary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(child: Icon(Icons.book_rounded, color: Colors.white, size: 24)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  color: scheme.surface,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 44, height: 3, color: scheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(height: 3),
                      Container(width: 32, height: 2, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _progress,
          builder: (context, child) {
            final showComplete = _isCompleted.value;
            final isRunning = _progress.value > 0.0 && _progress.value < 1.0;
            return Positioned(
              right: 12,
              top: 12,
              child: Transform.scale(
                scale: _bookmarkScale.value,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: showComplete ? Colors.blue[600] : scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: showComplete
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : isRunning
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  value: _progress.value,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                                  backgroundColor: scheme.outlineVariant.withValues(alpha: 0.3),
                                ),
                              )
                            : Icon(Icons.bookmark_border_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.8), size: 13),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 13: Record Voice Comment ───
class _VoiceCommentAnimation extends StatefulWidget {
  const _VoiceCommentAnimation();

  @override
  State<_VoiceCommentAnimation> createState() => _VoiceCommentAnimationState();
}

class _VoiceCommentAnimationState extends State<_VoiceCommentAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseScale1;
  late Animation<double> _pulseOpacity1;
  late Animation<double> _pulseScale2;
  late Animation<double> _pulseOpacity2;
  late Animation<double> _micPressed;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _micPressed = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.86), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.86), weight: 65),
      TweenSequenceItem(tween: Tween<double>(begin: 0.86, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 5),
    ]).animate(_controller);
    _pulseScale1 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 2.2), weight: 60),
      TweenSequenceItem(tween: ConstantTween(2.2), weight: 20),
    ]).animate(_controller);
    _pulseOpacity1 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.35, end: 0.0), weight: 60),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(_controller);
    _pulseScale2 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 2.2), weight: 50),
      TweenSequenceItem(tween: ConstantTween(2.2), weight: 10),
    ]).animate(_controller);
    _pulseOpacity2 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 0.35, end: 0.0), weight: 50),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 14,
          child: SizedBox(
            width: 100,
            height: 34,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final active = _controller.value > 0.15 && _controller.value < 0.85;
                return CustomPaint(
                  painter: _WavePainter(progress: _controller.value, isActive: active, color: scheme.primary),
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseScale1,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseScale1.value,
                    child: Opacity(opacity: _pulseOpacity1.value, child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary.withValues(alpha: 0.4)))),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _pulseScale2,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseScale2.value,
                    child: Opacity(opacity: _pulseOpacity2.value, child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary.withValues(alpha: 0.4)))),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _micPressed,
                builder: (context, child) {
                  final isPressed = _controller.value > 0.18 && _controller.value < 0.88;
                  return Transform.scale(
                    scale: _micPressed.value,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: isPressed ? scheme.primary : scheme.surfaceContainerHigh),
                      child: Icon(Icons.mic_rounded, color: isPressed ? scheme.onPrimary : scheme.primary, size: 16),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final Color color;

  _WavePainter({
    required this.progress,
    required this.isActive,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? color.withValues(alpha: 0.8) : color.withValues(alpha: 0.15)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double midY = size.height / 2;
    const int count = 12;
    final double spacing = size.width / (count - 1);

    for (int i = 0; i < count; i++) {
      final double x = i * spacing;
      double height = 3.0;

      if (isActive) {
        final factor = math.sin((progress * 4 * math.pi) + (i * 0.7));
        final envelope = math.sin((i / (count - 1)) * math.pi);
        height = 3.0 + (factor.abs() * 12 * envelope);
      }

      canvas.drawLine(Offset(x, midY - height), Offset(x, midY + height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isActive != isActive;
  }
}

// ─── Animation 14: Audio Post Player ───
class _AudioPlayerAnimation extends StatefulWidget {
  const _AudioPlayerAnimation();

  @override
  State<_AudioPlayerAnimation> createState() => _AudioPlayerAnimationState();
}

class _AudioPlayerAnimationState extends State<_AudioPlayerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sliderProgress;
  late Animation<double> _fingerOpacity;
  late Animation<double> _fingerX;
  late Animation<bool> _isPlaying;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Tap Play
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Drag Slider Start
      TweenSequenceItem(tween: ConstantTween(0.7), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 24),
    ]).animate(_controller);
    _fingerX = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(36.0), weight: 33),
      TweenSequenceItem(tween: Tween<double>(begin: 36.0, end: 84.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(84.0), weight: 37),
    ]).animate(_controller);
    _sliderProgress = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.2), weight: 33),
      TweenSequenceItem(tween: Tween<double>(begin: 0.2, end: 0.7), weight: 30),
      TweenSequenceItem(tween: ConstantTween(0.7), weight: 37),
    ]).animate(_controller);
    _isPlaying = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(false), weight: 10),
      TweenSequenceItem(tween: ConstantTween(true), weight: 90),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Audio Player Bar Card
        Container(
          width: 116,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player layout row
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _isPlaying,
                    builder: (context, child) {
                      return Icon(
                        _isPlaying.value ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: scheme.primary,
                        size: 20,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Progress line representation
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 3, color: scheme.outlineVariant),
                        AnimatedBuilder(
                          animation: _sliderProgress,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: _sliderProgress.value,
                              child: Container(height: 3, color: scheme.primary),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Dynamic bouncing sound waves below
              SizedBox(
                height: 12,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final playing = _isPlaying.value;
                    return CustomPaint(
                      painter: _WavePainter(progress: _controller.value, isActive: playing, color: scheme.primary),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Finger tap ring dragging the slider thumb
        AnimatedBuilder(
          animation: _fingerOpacity,
          builder: (context, child) {
            final val = _controller.value;
            double x = 8;
            double y = 10;
            if (val > 0.30) {
              x = _fingerX.value;
              y = 12;
            }
            return Positioned(
              left: x,
              top: y,
              child: _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 15: Swipe to Delete DM Message ───
class _SwipeToDeleteMessageAnimation extends StatefulWidget {
  const _SwipeToDeleteMessageAnimation();

  @override
  State<_SwipeToDeleteMessageAnimation> createState() => _SwipeToDeleteMessageAnimationState();
}

class _SwipeToDeleteMessageAnimationState extends State<_SwipeToDeleteMessageAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bubbleX;
  late Animation<double> _fingerOpacity;
  late Animation<double> _fingerX;
  late Animation<double> _bubbleOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _bubbleX = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -44.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(-44.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: -44.0, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(_controller);
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.6), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.6), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
    ]).animate(_controller);
    _fingerX = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(80.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 80.0, end: 36.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(36.0), weight: 55),
    ]).animate(_controller);
    _bubbleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10), // Deleted flash
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Delete Icon
        Positioned(
          right: 14,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 12),
          ),
        ),
        // Chat Message bubble
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_bubbleX.value, 0),
              child: Opacity(
                opacity: _bubbleOpacity.value,
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(width: 70, height: 3, color: scheme.onPrimary),
                      const SizedBox(height: 3),
                      Container(width: 40, height: 3, color: scheme.onPrimary),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Finger swipe indicator dragging left
        AnimatedBuilder(
          animation: _fingerX,
          builder: (context, child) {
            return Positioned(
              left: _fingerX.value,
              child: Opacity(
                opacity: _fingerOpacity.value,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 16: Make Private ───
class _MakePrivateAnimation extends StatefulWidget {
  const _MakePrivateAnimation();

  @override
  State<_MakePrivateAnimation> createState() => _MakePrivateAnimationState();
}

class _MakePrivateAnimationState extends State<_MakePrivateAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fingerOpacity;
  late Animation<double> _dropdownY;
  late Animation<bool> _isPrivate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 8),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Tap Dropdown
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 7),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Select Private
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 7),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 53),
    ]).animate(_controller);
    _dropdownY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 13), // Hidden scale
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 12), // Pop open
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10), // Close
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
    ]).animate(_controller);
    _isPrivate = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(false), weight: 40),
      TweenSequenceItem(tween: ConstantTween(true), weight: 60),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dropdown Field mockup
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 40, height: 3, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                const SizedBox(height: 5),
                // Dropdown box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedBuilder(
                        animation: _isPrivate,
                        builder: (context, child) {
                          return Row(
                            children: [
                              if (_isPrivate.value) Icon(Icons.lock_outline_rounded, size: 8, color: scheme.primary),
                              if (_isPrivate.value) const SizedBox(width: 4),
                              Text(_isPrivate.value ? "Private" : "Public", style: const TextStyle(fontSize: 8)),
                            ],
                          );
                        },
                      ),
                      Icon(Icons.arrow_drop_down, size: 10, color: scheme.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Dropdown choices pop up
        AnimatedBuilder(
          animation: _dropdownY,
          builder: (context, child) {
            return Opacity(
              opacity: _dropdownY.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _dropdownY.value,
                child: child,
              ),
            );
          },
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Public", style: TextStyle(fontSize: 8)),
                Divider(height: 8),
                Text("Private", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        // Tap Pointer
        AnimatedBuilder(
          animation: _fingerOpacity,
          builder: (context, child) {
            final val = _controller.value;
            double x = 100;
            double y = 62;
            if (val > 0.25) {
              x = 44;
              y = 74;
            }
            return Positioned(
              left: x,
              top: y,
              child: _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animation 17: Theme Selection ───
class _ThemeSelectionAnimation extends StatefulWidget {
  const _ThemeSelectionAnimation();

  @override
  State<_ThemeSelectionAnimation> createState() => _ThemeSelectionAnimationState();
}

class _ThemeSelectionAnimationState extends State<_ThemeSelectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fingerOpacity;
  late Animation<double> _dialogOpacity;
  late Animation<bool> _isDarkThemeActive;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 8),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Tap Dark Option
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 7),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 80),
    ]).animate(_controller);
    _dialogOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
    ]).animate(_controller);
    _isDarkThemeActive = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(false), weight: 10),
      TweenSequenceItem(tween: ConstantTween(true), weight: 80),
      TweenSequenceItem(tween: ConstantTween(false), weight: 10),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _isDarkThemeActive,
      builder: (context, child) {
        final dark = _isDarkThemeActive.value;
        final bg = dark ? const Color(0xFF10151F) : Colors.white;
        final fg = dark ? Colors.white : Colors.black;
        final outline = dark ? Colors.white24 : Colors.black12;
        return Container(
          width: 140,
          height: 130,
          color: bg,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Page mock contents
              Positioned(
                left: 10,
                top: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 44, height: 6, color: fg.withValues(alpha: 0.7)),
                    const SizedBox(height: 6),
                    Container(width: 80, height: 4, color: fg.withValues(alpha: 0.3)),
                  ],
                ),
              ),
              // Dialog Modal Options
              AnimatedBuilder(
                animation: _dialogOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _dialogOpacity.value,
                    child: Transform.scale(scale: 0.8 + (_dialogOpacity.value * 0.2), child: child),
                  );
                },
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1B2230) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: outline),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Theme Mode", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: fg)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: dark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Dark Theme", style: TextStyle(fontSize: 7, color: fg, fontWeight: FontWeight.bold)),
                            Icon(Icons.check_circle_rounded, size: 8, color: dark ? Colors.purple[300] : Colors.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Finger Tap
              Positioned(
                right: 32,
                bottom: 44,
                child: AnimatedBuilder(
                  animation: _fingerOpacity,
                  builder: (context, child) {
                    return _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: Colors.blue);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Animation 18: Language Switcher ───
class _LanguageSwitcherAnimation extends StatefulWidget {
  const _LanguageSwitcherAnimation();

  @override
  State<_LanguageSwitcherAnimation> createState() => _LanguageSwitcherAnimationState();
}

class _LanguageSwitcherAnimationState extends State<_LanguageSwitcherAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fingerOpacity;
  late Animation<bool> _isHindiSelected;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _fingerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 5), // Tap Hindi Option
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 72),
    ]).animate(_controller);
    _isHindiSelected = TweenSequence<bool>([
      TweenSequenceItem(tween: ConstantTween(false), weight: 18),
      TweenSequenceItem(tween: ConstantTween(true), weight: 82),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Language Option List
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Option 1 (English)
                AnimatedBuilder(
                  animation: _isHindiSelected,
                  builder: (context, child) {
                    final selected = !_isHindiSelected.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: selected ? scheme.primary.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("English / English", style: TextStyle(fontSize: 8)),
                          if (selected) Icon(Icons.check_circle_rounded, size: 8, color: scheme.primary),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Option 2 (Hindi)
                AnimatedBuilder(
                  animation: _isHindiSelected,
                  builder: (context, child) {
                    final selected = _isHindiSelected.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: selected ? scheme.primary.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selected ? "हिंदी / Hindi" : "Hindi / हिंदी", style: const TextStyle(fontSize: 8)),
                          if (selected) Icon(Icons.check_circle_rounded, size: 8, color: scheme.primary),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Tap Pointer over Hindi
        Positioned(
          right: 20,
          bottom: 34,
          child: AnimatedBuilder(
            animation: _fingerOpacity,
            builder: (context, child) {
              return _FingerTapIndicator(opacity: _fingerOpacity.value, scale: 1.0, color: scheme.primary);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Animation 19: Collections ───
class _CollectionAnimation extends StatefulWidget {
  const _CollectionAnimation();

  @override
  State<_CollectionAnimation> createState() => _CollectionAnimationState();
}

class _CollectionAnimationState extends State<_CollectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bookSlide;
  late Animation<double> _bookOpacity;
  late Animation<double> _folderScale;
  late Animation<double> _checkOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _bookSlide = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: -40.0, end: 15.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
      TweenSequenceItem(tween: ConstantTween(15.0), weight: 50),
    ]).animate(_controller);

    _bookOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
    ]).animate(_controller);

    _folderScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
    ]).animate(_controller);

    _checkOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _folderScale,
          builder: (context, child) {
            return Transform.scale(
              scale: _folderScale.value,
              child: Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: scheme.primary,
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bookSlide.value),
              child: Opacity(
                opacity: _bookOpacity.value,
                child: Icon(
                  Icons.book_rounded,
                  size: 24,
                  color: scheme.secondary,
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 15,
          right: 25,
          child: AnimatedBuilder(
            animation: _checkOpacity,
            builder: (context, child) {
              return Opacity(
                opacity: _checkOpacity.value,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Animation 20: Leaderboard ───
class _LeaderboardAnimation extends StatefulWidget {
  const _LeaderboardAnimation();

  @override
  State<_LeaderboardAnimation> createState() => _LeaderboardAnimationState();
}

class _LeaderboardAnimationState extends State<_LeaderboardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _userYOffset;
  late Animation<double> _other1YOffset;
  late Animation<double> _other2YOffset;
  late Animation<int> _userPoints;
  late Animation<double> _sparkleOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _userYOffset = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -48.0).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 40),
      TweenSequenceItem(tween: ConstantTween(-48.0), weight: 40),
    ]).animate(_controller);

    _other1YOffset = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 24.0).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 40),
      TweenSequenceItem(tween: ConstantTween(24.0), weight: 40),
    ]).animate(_controller);

    _other2YOffset = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 24.0).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 40),
      TweenSequenceItem(tween: ConstantTween(24.0), weight: 40),
    ]).animate(_controller);

    _userPoints = IntTween(begin: 800, end: 1500).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );

    _sparkleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 140,
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _other1YOffset,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _other1YOffset.value),
                child: _buildRankRow(1, "Alice", "1200", Colors.amber),
              );
            },
          ),
          AnimatedBuilder(
            animation: _other2YOffset,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _other2YOffset.value),
                child: _buildRankRow(2, "Bob", "950", Colors.grey),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 48.0 + _userYOffset.value),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildRankRow(
                      _userYOffset.value < -24 ? 1 : 3,
                      "You",
                      "${_userPoints.value}",
                      scheme.primary,
                      isUser: true,
                    ),
                    if (_sparkleOpacity.value > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Opacity(
                          opacity: _sparkleOpacity.value,
                          child: const Icon(Icons.star, size: 12, color: Colors.amber),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(
    int rank,
    String name,
    String points,
    Color color, {
    bool isUser = false,
  }) {
    return Container(
      height: 20,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isUser ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              "$rank",
              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 8,
                fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            "$points pts",
            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

