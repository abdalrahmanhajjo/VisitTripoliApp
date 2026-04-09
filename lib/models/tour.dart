class Tour {
  final String id;
  final String name;
  final String duration;
  final int durationHours;
  final int locations;
  final double rating;
  final int reviews;
  final double price;
  final String currency;
  final String priceDisplay;
  final String? badge;
  final String? badgeColor;
  final String description;
  final String image;
  final String difficulty;
  final List<String> languages;
  final List<String> includes;
  final List<String> excludes;
  final List<String> highlights;
  final List<TourItineraryItem> itinerary;
  final List<String> placeIds;

  Tour({
    required this.id,
    required this.name,
    required this.duration,
    required this.durationHours,
    required this.locations,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.currency,
    required this.priceDisplay,
    this.badge,
    this.badgeColor,
    required this.description,
    required this.image,
    required this.difficulty,
    required this.languages,
    required this.includes,
    required this.excludes,
    required this.highlights,
    required this.itinerary,
    required this.placeIds,
  });

  factory Tour.fromJson(Map<String, dynamic> json) {
    final rawItinerary = json['itinerary'];
    final itineraryItems = <TourItineraryItem>[];
    if (rawItinerary is List) {
      for (final item in rawItinerary) {
        final parsed = TourItineraryItem.fromDynamic(item);
        if (parsed != null) itineraryItems.add(parsed);
      }
    }
    return Tour(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      durationHours: (json['durationHours'] as num?)?.toInt() ?? 0,
      locations: (json['locations'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? '',
      priceDisplay: json['priceDisplay']?.toString() ?? '',
      badge: json['badge'] as String?,
      badgeColor: json['badgeColor'] as String?,
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      languages: (json['languages'] is List)
          ? List<String>.from((json['languages'] as List).map((e) => e.toString()))
          : const [],
      includes: (json['includes'] is List)
          ? List<String>.from((json['includes'] as List).map((e) => e.toString()))
          : const [],
      excludes: (json['excludes'] is List)
          ? List<String>.from((json['excludes'] as List).map((e) => e.toString()))
          : const [],
      highlights: (json['highlights'] is List)
          ? List<String>.from((json['highlights'] as List).map((e) => e.toString()))
          : const [],
      itinerary: itineraryItems,
      placeIds: (json['placeIds'] is List)
          ? List<String>.from((json['placeIds'] as List).map((e) => e.toString()))
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration,
      'durationHours': durationHours,
      'locations': locations,
      'rating': rating,
      'reviews': reviews,
      'price': price,
      'currency': currency,
      'priceDisplay': priceDisplay,
      'badge': badge,
      'badgeColor': badgeColor,
      'description': description,
      'image': image,
      'difficulty': difficulty,
      'languages': languages,
      'includes': includes,
      'excludes': excludes,
      'highlights': highlights,
      'itinerary': itinerary.map((i) => i.toJson()).toList(),
      'placeIds': placeIds,
    };
  }
}

class TourItineraryItem {
  final String time;
  final String activity;
  final String description;

  TourItineraryItem({
    required this.time,
    required this.activity,
    required this.description,
  });

  factory TourItineraryItem.fromJson(Map<String, dynamic> json) {
    return TourItineraryItem(
      time: json['time']?.toString() ?? '',
      activity: json['activity']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  /// Accepts either full object entries or plain string itinerary lines.
  static TourItineraryItem? fromDynamic(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return TourItineraryItem.fromJson(raw);
    if (raw is Map) {
      return TourItineraryItem.fromJson(
        raw.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    if (raw is String) {
      final line = raw.trim();
      if (line.isEmpty) return null;
      // Format support: "09:00 — Start: Tripoli introduction..."
      final sep = line.contains('—') ? '—' : (line.contains('-') ? '-' : null);
      if (sep != null) {
        final parts = line.split(sep);
        if (parts.length >= 2) {
          return TourItineraryItem(
            time: parts.first.trim(),
            activity: parts[1].trim(),
            description: line,
          );
        }
      }
      return TourItineraryItem(
        time: '',
        activity: line,
        description: line,
      );
    }
    return TourItineraryItem(
      time: '',
      activity: raw.toString(),
      description: raw.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'activity': activity,
      'description': description,
    };
  }
}


