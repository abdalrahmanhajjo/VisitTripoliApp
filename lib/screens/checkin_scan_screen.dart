import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../utils/checkin_qr.dart';

/// Full-screen QR scanner for place check-in (official door QR with secure token).
class CheckInScanScreen extends StatefulWidget {
  final String placeName;

  const CheckInScanScreen({
    super.key,
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
    final data = parseCheckInQr(raw);
    if (data == null) return;
    _hasScanned = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop<CheckInQrData>(data);
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
                      'Scan the official QR printed at the entrance of ${widget.placeName}. '
                      'The app needs the full secure code from that sign.',
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
