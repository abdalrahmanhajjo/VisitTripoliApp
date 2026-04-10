import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Result of the full-screen onboarding carousel.
enum AppOnboardingResult {
  /// User asked for on-screen spotlight (Showcase sequence).
  startSpotlight,

  /// User finished with “Got it” — no spotlight.
  finishedWithoutSpotlight,

  /// User skipped or dismissed early.
  skipped,
}

/// Multi-step, localized onboarding before optional spotlight tour.
Future<AppOnboardingResult?> showAppOnboardingFlow(BuildContext context) {
  return showGeneralDialog<AppOnboardingResult>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.56),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (ctx, animation, secondary) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: const _OnboardingCarousel(),
      );
    },
  );
}

class _OnboardingCarousel extends StatefulWidget {
  const _OnboardingCarousel();

  @override
  State<_OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<_OnboardingCarousel>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _page = 0;

  static const int _slideCount = 8;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _hapticLight() {
    HapticFeedback.lightImpact();
  }

  void _hapticSelect() {
    HapticFeedback.selectionClick();
  }

  void _goNext() {
    if (_page < _slideCount - 1) {
      _hapticLight();
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goBack() {
    if (_page > 0) {
      _hapticLight();
      _controller.previousPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<_SlideData> _slides(AppLocalizations l10n) => [
        _SlideData(
          icon: Icons.waving_hand_rounded,
          iconColor: AppTheme.accentColor,
          accentBg: AppTheme.accentColor.withValues(alpha: 0.1),
          title: l10n.appOnboardingSlideWelcomeTitle,
          body: l10n.appOnboardingSlideWelcomeBody,
        ),
        _SlideData(
          icon: Icons.explore_rounded,
          iconColor: AppTheme.primaryColor,
          accentBg: AppTheme.primaryColor.withValues(alpha: 0.1),
          title: l10n.appOnboardingSlideExploreTitle,
          body: l10n.appOnboardingSlideExploreBody,
        ),
        _SlideData(
          icon: Icons.dynamic_feed_rounded,
          iconColor: AppTheme.secondaryColor,
          accentBg: AppTheme.secondaryColor.withValues(alpha: 0.1),
          title: l10n.appOnboardingSlideCommunityTitle,
          body: l10n.appOnboardingSlideCommunityBody,
        ),
        _SlideData(
          icon: Icons.map_rounded,
          iconColor: AppTheme.primaryDark,
          accentBg: AppTheme.primaryDark.withValues(alpha: 0.09),
          title: l10n.appOnboardingSlideMapTitle,
          body: l10n.appOnboardingSlideMapBody,
        ),
        _SlideData(
          icon: Icons.auto_awesome_rounded,
          iconColor: AppTheme.accentColor,
          accentBg: AppTheme.accentMuted.withValues(alpha: 0.14),
          title: l10n.appOnboardingSlidePlannerTitle,
          body: l10n.appOnboardingSlidePlannerBody,
        ),
        _SlideData(
          icon: Icons.route_rounded,
          iconColor: AppTheme.successColor,
          accentBg: AppTheme.successColor.withValues(alpha: 0.1),
          title: l10n.appOnboardingSlideTripsTitle,
          body: l10n.appOnboardingSlideTripsBody,
        ),
        _SlideData(
          icon: Icons.local_offer_rounded,
          iconColor: AppTheme.secondaryColor,
          accentBg: AppTheme.secondaryColor.withValues(alpha: 0.1),
          title: l10n.appOnboardingSlideOffersTitle,
          body: l10n.appOnboardingSlideOffersBody,
        ),
        _SlideData(
          icon: Icons.help_outline_rounded,
          iconColor: AppTheme.primaryColor,
          accentBg: AppTheme.primaryLight.withValues(alpha: 0.2),
          title: l10n.appOnboardingSlideHelpTitle,
          body: l10n.appOnboardingSlideHelpBody,
        ),
      ];

  Widget _gradientPrimaryButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(gradient: AppTheme.ctaGradient),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 360;
    final isLast = _page == _slideCount - 1;
    final slides = _slides(l10n);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final slide = slides[_page];

    return Material(
      color: AppTheme.backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _OnboardingAtmospherePainter(
              pageIndex: _page,
              accent: slide.iconColor,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(4, isCompact ? 4 : 8, 8, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.surfaceColor.withValues(alpha: 0.92),
                        AppTheme.backgroundColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_page > 0)
                        IconButton(
                          onPressed: _goBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: l10n.appOnboardingBack,
                        )
                      else
                        const SizedBox(width: 48),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              l10n.appOnboardingJourneyTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.displayFontFamily,
                                fontSize: isCompact ? 17 : 19,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor
                                        .withValues(alpha: 0.12),
                                    AppTheme.secondaryColor
                                        .withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.28),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryDark
                                        .withValues(alpha: 0.12),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                l10n.appOnboardingStepOf(
                                  _page + 1,
                                  _slideCount,
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isCompact ? 11 : 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryDark,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _hapticSelect();
                          Navigator.of(context)
                              .pop(AppOnboardingResult.skipped);
                        },
                        child: Text(l10n.appOnboardingSkip),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slideCount,
                    onPageChanged: (i) {
                      _hapticSelect();
                      setState(() => _page = i);
                    },
                    itemBuilder: (context, i) {
                      final s = slides[i];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 18 : 26,
                          vertical: 6,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) {
                            return FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.9, end: 1)
                                    .animate(CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutBack,
                                )),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey<int>(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    maxWidth: 420,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 26,
                                    horizontal: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        s.accentBg,
                                        AppTheme.surfaceColor
                                            .withValues(alpha: 0.85),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: s.iconColor
                                          .withValues(alpha: 0.22),
                                      width: 1.2,
                                    ),
                                    boxShadow: AppTheme.premiumCardShadow,
                                  ),
                                  child: Column(
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          final t = Curves.easeInOut
                                              .transform(
                                                  _pulseController.value);
                                          final scale = 1 + 0.04 * t;
                                          return Transform.scale(
                                            scale: scale,
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          width: isCompact ? 86 : 98,
                                          height: isCompact ? 86 : 98,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                AppTheme.surfaceColor,
                                                AppTheme.surfaceVariant,
                                              ],
                                            ),
                                            border: Border.all(
                                              color: s.iconColor
                                                  .withValues(alpha: 0.35),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: s.iconColor
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 32,
                                                spreadRadius: -4,
                                                offset:
                                                    const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            s.icon,
                                            size: isCompact ? 40 : 44,
                                            color: s.iconColor,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                          height: isCompact ? 22 : 28),
                                      Text(
                                        s.title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily:
                                              AppTheme.displayFontFamily,
                                          fontSize: isCompact ? 24 : 28,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                          height: 1.15,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        s.body,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: AppTheme.uiFontFamily,
                                          fontSize: isCompact ? 14.5 : 15,
                                          height: 1.58,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
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
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slideCount, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: active
                              ? AppTheme.ctaGradient
                              : null,
                          color:
                              active ? null : AppTheme.borderColor,
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                    child: Text(
                      l10n.appOnboardingSwipeHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color:
                            AppTheme.textTertiary.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 14 + bottomInset),
                  child: isLast
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _gradientPrimaryButton(
                              onPressed: () {
                                _hapticLight();
                                Navigator.of(context).pop(
                                  AppOnboardingResult.startSpotlight,
                                );
                              },
                              child: Text(l10n.appOnboardingStartSpotlight),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                _hapticLight();
                                Navigator.of(context).pop(
                                  AppOnboardingResult.finishedWithoutSpotlight,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                side: BorderSide(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 17),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                l10n.appOnboardingGotIt,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.appOnboardingFinalHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.45,
                                color: AppTheme.textTertiary
                                    .withValues(alpha: 0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : _gradientPrimaryButton(
                          onPressed: _goNext,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.appOnboardingNext),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 22,
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
    );
  }
}

/// Layered mesh + noise-like grain for a high-end fullscreen backdrop.
class _OnboardingAtmospherePainter extends CustomPainter {
  _OnboardingAtmospherePainter({
    required this.pageIndex,
    required this.accent,
  });

  final int pageIndex;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final phase = pageIndex / 8.0;
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.backgroundColor,
          Color.lerp(AppTheme.backgroundColor, accent, 0.07)!,
          Color.lerp(
            AppTheme.surfaceVariant,
            AppTheme.secondaryColor.withValues(alpha: 0.12),
            0.35,
          )!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    final cx = rect.width * (0.15 + 0.7 * phase);
    final cy = rect.height * (0.28 + 0.08 * math.sin(phase * math.pi));
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (cx / rect.width) * 2 - 1,
          (cy / rect.height) * 2 - 1,
        ),
        radius: 1.05,
        colors: [
          accent.withValues(alpha: 0.18),
          AppTheme.secondaryColor.withValues(alpha: 0.07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final linePaint = Paint()
      ..color = AppTheme.textPrimary.withValues(alpha: 0.024)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = -size.height; x < size.width + step; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 1.05, size.height),
        linePaint,
      );
    }

    final dotPaint = Paint()
      ..color = accent.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    final rnd = math.Random(7 + pageIndex * 13);
    for (var i = 0; i < 64; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 1.8 + 0.35, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingAtmospherePainter oldDelegate) {
    return oldDelegate.pageIndex != pageIndex || oldDelegate.accent != accent;
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.iconColor,
    required this.accentBg,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color iconColor;
  final Color accentBg;
  final String title;
  final String body;
}
