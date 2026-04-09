import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _my = const [];
  List<Map<String, dynamic>> _place = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please sign in to view messages.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.instance.getMyProposals(token),
        ApiService.instance.getPlaceProposals(token),
      ]);
      if (!mounted) return;
      setState(() {
        _my = ((results[0]['proposals'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _place = ((results[1]['proposals'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My requests'),
            Tab(text: 'Business inbox'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ProposalList(items: _my),
                      _ProposalList(items: _place),
                    ],
                  ),
                ),
    );
  }
}

class _ProposalList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ProposalList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 140),
          Center(
            child: Text(
              'No messages yet',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = items[i];
        final title = (p['placeName'] ?? p['place_name'] ?? 'Place').toString();
        final body = (p['message'] ?? '').toString();
        final status = (p['status'] ?? 'pending').toString();
        final response = (p['restaurantResponse'] ?? p['restaurant_response'] ?? '')
            .toString();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      status,
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(color: AppTheme.textSecondary)),
                if (response.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(response),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
