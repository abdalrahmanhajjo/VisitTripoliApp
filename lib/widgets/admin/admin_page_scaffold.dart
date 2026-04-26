import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';
import '../../theme/admin_theme.dart';

/// Reusable empty state for admin list pages.
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final String addLabel;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAdd,
    required this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AdminTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, size: 44, color: AdminTheme.primary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          Text(title, style: AdminTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: AdminTheme.bodyMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AdminTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.inputRadius)),
            ),
            icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
            label: Text(addLabel),
          ),
        ],
      ),
    );
  }
}

/// Reusable list item card for admin list pages.
class AdminItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AdminTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AdminTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FaIcon(icon, color: AdminTheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AdminTheme.titleMedium.copyWith(fontSize: 16)),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(subtitle, style: AdminTheme.bodyMedium.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                IconButton(onPressed: onEdit, icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 18), color: AdminTheme.textSecondary, tooltip: AppLocalizations.of(context)!.edit),
                IconButton(onPressed: onDelete, icon: const FaIcon(FontAwesomeIcons.trashCan, size: 18), color: AdminTheme.error, tooltip: AppLocalizations.of(context)!.deleteTooltip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget body;
  final VoidCallback? onAdd;
  final String addLabel;
  final List<Widget>? actions;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  const AdminPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.body,
    this.onAdd,
    this.addLabel = 'Add',
    this.actions,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AdminTheme.primary),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminTheme.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.circleExclamation,
                  size: 40,
                  color: AdminTheme.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.errorGenericTitle,
                style: AdminTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: AdminTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTheme.inputRadius),
                  ),
                ),
                icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
                label: Text(AppLocalizations.of(context)!.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AdminTheme.inputRadius),
                ),
                child: FaIcon(icon, size: 22, color: AdminTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminTheme.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: AdminTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
              if (onAdd != null)
                FilledButton.icon(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.inputRadius),
                    ),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                  label: Text(addLabel),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }
}
