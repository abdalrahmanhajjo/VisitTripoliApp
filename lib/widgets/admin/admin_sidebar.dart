import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/admin_theme.dart';

class AdminSidebarItem {
  final IconData icon;
  final String label;
  final int index;

  const AdminSidebarItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<AdminSidebarItem> items;
  final String title;
  final String? subtitle;
  final VoidCallback? onLogout;
  final VoidCallback? onRefresh;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
    required this.title,
    this.subtitle,
    this.onLogout,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AdminTheme.sidebarWidth,
      decoration: const BoxDecoration(
        color: AdminTheme.sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.gear,
                    color: AdminTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AdminTheme.sidebarItemActive,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AdminTheme.sidebarItem,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFF2D3238), height: 1),
          const SizedBox(height: 12),
          ...items.map((item) {
            final isSelected = selectedIndex == item.index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: isSelected
                    ? AdminTheme.sidebarItemActiveBg
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onSelect(item.index),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          item.icon,
                          size: 18,
                          color: isSelected
                              ? AdminTheme.sidebarItemActive
                              : AdminTheme.sidebarItem,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? AdminTheme.sidebarItemActive
                                  : AdminTheme.sidebarItem,
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (onRefresh != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.sidebarItem,
                    side: const BorderSide(color: Color(0xFF2D3238)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
                  label: const Text('Refresh data'),
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (onLogout != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE07C7C),
                    side: const BorderSide(color: Color(0xFFE07C7C)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket, size: 14),
                  label: const Text('Sign out'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
