import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class MapProvider extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _lastLocationError;

  Position? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  /// Last error from [getCurrentLocation], cleared on success.
  String? get lastLocationError => _lastLocationError;

  Future<void> getCurrentLocation() async {
    _isLoadingLocation = true;
    _lastLocationError = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location is turned off on this device. Enable it in system settings, or choose a starting point on the map.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastLocationError = null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      _lastLocationError = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoadingLocation = false;
    notifyListeners();
  }

  void clearLocationError() {
    _lastLocationError = null;
    notifyListeners();
  }
}


