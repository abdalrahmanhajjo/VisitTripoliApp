import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';

class AdminTourFormScreen extends StatefulWidget {
  final String adminKey;
  final Map<String, dynamic>? tour;

  const AdminTourFormScreen({
    super.key,
    required this.adminKey,
    this.tour,
  });

  @override
  State<AdminTourFormScreen> createState() => _AdminTourFormScreenState();
}

class _AdminTourFormScreenState extends State<AdminTourFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _durationHoursController = TextEditingController();
  final _locationsController = TextEditingController();
  final _ratingController = TextEditingController();
  final _reviewsController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController();
  final _priceDisplayController = TextEditingController();
  final _badgeController = TextEditingController();
  final _badgeColorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _languagesController = TextEditingController();
  final _includesController = TextEditingController();
  final _excludesController = TextEditingController();
  final _highlightsController = TextEditingController();
  final _itineraryController = TextEditingController();
  final _placeIdsController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tour != null) {
      _idController.text = widget.tour!['id'] ?? '';
      _nameController.text = widget.tour!['name'] ?? '';
      _durationController.text = widget.tour!['duration'] ?? '';
      _durationHoursController.text = widget.tour!['duration_hours']?.toString() ?? '0';
      _locationsController.text = widget.tour!['locations']?.toString() ?? '0';
      _ratingController.text = widget.tour!['rating']?.toString() ?? '0';
      _reviewsController.text = widget.tour!['reviews']?.toString() ?? '0';
      _priceController.text = widget.tour!['price']?.toString() ?? '0';
      _currencyController.text = widget.tour!['currency'] ?? 'USD';
      _priceDisplayController.text = widget.tour!['price_display'] ?? '';
      _badgeController.text = widget.tour!['badge'] ?? '';
      _badgeColorController.text = widget.tour!['badge_color'] ?? '';
      _descriptionController.text = widget.tour!['description'] ?? '';
      _imageController.text = widget.tour!['image'] ?? '';
      _difficultyController.text = widget.tour!['difficulty'] ?? 'moderate';
      _languagesController.text = _listToString(widget.tour!['languages'] ?? []);
      _includesController.text = _listToString(widget.tour!['includes'] ?? []);
      _excludesController.text = _listToString(widget.tour!['excludes'] ?? []);
      _highlightsController.text = _listToString(widget.tour!['highlights'] ?? []);
      _itineraryController.text = _itineraryToString(widget.tour!['itinerary'] ?? []);
      _placeIdsController.text = _listToString(widget.tour!['place_ids'] ?? []);
    }
  }

  String _listToString(dynamic list) {
    if (list is List) {
      return list.map((e) => e.toString()).join(', ');
    }
    return '';
  }

  String _itineraryToString(dynamic list) {
    if (list is List) {
      return list.map((e) {
        if (e is Map) {
          return '${e['time'] ?? ''}|${e['activity'] ?? ''}|${e['description'] ?? ''}';
        }
        return e.toString();
      }).join('\n');
    }
    return '';
  }

  List<Map<String, dynamic>> _parseItinerary(String text) {
    return text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          final parts = line.split('|');
          return {
            'time': parts.isNotEmpty ? parts[0].trim() : '',
            'activity': parts.length > 1 ? parts[1].trim() : '',
            'description': parts.length > 2 ? parts[2].trim() : '',
          };
        })
        .toList();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _durationController.dispose();
    _durationHoursController.dispose();
    _locationsController.dispose();
    _ratingController.dispose();
    _reviewsController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _priceDisplayController.dispose();
    _badgeController.dispose();
    _badgeColorController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _difficultyController.dispose();
    _languagesController.dispose();
    _includesController.dispose();
    _excludesController.dispose();
    _highlightsController.dispose();
    _itineraryController.dispose();
    _placeIdsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tourData = {
        'id': _idController.text.trim(),
        'name': _nameController.text.trim(),
        'duration': _durationController.text.trim(),
        'durationHours': int.tryParse(_durationHoursController.text.trim()) ?? 0,
        'locations': int.tryParse(_locationsController.text.trim()) ?? 0,
        'rating': double.tryParse(_ratingController.text.trim()) ?? 0.0,
        'reviews': int.tryParse(_reviewsController.text.trim()) ?? 0,
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'currency': _currencyController.text.trim(),
        'priceDisplay': _priceDisplayController.text.trim(),
        'badge': _badgeController.text.trim().isEmpty ? null : _badgeController.text.trim(),
        'badgeColor': _badgeColorController.text.trim().isEmpty ? null : _badgeColorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': _imageController.text.trim(),
        'difficulty': _difficultyController.text.trim(),
        'languages': _languagesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'includes': _includesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'excludes': _excludesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'highlights': _highlightsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'itinerary': _parseItinerary(_itineraryController.text),
        'placeIds': _placeIdsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      };

      if (widget.tour != null) {
        await ApiService.instance.adminUpdateTour(
          widget.tour!['id'],
          tourData,
          adminKey: widget.adminKey,
        );
      } else {
        await ApiService.instance.adminCreateTour(
          tourData,
          adminKey: widget.adminKey,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.tour != null ? 'Tour updated' : 'Tour created'),
          ),
        );
        Navigator.pop(context, tourData);
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
        title: Text(widget.tour != null ? 'Edit tour' : 'Add tour', style: AdminTheme.titleMedium.copyWith(color: Colors.white)),
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
              enabled: widget.tour == null,
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
                    controller: _durationController,
                    decoration: AdminTheme.inputDecoration('Duration'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationHoursController,
                    decoration: AdminTheme.inputDecoration('Duration (hours)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationsController,
                    decoration: AdminTheme.inputDecoration('Locations'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _ratingController,
                    decoration: AdminTheme.inputDecoration('Rating'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _reviewsController,
                    decoration: AdminTheme.inputDecoration('Reviews'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: AdminTheme.inputDecoration('Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currencyController,
                    decoration: AdminTheme.inputDecoration('Currency'),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _badgeController,
                    decoration: AdminTheme.inputDecoration('Badge'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _badgeColorController,
                    decoration: AdminTheme.inputDecoration('Badge color'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageController,
              decoration: AdminTheme.inputDecoration('Image URL'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _difficultyController,
              decoration: AdminTheme.inputDecoration('Difficulty'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _languagesController,
              decoration: AdminTheme.inputDecoration('Languages (comma-separated)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _includesController,
              decoration: AdminTheme.inputDecoration('Includes (comma-separated)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _excludesController,
              decoration: AdminTheme.inputDecoration('Excludes (comma-separated)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _highlightsController,
              decoration: AdminTheme.inputDecoration('Highlights (comma-separated)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _itineraryController,
              decoration: AdminTheme.inputDecoration('Itinerary (time|activity|description, one per line)'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _placeIdsController,
              decoration: AdminTheme.inputDecoration('Place IDs (comma-separated)'),
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
                    : Text(widget.tour != null ? 'Update tour' : 'Create tour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
