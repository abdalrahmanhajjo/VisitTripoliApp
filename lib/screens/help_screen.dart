import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';
import '../utils/responsive_utils.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: Text(l10n.helpSupportTitle),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: ResponsiveUtils.screenPadding(context),
        children: [
          // FAQ Section
          const _HelpSection(
            title: 'Frequently Asked Questions',
            items: [
              _HelpItem(
                question: 'How do I save a place?',
                answer: 'Tap the heart icon on any place card or place details page to save it to your favorites.',
              ),
              _HelpItem(
                question: 'How do I create a trip?',
                answer: 'Manually add places to your trips from the Trips screen. Save places from Explore, then add them to a trip.',
              ),
              _HelpItem(
                question: 'Can I use the app offline?',
                answer: 'Yes! Saved places and trips are stored locally on your device and can be accessed offline.',
              ),
              _HelpItem(
                question: 'How do I get directions?',
                answer: 'Tap the "Directions" button on any place card, or use the Map screen to navigate to multiple places.',
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Contact Section
          _HelpSection(
            title: 'Contact Us',
            items: [
              _ContactTile(
                icon: FontAwesomeIcons.envelope,
                title: 'Email Support',
                subtitle: 'support@tripoliexplorer.com',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.helpEmailComingSoon)),
                  );
                },
              ),
              _ContactTile(
                icon: FontAwesomeIcons.phone,
                title: 'Phone Support',
                subtitle: '+961 1 234 567',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.helpPhoneComingSoon)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Resources
          _HelpSection(
            title: 'Resources',
            items: [
              _ContactTile(
                icon: FontAwesomeIcons.book,
                title: 'User Guide',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.helpUserGuideComingSoon)),
                  );
                },
              ),
              _ContactTile(
                icon: FontAwesomeIcons.video,
                title: 'Video Tutorials',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.helpVideoTutorialsComingSoon)),
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

class _HelpSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _HelpSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172a),
          ),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String question;
  final String answer;

  const _HelpItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFeff6ff),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1d4ed8),
            size: 24,
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
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
