import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import 'admin_user_form_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  final String adminKey;

  const AdminUsersScreen({super.key, required this.adminKey});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await ApiService.instance.adminGetUsers(adminKey: widget.adminKey);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.cardRadius)),
        title: const Text('Delete user?'),
        content: const Text('This user will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.instance.adminDeleteUser(id, adminKey: widget.adminKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserFormScreen(
          adminKey: widget.adminKey,
          user: user,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadUsers();
    }
  }

  Future<void> _addUser() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserFormScreen(
          adminKey: widget.adminKey,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_users.isEmpty) {
      body = AdminEmptyState(
        icon: FontAwesomeIcons.users,
        title: 'No users yet',
        subtitle: 'Add your first user to get started.',
        onAdd: _addUser,
        addLabel: 'Add User',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadUsers,
        color: AdminTheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(28),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            return AdminItemCard(
              title: user['name'] ?? user['email'] ?? 'Unnamed',
              subtitle: user['email'] ?? '',
              icon: FontAwesomeIcons.user,
              onTap: () => _editUser(user),
              onEdit: () => _editUser(user),
              onDelete: () => _deleteUser(user['id']),
            );
          },
        ),
      );
    }
    return AdminPageScaffold(
      title: 'Users',
      subtitle: '${_users.length} user${_users.length == 1 ? '' : 's'}',
      icon: FontAwesomeIcons.users,
      body: body,
      onAdd: _addUser,
      addLabel: 'Add user',
      isLoading: _isLoading,
      error: _error,
      onRetry: _loadUsers,
    );
  }
}
