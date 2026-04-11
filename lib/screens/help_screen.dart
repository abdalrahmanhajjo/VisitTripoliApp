import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/app_tutorial_prefs.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_onboarding_flow.dart';

/// Single professional Help screen: about the app, quick answers, privacy note.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pad = ResponsiveUtils.screenPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.help,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: ListView(
        padding: pad.copyWith(top: 8, bottom: 32),
        children: [
          _HeroHeader(l10n: l10n),
          const SizedBox(height: 24),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.helpAboutTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.helpAboutBody,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: AppTheme.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpQuickAnswersTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          _FaqTile(question: l10n.helpFaqSavePlaceQ, answer: l10n.helpFaqSavePlaceA),
          _FaqTile(question: l10n.helpFaqPlanQ, answer: l10n.helpFaqPlanA),
          _FaqTile(question: l10n.helpFaqOfflineQ, answer: l10n.helpFaqOfflineA),
          const SizedBox(height: 24),
          Text(
            l10n.helpGuidedTourSection,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          _GuidedTourCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.slideshow_rounded,
                    color: AppTheme.primaryColor.withValues(alpha: 0.95),
                  ),
                  title: Text(
                    l10n.helpReplayTourTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    l10n.helpReplayTourSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await AppTutorialPrefs.clearResolvedForReplay(prefs);
                    if (!context.mounted) return;
                    final r = await showAppOnboardingFlow(context);
                    if (!context.mounted) return;
                    if (r == AppOnboardingResult.startSpotlight) {
                      context.read<AppStateProvider>().startFullAppTour();
                      context.go('/explore');
                    } else {
                      await AppTutorialPrefs.markResolved(prefs);
                    }
                  },
                ),
                Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.7)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.highlight_rounded,
                    color: AppTheme.secondaryColor.withValues(alpha: 0.95),
                  ),
                  title: Text(
                    l10n.helpReplaySpotlightTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    l10n.helpReplaySpotlightSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  onTap: () {
                    context.read<AppStateProvider>().startFullAppTour();
                    context.go('/explore');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: AppTheme.primaryColor.withValues(alpha: 0.9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.helpPrivacyNoticeTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.helpPrivacyNoticeBody,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.textSecondary.withValues(alpha: 0.95),
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

class _HeroHeader extends StatelessWidget {
  final AppLocalizations l10n;

  const _HeroHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.55),
            AppTheme.secondaryColor.withValues(alpha: 0.4),
            AppTheme.accentMuted.withValues(alpha: 0.35),
          ],
        ),
        boxShadow: AppTheme.premiumCardShadow,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppTheme.ctaGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                FontAwesomeIcons.mapLocationDot,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppTheme.brandSkyGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: Text(
                      l10n.appTitle,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFontFamily,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.45,
                        height: 1.12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1.0.0',
                    style: TextStyle(
                      fontFamily: AppTheme.uiFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textTertiary.withValues(alpha: 0.95),
                      letterSpacing: 0.35,
                    ),
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

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Gradient frame so “Guided tour” stands out from FAQ cards.
class _GuidedTourCard extends StatelessWidget {
  const _GuidedTourCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.45),
            AppTheme.secondaryColor.withValues(alpha: 0.35),
            AppTheme.accentColor.withValues(alpha: 0.25),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16.5),
        ),
        child: child,
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.75)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(
              question,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            children: [
              Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textSecondary.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
