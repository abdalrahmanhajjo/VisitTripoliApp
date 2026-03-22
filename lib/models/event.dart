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
    return Event(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      location: json['location'] as String,
      image: json['image'] as String?,
      category: json['category'] as String,
      organizer: json['organizer'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      priceDisplay: json['priceDisplay'] as String?,
      status: json['status'] as String?,
      placeId: json['placeId'] as String?,
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
