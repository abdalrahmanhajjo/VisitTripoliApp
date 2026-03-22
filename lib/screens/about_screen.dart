import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/responsive_utils.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: ResponsiveUtils.screenPadding(context),
        children: [
          // App Logo/Icon
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1d4ed8),
                    Color(0xFF3b82f6),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1d4ed8).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                FontAwesomeIcons.mapLocationDot,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // App Name & Version
          const Center(
            child: Text(
              'Visit Tripoli',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172a),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Description
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172a),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Visit Tripoli is your comprehensive guide to discovering the rich heritage, culture, and hidden gems of Tripoli, Lebanon. '
                  'Explore historical sites, traditional souks, beautiful mosques, and authentic local experiences.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Features
          _AboutSection(
            title: 'Features',
            items: [
              _AboutItem(
                icon: FontAwesomeIcons.mapLocationDot,
                text: 'Interactive maps with directions',
              ),
              _AboutItem(
                icon: FontAwesomeIcons.wandMagicSparkles,
                text: 'AI-powered trip planning',
              ),
              _AboutItem(
                icon: FontAwesomeIcons.heart,
                text: 'Save your favorite places',
              ),
              _AboutItem(
                icon: FontAwesomeIcons.route,
                text: 'Create and manage trips',
              ),
              _AboutItem(
                icon: FontAwesomeIcons.calendar,
                text: 'Discover local events',
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Partners
          _AboutSection(
            title: 'Partners',
            items: [
              _AboutItem(
                icon: FontAwesomeIcons.graduationCap,
                text: 'Beirut Arab University',
              ),
              _AboutItem(
                icon: FontAwesomeIcons.flag,
                text: 'Lebanese Ministry of Tourism',
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Links
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(FontAwesomeIcons.shieldHalved, color: Color(0xFF1d4ed8)),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Privacy Policy'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'Your privacy is important to us. This app collects minimal data necessary for functionality:\n\n'
                            '• Location data (only when you use map features)\n'
                            '• Saved places and trips (stored locally)\n'
                            '• User preferences\n\n'
                            'We do not share your data with third parties. All data is stored securely on your device.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(FontAwesomeIcons.fileContract, color: Color(0xFF1d4ed8)),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of Service coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(FontAwesomeIcons.code, color: Color(0xFF1d4ed8)),
                  title: const Text('Open Source Licenses'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open source licenses coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Copyright
          Center(
            child: Text(
              '© 2024 Visit Tripoli\nAll rights reserved',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final List<_AboutItem> items;

  const _AboutSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172a),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFeff6ff),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: const Color(0xFF1d4ed8),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.text,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 20),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AboutItem {
  final IconData icon;
  final String text;

  _AboutItem({required this.icon, required this.text});
}
