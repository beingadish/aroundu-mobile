import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../view_model/auth_ui_view_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'Book Local Services Fast',
      description:
          'Post your requirement in minutes and get matched with nearby verified workers.',
      icon: Icons.bolt_rounded,
    ),
    _OnboardingSlide(
      title: 'Compare Bids Transparently',
      description:
          'Review pricing, profiles, and timelines before assigning your job with confidence.',
      icon: Icons.compare_arrows_rounded,
    ),
    _OnboardingSlide(
      title: 'Track Every Job Clearly',
      description:
          'Stay updated from job creation to completion with role-based dashboards.',
      icon: Icons.fact_check_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _goNext() {
    final currentPage = ref.read(onboardingPageProvider);
    if (currentPage == _slides.length - 1) {
      _toLogin();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingPageProvider);
    final isLastPage = currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _toLogin, child: const Text('Skip')),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    ref.read(onboardingPageProvider.notifier).state = index;
                  },
                  itemBuilder: (context, index) {
                    return _OnboardingCard(slide: _slides[index]);
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: currentPage == index
                          ? AppPalette.primary
                          : AppPalette.border,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: isLastPage ? 'Get Started' : 'Next',
                onPressed: _goNext,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.register);
                },
                child: const Text('New here? Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppPalette.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(slide.icon, color: AppPalette.primary, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              slide.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
