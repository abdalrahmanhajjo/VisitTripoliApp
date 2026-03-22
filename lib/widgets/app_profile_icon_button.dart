import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

/// Profile icon for the header. Navigates to /profile. Shows login dialog for guests.
class AppProfileIconButton extends StatelessWidget {
  const AppProfileIconButton({
    super.key,
    this.iconColor,
    this.iconSize = 24,
  });

  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        if (auth.isGuest) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.loginRequired),
              content: Text(l10n.signInToAccessProfile),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/login');
                  },
                  child: Text(l10n.signIn),
                ),
              ],
            ),
          );
          return;
        }
        context.push('/profile');
      },
      icon: Icon(
        Icons.person_outline,
        size: iconSize,
        color: iconColor,
      ),
      style: IconButton.styleFrom(
        foregroundColor: iconColor,
      ),
      tooltip: l10n.profile,
    );
  }
}
