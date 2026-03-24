import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// One-time "Take a tour?" prompt before the showcase starts.
Future<bool?> showAppTutorialPromptDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.explore_rounded,
        size: 40,
        color: AppTheme.primaryColor,
      ),
      title: Text(l10n.appTutorialDialogTitle),
      content: SingleChildScrollView(
        child: Text(
          l10n.appTutorialDialogBody,
          style: const TextStyle(
            height: 1.45,
            color: AppTheme.textSecondary,
            fontSize: 15,
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.appTutorialNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.appTutorialStartTour),
        ),
      ],
    ),
  );
}
