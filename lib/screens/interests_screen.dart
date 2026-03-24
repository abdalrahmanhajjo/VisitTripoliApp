import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/interests_provider.dart';
import '../models/interest.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class InterestsScreen extends StatefulWidget {
  /// When true (opened from Profile), shows back + Done and does not complete onboarding.
  const InterestsScreen({super.key, this.profileEditMode = false});

  final bool profileEditMode;

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InterestsProvider>(context);
    final interests = provider.interests;

    return Scaffold(
      body: Stack(
        children: [
          // Decorative background
          _buildBackground(context),
          SafeArea(
            child: provider.isLoading
                ? _buildLoadingState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header section
                      _buildHeader(context),
                      // Content section
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProgressSection(provider),
                              _buildQuickActions(provider),
                              _buildInterestsGrid(interests, provider),
                              const SizedBox(
                                  height: 100), // Space for bottom bar
                            ],
                          ),
                        ),
                      ),
                      // Bottom action bar
                      _buildBottomBar(context, provider),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundColor,
            AppTheme.backgroundColor,
            AppTheme.surfaceColor.withValues(alpha: 0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2.5,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.loadingInterests,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final edit = widget.profileEditMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (edit)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppTheme.textPrimary,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.9),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ),
          if (edit) const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.yourInterests,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.tapToSelectInterests,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(InterestsProvider provider) {
    final selected = provider.selectedIds.length;
    final total = provider.interests.length;
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? selected / total : 0,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  selected > 0 ? AppTheme.primaryColor : AppTheme.borderColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.selectedCount(selected),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(InterestsProvider provider) {
    final total = provider.interests.length;
    final selected = provider.selectedIds.length;
    final allSelected = selected == total && total > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SimpleChip(
            label: allSelected
                ? AppLocalizations.of(context)!.clearAll
                : AppLocalizations.of(context)!.selectAll,
            onTap: () {
              HapticFeedback.lightImpact();
              if (allSelected) {
                provider.setSelected([]);
              } else {
                provider.setSelected(
                  provider.interests.map((i) => i.id).toList(),
                );
              }
            },
          ),
          _SimpleChip(
            label: AppLocalizations.of(context)!.popularPicks,
            onTap: () {
              HapticFeedback.lightImpact();
              final sorted = List<Interest>.from(provider.interests)
                ..sort((a, b) => b.popularity.compareTo(a.popularity));
              provider.setSelected(
                sorted.take(5).map((i) => i.id).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsGrid(
    List<Interest> interests,
    InterestsProvider provider,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: interests.map((interest) {
        final isSelected = provider.isSelected(interest.id);
        return _InterestChip(
          label: interest.name,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            provider.toggleInterest(interest.id);
          },
        );
      }).toList(),
    );
  }

  void _completeOnboardingAndGoToExplore() async {
    HapticFeedback.mediumImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isGuest) {
      auth.setOnboardingCompleted(true); // Store locally for guests
    } else if (auth.authToken != null) {
      try {
        await ApiService.instance
            .updateProfile(auth.authToken!, {'onboardingCompleted': true});
        auth.setOnboardingCompleted(true);
      } catch (_) {}
    }
    if (mounted) context.go('/explore?welcome=1');
  }

  Widget _buildBottomBar(BuildContext context, InterestsProvider provider) {
    final selected = provider.selectedIds.length;

    if (widget.profileEditMode) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              AppLocalizations.of(context)!.done,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _completeOnboardingAndGoToExplore,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                selected > 0
                    ? AppLocalizations.of(context)!.continueWithCount(selected)
                    : AppLocalizations.of(context)!.continueBtn,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _completeOnboardingAndGoToExplore,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(AppLocalizations.of(context)!.skip),
          ),
        ],
      ),
    );
  }
}

class _SimpleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SimpleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
