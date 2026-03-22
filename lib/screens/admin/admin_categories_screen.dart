import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import 'admin_category_form_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  final String adminKey;

  const AdminCategoriesScreen({super.key, required this.adminKey});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await ApiService.instance.adminGetCategories(adminKey: widget.adminKey);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.cardRadius)),
        title: const Text('Delete category?'),
        content: const Text('This category will be removed permanently.'),
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
      await ApiService.instance.adminDeleteCategory(id, adminKey: widget.adminKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
        _loadCategories();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCategoryFormScreen(
          adminKey: widget.adminKey,
          category: category,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadCategories();
    }
  }

  Future<void> _addCategory() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCategoryFormScreen(
          adminKey: widget.adminKey,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_categories.isEmpty) {
      body = AdminEmptyState(
        icon: FontAwesomeIcons.tags,
        title: 'No categories yet',
        subtitle: 'Add your first category to get started.',
        onAdd: _addCategory,
        addLabel: 'Add Category',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadCategories,
        color: AdminTheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(28),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return AdminItemCard(
              title: category['name'] ?? 'Unnamed',
              subtitle: category['description'] ?? '',
              icon: FontAwesomeIcons.tags,
              onTap: () => _editCategory(category),
              onEdit: () => _editCategory(category),
              onDelete: () => _deleteCategory(category['id']),
            );
          },
        ),
      );
    }
    return AdminPageScaffold(
      title: 'Categories',
      subtitle: '${_categories.length} categor${_categories.length == 1 ? 'y' : 'ies'}',
      icon: FontAwesomeIcons.tags,
      body: body,
      onAdd: _addCategory,
      addLabel: 'Add category',
      isLoading: _isLoading,
      error: _error,
      onRetry: _loadCategories,
    );
  }
}
