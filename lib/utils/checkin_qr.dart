import 'package:flutter/foundation.dart';

/// Data encoded in official door check-in QR codes (not exposed in public place APIs).
@immutable
class CheckInQrData {
  final String placeId;
  final String? token;

  const CheckInQrData({required this.placeId, this.token});
}

/// Canonical payload string for printing — must match [backend/src/routes/admin.js] `buildCheckinQrPayload`.
String buildOfficialCheckinQrPayload(String placeId, String token) {
  final uri = Uri(
    scheme: 'tripoli-explorer',
    host: 'checkin',
    queryParameters: <String, String>{
      'p': placeId,
      'token': token,
    },
  );
  return uri.toString();
}

/// Parses QR raw value from scanner. Supports official format + legacy plain place id (no token).
CheckInQrData? parseCheckInQr(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();

  final uri = Uri.tryParse(s);
  if (uri != null && uri.hasScheme) {
    // tripoli-explorer://checkin?p=PLACE_ID&token=SECRET
    if (uri.scheme == 'tripoli-explorer' && uri.host == 'checkin') {
      final p = uri.queryParameters['p'] ?? uri.queryParameters['placeId'];
      final t = uri.queryParameters['token'] ?? uri.queryParameters['t'];
      if (p != null && p.isNotEmpty && t != null && t.isNotEmpty) {
        return CheckInQrData(placeId: p, token: t);
      }
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        final t2 = uri.queryParameters['token'] ?? uri.queryParameters['t'];
        if (last.isNotEmpty && t2 != null && t2.isNotEmpty) {
          return CheckInQrData(placeId: last, token: t2);
        }
      }
    }

    // https?://...?p=...&token=... (optional universal links)
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      final p = uri.queryParameters['p'] ?? uri.queryParameters['placeId'];
      final t = uri.queryParameters['token'] ?? uri.queryParameters['t'];
      if (p != null && p.isNotEmpty && t != null && t.isNotEmpty) {
        return CheckInQrData(placeId: p, token: t);
      }
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        final t2 = uri.queryParameters['token'] ?? uri.queryParameters['t'];
        if (last.isNotEmpty && t2 != null && t2.isNotEmpty) {
          return CheckInQrData(placeId: last, token: t2);
        }
      }
    }
  }

  // Legacy: raw place id only (server will reject without token)
  if (!s.contains('://') && !s.contains('?')) {
    return CheckInQrData(placeId: s, token: null);
  }

  return null;
}
