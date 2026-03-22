import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/intro_images.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Slide data for onboarding
class IntroSlideData {
  const IntroSlideData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
}

/// Intro onboarding - image-first, clear hierarchy, easy navigation
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _precached = false;

  static const List<IntroSlideData> _slides = [
    IntroSlideData(
      title: 'Welcome to Visit Tripoli',
      subtitle: 'The Pearl of the North',
      description:
          'Lebanon\'s second city—a treasure of history, souks, and authentic experiences.',
      icon: Icons.explore_outlined,
    ),
    IntroSlideData(
      title: 'Historic Landmarks',
      subtitle: 'Centuries of heritage',
      description:
          'Ancient citadels, Mamluk mosques, vaulted souks—each corner tells a story.',
      icon: Icons.account_balance_outlined,
    ),
    IntroSlideData(
      title: 'Plan Your Visit',
      subtitle: 'AI-powered itineraries',
      description:
          'Personalized trips, saved favorites, and smart recommendations for you.',
      icon: Icons.auto_awesome_outlined,
    ),
    IntroSlideData(
      title: 'Explore with Ease',
      subtitle: 'Maps & directions',
      description:
          'Interactive maps and clear directions to every destination in Tripoli.',
      icon: Icons.map_outlined,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final path in IntroImages.urls) {
          precacheImage(AssetImage(path), context);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishIntro(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await auth.loginAsGuest();
      auth.setOnboardingCompleted(true);
    }
    if (context.mounted) {
      context.go('/explore');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _IntroSlideWidget(
              slide: _slides[i],
              imagePath: IntroImages.urls[i],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width < 340 ? 12 : 16,
                8,
                MediaQuery.sizeOf(context).width < 340 ? 12 : 16,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PageIndicator(current: _currentPage, total: _slides.length),
                  if (_currentPage < _slides.length - 1)
                    _SkipButton(
                      onTap: () => _finishIntro(context),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomSection(
              currentPage: _currentPage,
              slides: _slides,
              onNext: () {
                if (_currentPage < _slides.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                } else {
                  _finishIntro(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroSlideWidget extends StatelessWidget {
  final IntroSlideData slide;
  final String imagePath;

  const _IntroSlideWidget({required this.slide, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: AppTheme.primaryColor),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1A000000),
                  Color(0x33000000),
                  Color(0x66000000),
                  Color(0xCC000000),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 340 ? 18 : 28,
                vertical: MediaQuery.sizeOf(context).width < 340 ? 56 : 80,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconBadge(icon: slide.icon),
                  SizedBox(height: MediaQuery.sizeOf(context).width < 340 ? 20 : 28),
                  Text(
                    slide.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.sizeOf(context).width < 340 ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: MediaQuery.sizeOf(context).width < 340 ? 8 : 10),
                  Text(
                    slide.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: MediaQuery.sizeOf(context).width < 340 ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: MediaQuery.sizeOf(context).width < 340 ? 14 : 20),
                  Text(
                    slide.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: MediaQuery.sizeOf(context).width < 340 ? 13 : 15,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _PageIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Text(
            'Skip',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.98),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 30, color: Colors.white),
    );
  }
}

class _BottomSection extends StatelessWidget {
  final int currentPage;
  final List<IntroSlideData> slides;
  final VoidCallback onNext;

  const _BottomSection(
      {required this.currentPage, required this.slides, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == slides.length - 1;
    final small = MediaQuery.sizeOf(context).width < 340;
    return Container(
      padding: EdgeInsets.fromLTRB(
          small ? 16 : 24,
          small ? 14 : 20,
          small ? 16 : 24,
          MediaQuery.of(context).padding.bottom + (small ? 18 : 24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLast ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            if (isLast) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => context.push('/login'),
                child: Text(
                  'Already have an account? Log in',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
