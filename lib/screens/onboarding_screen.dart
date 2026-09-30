// dart format off
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'main_nav_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      image: 'assets/images/onboarding_prepare.png',
      eyebrow: 'WELCOME TO DOCIFY',
      title: "Make every document\nform-ready.",
      body: 'Resize photos, clean signatures and create PDFs in seconds — right from your phone.',
      tint: Color(0xFFEAF2FF),
    ),
    _OnboardingSlide(
      image: 'assets/images/onboarding_privacy.png',
      eyebrow: 'PRIVATE BY DESIGN',
      title: "Your documents\nstay yours.",
      body: 'Your files are processed on your device. No account is needed to get started.',
      tint: Color(0xFFEFF8FF),
    ),
    _OnboardingSlide(
      image: 'assets/images/onboarding_ready.png',
      eyebrow: 'READY WHEN YOU ARE',
      title: "From draft to\ndone, beautifully.",
      body: 'Build a CV, prepare an application and keep your important files organised in one place.',
      tint: Color(0xFFF3F0FF),
    ),
  ];

  @override
  void dispose() {
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
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primaryButton, size: 21),
                  const SizedBox(width: 8),
                  const Text('Docify', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (_page < _slides.length - 1)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Skip', style: TextStyle(color: AppColors.mutedText)),
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 22),
                        Expanded(
                          flex: 6,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: item.tint,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Image.asset(item.image, fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.eyebrow, style: const TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w800, color: AppColors.primaryButton)),
                              const SizedBox(height: 12),
                              Text(item.title, style: const TextStyle(fontSize: 30, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: AppColors.bodyText)),
                              const SizedBox(height: 14),
                              Text(item.body, style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.mutedText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: Row(
                children: [
                  Row(children: List.generate(_slides.length, (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 6),
                    width: index == _page ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(color: index == _page ? AppColors.primaryButton : const Color(0xFFD5DFEE), borderRadius: BorderRadius.circular(9)),
                  ))),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _next,
                    icon: Icon(_page == _slides.length - 1 ? Icons.arrow_forward_rounded : Icons.chevron_right_rounded),
                    label: Text(_page == _slides.length - 1 ? 'Get started' : 'Continue'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String image;
  final String eyebrow;
  final String title;
  final String body;
  final Color tint;

  const _OnboardingSlide({required this.image, required this.eyebrow, required this.title, required this.body, required this.tint});
}
