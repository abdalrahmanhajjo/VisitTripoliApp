class Place {
  final String id;
  final String name;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> images;
  final String category;
  final String? categoryId;
  final String? duration;
  final String? price;
  final String? bestTime;
  final double? rating;
  final int? reviewCount;
  final Map<String, dynamic>? hours;
  final List<String>? tags;

  /// Optional: name as it appears on Google Maps (for accurate geocoding).
  final String? searchName;

  /// Search string for Google Maps (place name or address).
  /// Use this for MapLauncher instead of lat/lng when location is resolved by name.
  String get mapSearchName =>
      searchName?.trim().isNotEmpty == true
          ? '$searchName, Tripoli Lebanon'
          : '$name, $location, Tripoli Lebanon';

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.images,
    required this.category,
    this.categoryId,
    this.duration,
    this.price,
    this.bestTime,
    this.rating,
    this.reviewCount,
    this.hours,
    this.tags,
    this.searchName,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      images: List<String>.from(json['images'] as List),
      category: json['category'] as String,
      categoryId: json['categoryId'] as String?,
      duration: json['duration'] as String?,
      price: json['price'] as String?,
      bestTime: json['bestTime'] as String?,
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['reviewCount'] as int?,
      hours: json['hours'] as Map<String, dynamic>?,
      tags:
          json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      searchName: json['searchName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'category': category,
      'categoryId': categoryId,
      'duration': duration,
      'price': price,
      'bestTime': bestTime,
      'rating': rating,
      'reviewCount': reviewCount,
      'hours': hours,
      'tags': tags,
      'searchName': searchName,
    };
  }
}
