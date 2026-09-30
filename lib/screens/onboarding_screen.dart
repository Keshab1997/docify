// dart format off
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'main_nav_screen.dart';

/// First-launch walkthrough: three claymorphism slides that share one set of
/// artwork (same pedestal, same soft-clay material) so the flow reads as a
/// single story instead of three unrelated posters.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();

  /// Drives the gentle "hover" of the artwork. Stopped entirely when the
  /// device asks for reduced motion (see [didChangeDependencies]).
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  int _page = 0;
  bool _precached = false;

  static const _slides = [
    _OnboardingSlide(
      image: 'assets/images/onboarding_prepare.jpg',
      alt: 'A phone surrounded by a photo card, a signed document and a PDF',
      eyebrow: 'WELCOME TO DOCIFY',
      title: "Make every document\nform-ready.",
      body:
          'Resize photos, clean signatures and create PDFs in seconds — right from your phone.',
      tint: Color(0xFFE3EFFF),
      artBackdrop: Color(0xFFB2D6FA),
      accent: AppColors.primaryButton,
      chips: [
        _Chip(Icons.photo_size_select_large_rounded, 'Photo'),
        _Chip(Icons.draw_rounded, 'Signature'),
        _Chip(Icons.picture_as_pdf_rounded, 'PDF'),
        _Chip(Icons.badge_rounded, 'CV'),
      ],
    ),
    _OnboardingSlide(
      image: 'assets/images/onboarding_privacy.jpg',
      alt: 'A shield with a padlock protecting a stack of documents',
      eyebrow: 'PRIVATE BY DESIGN',
      title: "Your documents\nstay yours.",
      body:
          'Your files are processed on your device. No account is needed to get started.',
      tint: Color(0xFFDDF7EB),
      artBackdrop: Color(0xFFD4F5E6),
      accent: Color(0xFF0F766E),
      chips: [
        _Chip(Icons.phone_android_rounded, 'On-device'),
        _Chip(Icons.person_off_rounded, 'No account'),
        _Chip(Icons.lock_rounded, 'Private'),
      ],
    ),
    _OnboardingSlide(
      image: 'assets/images/onboarding_ready.jpg',
      alt: 'A finished CV with a check mark, surrounded by confetti',
      eyebrow: 'READY WHEN YOU ARE',
      title: "From draft to\ndone, beautifully.",
      body:
          'Build a CV, prepare an application and keep your important files organised in one place.',
      tint: Color(0xFFEAE4FF),
      artBackdrop: Color(0xFFDEDAFA),
      accent: AppColors.assistantInk,
      chips: [
        _Chip(Icons.description_rounded, 'CV builder'),
        _Chip(Icons.assignment_turned_in_rounded, 'Job forms'),
        _Chip(Icons.folder_rounded, 'My documents'),
      ],
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the artwork up front so the first swipe never flashes a blank card.
    if (!_precached) {
      _precached = true;
      for (final slide in _slides) {
        precacheImage(AssetImage(slide.image), context);
      }
    }
    if (MediaQuery.of(context).disableAnimations) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen_v1', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainNavScreen()),
    );
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: Motion.of(context, Motion.long),
      curve: Motion.enter,
    );
  }

  /// Fractional distance of [index] from the page currently on screen:
  /// 0 when centred, ±1 when fully swiped away. Drives parallax and fade.
  double _delta(int index) {
    final position = _pageController.hasClients &&
            _pageController.position.haveDimensions
        ? (_pageController.page ?? _page.toDouble())
        : _page.toDouble();
    return position - index;
  }

  @override
  Widget build(BuildContext context) {
    final current = _slides[_page];
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedContainer(
        duration: Motion.of(context, Motion.long),
        curve: Motion.move,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [current.tint, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset('assets/images/app_logo.png',
                          width: 30, height: 30),
                    ),
                    const SizedBox(width: 10),
                    const Text('Docify', style: AppText.title),
                    const Spacer(),
                    // Faded (not removed) on the last slide so the header
                    // never reflows.
                    AnimatedOpacity(
                      duration: Motion.of(context, Motion.short),
                      opacity: isLast ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: isLast,
                        child: TextButton(
                          onPressed: _finish,
                          child: const Text('Skip',
                              style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) {
                    final item = _slides[index];
                    return AnimatedBuilder(
                      animation: Listenable.merge([_pageController, _float]),
                      builder: (context, _) {
                        final delta = _delta(index);
                        final away = delta.abs().clamp(0.0, 1.0).toDouble();
                        // Smooth 0..1..0 wave, eased so the hover feels soft.
                        final hover =
                            Curves.easeInOut.transform(_float.value) * 2 - 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Column(
                            children: [
                              const SizedBox(height: 14),
                              Expanded(
                                child: _ArtCard(
                                  slide: item,
                                  // Art slides the opposite way to the page,
                                  // which gives the depth of a parallax.
                                  dx: -delta * 46,
                                  dy: hover * 7,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Opacity(
                                opacity: 1 - away,
                                child: Transform.translate(
                                  offset: Offset(delta * -24, 0),
                                  child: _SlideText(slide: item),
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: Motion.of(context, Motion.short),
                          curve: Motion.enter,
                          margin: const EdgeInsets.only(right: 6),
                          width: index == _page ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _page
                                ? current.accent
                                : const Color(0xFFCBD5E6),
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.pill),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryButton
                                .withValues(alpha: 0.32),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSize(
                              duration: Motion.of(context, Motion.short),
                              curve: Motion.enter,
                              child: Text(isLast ? 'Get started' : 'Continue'),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isLast
                                  ? Icons.arrow_forward_rounded
                                  : Icons.chevron_right_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
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
}

/// The big rounded "clay tile" that frames each illustration.
class _ArtCard extends StatelessWidget {
  final _OnboardingSlide slide;
  final double dx;
  final double dy;

  const _ArtCard({required this.slide, required this.dx, required this.dy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // Shown for a frame while the image decodes, and matches the art's
        // own backdrop so there is no flash.
        color: slide.artBackdrop,
        borderRadius: BorderRadius.circular(38),
        // White rim + tinted drop shadow is what sells the "soft clay" look.
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: slide.accent.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(33),
        child: Transform.translate(
          offset: Offset(dx, dy),
          // Scaled up a touch so the parallax shift never reveals an edge.
          child: Transform.scale(
            scale: 1.1,
            child: Image.asset(
              slide.image,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              width: double.infinity,
              height: double.infinity,
              semanticLabel: slide.alt,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideText extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideText({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: slide.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Text(
              slide.eyebrow,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: slide.accent,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: AppColors.bodyText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in slide.chips)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Radii.pill),
                    border: Border.all(color: AppColors.chipBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chip.icon, size: 15, color: slide.accent),
                      const SizedBox(width: 6),
                      Text(chip.label, style: AppText.label.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip {
  final IconData icon;
  final String label;

  const _Chip(this.icon, this.label);
}

class _OnboardingSlide {
  final String image;
  final String alt;
  final String eyebrow;
  final String title;
  final String body;

  /// Soft top colour of the screen's background gradient for this slide.
  final Color tint;

  /// Dominant colour of the illustration's own backdrop.
  final Color artBackdrop;

  /// Ink for the eyebrow, chips, dots and card shadow.
  final Color accent;
  final List<_Chip> chips;

  const _OnboardingSlide({
    required this.image,
    required this.alt,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.tint,
    required this.artBackdrop,
    required this.accent,
    required this.chips,
  });
}
