class Event {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String? image;
  final String category;
  final String? organizer;
  final double? price;
  final String? priceDisplay;
  final String? status;
  final String? placeId;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.image,
    required this.category,
    this.organizer,
    this.price,
    this.priceDisplay,
    this.status,
    this.placeId,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
      final parsed = DateTime.tryParse(value.toString());
      return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return Event(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      location: json['location']?.toString() ?? '',
      image: json['image']?.toString(),
      category: json['category']?.toString() ?? '',
      organizer: json['organizer']?.toString(),
      price: json['price'] != null ? (json['price'] as num?)?.toDouble() : null,
      priceDisplay: json['priceDisplay']?.toString(),
      status: json['status']?.toString(),
      placeId: json['placeId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'image': image,
      'category': category,
      'organizer': organizer,
      'price': price,
      'priceDisplay': priceDisplay,
      'status': status,
      'placeId': placeId,
    };
  }
}
