import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';

class AdminUserFormScreen extends StatefulWidget {
  final String adminKey;
  final Map<String, dynamic>? user;

  const AdminUserFormScreen({
    super.key,
    required this.adminKey,
    this.user,
  });

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAdmin = false;
  bool _feedUploadBlocked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!['name'] ?? '';
      _emailController.text = widget.user!['email'] ?? '';
      _isAdmin = widget.user!['is_admin'] == true;
      _feedUploadBlocked = widget.user!['feed_upload_blocked'] == true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.user == null && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is required for new users')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.user != null) {
        // Update existing user
        final userData = {
          'isAdmin': _isAdmin,
          'feedUploadBlocked': _feedUploadBlocked,
        };
        await ApiService.instance.adminUpdateUser(
          widget.user!['id'],
          userData,
          adminKey: widget.adminKey,
        );
      } else {
        // Create new user
        final userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        };
        await ApiService.instance.adminCreateUser(
          userData,
          adminKey: widget.adminKey,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.user != null ? 'User updated' : 'User created'),
          ),
        );
        Navigator.pop(context, {});
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
        title: Text(widget.user != null ? 'Edit user' : 'Add user', style: AdminTheme.titleMedium.copyWith(color: Colors.white)),
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
              controller: _nameController,
              decoration: AdminTheme.inputDecoration('Name'),
              enabled: widget.user == null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: AdminTheme.inputDecoration('Email *'),
              enabled: widget.user == null,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            if (widget.user == null) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: AdminTheme.inputDecoration('Password *'),
                obscureText: true,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
            if (widget.user != null) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text('Is admin', style: AdminTheme.bodyMedium),
                value: _isAdmin,
                activeColor: AdminTheme.primary,
                onChanged: (value) {
                  setState(() {
                    _isAdmin = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Block feed uploads', style: AdminTheme.bodyMedium),
                value: _feedUploadBlocked,
                activeColor: AdminTheme.primary,
                onChanged: (value) {
                  setState(() {
                    _feedUploadBlocked = value ?? false;
                  });
                },
              ),
            ],
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
                    : Text(widget.user != null ? 'Update user' : 'Create user'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
