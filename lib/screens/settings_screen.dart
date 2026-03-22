import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../providers/language_provider.dart';
import '../utils/responsive_utils.dart';

Future<void> _showServerUrlDialog(BuildContext context) async {
  final controller = TextEditingController(text: ApiConfig.apiBaseUrlOverride ?? '');
  final formKey = GlobalKey<FormState>();
  if (!context.mounted) return;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('API Server URL'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API server URL. Default is the cloud (https://tripoli-explorer-api.onrender.com). Change only if you use a different server.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://tripoli-explorer-api.onrender.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autofillHints: const [AutofillHints.url],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final u = Uri.tryParse(v.trim());
                if (u == null || !u.hasScheme || !u.hasAuthority) return 'Enter a valid URL (e.g. https://example.com)';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(ctx, true);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (result != true || !context.mounted) return;
  final prefs = await SharedPreferences.getInstance();
  await ApiConfig.setOverride(controller.text, prefs);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Server URL saved. Restart or refresh to use it.')),
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

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: ResponsiveUtils.screenPadding(context),
        children: [
          _SettingsSection(
            title: 'General',
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.language,
                title: 'Language',
                subtitle: languageProvider.currentLanguage.displayName,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Select Language'),
                      content: RadioGroup<AppLanguage>(
                        groupValue: languageProvider.currentLanguage,
                        onChanged: (value) {
                          if (value != null) {
                            languageProvider.setLanguage(value);
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<AppLanguage>(
                              title: Text('English'),
                              value: AppLanguage.english,
                            ),
                            RadioListTile<AppLanguage>(
                              title: Text('Arabic'),
                              value: AppLanguage.arabic,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.moon,
                title: 'Theme',
                subtitle: 'Light',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dark theme coming soon')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.bell,
                title: 'Push Notifications',
                subtitle: 'Enabled',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.envelope,
                title: 'Email Notifications',
                subtitle: 'Disabled',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Server',
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.server,
                title: 'API Server URL',
                subtitle: ApiConfig.apiBaseUrlOverride ?? 'Default (cloud)',
                onTap: () async {
                  await _showServerUrlDialog(context);
                  if (mounted) setState(() {});
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.envelope,
                title: 'Email / SMTP Setup',
                subtitle:
                    'Configure SMTP for password reset and verification emails',
                onTap: () => context.push('/settings/email'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Data & Privacy',
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.download,
                title: 'Download Data',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading your data...')),
                  );
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.trash,
                title: 'Clear Cache',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear Cache'),
                      content: const Text(
                          'This will clear all cached data. Continue?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cache cleared')),
                            );
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
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
