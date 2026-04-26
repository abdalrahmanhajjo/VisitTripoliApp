import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../utils/checkin_qr.dart';

class PlaceScanScreen extends StatefulWidget {
  const PlaceScanScreen({super.key});

  @override
  State<PlaceScanScreen> createState() => _PlaceScanScreenState();
}

class _PlaceScanScreenState extends State<PlaceScanScreen> {
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null) return;
    
    // First try the checkin QR format
    final data = parseCheckInQr(raw);
    if (data != null) {
      _hasScanned = true;
      HapticFeedback.mediumImpact();
      context.replace('/place/${data.placeId}');
      return;
    }
    
    // Fallback: If it's a URL ending with place/id, parse it
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.pathSegments.contains('place')) {
      final index = uri.pathSegments.indexOf('place');
      if (index + 1 < uri.pathSegments.length) {
        final placeId = uri.pathSegments[index + 1];
        _hasScanned = true;
        HapticFeedback.mediumImpact();
        context.replace('/place/$placeId');
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Scan a place QR code to view its details.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const AspectRatio(
                    aspectRatio: 1,
                    child: SizedBox.expand(),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
