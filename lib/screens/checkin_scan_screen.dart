import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

/// Extracts place ID from QR content. Supports:
/// - Raw place ID (e.g. "place_123")
/// - URL with path segment: tripoli-explorer://checkin/place_123 or .../place/place_123
String? parsePlaceIdFromQr(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  try {
    final uri = Uri.tryParse(s);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last;
      if (last.isNotEmpty) return last;
    }
  } catch (_) {}
  return s;
}

/// Full-screen QR scanner for place check-in. Scanned code must match [expectedPlaceId].
class CheckInScanScreen extends StatefulWidget {
  final String expectedPlaceId;
  final String placeName;

  const CheckInScanScreen({
    super.key,
    required this.expectedPlaceId,
    required this.placeName,
  });

  @override
  State<CheckInScanScreen> createState() => _CheckInScanScreenState();
}

class _CheckInScanScreenState extends State<CheckInScanScreen> {
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    final placeId = parsePlaceIdFromQr(raw);
    if (placeId == null) return;
    _hasScanned = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(placeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan QR to check in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
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
                    child: Text(
                      'Point your camera at the QR code at ${widget.placeName}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
