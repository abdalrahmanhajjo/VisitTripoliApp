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
    return Tour(
      id: json['id'] as String,
      name: json['name'] as String,
      duration: json['duration'] as String,
      durationHours: json['durationHours'] as int,
      locations: json['locations'] as int,
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      priceDisplay: json['priceDisplay'] as String,
      badge: json['badge'] as String?,
      badgeColor: json['badgeColor'] as String?,
      description: json['description'] as String,
      image: json['image'] as String,
      difficulty: json['difficulty'] as String,
      languages: List<String>.from(json['languages'] as List),
      includes: List<String>.from(json['includes'] as List),
      excludes: List<String>.from(json['excludes'] as List),
      highlights: List<String>.from(json['highlights'] as List),
      itinerary: (json['itinerary'] as List)
          .map((i) => TourItineraryItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      placeIds: List<String>.from(json['placeIds'] ?? []),
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
      time: json['time'] as String,
      activity: json['activity'] as String,
      description: json['description'] as String,
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


