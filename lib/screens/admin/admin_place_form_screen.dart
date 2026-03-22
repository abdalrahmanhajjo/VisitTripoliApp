import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';

class AdminPlaceFormScreen extends StatefulWidget {
  final String adminKey;
  final Map<String, dynamic>? place;

  const AdminPlaceFormScreen({
    super.key,
    required this.adminKey,
    this.place,
  });

  @override
  State<AdminPlaceFormScreen> createState() => _AdminPlaceFormScreenState();
}

class _AdminPlaceFormScreenState extends State<AdminPlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _categoryIdController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _bestTimeController = TextEditingController();
  final _ratingController = TextEditingController();
  final _reviewCountController = TextEditingController();
  final _imagesController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.place != null) {
      _idController.text = widget.place!['id'] ?? '';
      _nameController.text = widget.place!['name'] ?? '';
      _descriptionController.text = widget.place!['description'] ?? '';
      _locationController.text = widget.place!['location'] ?? '';
      _latitudeController.text = widget.place!['latitude']?.toString() ?? '';
      _longitudeController.text = widget.place!['longitude']?.toString() ?? '';
      _categoryController.text = widget.place!['category'] ?? '';
      _categoryIdController.text = widget.place!['category_id'] ?? '';
      _durationController.text = widget.place!['duration'] ?? '';
      _priceController.text = widget.place!['price'] ?? '';
      _bestTimeController.text = widget.place!['best_time'] ?? '';
      _ratingController.text = widget.place!['rating']?.toString() ?? '';
      _reviewCountController.text =
          widget.place!['review_count']?.toString() ?? '';
      _imagesController.text =
          (widget.place!['images'] is List ? widget.place!['images'] : [])
              .join('\n');
      _tagsController.text =
          (widget.place!['tags'] is List ? widget.place!['tags'] : [])
              .join(', ');
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _categoryController.dispose();
    _categoryIdController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _bestTimeController.dispose();
    _ratingController.dispose();
    _reviewCountController.dispose();
    _imagesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final placeData = {
        'id': _idController.text.trim(),
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _latitudeController.text.trim().isEmpty
            ? null
            : double.tryParse(_latitudeController.text.trim()),
        'longitude': _longitudeController.text.trim().isEmpty
            ? null
            : double.tryParse(_longitudeController.text.trim()),
        'category': _categoryController.text.trim(),
        'categoryId': _categoryIdController.text.trim(),
        'duration': _durationController.text.trim(),
        'price': _priceController.text.trim(),
        'bestTime': _bestTimeController.text.trim(),
        'rating': _ratingController.text.trim().isEmpty
            ? null
            : double.tryParse(_ratingController.text.trim()),
        'reviewCount': _reviewCountController.text.trim().isEmpty
            ? null
            : int.tryParse(_reviewCountController.text.trim()),
        'images': _imagesController.text
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList(),
        'tags': _tagsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      };

      if (widget.place != null) {
        await ApiService.instance.adminUpdatePlace(
          widget.place!['id'],
          placeData,
          adminKey: widget.adminKey,
        );
      } else {
        await ApiService.instance.adminCreatePlace(
          placeData,
          adminKey: widget.adminKey,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(widget.place != null ? 'Place updated' : 'Place created'),
          ),
        );
        Navigator.pop(context, placeData);
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
        title: Text(widget.place != null ? 'Edit place' : 'Add place',
            style: AdminTheme.titleMedium.copyWith(color: Colors.white)),
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
              enabled: widget.place == null,
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
            TextFormField(
              controller: _locationController,
              decoration: AdminTheme.inputDecoration('Location'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: AdminTheme.inputDecoration('Latitude'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: AdminTheme.inputDecoration('Longitude'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: AdminTheme.inputDecoration('Category'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryIdController,
              decoration: AdminTheme.inputDecoration('Category ID'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: AdminTheme.inputDecoration('Duration'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: AdminTheme.inputDecoration('Price'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bestTimeController,
              decoration: AdminTheme.inputDecoration('Best time to visit'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ratingController,
                    decoration: AdminTheme.inputDecoration('Rating'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _reviewCountController,
                    decoration: AdminTheme.inputDecoration('Review count'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imagesController,
              decoration: AdminTheme.inputDecoration(
                  'Images (one URL per line)',
                  helperText: 'Or use Upload below to add from device'),
              maxLines: 5,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isUploadingImage
                  ? null
                  : () async {
                      final picked = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1920,
                      );
                      if (picked == null || !mounted) return;
                      final path = picked.path;
                      if (path.isEmpty) return;
                      setState(() => _isUploadingImage = true);
                      try {
                        final url = await ApiService.instance.uploadImage(
                          adminKey: widget.adminKey,
                          filePath: path,
                        );
                        if (url != null && context.mounted) {
                          final cur = _imagesController.text.trim();
                          _imagesController.text =
                              cur.isEmpty ? url : '$cur\n$url';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Image uploaded and added')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Upload failed: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isUploadingImage = false);
                        }
                      }
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.primary,
                side: const BorderSide(color: AdminTheme.primary),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AdminTheme.inputRadius)),
              ),
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AdminTheme.primary),
                    )
                  : const FaIcon(FontAwesomeIcons.upload, size: 18),
              label: Text(_isUploadingImage ? 'Uploading...' : 'Upload image'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: AdminTheme.inputDecoration('Tags (comma-separated)',
                  helperText: 'e.g. historic, family-friendly'),
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
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AdminTheme.inputRadius)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        widget.place != null ? 'Update place' : 'Create place'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
