import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import 'admin_interest_form_screen.dart';

class AdminInterestsScreen extends StatefulWidget {
  final String adminKey;

  const AdminInterestsScreen({super.key, required this.adminKey});

  @override
  State<AdminInterestsScreen> createState() => _AdminInterestsScreenState();
}

class _AdminInterestsScreenState extends State<AdminInterestsScreen> {
  List<dynamic> _interests = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final interests = await ApiService.instance.adminGetInterests(adminKey: widget.adminKey);
      setState(() {
        _interests = interests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteInterest(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.cardRadius)),
        title: const Text('Delete interest?'),
        content: const Text('This interest will be removed permanently.'),
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
      await ApiService.instance.adminDeleteInterest(id, adminKey: widget.adminKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interest deleted successfully')),
        );
        _loadInterests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editInterest(Map<String, dynamic> interest) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminInterestFormScreen(
          adminKey: widget.adminKey,
          interest: interest,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadInterests();
    }
  }

  Future<void> _addInterest() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminInterestFormScreen(
          adminKey: widget.adminKey,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadInterests();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_interests.isEmpty) {
      body = AdminEmptyState(
        icon: FontAwesomeIcons.star,
        title: 'No interests yet',
        subtitle: 'Add your first interest to get started.',
        onAdd: _addInterest,
        addLabel: 'Add Interest',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadInterests,
        color: AdminTheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(28),
          itemCount: _interests.length,
          itemBuilder: (context, index) {
            final interest = _interests[index];
            return AdminItemCard(
              title: interest['name'] ?? 'Unnamed',
              subtitle: interest['description'] ?? '',
              icon: FontAwesomeIcons.star,
              onTap: () => _editInterest(interest),
              onEdit: () => _editInterest(interest),
              onDelete: () => _deleteInterest(interest['id']),
            );
          },
        ),
      );
    }
    return AdminPageScaffold(
      title: 'Interests',
      subtitle: '${_interests.length} interest${_interests.length == 1 ? '' : 's'}',
      icon: FontAwesomeIcons.star,
      body: body,
      onAdd: _addInterest,
      addLabel: 'Add interest',
      isLoading: _isLoading,
      error: _error,
      onRetry: _loadInterests,
    );
  }
}
