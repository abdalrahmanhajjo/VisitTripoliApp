class Trip {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<TripDay> days;
  final String? description;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.days,
    this.description,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      days: (json['days'] as List)
          .map((d) => TripDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'days': days.map((d) => d.toJson()).toList(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class TripDay {
  final String date;
  final List<TripSlot> slots;

  TripDay({
    required this.date,
    required this.slots,
  });

  factory TripDay.fromJson(Map<String, dynamic> json) {
    return TripDay(
      date: json['date'] as String,
      slots: (json['slots'] as List)
          .map((s) => TripSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'slots': slots.map((s) => s.toJson()).toList(),
    };
  }
}

class TripSlot {
  final String placeId;
  final String? startTime;
  final String? endTime;
  final String? notes;

  TripSlot({
    required this.placeId,
    this.startTime,
    this.endTime,
    this.notes,
  });

  factory TripSlot.fromJson(Map<String, dynamic> json) {
    return TripSlot(
      placeId: json['placeId'] as String,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'startTime': startTime,
      'endTime': endTime,
      'notes': notes,
    };
  }
}
