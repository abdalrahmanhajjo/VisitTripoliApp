import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class BusinessOwnerPlaceFormScreen extends StatefulWidget {
  final String authToken;
  final Map<String, dynamic> place;

  const BusinessOwnerPlaceFormScreen({
    super.key,
    required this.authToken,
    required this.place,
  });

  @override
  State<BusinessOwnerPlaceFormScreen> createState() => _BusinessOwnerPlaceFormScreenState();
}

class _BusinessOwnerPlaceFormScreenState extends State<BusinessOwnerPlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
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
    _nameController.text = widget.place['name'] ?? '';
    _descriptionController.text = widget.place['description'] ?? '';
    _locationController.text = widget.place['location'] ?? '';
    _latitudeController.text = widget.place['latitude']?.toString() ?? '';
    _longitudeController.text = widget.place['longitude']?.toString() ?? '';
    _categoryController.text = widget.place['category'] ?? '';
    _categoryIdController.text = widget.place['categoryId'] ?? '';
    _durationController.text = widget.place['duration'] ?? '';
    _priceController.text = widget.place['price'] ?? '';
    _bestTimeController.text = widget.place['bestTime'] ?? '';
    _ratingController.text = widget.place['rating']?.toString() ?? '';
    _reviewCountController.text = widget.place['reviewCount']?.toString() ?? '';
    _imagesController.text = (widget.place['images'] is List
            ? widget.place['images']
            : [])
        .join('\n');
    _tagsController.text = (widget.place['tags'] is List ? widget.place['tags'] : [])
        .join(', ');
  }

  @override
  void dispose() {
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

      await ApiService.instance.businessUpdatePlace(
        widget.place['id'],
        placeData,
        authToken: widget.authToken,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place updated successfully')),
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
      appBar: AppBar(
        title: const Text('Edit Place'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryIdController,
              decoration: const InputDecoration(
                labelText: 'Category ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bestTimeController,
              decoration: const InputDecoration(
                labelText: 'Best Time',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ratingController,
                    decoration: const InputDecoration(
                      labelText: 'Rating',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _reviewCountController,
                    decoration: const InputDecoration(
                      labelText: 'Review Count',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imagesController,
              decoration: const InputDecoration(
                labelText: 'Images (one per line)',
                border: OutlineInputBorder(),
                helperText: 'Enter image URLs or use Upload below',
              ),
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
                          authToken: widget.authToken,
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
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isUploadingImage ? 'Uploading...' : 'Upload image'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                border: OutlineInputBorder(),
                helperText: 'Enter tags separated by commas',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Place'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
