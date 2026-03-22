import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';

class AdminEventFormScreen extends StatefulWidget {
  final String adminKey;
  final Map<String, dynamic>? event;

  const AdminEventFormScreen({
    super.key,
    required this.adminKey,
    this.event,
  });

  @override
  State<AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends State<AdminEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageController = TextEditingController();
  final _categoryController = TextEditingController();
  final _organizerController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceDisplayController = TextEditingController();
  final _statusController = TextEditingController();
  final _placeIdController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _idController.text = widget.event!['id'] ?? '';
      _nameController.text = widget.event!['name'] ?? '';
      _descriptionController.text = widget.event!['description'] ?? '';
      _startDateController.text = widget.event!['start_date'] ?? '';
      _endDateController.text = widget.event!['end_date'] ?? '';
      _locationController.text = widget.event!['location'] ?? '';
      _imageController.text = widget.event!['image'] ?? '';
      _categoryController.text = widget.event!['category'] ?? '';
      _organizerController.text = widget.event!['organizer'] ?? '';
      _priceController.text = widget.event!['price']?.toString() ?? '';
      _priceDisplayController.text = widget.event!['price_display'] ?? '';
      _statusController.text = widget.event!['status'] ?? 'active';
      _placeIdController.text = widget.event!['place_id'] ?? '';
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _locationController.dispose();
    _imageController.dispose();
    _categoryController.dispose();
    _organizerController.dispose();
    _priceController.dispose();
    _priceDisplayController.dispose();
    _statusController.dispose();
    _placeIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final eventData = {
        'id': _idController.text.trim(),
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': _startDateController.text.trim(),
        'endDate': _endDateController.text.trim(),
        'location': _locationController.text.trim(),
        'image': _imageController.text.trim(),
        'category': _categoryController.text.trim(),
        'organizer': _organizerController.text.trim(),
        'price': _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        'priceDisplay': _priceDisplayController.text.trim(),
        'status': _statusController.text.trim(),
        'placeId': _placeIdController.text.trim().isEmpty
            ? null
            : _placeIdController.text.trim(),
      };

      if (widget.event != null) {
        await ApiService.instance.adminUpdateEvent(
          widget.event!['id'],
          eventData,
          adminKey: widget.adminKey,
        );
      } else {
        await ApiService.instance.adminCreateEvent(
          eventData,
          adminKey: widget.adminKey,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null ? 'Event updated' : 'Event created'),
          ),
        );
        Navigator.pop(context, eventData);
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
        title: Text(widget.event != null ? 'Edit event' : 'Add event', style: AdminTheme.titleMedium.copyWith(color: Colors.white)),
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
              enabled: widget.event == null,
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
              controller: _descriptionController,
              decoration: AdminTheme.inputDecoration('Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: AdminTheme.inputDecoration('Start date (YYYY-MM-DD)'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: AdminTheme.inputDecoration('End date (YYYY-MM-DD)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: AdminTheme.inputDecoration('Location'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageController,
              decoration: AdminTheme.inputDecoration('Image URL'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: AdminTheme.inputDecoration('Category'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _organizerController,
              decoration: AdminTheme.inputDecoration('Organizer'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: AdminTheme.inputDecoration('Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceDisplayController,
                    decoration: AdminTheme.inputDecoration('Price display'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _statusController,
              decoration: AdminTheme.inputDecoration('Status'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _placeIdController,
              decoration: AdminTheme.inputDecoration('Place ID'),
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
                    : Text(widget.event != null ? 'Update event' : 'Create event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
