import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  final String adminKey;
  final Map<String, dynamic>? category;

  const AdminCategoryFormScreen({
    super.key,
    required this.adminKey,
    this.category,
  });

  @override
  State<AdminCategoryFormScreen> createState() => _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _countController = TextEditingController();
  final _colorController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _idController.text = widget.category!['id'] ?? '';
      _nameController.text = widget.category!['name'] ?? '';
      _iconController.text = widget.category!['icon'] ?? '';
      _descriptionController.text = widget.category!['description'] ?? '';
      _tagsController.text = (widget.category!['tags'] is List
              ? widget.category!['tags']
              : [])
          .join(', ');
      _countController.text = widget.category!['count']?.toString() ?? '0';
      _colorController.text = widget.category!['color'] ?? '#666';
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _countController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryData = {
        'id': _idController.text.trim(),
        'name': _nameController.text.trim(),
        'icon': _iconController.text.trim(),
        'description': _descriptionController.text.trim(),
        'tags': _tagsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'count': int.tryParse(_countController.text.trim()) ?? 0,
        'color': _colorController.text.trim(),
      };

      if (widget.category != null) {
        await ApiService.instance.adminUpdateCategory(
          widget.category!['id'],
          categoryData,
          adminKey: widget.adminKey,
        );
      } else {
        await ApiService.instance.adminCreateCategory(
          categoryData,
          adminKey: widget.adminKey,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.category != null ? 'Category updated' : 'Category created'),
          ),
        );
        Navigator.pop(context, categoryData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AppBar(
        title: Text(widget.category != null ? 'Edit category' : 'Add category', style: AdminTheme.titleMedium.copyWith(color: Colors.white)),
        backgroundColor: AdminTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _idController,
              decoration: AdminTheme.inputDecoration('ID *'),
              enabled: widget.category == null,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: AdminTheme.inputDecoration('Name *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _iconController,
              decoration: AdminTheme.inputDecoration('Icon'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: AdminTheme.inputDecoration('Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: AdminTheme.inputDecoration('Tags (comma-separated)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countController,
                    decoration: AdminTheme.inputDecoration('Count'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: AdminTheme.inputDecoration('Color'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.inputRadius)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.category != null ? 'Update category' : 'Create category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
