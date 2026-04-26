import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin/admin_page_scaffold.dart';
import 'admin_place_form_screen.dart';

class AdminPlacesScreen extends StatefulWidget {
  final String adminKey;

  const AdminPlacesScreen({super.key, required this.adminKey});

  @override
  State<AdminPlacesScreen> createState() => _AdminPlacesScreenState();
}

class _AdminPlacesScreenState extends State<AdminPlacesScreen> {
  List<dynamic> _places = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final places =
          await ApiService.instance.adminGetPlaces(adminKey: widget.adminKey);
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlace(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.cardRadius)),
        title: const Text('Delete place?'),
        content: const Text(
          'This place will be removed permanently. You can’t undo this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
      await ApiService.instance.adminDeletePlace(id, adminKey: widget.adminKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Place deleted'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadPlaces();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AdminTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _generateQrForPlace(Map<String, dynamic> place) async {
    try {
      setState(() => _isLoading = true);
      final res = await ApiService.instance.adminRegeneratePlaceQrCode(place['id'], adminKey: widget.adminKey);
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      final qrPayload = res['qrPayload'] as String;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('QR Code for ${place['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text('Payload: $qrPayload', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: qrPayload));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
              },
              child: const Text('Copy Data'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _generateAndExportAllQRs() async {
    try {
      setState(() => _isLoading = true);
      // Generate all QRs first
      await ApiService.instance.adminGenerateAllPlacesQrCodes(adminKey: widget.adminKey);
      
      // Fetch them
      final qrs = await ApiService.instance.adminGetPlacesQrCodes(adminKey: widget.adminKey);
      setState(() => _isLoading = false);
      if (!mounted) return;

      final pdf = pw.Document();
      
      final chunked = <List<dynamic>>[];
      for (var i = 0; i < qrs.length; i += 6) {
        chunked.add(qrs.sublist(i, i + 6 > qrs.length ? qrs.length : i + 6));
      }

      for (final chunk in chunked) {
        pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              final rows = <pw.Widget>[];
              for (var i = 0; i < chunk.length; i += 2) {
                final rowItems = <pw.Widget>[];
                for (var j = 0; j < 2; j++) {
                  if (i + j < chunk.length) {
                    final q = chunk[i + j];
                    final payload = q['qrPayload'] as String?;
                    if (payload != null && payload.isNotEmpty) {
                      rowItems.add(
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(16),
                            margin: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey300),
                            ),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  q['name'],
                                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 16),
                                pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: payload,
                                  width: 150,
                                  height: 150,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      rowItems.add(pw.Expanded(child: pw.SizedBox()));
                    }
                  } else {
                    rowItems.add(pw.Expanded(child: pw.SizedBox()));
                  }
                }
                rows.add(pw.Row(children: rowItems));
                rows.add(pw.SizedBox(height: 16));
              }
              return pw.Column(children: rows);
            },
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'tripoli_places_qrs.pdf',
      );

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _editPlace(Map<String, dynamic> place) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminPlaceFormScreen(
          adminKey: widget.adminKey,
          place: place,
        ),
      ),
    );

    if (result != null && mounted) _loadPlaces();
  }

  Future<void> _addPlace() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminPlaceFormScreen(
          adminKey: widget.adminKey,
        ),
      ),
    );

    if (result != null && mounted) _loadPlaces();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_places.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AdminTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.locationDot,
                size: 44,
                color: AdminTheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No places yet',
              style: AdminTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first place to get started.',
              style: AdminTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _addPlace,
              style: FilledButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.inputRadius),
                ),
              ),
              icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
              label: const Text('Add Place'),
            ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadPlaces,
        color: AdminTheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(28),
          itemCount: _places.length,
          itemBuilder: (context, index) {
            final place = _places[index];
            return _PlaceCard(
              name: place['name'] ?? 'Unnamed',
              location: place['location'] ?? '',
              onTap: () => _editPlace(place),
              onEdit: () => _editPlace(place),
              onGenerateQr: () => _generateQrForPlace(place),
              onDelete: () => _deletePlace(place['id']),
            );
          },
        ),
      );
    }

    return AdminPageScaffold(
      title: 'Places',
      subtitle: '${_places.length} place${_places.length == 1 ? '' : 's'}',
      icon: FontAwesomeIcons.locationDot,
      body: body,
      onAdd: _addPlace,
      addLabel: 'Add place',
      actions: [
        OutlinedButton.icon(
          onPressed: _generateAndExportAllQRs,
          icon: const FaIcon(FontAwesomeIcons.download, size: 14),
          label: const Text('Generate & Export QRs'),
        ),
        const SizedBox(width: 12),
      ],
      isLoading: _isLoading,
      error: _error,
      onRetry: _loadPlaces,
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String name;
  final String location;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onGenerateQr;

  const _PlaceCard({
    required this.name,
    required this.location,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onGenerateQr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AdminTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AdminTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.locationDot,
                    color: AdminTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AdminTheme.titleMedium.copyWith(fontSize: 16),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location,
                          style: AdminTheme.bodyMedium.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onGenerateQr,
                  icon: const FaIcon(FontAwesomeIcons.qrcode, size: 18),
                  color: AdminTheme.primary,
                  tooltip: 'Generate QR',
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 18),
                  color: AdminTheme.textSecondary,
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const FaIcon(FontAwesomeIcons.trashCan, size: 18),
                  color: AdminTheme.error,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
