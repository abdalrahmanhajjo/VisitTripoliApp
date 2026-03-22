import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';

class AdminInterestFormScreen extends StatefulWidget {
  final String adminKey;
  final Map<String, dynamic>? interest;

  const AdminInterestFormScreen({
    super.key,
    required this.adminKey,
    this.interest,
  });

  @override
  State<AdminInterestFormScreen> createState() => _AdminInterestFormScreenState();
}

class _AdminInterestFormScreenState extends State<AdminInterestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final _countController = TextEditingController();
  final _popularityController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.interest != null) {
      _idController.text = widget.interest!['id'] ?? '';
      _nameController.text = widget.interest!['name'] ?? '';
      _iconController.text = widget.interest!['icon'] ?? '';
      _descriptionController.text = widget.interest!['description'] ?? '';
      _colorController.text = widget.interest!['color'] ?? '#666';
      _countController.text = widget.interest!['count']?.toString() ?? '0';
      _popularityController.text = widget.interest!['popularity']?.toString() ?? '0';
      _tagsController.text = (widget.interest!['tags'] is List
              ? widget.interest!['tags']
              : [])
          .join(', ');
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _countController.dispose();
    _popularityController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final interestData = {
        'id': _idController.text.trim(),
        'name': _nameController.text.trim(),
        'icon': _iconController.text.trim(),
        'description': _descriptionController.text.trim(),
        'color': _colorController.text.trim(),
        'count': int.tryParse(_countController.text.trim()) ?? 0,
        'popularity': int.tryParse(_popularityController.text.trim()) ?? 0,
        'tags': _tagsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      };

      if (widget.interest != null) {
        await ApiService.instance.adminUpdateInterest(
          widget.interest!['id'],
          interestData,
          adminKey: widget.adminKey,
        );
      } else {
        await ApiService.instance.adminCreateInterest(
          interestData,
          adminKey: widget.adminKey,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.interest != null ? 'Interest updated' : 'Interest created'),
          ),
        );
        Navigator.pop(context, interestData);
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
        title: Text(widget.interest != null ? 'Edit interest' : 'Add interest', style: AdminTheme.titleMedium.copyWith(color: Colors.white)),
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
              enabled: widget.interest == null,
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
              controller: _colorController,
              decoration: AdminTheme.inputDecoration('Color'),
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
                    controller: _popularityController,
                    decoration: AdminTheme.inputDecoration('Popularity'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: AdminTheme.inputDecoration('Tags (comma-separated)'),
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
                    : Text(widget.interest != null ? 'Update interest' : 'Create interest'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
