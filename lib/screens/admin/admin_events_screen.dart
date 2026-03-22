import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import 'admin_event_form_screen.dart';

class AdminEventsScreen extends StatefulWidget {
  final String adminKey;

  const AdminEventsScreen({super.key, required this.adminKey});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  List<dynamic> _events = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await ApiService.instance.adminGetEvents(adminKey: widget.adminKey);
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.cardRadius)),
        title: const Text('Delete event?'),
        content: const Text('This event will be removed permanently.'),
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
      await ApiService.instance.adminDeleteEvent(id, adminKey: widget.adminKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
        _loadEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editEvent(Map<String, dynamic> event) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEventFormScreen(
          adminKey: widget.adminKey,
          event: event,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadEvents();
    }
  }

  Future<void> _addEvent() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEventFormScreen(
          adminKey: widget.adminKey,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_events.isEmpty) {
      body = AdminEmptyState(
        icon: FontAwesomeIcons.calendarDays,
        title: 'No events yet',
        subtitle: 'Add your first event to get started.',
        onAdd: _addEvent,
        addLabel: 'Add Event',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadEvents,
        color: AdminTheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(28),
          itemCount: _events.length,
          itemBuilder: (context, index) {
            final event = _events[index];
            return AdminItemCard(
              title: event['name'] ?? 'Unnamed',
              subtitle: event['start_date'] ?? '',
              icon: FontAwesomeIcons.calendarDays,
              onTap: () => _editEvent(event),
              onEdit: () => _editEvent(event),
              onDelete: () => _deleteEvent(event['id']),
            );
          },
        ),
      );
    }
    return AdminPageScaffold(
      title: 'Events',
      subtitle: '${_events.length} event${_events.length == 1 ? '' : 's'}',
      icon: FontAwesomeIcons.calendarDays,
      body: body,
      onAdd: _addEvent,
      addLabel: 'Add event',
      isLoading: _isLoading,
      error: _error,
      onRetry: _loadEvents,
    );
  }
}
