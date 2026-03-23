import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Normalize API/DB JSON: accept snake_case keys so we parse regardless of backend format.
Map<String, dynamic> _normalizeTripJson(Map<String, dynamic> json) {
  final m = Map<String, dynamic>.from(json);
  final keys = m.keys.toList();
  for (final k in keys) {
    if (k.contains('_')) {
      final camel = k.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (match) => (match.group(1) ?? '').toUpperCase(),
      );
      if (!m.containsKey(camel)) m[camel] = m[k];
    }
  }
  return m;
}

/// Throttle: skip API reload if last load was within this duration (avoids hammering when switching tabs).
const _tripsReloadThrottle = Duration(seconds: 30);

class TripsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final AuthProvider _auth;
  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _lastError;
  DateTime? _lastLoadTime;

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  TripsProvider(this._prefs, this._auth) {
    loadTrips();
  }

  Future<void> loadTrips({bool forceRefresh = false}) async {
    final token = _auth.authToken;
    final useApi = token != null && token.isNotEmpty && !_auth.isGuest;
    if (useApi &&
        !forceRefresh &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < _tripsReloadThrottle) {
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      if (token != null && token.isNotEmpty && !_auth.isGuest) {
        final list = await ApiService.instance.getTrips(token);
        final parsed = <Trip>[];
        for (final raw in list) {
          if (raw is! Map<String, dynamic>) continue;
          try {
            final normalized = _normalizeTripJson(raw);
            parsed.add(_tripFromApiJson(normalized));
          } catch (e) {
            debugPrint('Error parsing one trip: $e');
          }
        }
        _trips = parsed;
        _lastLoadTime = DateTime.now();
      } else {
        final tripsJson = _prefs.getString('trips');
        if (tripsJson != null) {
          final List<dynamic> jsonData = json.decode(tripsJson);
          _trips = jsonData
              .map((j) => Trip.fromJson(j as Map<String, dynamic>))
              .toList();
        } else {
          _trips = [];
        }
      }
      await _persistToLocal();
    } on ApiException catch (e) {
      debugPrint('Trips API error: ${e.statusCode} ${e.body}');
      _lastError = e.statusCode == 401
          ? 'Please sign in to load your trips.'
          : (e.statusCode == 500
              ? 'Server error. Try again.'
              : 'Could not load trips.');
      _loadTripsFromPrefs();
    } catch (e) {
      debugPrint('Error loading trips: $e');
      _lastError = 'Could not load trips.';
      _loadTripsFromPrefs();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadTripsFromPrefs() {
    final tripsJson = _prefs.getString('trips');
    if (tripsJson != null) {
      try {
        final List<dynamic> jsonData = json.decode(tripsJson);
        _trips = jsonData
            .map((j) => Trip.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _trips = [];
      }
    } else {
      _trips = [];
    }
  }

  /// Persist current _trips to SharedPreferences (cache for offline / guest).
  Future<void> _persistToLocal() async {
    try {
      final tripsJson = json.encode(_trips.map((t) => t.toJson()).toList());
      await _prefs.setString('trips', tripsJson);
    } catch (e) {
      debugPrint('Error persisting trips: $e');
    }
  }

  static Trip _tripFromApiJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final name = json['name']?.toString();
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      throw const FormatException('Trip missing id or name');
    }
    final startDate = _parseDateTime(json['startDate']);
    final endDate = _parseDateTime(json['endDate']);
    final createdAt = _parseDateTime(json['createdAt']);
    if (startDate == null || endDate == null || createdAt == null) {
      throw const FormatException('Trip missing required dates');
    }
    final daysRaw = json['days'];
    final daysList = daysRaw is List ? daysRaw : null;
    final days = (daysList ?? []).map((d) {
      if (d is Map<String, dynamic>) return TripDay.fromJson(d);
      if (d is Map) return TripDay.fromJson(Map<String, dynamic>.from(d));
      throw const FormatException('Invalid day');
    }).toList();
    return Trip(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      days: days,
      description: json['description']?.toString(),
      createdAt: createdAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  Future<void> saveTrips() async {
    await _persistToLocal();
    notifyListeners();
  }

  Future<void> addTrip(Trip trip) async {
    final token = _auth.authToken;
    if (token != null && token.isNotEmpty && !_auth.isGuest) {
      try {
        final body = {
          'name': trip.name,
          'startDate': trip.startDate.toIso8601String(),
          'endDate': trip.endDate.toIso8601String(),
          'description': trip.description,
          'days': trip.days.map((d) => d.toJson()).toList(),
        };
        final res = await ApiService.instance.createTrip(token, body);
        if (res != null) {
          _trips.add(_tripFromApiJson(res));
          await _persistToLocal();
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error creating trip on server: $e');
      }
    }
    _trips.add(trip);
    await _persistToLocal();
    notifyListeners();
  }

  Future<void> updateTrip(Trip trip) async {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index == -1) return;
    final token = _auth.authToken;
    if (token != null && token.isNotEmpty && !_auth.isGuest) {
      try {
        final body = {
          'name': trip.name,
          'startDate': trip.startDate.toIso8601String(),
          'endDate': trip.endDate.toIso8601String(),
          'description': trip.description,
          'days': trip.days.map((d) => d.toJson()).toList(),
        };
        final res = await ApiService.instance.updateTrip(token, trip.id, body);
        if (res != null) {
          _trips[index] = _tripFromApiJson(res);
          await _persistToLocal();
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error updating trip on server: $e');
      }
    }
    _trips[index] = trip;
    await _persistToLocal();
    notifyListeners();
  }

  Future<void> deleteTrip(String tripId) async {
    final token = _auth.authToken;
    if (token != null && token.isNotEmpty && !_auth.isGuest) {
      try {
        final ok = await ApiService.instance.deleteTrip(token, tripId);
        if (!ok) {
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error deleting trip on server: $e');
      }
    }
    _trips.removeWhere((t) => t.id == tripId);
    await _persistToLocal();
    notifyListeners();
  }

  Trip? getTripById(String id) {
    try {
      return _trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }

  bool hasDateConflict(DateTime startDate, DateTime endDate,
      {String? excludeTripId}) {
    return _trips.any((trip) {
      if (excludeTripId != null && trip.id == excludeTripId) return false;
      return (trip.startDate.isBefore(endDate) ||
              trip.startDate.isAtSameMomentAs(endDate)) &&
          (trip.endDate.isAfter(startDate) ||
              trip.endDate.isAtSameMomentAs(startDate));
    });
  }

  /// Returns all place IDs in trip order (across all days and slots).
  List<String> getPlaceIdsForTrip(Trip trip) {
    final ids = <String>[];
    for (final day in trip.days) {
      for (final slot in day.slots) {
        ids.add(slot.placeId);
      }
    }
    return ids;
  }

  /// Place IDs for a single day (slot order), for multi-day trip maps and directions.
  List<String> getPlaceIdsForTripDay(Trip trip, int dayIndex) {
    if (dayIndex < 0 || dayIndex >= trip.days.length) return [];
    return trip.days[dayIndex].slots.map((s) => s.placeId).toList();
  }

  /// Returns all slots in trip order (same order as getPlaceIdsForTrip).
  List<TripSlot> getSlotsForTrip(Trip trip) {
    final slots = <TripSlot>[];
    for (final day in trip.days) {
      slots.addAll(day.slots);
    }
    return slots;
  }

  /// Add a place to a trip on the given date. Creates the day if needed.
  /// Persists to the API for logged-in users so the database stays in sync.
  Future<void> addPlaceToTrip(String tripId, String placeId, String date,
      {String? startTime, String? endTime}) async {
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index == -1) return;
    final trip = _trips[index];
    final newSlot =
        TripSlot(placeId: placeId, startTime: startTime, endTime: endTime);
    final dayIndex = trip.days.indexWhere((d) => d.date == date);
    List<TripDay> newDays;
    if (dayIndex >= 0) {
      final day = trip.days[dayIndex];
      newDays = List.from(trip.days);
      newDays[dayIndex] =
          TripDay(date: day.date, slots: [...day.slots, newSlot]);
    } else {
      newDays = [
        ...trip.days,
        TripDay(date: date, slots: [newSlot])
      ];
      newDays.sort((a, b) => a.date.compareTo(b.date));
    }
    final updatedTrip = Trip(
      id: trip.id,
      name: trip.name,
      startDate: trip.startDate,
      endDate: trip.endDate,
      days: newDays,
      description: trip.description,
      createdAt: trip.createdAt,
    );
    _trips[index] = updatedTrip;
    await updateTrip(updatedTrip);
  }
}
