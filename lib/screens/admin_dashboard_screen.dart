import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/admin/admin_sidebar.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_places_screen.dart';
import 'admin/admin_tours_screen.dart';
import 'admin/admin_events_screen.dart';
import 'admin/admin_categories_screen.dart';
import 'admin/admin_interests_screen.dart';
import 'admin/admin_users_screen.dart';
import 'admin/business_owner_places_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? _adminKey;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;
  int _selectedIndex = 0;
  bool _isBusinessOwnerMode = false;
  final _keyController = TextEditingController();

  static const List<AdminSidebarItem> _sidebarItems = [
    AdminSidebarItem(
        icon: FontAwesomeIcons.chartPie, label: 'Overview', index: 0),
    AdminSidebarItem(
        icon: FontAwesomeIcons.locationDot, label: 'Places', index: 1),
    AdminSidebarItem(icon: FontAwesomeIcons.route, label: 'Tours', index: 2),
    AdminSidebarItem(
        icon: FontAwesomeIcons.calendarDays, label: 'Events', index: 3),
    AdminSidebarItem(
        icon: FontAwesomeIcons.tags, label: 'Categories', index: 4),
    AdminSidebarItem(icon: FontAwesomeIcons.star, label: 'Interests', index: 5),
    AdminSidebarItem(icon: FontAwesomeIcons.users, label: 'Users', index: 6),
  ];

  @override
  void initState() {
    super.initState();
    _checkBusinessOwnerAccess();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _checkBusinessOwnerAccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isBusinessOwner && authProvider.isLoggedIn) {
      setState(() {
        _isBusinessOwnerMode = true;
        _adminKey = 'business_owner';
      });
      _loadStats();
    }
  }

  Future<void> _login(String key) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.instance.adminLogin(key);
      if (result['success'] == true) {
        setState(() {
          _adminKey = key;
          _isLoading = false;
        });
        _loadStats();
      } else {
        setState(() {
          _error = result['error'] ?? 'Invalid admin key';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    if (_adminKey == null) return;
    try {
      final stats =
          await ApiService.instance.getAdminStats(adminKey: _adminKey!);
      setState(() => _stats = stats);
    } catch (_) {}
  }

  Widget _buildLoginScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isBusinessOwner =
        authProvider.isBusinessOwner && authProvider.isLoggedIn;

    return Scaffold(
      backgroundColor: AdminTheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AdminTheme.sidebarBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.shieldHalved,
                    size: 48,
                    color: AdminTheme.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Visit Tripoli',
                  style: AdminTheme.titleLarge.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  'Admin & Business Dashboard',
                  style: AdminTheme.bodyMedium.copyWith(
                    color: AdminTheme.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                if (isBusinessOwner) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _isBusinessOwnerMode = true;
                          _adminKey = 'business_owner';
                        });
                        _loadStats();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AdminTheme.inputRadius),
                        ),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.building, size: 18),
                      label: const Text('Open Business Dashboard'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AdminTheme.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or sign in as full admin',
                          style: AdminTheme.label,
                        ),
                      ),
                      const Expanded(child: Divider(color: AdminTheme.border)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                TextField(
                  controller: _keyController,
                  obscureText: true,
                  style: AdminTheme.bodyMedium
                      .copyWith(color: AdminTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Admin key',
                    hintText: 'Enter your admin key',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 12),
                      child: FaIcon(FontAwesomeIcons.key,
                          size: 18, color: AdminTheme.textSecondary),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AdminTheme.inputRadius),
                    ),
                    filled: true,
                    fillColor: AdminTheme.surfaceCard,
                  ),
                  onSubmitted: (_) => _login(_keyController.text),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminTheme.error.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AdminTheme.inputRadius),
                      border: Border.all(
                          color: AdminTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.circleExclamation,
                            color: AdminTheme.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: AdminTheme.error, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _isLoading ? null : () => _login(_keyController.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AdminTheme.inputRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sign in as Admin'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_isBusinessOwnerMode) return _buildBusinessOwnerDashboard();

    return Scaffold(
      backgroundColor: AdminTheme.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSidebar(
            title: 'Dashboard',
            subtitle: 'Visit Tripoli',
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
            items: _sidebarItems,
            onRefresh: _loadStats,
            onLogout: () {
              setState(() {
                _adminKey = null;
                _stats = null;
                _isBusinessOwnerMode = false;
              });
            },
          ),
          Expanded(
            child: _stats == null
                ? const Center(
                    child: CircularProgressIndicator(color: AdminTheme.primary))
                : _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return AdminPlacesScreen(adminKey: _adminKey!);
      case 2:
        return AdminToursScreen(adminKey: _adminKey!);
      case 3:
        return AdminEventsScreen(adminKey: _adminKey!);
      case 4:
        return AdminCategoriesScreen(adminKey: _adminKey!);
      case 5:
        return AdminInterestsScreen(adminKey: _adminKey!);
      case 6:
        return AdminUsersScreen(adminKey: _adminKey!);
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildBusinessOwnerDashboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        backgroundColor: AdminTheme.surfaceCard,
        foregroundColor: AdminTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket),
            onPressed: () {
              setState(() {
                _adminKey = null;
                _stats = null;
                _isBusinessOwnerMode = false;
              });
            },
          ),
        ],
      ),
      body: BusinessOwnerPlacesScreen(authToken: authProvider.authToken ?? ''),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _stats ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AdminTheme.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: AdminTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Content and user counts at a glance.',
                style: AdminTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 800
                      ? 4
                      : (constraints.maxWidth > 500 ? 3 : 2);
                  return GridView.count(
                    crossAxisCount: crossCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.4,
                    children: [
                      _statCard(
                          'Places',
                          stats['places']?.toString() ?? '0',
                          FontAwesomeIcons.locationDot,
                          const Color(0xFF2563EB)),
                      _statCard('Tours', stats['tours']?.toString() ?? '0',
                          FontAwesomeIcons.route, const Color(0xFF059669)),
                      _statCard(
                          'Events',
                          stats['events']?.toString() ?? '0',
                          FontAwesomeIcons.calendarDays,
                          const Color(0xFFD97706)),
                      _statCard(
                          'Categories',
                          stats['categories']?.toString() ?? '0',
                          FontAwesomeIcons.tags,
                          const Color(0xFF7C3AED)),
                      _statCard(
                          'Interests',
                          stats['interests']?.toString() ?? '0',
                          FontAwesomeIcons.star,
                          const Color(0xFFDB2777)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AdminTheme.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, size: 22, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: AdminTheme.titleLarge.copyWith(fontSize: 28, color: color),
          ),
          const SizedBox(height: 4),
          Text(title, style: AdminTheme.label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_adminKey == null && !_isBusinessOwnerMode) {
      return _buildLoginScreen();
    }
    return _buildDashboard();
  }
}
