import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import 'admin_tour_form_screen.dart';

class AdminToursScreen extends StatefulWidget {
  final String adminKey;

  const AdminToursScreen({super.key, required this.adminKey});

  @override
  State<AdminToursScreen> createState() => _AdminToursScreenState();
}

class _AdminToursScreenState extends State<AdminToursScreen> {
  List<dynamic> _tours = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tours = await ApiService.instance.adminGetTours(adminKey: widget.adminKey);
      setState(() {
        _tours = tours;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTour(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.cardRadius)),
        title: const Text('Delete tour?'),
        content: const Text('This tour will be removed permanently.'),
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
      await ApiService.instance.adminDeleteTour(id, adminKey: widget.adminKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tour deleted successfully')),
        );
        _loadTours();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editTour(Map<String, dynamic> tour) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTourFormScreen(
          adminKey: widget.adminKey,
          tour: tour,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadTours();
    }
  }

  Future<void> _addTour() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTourFormScreen(
          adminKey: widget.adminKey,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadTours();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_tours.isEmpty) {
      body = AdminEmptyState(
        icon: FontAwesomeIcons.route,
        title: 'No tours yet',
        subtitle: 'Add your first tour to get started.',
        onAdd: _addTour,
        addLabel: 'Add Tour',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadTours,
        color: AdminTheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(28),
          itemCount: _tours.length,
          itemBuilder: (context, index) {
            final tour = _tours[index];
            return AdminItemCard(
              title: tour['name'] ?? 'Unnamed',
              subtitle: tour['duration'] ?? '',
              icon: FontAwesomeIcons.route,
              onTap: () => _editTour(tour),
              onEdit: () => _editTour(tour),
              onDelete: () => _deleteTour(tour['id']),
            );
          },
        ),
      );
    }

    return AdminPageScaffold(
      title: 'Tours',
      subtitle: '${_tours.length} tour${_tours.length == 1 ? '' : 's'}',
      icon: FontAwesomeIcons.route,
      body: body,
      onAdd: _addTour,
      addLabel: 'Add tour',
      isLoading: _isLoading,
      error: _error,
      onRetry: _loadTours,
    );
  }
}
