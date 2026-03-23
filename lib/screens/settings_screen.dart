import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';
import '../config/api_config.dart';
import '../providers/language_provider.dart';
import '../utils/responsive_utils.dart';

Future<void> _showServerUrlDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: ApiConfig.apiBaseUrlOverride ?? '');
  final formKey = GlobalKey<FormState>();
  if (!context.mounted) return;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final d = AppLocalizations.of(ctx)!;
      return AlertDialog(
        title: Text(d.apiServerUrlTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.apiServerUrlDialogBody,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: d.serverUrlLabel,
                  hintText: 'https://tripoli-explorer-api.onrender.com',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                autofillHints: const [AutofillHints.url],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final u = Uri.tryParse(v.trim());
                  if (u == null || !u.hasScheme || !u.hasAuthority) {
                    return d.serverUrlInvalid;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(d.cancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(d.save),
          ),
        ],
      );
    },
  );
  if (result != true || !context.mounted) return;
  final prefs = await SharedPreferences.getInstance();
  await ApiConfig.setOverride(controller.text, prefs);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.serverUrlSavedMessage)),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: ResponsiveUtils.screenPadding(context),
        children: [
          _SettingsSection(
            title: l10n.settingsGeneral,
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.language,
                title: l10n.language,
                subtitle: languageProvider.currentLanguage.displayName,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final d = AppLocalizations.of(ctx)!;
                      return AlertDialog(
                        title: Text(d.selectLanguage),
                        content: RadioGroup<AppLanguage>(
                          groupValue: languageProvider.currentLanguage,
                          onChanged: (value) {
                            if (value != null) {
                              languageProvider.setLanguage(value);
                              Navigator.pop(ctx);
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile<AppLanguage>(
                                title: Text(d.english),
                                value: AppLanguage.english,
                              ),
                              RadioListTile<AppLanguage>(
                                title: Text(d.arabic),
                                value: AppLanguage.arabic,
                              ),
                              RadioListTile<AppLanguage>(
                                title: Text(d.french),
                                value: AppLanguage.french,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.moon,
                title: l10n.settingsTheme,
                subtitle: l10n.settingsThemeLight,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.darkThemeComingSoon)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: l10n.settingsNotifications,
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.bell,
                title: l10n.settingsPushNotifications,
                subtitle: l10n.settingsEnabled,
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.envelope,
                title: l10n.settingsEmailNotifications,
                subtitle: l10n.settingsDisabled,
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: l10n.settingsServerSection,
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.server,
                title: l10n.apiServerUrlTitle,
                subtitle: ApiConfig.apiBaseUrlOverride ?? l10n.settingsDefaultCloud,
                onTap: () async {
                  await _showServerUrlDialog(context);
                  if (mounted) setState(() {});
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.envelope,
                title: l10n.emailSmtpSetupTitle,
                subtitle: l10n.settingsEmailSmtpSubtitle,
                onTap: () => context.push('/settings/email'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: l10n.settingsDataPrivacy,
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.download,
                title: l10n.settingsDownloadData,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.downloadingYourData)),
                  );
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.trash,
                title: l10n.clearCacheTitle,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final d = AppLocalizations.of(ctx)!;
                      return AlertDialog(
                        title: Text(d.clearCacheTitle),
                        content: Text(d.settingsClearCacheMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(d.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(d.cacheCleared)),
                              );
                            },
                            child: Text(d.clear),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFeff6ff),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF1d4ed8),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              )
            : null,
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
